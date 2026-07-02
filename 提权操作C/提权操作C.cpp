#include<共享头.h>
#include<phnt_windows.h>
#include<MATLAB异常.h>
#define PHNT_VERSION PHNT_WIN11_24H2
#include<phnt.h>
#include<AclAPI.h>
import std;
using namespace std::filesystem;
static path EXE目录;
static inline const path& 安装目录()noexcept
{
	static const path 返回值 = path(EXE目录) / L"安装";
	return 返回值;
} 
static inline const path& 数据目录()noexcept
{
	static const path 返回值 = []()noexcept
		{
			constexpr wchar_t ProgramData[] = L"ProgramData";
			const DWORD Size = GetEnvironmentVariableW(ProgramData, nullptr, 0);
			std::unique_ptr<wchar_t[]>Buffer = std::make_unique_for_overwrite<wchar_t[]>(Size);
			GetEnvironmentVariableW(ProgramData, Buffer.get(), Size);
			return path(Buffer.get()) / L"MathWorks\\埃博拉酱";
		}();
	return 返回值;
}
static inline const path& 共享路径()noexcept
{
	static const path 返回值 = 数据目录() / L"共享路径.txt";
	return 返回值;
}
static inline const path& 原文件目录()noexcept
{
	static const path 返回值 = 数据目录() / L"原文件";
	return 返回值;
}
static std::ostringstream RC输出流(const path& MatlabRc)noexcept
{
	std::ifstream RC输入流(MatlabRc);
	std::string 行;
	std::ostringstream 输出流;
	while (std::getline(RC输入流, 行))
		if (!行.ends_with("%埃博拉酱"))
			输出流 << 行 << std::endl;
	return 输出流;
}
template<typename 指针类型,typename 释放类型>
struct 系统指针
{
	系统指针(释放类型 释放函数, 指针类型 裸指针 = nullptr)noexcept :释放函数(释放函数), 裸指针(裸指针) {};
	指针类型* operator&()noexcept
	{
		释放函数(裸指针);
		return &裸指针;
	}
	operator 指针类型()const noexcept
	{
		return 裸指针;
	}
	~系统指针()
	{
		释放函数(裸指针);
	}
	系统指针(const 系统指针&) = delete;
	系统指针(系统指针&& 旧)noexcept:释放函数(旧.释放函数),裸指针(旧.裸指针)
	{
		旧.裸指针 = nullptr;
	}
	指针类型 operator=(指针类型 新)noexcept
	{
		释放函数(裸指针);
		return 裸指针 = 新;
	}
	operator bool()const noexcept
	{
		return 裸指针;
	}
protected:
	指针类型 裸指针;
	const 释放类型 释放函数;
};
template<typename T>
struct 原地扩张缓冲
{
	原地扩张缓冲()noexcept = default;
	原地扩张缓冲(size_t 元素数)
	{
		resize(元素数);
	}
	~原地扩张缓冲()noexcept
	{
		free(数据);
	}
	原地扩张缓冲(const 原地扩张缓冲&) = delete;
		原地扩张缓冲& operator=(const 原地扩张缓冲&) = delete;
	原地扩张缓冲(原地扩张缓冲&& 旧)noexcept :数据(旧.数据),容量(旧.容量)
	{
		旧.数据 = nullptr;
		旧.容量 = 0;
	}
	原地扩张缓冲& operator=(原地扩张缓冲&& 旧)noexcept
	{
		if (this != &旧)
		{
			free(数据);
			数据 = 旧.数据;
			容量 = 旧.容量;
			旧.数据 = nullptr;
			旧.容量 = 0;
		}
		return *this;
	}
	void resize(size_t 元素数)noexcept
	{
		数据 = reinterpret_cast<T*>(realloc(数据, 元素数 * sizeof(T)));
		容量 = 元素数;
	}
	inline T* get()const noexcept
	{
		return 数据;
	}
	inline size_t size()const noexcept
	{
		return 容量;
	}
protected:
	T* 数据 = nullptr;
	size_t 容量 = 0;
};
static HANDLE File;
static DWORD NumberOfBytesRead;
static std::wstring 读入UTF16字符串()noexcept
{
	size_t 字符串长度;
	ReadFile(File, &字符串长度, sizeof(字符串长度), &NumberOfBytesRead, NULL);
	std::wstring 缓冲区;
	缓冲区.resize_and_overwrite(字符串长度, [](wchar_t* 指针, size_t 长度)
		{
			ReadFile(File, 指针, 长度 * sizeof(wchar_t), &NumberOfBytesRead, NULL);
			return 长度;
		});
	return 缓冲区;
}
static std::string 读入UTF8字符串()noexcept
{
	const std::wstring UTF16 = 读入UTF16字符串();
	std::string UTF8;
	UTF8.resize_and_overwrite(UTF16.size() * 3, [&UTF16](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, NULL, UTF16.c_str(), UTF16.size(), 指针, 尺寸, NULL, NULL); });
	return UTF8;
}
//此函数假定文件存在
static void 设置文件权限(LPWSTR ObjectName, LPWSTR TrusteeName, DWORD AccessPermissions)noexcept
{
	PACL Dacl;
	系统指针<PSECURITY_DESCRIPTOR, decltype(LocalFree)*>SecurityDescriptor(LocalFree);
	EXPLICIT_ACCESS_W ExplicitAccess;
	static wchar_t Users[] = L"Users";
	GetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &Dacl, NULL, &SecurityDescriptor);
	//这一步返回的Dacl不应被释放
	BuildExplicitAccessWithNameW(&ExplicitAccess, TrusteeName, AccessPermissions, GRANT_ACCESS, SUB_CONTAINERS_AND_OBJECTS_INHERIT);
	SetEntriesInAclW(1, &ExplicitAccess, Dacl, &Dacl);
	//这一步返回的Dacl需要释放
	SetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, Dacl, NULL);
	LocalFree(Dacl);
}
#define API(名称) static void 名称(std::ostringstream&输出)
static path MatlabSavepath(const path& MatlabRoot)noexcept
{
	return MatlabRoot / L"toolbox\\matlab\\general\\savepath.m";
}
static inline const path& 原Savepath()noexcept
{
	static const path 返回值 = 原文件目录() / L"savepath.m";
	return 返回值;
}
static path MatlabRc(const path& MatlabRoot)noexcept
{
	return MatlabRoot / L"toolbox\\local\\matlabrc.m";
}
static bool 文件未修复(const path& Matlab文件路径)noexcept
{
	std::string 行;
	std::ifstream 输入流(Matlab文件路径);
	while (std::getline(输入流, 行))
		if (行.contains("埃博拉酱修复"))
			return false;
	return true;
}
static DWORD 计算VersionMS(const std::wstring& MATLAB版本)noexcept
{
	std::wistringstream 版本号拆分(MATLAB版本);
	std::wstring 号;
	std::getline(版本号拆分, 号, L'.');
	DWORD 返回值 = std::stoi(号) << 16;
	std::getline(版本号拆分, 号, L'.');
	返回值 += std::stoi(号);
	return 返回值;
}
struct 版本名称值
{
	std::wstring 版本名称;
	DWORD 版本值;
	版本名称值(const std::wstring& 版本名称) :版本名称(版本名称), 版本值(计算VersionMS(版本名称)) {}
	版本名称值(std::wstring&& 版本名称) :版本名称(std::move(版本名称)), 版本值(计算VersionMS(版本名称)) {}
};
static std::vector<版本名称值> 所有版本(DWORD 版本值)noexcept
{
	std::vector<版本名称值>返回值;
	for (const directory_entry& 条目 : directory_iterator(安装目录()))
		if (条目.is_directory())
		{
			const 版本名称值 名称值(条目.path().filename().native());
			if (名称值.版本值 <= 版本值)
				返回值.push_back(名称值);
		}
	std::sort(返回值.begin(), 返回值.end(), [](const 版本名称值& a, const 版本名称值& b)
		{
			return a.版本值 > b.版本值;
		});
	return 返回值;
}
static DWORD 当前VersionMS(const std::wstring& MATLAB版本)noexcept
{
	return 计算VersionMS(MATLAB版本);
}
API(Install_path_manager)
{
	const path MatlabRoot(读入UTF16字符串());
	const std::wstring MatlabVersion = 读入UTF16字符串();
	create_directories(原文件目录());
	static const path& MSP = MatlabSavepath(MatlabRoot);
	if (文件未修复(MSP))
		copy_file(MSP, 原Savepath(), copy_options::overwrite_existing);
	for (const 版本名称值& 版本 : 所有版本(当前VersionMS(MatlabVersion)))
	{
		const path 版本文件路径 = 安装目录() / 版本.版本名称 / L"savepath.m";
		if (exists(版本文件路径))
		{
			copy_file(版本文件路径, MSP, copy_options::overwrite_existing);
			break;
		}
	}
	static const path 可执行目录 = 数据目录() / L"可执行";
	static const path internal目录 = 可执行目录 / L"+MATLAB\\+internal";
	create_directories(internal目录);
	copy_file(安装目录() / L"RcAddPath.m", internal目录 / L"RcAddPath.m", copy_options::overwrite_existing);
	if (!is_regular_file(共享路径()))
		std::ofstream(共享路径()).close();
	const path& MRC = MatlabRc(MatlabRoot);
	std::ostringstream 输出流 = RC输出流(MRC);
	static const std::string RC加尾 = []()
		{
			const int MultiByte = 可执行目录.native().size() * 3 + 1;
			const std::unique_ptr<char[]>可执行目录UTF8 = std::make_unique_for_overwrite<char[]>(MultiByte);
			WideCharToMultiByte(CP_UTF8, 0, 可执行目录.c_str(), -1, 可执行目录UTF8.get(), MultiByte, NULL, NULL);
			std::ostringstream 返回值;
			返回值 << "addpath('" << 可执行目录UTF8.get() << "');MATLAB.internal.RcAddPath;%埃博拉酱";
			return 返回值.str();
		}();
	输出流 << RC加尾;
	std::ofstream(MRC) << 输出流.str();
	static const std::unique_ptr<wchar_t[]>路径缓冲 = [&MatlabRoot]()
		{
			const path::string_type PathDef = (MatlabRoot / L"toolbox\\local\\pathdef.m").native();
			std::unique_ptr<wchar_t[]>返回值 = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
			wcscpy(路径缓冲.get(), PathDef.c_str());
			return 返回值;
		}(); 
	static wchar_t TrusteeName[] = L"Users";
	设置文件权限(路径缓冲.get(), TrusteeName, GENERIC_READ);
}
API(Uninstall_path_manager)
{
	path MatlabRoot(读入UTF16字符串());
	static const path& MSP = MatlabSavepath(MatlabRoot);
	if (!文件未修复(MSP))
		rename(原Savepath(), MatlabSavepath(MatlabRoot));
	static const path& MRC = MatlabRc(MatlabRoot);
	std::ofstream(MRC) << RC输出流(MRC).str();
}
static std::unordered_set<std::string>输入路径集合()noexcept
{
	std::istringstream 输入路径(读入UTF8字符串());
	std::string 路径;
	std::unordered_set<std::string>路径集合;
	while (std::getline(输入路径, 路径, ';'))
		路径集合.insert(std::move(路径));
	return 路径集合;
}
static void 开放新路径权限(const std::unordered_set<std::string>&新路径集合)
{
	PACL Dacl;
	系统指针<PSECURITY_DESCRIPTOR, decltype(LocalFree)*>SecurityDescriptor(LocalFree);
	EXPLICIT_ACCESS_A ExplicitAccess;
	static char Users[] = "Users";
	std::unique_ptr<char[]>路径缓冲;
	size_t 缓冲区大小 = 0;
	for (const std::string& 路径 : 新路径集合)
	{
		if (路径.size() + 1 > 缓冲区大小)
			路径缓冲 = std::make_unique_for_overwrite<char[]>(缓冲区大小 = 路径.size() + 1);
		strcpy(路径缓冲.get(), 路径.c_str());
		switch (GetNamedSecurityInfoA(路径缓冲.get(), SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &Dacl, NULL, &SecurityDescriptor))
		{
		case ERROR_FILE_NOT_FOUND:
			throw MATLAB::Exception::File_not_found;
		case ERROR_BAD_PATHNAME:
			throw MATLAB::Exception::Bad_pathname;
		}
		//这一步取得的ACL不能释放
		BuildExplicitAccessWithNameA(&ExplicitAccess, Users, GENERIC_READ | GENERIC_EXECUTE, GRANT_ACCESS, SUB_CONTAINERS_AND_OBJECTS_INHERIT);
		SetEntriesInAclA(1, &ExplicitAccess, Dacl, &Dacl);
		SetNamedSecurityInfoA(路径缓冲.get(), SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, Dacl, NULL);
		LocalFree(Dacl);
	}
}
static void 写出路径(const std::unordered_set<std::string>& 新路径集合)noexcept
{
	std::ofstream 输出流(共享路径());
	for (const std::string& 路径 : 新路径集合)
		输出流 << 路径 << ';';
}
API(Set_shared_path)
{
	const std::unordered_set<std::string>输入集合 = 输入路径集合();
	std::unordered_set<std::string>新路径集合 = 输入集合;
	std::ifstream 旧路径(共享路径());
	std::string 路径;
	while (std::getline(旧路径, 路径, ';'))
		新路径集合.erase(路径);
	旧路径.close();
	开放新路径权限(新路径集合);
	写出路径(输入集合);
}
API(Add_shared_path)
{
	std::unordered_set<std::string>新路径集合 = 输入路径集合();
	std::unordered_set<std::string>输出路径集合 = 新路径集合;
	std::ifstream 旧路径(共享路径());
	std::string 路径;
	while (std::getline(旧路径, 路径, ';'))
	{
		新路径集合.erase(路径);
		输出路径集合.insert(std::move(路径));
	}
	旧路径.close();
	开放新路径权限(新路径集合);
	写出路径(输出路径集合);
}
API(Remove_shared_path)
{
	std::unordered_set<std::string>路径集合;
	std::ifstream 旧路径(共享路径());
	std::string 路径;
	while (std::getline(旧路径, 路径, ';'))
		路径集合.insert(std::move(路径));
	旧路径.close();
	std::istringstream 删除路径(读入UTF8字符串());
	while (std::getline(删除路径, 路径, ';'))
		路径集合.erase(路径);
	写出路径(路径集合);
}
API(Builtin_bug_fix)
{
	struct 补丁位置
	{
		wchar_t 文件名[32];
		wchar_t 目标目录[128];
	};
	const path MatlabRoot(读入UTF16字符串());
	const std::wstring MatlabVersion = 读入UTF16字符串();
	size_t 命令数;
	DWORD NumberOfBytes;
	ReadFile(File, &命令数, sizeof(命令数), &NumberOfBytes, NULL);
	std::unique_ptr<std::int8_t[]>所有命令 = std::make_unique_for_overwrite<int8_t[]>(命令数);
	ReadFile(File, 所有命令.get(), 命令数, &NumberOfBytes, NULL);
	//必须先读完所有参数。如果参数没读完就退出函数，剩余的无效参数会进入下一轮命令循环，导致不可预测的情况
	static const std::vector<补丁位置>& 版本命令集 = [&MatlabVersion]()
		{
			static const std::unordered_map<std::wstring, std::vector<补丁位置>>补丁信息
			{
				{
					L"23.2",
					{{
						{
							L"getDocumentationXML.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc"
						},
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"Document.m",
							L"toolbox\\matlab\\codetools\\+matlab\\+desktop\\+editor\\@Document",
						},
						{
							L"ToolboxConfigurationReader.m",
							L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
						},
						{
							L"getReferencePage.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+reference"
						}
					}}
				},
				{
					L"24.1",
					{{
						{
							L"safeWhich.m",
							L"toolbox\\matlab\\lang\\+matlab\\+lang\\+internal\\+introspective"
						},
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"Document.m",
							L"toolbox\\matlab\\codetools\\+matlab\\+desktop\\+editor\\@Document",
						},
						{
							L"ToolboxConfigurationReader.m",
							L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
						}
					}}
				},
				{
					L"24.2",
					{{
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"Document.m",
							L"toolbox\\matlab\\codetools\\+matlab\\+desktop\\+editor\\@Document",
						},
						{
							L"ToolboxConfigurationReader.m",
							L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
						}
					}}
				},
				{
					L"25.1",
					{{
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"ToolboxConfigurationReader.m",
							L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
						},
						{
							L"BuildRunner.m",
							L"toolbox\\matlab\\buildtool\\core\\+matlab\\+buildtool"
						}
					}}
				},
				{
					L"25.2",
					{{
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"ToolboxConfigurationReader.m",
							L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
						},
						{
							L"BuildRunner.m",
							L"toolbox\\matlab\\buildtool\\core\\+matlab\\+buildtool"
						},
						{
							L"Completion.m",
							L"toolbox\\matlab\\depfun\\+matlab\\+depfun\\+internal",
						}
					}}
				},
				{
					L"26.1",
					{{
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
						},
						{
							L"Completion.m",
							L"toolbox\\matlab\\depfun\\+matlab\\+depfun\\+internal",
						},
						{
							L"BuildRunner.m",
							L"toolbox\\matlab\\buildtool\\core\\+matlab\\+buildtool"
						}
					}}
				}
			};
			const auto 返回值 = 补丁信息.find(MatlabVersion);
			if (返回值 == 补丁信息.cend())
				throw MATLAB::Exception::Current_MATLAB_version_not_supported;
			return 返回值->second;
		}();
	static const path 版本原文件目录 = 原文件目录() / MatlabVersion;
	create_directories(版本原文件目录);
	for (size_t C = 0; C < 命令数; ++C)
	{
		int8_t 命令 = 所有命令[C];
		if (命令 > 0)
		{
			命令--;
			const 补丁位置& 命令位置 = 版本命令集[命令];
			const path Matlab文件路径 = MatlabRoot / 命令位置.目标目录 / 命令位置.文件名;
			if (文件未修复(Matlab文件路径))
				copy_file(Matlab文件路径, 版本原文件目录 / 命令位置.文件名, copy_options::overwrite_existing);
				for (const 版本名称值& 版本 : 所有版本(当前VersionMS(MatlabVersion)))
				{
					const path 版本文件路径 = 安装目录() / 版本.版本名称 / 命令位置.文件名;
					if (exists(版本文件路径))
					{
						copy_file(版本文件路径, Matlab文件路径, copy_options::overwrite_existing);
						break;
					}
				}
		}
		else if (命令 < 0)
		{
			命令 = -1 - 命令;
			const 补丁位置& 命令位置 = 版本命令集[命令];
			const path Matlab文件路径 = MatlabRoot / 命令位置.目标目录 / 命令位置.文件名;
			if (!文件未修复(Matlab文件路径))
				rename(版本原文件目录 / 命令位置.文件名, Matlab文件路径);
		}
		else
			throw MATLAB::Exception::Builtin_bug_fix_command_is_0;
	}
}
API(Associate_prj_extension)
{
	const path MatlabRoot(读入UTF16字符串());
	const std::wstring MATLAB版本 = 读入UTF16字符串() + L".0";
	系统指针<HKEY, decltype(RegCloseKey)*>键A(RegCloseKey);
	RegCreateKeyExW(HKEY_CLASSES_ROOT, L".prj", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	static const std::wstring prj类 = L"MATLAB.prj." + MATLAB版本;
	RegSetValueExW(键A, NULL, 0, REG_SZ, (const BYTE*)prj类.c_str(), (prj类.size() + 1) * sizeof(wchar_t));
	constexpr wchar_t mwopc[] = L"mwopc";
	RegSetValueExW(键A, L"PerceivedType", 0, REG_SZ, (const BYTE*)mwopc, sizeof(mwopc));
	constexpr wchar_t OpenWithProgids[] = L"";
	RegSetKeyValueW(键A, L"OpenWithProgids", prj类.c_str(), REG_SZ, OpenWithProgids, sizeof(OpenWithProgids));
	系统指针<HKEY, decltype(RegCloseKey)*>键B(RegCloseKey);
	RegCreateKeyExW(键A, L"ShellEx", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键B, NULL);
	constexpr wchar_t ShellEx[] = L"{44121072-A222-48f2-A58A-6D9AD51EBBE9}";
	RegSetKeyValueW(键B, L"{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}", NULL, REG_SZ, ShellEx, sizeof(ShellEx));
	RegSetKeyValueW(键B, L"{E357FCCD-A995-4576-B01F-234630154E96}", NULL, REG_SZ, ShellEx, sizeof(ShellEx));
	static const std::wstring Versions = L"Versions\\" + prj类;
	RegCreateKeyExW(键A, Versions.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, NULL, &键B, NULL);
	constexpr DWORD FileVersionLS = 0;
	RegSetValueExW(键B, L"FileVersionLS", 0, REG_DWORD, (const BYTE*)&FileVersionLS, sizeof(FileVersionLS));
	static const DWORD FileVersionMS = 当前VersionMS(MATLAB版本);
	RegSetValueExW(键B, L"FileVersionMS", 0, REG_DWORD, (const BYTE*)&FileVersionMS, sizeof(FileVersionMS));
	RegCreateKeyExW(HKEY_CLASSES_ROOT, prj类.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	static const std::wstring DefaultIcon = L"\"" + (MatlabRoot / L"bin\\win64\\osintegplugins\\osintegplugins\\mlproj\\mwmlprojfaplugin.dll").native() + L"\",0";
	RegSetKeyValueW(键A, L"DefaultIcon", NULL, REG_SZ, DefaultIcon.c_str(), (DefaultIcon.size() + 1) * sizeof(wchar_t));
	RegCreateKeyExW(键A, L"Shell\\Open", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键B, NULL);
	constexpr wchar_t Open[] = L"Open";
	RegSetValueExW(键B, NULL, 0, REG_SZ, (const BYTE*)Open, sizeof(Open));
	static const std::wstring command = L"\"" + (MatlabRoot / L"bin\\win64\\matlab.exe").native() + L"\" -r \"uiopen('%1',1)\"";
	RegSetKeyValueW(键B, L"command", NULL, REG_SZ, command.c_str(), (command.size() + 1) * sizeof(wchar_t));
	RegCreateKeyExW(键B, L"ddeexec", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	constexpr wchar_t uiopen[] = L"uiopen('%1',1)";
	RegSetValueExW(键A, NULL, 0, REG_SZ, (const BYTE*)uiopen, sizeof(uiopen));
	static const std::wstring application = L"ShellVerbs.MATLAB." + MATLAB版本;
	RegSetKeyValueW(键A, L"application", NULL, REG_SZ, application.c_str(), (application.size() + 1) * sizeof(wchar_t));
	constexpr wchar_t system[] = L"system";
	RegSetKeyValueW(键A, L"topic", NULL, REG_SZ, system, sizeof(system));
}
API(Get_pathdef_permission)
{
	const std::wstring PathDef = 读入UTF16字符串();
	static const std::unique_ptr<wchar_t[]>ObjectName = [&PathDef]()
		{
			std::unique_ptr<wchar_t[]>返回值 = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
			wcscpy(返回值.get(), PathDef.c_str());
			return 返回值;
		}();
		static const std::unique_ptr<wchar_t[]>Buffer = []()
			{
				constexpr wchar_t Name[] = L"USERNAME";
				const DWORD Size = GetEnvironmentVariableW(Name, nullptr, 0);
				std::unique_ptr<wchar_t[]>返回值 = std::make_unique_for_overwrite<wchar_t[]>(Size);
				GetEnvironmentVariableW(Name, 返回值.get(), Size);
				return 返回值;
			}();
	设置文件权限(ObjectName.get(), Buffer.get(), GENERIC_READ | GENERIC_WRITE);
}
using UniqueHandle = 系统指针<HANDLE, decltype(CloseHandle)*>;
static const HANDLE ProcessHandle = GetCurrentProcess();
#pragma pack(push,4)
struct 有头Win32异常
{
	MATLAB::Exception const 异常头 = MATLAB::Exception::Win32_exception;
	Win32异常 异常体;
	constexpr 有头Win32异常(MATLAB::Exception 表象, DWORD 底层)noexcept :异常体{ 表象, 底层 } {}
};
#pragma pack(pop)
static bool 句柄不可用(const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头, UniqueHandle& SourceProcessHandle, UniqueHandle& TargetHandle)
{
	static std::unordered_set<ULONG_PTR>无效进程;
	if (无效进程.contains(系统句柄表条目信息头->UniqueProcessId))
		return true;
	if (!(SourceProcessHandle = OpenProcess(PROCESS_DUP_HANDLE, FALSE, 系统句柄表条目信息头->UniqueProcessId)))
	{
		DWORD const LastError = GetLastError();
		switch (LastError)
		{
		case ERROR_ACCESS_DENIED:
		case ERROR_INVALID_HANDLE:
			无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
			break;
		default:
			throw 有头Win32异常{ MATLAB::Exception::Unexpected_error_in_DuplicateHandle, LastError };
		}
		return true;
	}
	DuplicateHandle(SourceProcessHandle, (HANDLE)系统句柄表条目信息头->HandleValue, ProcessHandle, &TargetHandle, NULL, FALSE, DUPLICATE_SAME_ACCESS);
	if (!TargetHandle)
	{
		DWORD const LastError = GetLastError();
		switch (LastError)
		{
		case ERROR_INVALID_HANDLE:
			break;
		case ERROR_ACCESS_DENIED:
		case ERROR_NOT_SUPPORTED:
			无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
			break;
		default:
			throw 有头Win32异常{ MATLAB::Exception::Unexpected_error_in_DuplicateHandle, LastError };
		}
		return true;
	}
	return false;
}
static const HMODULE Ntdll = GetModuleHandleA("ntdll.dll");
static decltype(NtQuerySystemInformation)* const 查询系统信息 = (decltype(NtQuerySystemInformation)*)GetProcAddress(Ntdll, "NtQuerySystemInformation");
static decltype(NtQueryObject)* const 查询对象 = (decltype(NtQueryObject)*)GetProcAddress(Ntdll, "NtQueryObject");
#pragma pack(push,8)
struct ProcExp_InBuffer
{
	const DWORD CurrentProcessId = GetCurrentProcessId();
	PVOID Object;
	const bool IsFile = true;
	HANDLE DuplicatedHandle;
};
#pragma pack(pop)
struct ProcExp_OutBuffer
{
	ULONG ShareAccess;
	wchar_t* 文件名()const noexcept { return (wchar_t*)(this + 1); }
};
static inline HANDLE 获取ProExp152()
{
	static const HANDLE ProExp152 = []()
		{
			HANDLE 返回值 = CreateFileW(L"\\\\.\\PROCEXP152", GENERIC_READ | GENERIC_WRITE, NULL, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (返回值 == INVALID_HANDLE_VALUE)
			{
				HKEY PROCEXP152;
				RegCreateKeyW(HKEY_LOCAL_MACHINE, L"System\\CurrentControlSet\\Services\\PROCEXP152", &PROCEXP152);
				DWORD Data = 1;
				RegSetValueExW(PROCEXP152, L"Type", 0, REG_DWORD, (BYTE*)&Data, sizeof(Data));
				RegSetValueExW(PROCEXP152, L"ErrorControl", 0, REG_DWORD, (BYTE*)&Data, sizeof(Data));
				Data = 3;
				RegSetValueExW(PROCEXP152, L"Start", 0, REG_DWORD, (BYTE*)&Data, sizeof(Data));
				const std::wstring PROCEXP152_SYS = L"\\??\\" + (EXE目录 / L"PROCEXP152.SYS").native();
				RegSetValueExW(PROCEXP152, L"ImagePath", 0, REG_SZ, (BYTE*)PROCEXP152_SYS.c_str(), PROCEXP152_SYS.size() * sizeof(wchar_t));
				RegCloseKey(PROCEXP152);
				decltype(NtLoadDriver)* const 加载驱动 = (decltype(NtLoadDriver)*)GetProcAddress(Ntdll, "NtLoadDriver");
				UNICODE_STRING DriverServiceName;
				decltype(RtlInitUnicodeString)* const 初始化Unicode字符串 = (decltype(RtlInitUnicodeString)*)GetProcAddress(Ntdll, "RtlInitUnicodeString");
				初始化Unicode字符串(&DriverServiceName, L"\\Registry\\Machine\\System\\CurrentControlSet\\Services\\PROCEXP152");
				加载驱动(&DriverServiceName);
				返回值 = CreateFileW(L"\\\\.\\PROCEXP152", GENERIC_READ | GENERIC_WRITE, NULL, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			}
			return 返回值;
		}();
	return ProExp152;
}
static const SYSTEM_HANDLE_INFORMATION_EX* 获取系统句柄信息()
{
	static std::vector<char>SystemInformation(sizeof(SYSTEM_HANDLE_INFORMATION_EX));
	static bool 未获取特权 = true;
	if (未获取特权)
	{
		constexpr DWORD BufferLength = sizeof(TOKEN_PRIVILEGES) + sizeof(LUID_AND_ATTRIBUTES);
		std::unique_ptr<char[]> NewStateUP = std::make_unique_for_overwrite<char[]>(BufferLength);
		TOKEN_PRIVILEGES* const NewState = (TOKEN_PRIVILEGES*)NewStateUP.get();
		NewState->PrivilegeCount = 2;
		LUID_AND_ATTRIBUTES* const Privileges = NewState->Privileges;
		LookupPrivilegeValueW(NULL, SE_DEBUG_NAME, &Privileges[0].Luid);
		Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
		LookupPrivilegeValueW(NULL, SE_LOAD_DRIVER_NAME, &Privileges[1].Luid);
		Privileges[1].Attributes = SE_PRIVILEGE_ENABLED;
		HANDLE TokenHandle;
		OpenProcessToken(ProcessHandle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &TokenHandle);
		AdjustTokenPrivileges(TokenHandle, FALSE, NewState, BufferLength, NULL, NULL);
		CloseHandle(TokenHandle);
		未获取特权 = false;
	}
	ULONG ReturnLength;
	while (查询系统信息(SystemExtendedHandleInformation, SystemInformation.data(), SystemInformation.size(), &ReturnLength))
		SystemInformation.resize(ReturnLength);
	return (SYSTEM_HANDLE_INFORMATION_EX*)SystemInformation.data();
}
static inline USHORT 获取文件对象类型索引(const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX*& 系统句柄表条目信息头, const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息尾, UniqueHandle& SourceProcessHandle, UniqueHandle& TargetHandle)
{
	USHORT 返回值 = 0;
	std::unordered_set<USHORT>非文件类型;
	static 原地扩张缓冲<char> ObjectInformation(sizeof(OBJECT_TYPE_INFORMATION));
	for (; 系统句柄表条目信息头 < 系统句柄表条目信息尾; 系统句柄表条目信息头++)
	{
		if (非文件类型.contains(返回值 = 系统句柄表条目信息头->ObjectTypeIndex) || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle))
			continue;
		ULONG ReturnLength;
		while (查询对象(TargetHandle, ObjectTypeInformation, ObjectInformation.get(), (ULONG)ObjectInformation.size(), &ReturnLength))
			ObjectInformation.resize(ReturnLength);
		if (wcscmp((reinterpret_cast<OBJECT_TYPE_INFORMATION*>(ObjectInformation.get()))->TypeName.Buffer, L"File"))
			非文件类型.insert(返回值);
		else
			return 返回值;
	}
	throw 有头Win32异常{ MATLAB::Exception::Unexpected_error_in_OpenProcess, GetLastError() };
}
static 原地扩张缓冲<char> OutBuffer{ 32 };
API(Serialport_snatch)
{
	DWORD 调用进程ID;

	ReadFile(File, &调用进程ID, sizeof(调用进程ID), &NumberOfBytesRead, NULL);
	const std::wstring COM = 读入UTF16字符串();
	static const 系统指针<HKEY, decltype(RegCloseKey)*>SERIALCOMM = []()
		{
			系统指针<HKEY, decltype(RegCloseKey)*>返回值(RegCloseKey);
			RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"HARDWARE\\DEVICEMAP\\SERIALCOMM", 0, KEY_READ, &返回值);
			if (!返回值)
				throw MATLAB::Exception::COM_number_not_found;
			return 返回值;
		}();
	DWORD Values, MaxValueNameLen, MaxValueLen;
	RegQueryInfoKeyW(SERIALCOMM, NULL, NULL, NULL, NULL, NULL, NULL, &Values, &MaxValueNameLen, &MaxValueLen, NULL, NULL);
	static 原地扩张缓冲<wchar_t> ValueName;
	if (++MaxValueNameLen > ValueName.size())
		ValueName.resize(MaxValueNameLen);
	static 原地扩张缓冲<BYTE>Data;
	if (MaxValueLen > Data.size())
		Data.resize(MaxValueLen);
	for (DWORD Index = 0; Index < Values; ++Index)
	{
		DWORD ValueNameLen = MaxValueNameLen;
		DWORD ValueLen = MaxValueLen;
		RegEnumValueW(SERIALCOMM, Index, ValueName.get(), &ValueNameLen, NULL, NULL, Data.get(), &ValueLen);
		if (COM != reinterpret_cast<wchar_t*>(Data.get()))
			continue;
		const SYSTEM_HANDLE_INFORMATION_EX* const 系统句柄信息 = 获取系统句柄信息();
		const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头 = 系统句柄信息->Handles;
		const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* const 系统句柄表条目信息尾 = 系统句柄表条目信息头 + 系统句柄信息->NumberOfHandles;
		UniqueHandle TargetHandle(CloseHandle);
		UniqueHandle SourceProcessHandle(CloseHandle);
		static USHORT const OB_TYPE_FILE = 获取文件对象类型索引(系统句柄表条目信息头, 系统句柄表条目信息尾, SourceProcessHandle, TargetHandle);
		if (!TargetHandle)
			for (; 系统句柄表条目信息头->ObjectTypeIndex != OB_TYPE_FILE || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle); 系统句柄表条目信息头++);
		ProcExp_InBuffer InBuffer;
		for (;;)
		{
			InBuffer.Object = 系统句柄表条目信息头->Object;
			InBuffer.DuplicatedHandle = TargetHandle;
			for (;;)
			{
				if (DeviceIoControl(获取ProExp152(), 0x83350048, &InBuffer, sizeof(InBuffer), OutBuffer.get(), OutBuffer.size(), nullptr, nullptr))
				{
					if (!wcscmp(ValueName.get(), (reinterpret_cast<ProcExp_OutBuffer*>(OutBuffer.get()))->文件名()))
					{
						DWORD const 当前进程ID = 系统句柄表条目信息头->UniqueProcessId;
						if (当前进程ID == 调用进程ID)
							throw MATLAB::Exception::Attempt_to_snatch_the_serialport_occupied_by_yourself;
						DuplicateHandle(SourceProcessHandle, reinterpret_cast<HANDLE>(系统句柄表条目信息头->HandleValue), NULL, &TargetHandle, NULL, FALSE, DUPLICATE_CLOSE_SOURCE);
						输出.write(reinterpret_cast<char const*>(&当前进程ID), sizeof(当前进程ID));
						return;
					}
					break;
				}
				if (GetLastError() != ERROR_MORE_DATA)
					break;
				OutBuffer.resize(OutBuffer.size() * 2);
			}
			do
				if (++系统句柄表条目信息头 >= 系统句柄表条目信息尾)
				{
					constexpr DWORD PID0 = 0;
					输出.write(reinterpret_cast<char const*>(&PID0), sizeof(PID0));
					return;
				}
			while (OB_TYPE_FILE != 系统句柄表条目信息头->ObjectTypeIndex || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle));
		}
	}
	throw MATLAB::Exception::COM_number_not_found;
}
API(IO_FindLocking)
{
	const HANDLE FileHandle = CreateFileW(读入UTF16字符串().c_str(), FILE_READ_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
	if (FileHandle == INVALID_HANDLE_VALUE)
		switch (GetLastError())
		{
		case ERROR_FILE_NOT_FOUND:
		case ERROR_PATH_NOT_FOUND:
			throw MATLAB::Exception::File_not_found;
		default:
			throw MATLAB::Exception::Failed_to_open_the_file;
		}
	static std::wstring 目标路径;
	{
		const 系统指针<HANDLE, decltype(CloseHandle)*>自动关文件(CloseHandle, FileHandle);
		DWORD const 长度 = GetFinalPathNameByHandleW(FileHandle, nullptr, 0, FILE_NAME_NORMALIZED | VOLUME_NAME_NT);
		目标路径.resize_and_overwrite(长度, [FileHandle, 长度](wchar_t* 缓冲区, size_t)noexcept
			{
				return GetFinalPathNameByHandleW(FileHandle, 缓冲区, 长度, FILE_NAME_NORMALIZED | VOLUME_NAME_NT);
			});
		//此处系统指针销毁，自动关闭文件句柄，否则后续查询所有句柄时会查到我们自己占用的句柄
	}
	const SYSTEM_HANDLE_INFORMATION_EX* const 系统句柄信息 = 获取系统句柄信息();
	const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头 = 系统句柄信息->Handles;
	const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* const 系统句柄表条目信息尾 = 系统句柄表条目信息头 + 系统句柄信息->NumberOfHandles;
	UniqueHandle TargetHandle(CloseHandle);
	UniqueHandle SourceProcessHandle(CloseHandle);
	const USHORT OB_TYPE_FILE = 获取文件对象类型索引(系统句柄表条目信息头, 系统句柄表条目信息尾, SourceProcessHandle, TargetHandle);
	if (!TargetHandle)
		for (; 系统句柄表条目信息头->ObjectTypeIndex != OB_TYPE_FILE || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle); 系统句柄表条目信息头++);
	static ProcExp_InBuffer InBuffer;
	static std::vector<ULONG_PTR>锁定句柄;
	static std::vector<uint32_t>锁定进程;
	for (;;)
	{
		InBuffer.Object = 系统句柄表条目信息头->Object;
		InBuffer.DuplicatedHandle = TargetHandle;
		for (;;)
		{
			if (DeviceIoControl(获取ProExp152(), 0x83350048, &InBuffer, sizeof(InBuffer), OutBuffer.get(), OutBuffer.size(), nullptr, nullptr))
			{
				if (目标路径 == (reinterpret_cast<ProcExp_OutBuffer*>(OutBuffer.get()))->文件名())
				{
					锁定句柄.push_back(系统句柄表条目信息头->HandleValue);
					锁定进程.push_back(系统句柄表条目信息头->UniqueProcessId);
				}
				break;
			}
			if (GetLastError() != ERROR_MORE_DATA)
				break;
			OutBuffer.resize(OutBuffer.size() * 2);
		}
		do
			if (++系统句柄表条目信息头 >= 系统句柄表条目信息尾)
			{
				const size_t Size = 锁定句柄.size();
				输出.write(reinterpret_cast<char const*>(&Size), sizeof(Size));
				if (Size)
				{
					输出.write(reinterpret_cast<char const*>(锁定句柄.data()), sizeof(ULONG_PTR) * Size);
					输出.write(reinterpret_cast<char const*>(锁定进程.data()), sizeof(uint32_t) * Size);
					锁定句柄.clear();
					锁定进程.clear();
				}
				return;
			}
		while (OB_TYPE_FILE != 系统句柄表条目信息头->ObjectTypeIndex || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle));
	}
}
API(IO_CloseHandle)
{
	size_t 记录数;

	ReadFile(File, &记录数, sizeof(记录数), &NumberOfBytesRead, NULL);

	static 原地扩张缓冲<HANDLE>句柄缓冲;
	static 原地扩张缓冲<DWORD> 进程缓冲;
	if (记录数 > 句柄缓冲.size())
	{
		句柄缓冲.resize(记录数);
		进程缓冲.resize(记录数);
	}
	ReadFile(File, 句柄缓冲.get(), 记录数 * sizeof(HANDLE), &NumberOfBytesRead, NULL);
	ReadFile(File, 进程缓冲.get(), 记录数 * sizeof(DWORD), &NumberOfBytesRead, NULL);

	UniqueHandle SourceProcessHandle{ CloseHandle };
	UniqueHandle TargetHandle{ CloseHandle };
	//循环构造-销毁这两个对象以保证所有句柄安全关闭

	DWORD const* const 进程头 = 进程缓冲.get();
	HANDLE const* const 句柄头 = 句柄缓冲.get();
	for (size_t i = 0; i < 记录数; ++i)
		DuplicateHandle(SourceProcessHandle = OpenProcess(PROCESS_DUP_HANDLE, FALSE, 进程头[i]), 句柄头[i], ProcessHandle, &TargetHandle, 0, FALSE, DUPLICATE_CLOSE_SOURCE | DUPLICATE_SAME_ACCESS);
}
struct SEH异常
{
	const MATLAB::Exception 标识符 = MATLAB::Exception::SEH_exception;
	decltype(GetExceptionCode())异常码;
	constexpr SEH异常(decltype(异常码)异常码)noexcept :异常码(异常码) {}
};
static void SEH安全(const std::move_only_function<void()const>& 函数)
{
	__try
	{
		函数();
	}
	__except (GetExceptionCode() != 0xE06D7363)//魔数，表示标准C++异常，不在此处理
	{
		throw SEH异常(GetExceptionCode());
	}
}
int wmain(int argc, wchar_t* argv[])
{
	EXE目录 = path(argv[0]).parent_path();
	const path NamedPipeName = path(L"\\\\.\\pipe") / argv[1];
	WaitNamedPipeW(NamedPipeName.c_str(), NMPWAIT_WAIT_FOREVER);
	File = CreateFileW(NamedPipeName.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
	constexpr void(*操作列表[])(std::ostringstream&输出) = 
	{ 
		Install_path_manager,
		Uninstall_path_manager,
		Set_shared_path,Add_shared_path,
		Remove_shared_path,
		Builtin_bug_fix,
		Associate_prj_extension,
		Get_pathdef_permission,
		Serialport_snatch,
		IO_FindLocking,
		IO_CloseHandle 
	};	
	for (;;)
	{
		提权操作函数 函数序号;
		ReadFile(File, &函数序号, sizeof(函数序号), &NumberOfBytesRead, NULL);
		if (static_cast<size_t>(函数序号) == std::extent_v<decltype(操作列表)>)
			break;
		DWORD NumberOfBytesWritten;
		constexpr MATLAB::Exception 操作成功 = MATLAB::Exception::Successful;
		static const std::string 成功输出((char*)&操作成功, sizeof(操作成功));
		std::ostringstream 输出(成功输出);
		输出.seekp(sizeof(MATLAB::Exception), std::ios_base::beg);
		try
		{
			SEH安全([操作 = 操作列表[static_cast<size_t>(函数序号)], &输出]() {操作(输出); });
			const std::string 输出缓冲 = 输出.str();
			WriteFile(File, 输出缓冲.data(), 输出缓冲.size(), &NumberOfBytesWritten, NULL);
		}
		catch (MATLAB::Exception ex)
		{
			WriteFile(File, &ex, sizeof(ex), &NumberOfBytesWritten, NULL);
		}
		catch (const SEH异常& ex)
		{
			WriteFile(File, &ex, sizeof(ex), &NumberOfBytesWritten, NULL);
		}
		catch (const 有头Win32异常& ex)
		{
			WriteFile(File, &ex, sizeof(ex), &NumberOfBytesWritten, NULL);
		}
		catch (...)
		{
			constexpr MATLAB::Exception 未知异常 = MATLAB::Exception::Unknown_exception;
			WriteFile(File, &未知异常, sizeof(未知异常), &NumberOfBytesWritten, NULL);
		}
	}
}
#include<共享头.h>
#include<MATLAB异常.h>
#include<phnt_windows.h>
#define PHNT_VERSION PHNT_WIN11_24H2
#include<phnt.h>
#include<AclAPI.h>
import std;
using namespace std::filesystem;
static path EXE目录;
static 懒加载 安装目录([]()noexcept
	{
		return path(EXE目录) / L"安装";
	});
static 懒加载 数据目录([]()noexcept
	{
		constexpr wchar_t ProgramData[] = L"ProgramData";
		const DWORD Size = GetEnvironmentVariableW(ProgramData, nullptr, 0);
		std::unique_ptr<wchar_t[]>Buffer = std::make_unique_for_overwrite<wchar_t[]>(Size);
		GetEnvironmentVariableW(ProgramData, Buffer.get(), Size);
		return path(Buffer.get()) / L"MathWorks\\埃博拉酱";
	});
static 懒加载 共享路径([]()noexcept
	{
		return 数据目录() / L"共享路径.txt";
	});
static 懒加载 原文件目录([]()noexcept
	{
		return 数据目录() / L"原文件";
	});
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
static HANDLE File;
static std::wstring 读入UTF16字符串()noexcept
{
	size_t 字符串长度;
	DWORD NumberOfBytesRead;
	ReadFile(File, &字符串长度, sizeof(字符串长度), &NumberOfBytesRead, NULL);
	std::wstring 缓冲区;
	缓冲区.resize_and_overwrite(字符串长度, [](wchar_t* 指针, size_t 长度)
		{
			DWORD NumberOfBytesRead;
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
static 懒加载 MatlabSavepath([](const path& MatlabRoot)noexcept
	{
		return MatlabRoot / L"toolbox\\matlab\\general\\savepath.m";
	});
static 懒加载 原Savepath([]()noexcept
	{
		return 原文件目录() / L"savepath.m";
	});
static 懒加载 MatlabRc([](const path& MatlabRoot)noexcept
	{
		return MatlabRoot / L"toolbox\\local\\matlabrc.m";
	});
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
static 懒加载 所有版本([](DWORD 版本值)noexcept
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
	});
static 懒加载 当前VersionMS(计算VersionMS);
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
						}
					}}
				},
				{
					L"26.1",
					{{
						{
							L"CshDocPageHandler.m",
							L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
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
static bool 句柄不可用(const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头, UniqueHandle& SourceProcessHandle, UniqueHandle& TargetHandle)
{
	static std::unordered_set<ULONG_PTR>无效进程;
	if (无效进程.contains(系统句柄表条目信息头->UniqueProcessId))
		return true;
	if (!(SourceProcessHandle = OpenProcess(PROCESS_DUP_HANDLE, FALSE, 系统句柄表条目信息头->UniqueProcessId)))
	{
		switch (GetLastError())
		{
		case ERROR_ACCESS_DENIED:
		case ERROR_INVALID_HANDLE:
			无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
			break;
		default:
			throw MATLAB::Exception::Unexpected_error_in_DuplicateHandle;
		}
		return true;
	}
	DuplicateHandle(SourceProcessHandle, (HANDLE)系统句柄表条目信息头->HandleValue, ProcessHandle, &TargetHandle, NULL, FALSE, DUPLICATE_SAME_ACCESS);
	if (!TargetHandle)
	{
		switch (GetLastError())
		{
		case ERROR_INVALID_HANDLE:
			break;
		case ERROR_ACCESS_DENIED:
		case ERROR_NOT_SUPPORTED:
			无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
			break;
		default:
			throw MATLAB::Exception::Unexpected_error_in_DuplicateHandle;
		}
		return true;
	}
	return false;
}
API(Serialport_snatch)
{
	DWORD 调用进程ID;
	DWORD NumberOfBytesRead;
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
	const std::unique_ptr<wchar_t[]>ValueName = std::make_unique_for_overwrite<wchar_t[]>(++MaxValueNameLen);
	const std::unique_ptr<std::remove_pointer_t<LPBYTE>[]>Data = std::make_unique_for_overwrite<std::remove_pointer_t<LPBYTE>[]>(MaxValueLen);
	for (DWORD Index = 0; Index < Values; ++Index)
	{
		DWORD ValueNameLen = MaxValueNameLen;
		DWORD ValueLen = MaxValueLen;
		RegEnumValueW(SERIALCOMM, Index, ValueName.get(), &ValueNameLen, NULL, NULL, Data.get(), &ValueLen);
		if (COM == (wchar_t*)Data.get())
		{
			static const HMODULE Ntdll = GetModuleHandleA("ntdll.dll");
			static decltype(NtQuerySystemInformation)* const 查询系统信息 = (decltype(NtQuerySystemInformation)*)GetProcAddress(Ntdll, "NtQuerySystemInformation");
			static std::vector<char>SystemInformation(sizeof(SYSTEM_HANDLE_INFORMATION_EX));
			ULONG ReturnLength;
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
			while (查询系统信息(SystemExtendedHandleInformation, SystemInformation.data(), SystemInformation.size(), &ReturnLength))
				SystemInformation.resize(ReturnLength);
			const SYSTEM_HANDLE_INFORMATION_EX* const 系统句柄信息 = (SYSTEM_HANDLE_INFORMATION_EX*)SystemInformation.data();
			const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头 = 系统句柄信息->Handles;
			const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* const 系统句柄表条目信息尾 = 系统句柄表条目信息头 + 系统句柄信息->NumberOfHandles;
			系统指针<HANDLE, decltype(CloseHandle)*>TargetHandle(CloseHandle);
			系统指针<HANDLE, decltype(CloseHandle)*>SourceProcessHandle(CloseHandle);
			static const USHORT OB_TYPE_FILE = [&系统句柄表条目信息头, &TargetHandle, &SourceProcessHandle]()
				{
					USHORT 返回值;
					std::unordered_set<USHORT>非文件类型;
					ULONG ObjectInformationLength = sizeof(OBJECT_TYPE_INFORMATION);
					std::unique_ptr<char[]>ObjectInformation = std::make_unique_for_overwrite<char[]>(ObjectInformationLength);
					decltype(NtQueryObject)* const 查询对象 = (decltype(NtQueryObject)*)GetProcAddress(Ntdll, "NtQueryObject");
					for (;; 系统句柄表条目信息头++)
					{
						if (非文件类型.contains(返回值 = 系统句柄表条目信息头->ObjectTypeIndex) || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle))
							continue;
						ULONG ReturnLength;
						while (查询对象(TargetHandle, ObjectTypeInformation, ObjectInformation.get(), ObjectInformationLength, &ReturnLength))
							ObjectInformation = std::make_unique_for_overwrite<char[]>(ObjectInformationLength = ReturnLength);
						if (wcscmp(((OBJECT_TYPE_INFORMATION*)ObjectInformation.get())->TypeName.Buffer, L"File"))
							非文件类型.insert(返回值);
						else
							break;
					};
					return 返回值;
				}();
#pragma pack(push,8)
				static struct
				{
					const DWORD CurrentProcessId = GetCurrentProcessId();
					PVOID Object;
					const bool IsFile = true;
					HANDLE DuplicatedHandle;
				}InBuffer;
#pragma pack(pop)
				if (!TargetHandle)
					for (; 系统句柄表条目信息头->ObjectTypeIndex != OB_TYPE_FILE || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle); 系统句柄表条目信息头++);
				struct ProcExp_OutBuffer
				{
					ULONG ShareAccess;
					wchar_t* 文件名()const noexcept { return (wchar_t*)(this + 1); }
				};
				static std::vector<char> OutBuffer(32);//初始大小不能太小，否则DeviceIoControl会报ERROR_MORE_DATA以外的错
				for (;;)
				{
					InBuffer.Object = 系统句柄表条目信息头->Object;
					InBuffer.DuplicatedHandle = TargetHandle;
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

					for (;;)
					{
						if (DeviceIoControl(ProExp152, 0x83350048, &InBuffer, sizeof(InBuffer), OutBuffer.data(), OutBuffer.size(), nullptr, nullptr))
						{
							if (系统句柄表条目信息头->UniqueProcessId == 调用进程ID)
								int a = 1;
							if (!wcscmp(ValueName.get(), ((ProcExp_OutBuffer*)OutBuffer.data())->文件名()))
							{
								if (系统句柄表条目信息头->UniqueProcessId == 调用进程ID)
									throw MATLAB::Exception::Attempt_to_snatch_the_serialport_occupied_by_yourself;
								DuplicateHandle(SourceProcessHandle, (HANDLE)系统句柄表条目信息头->HandleValue, NULL, &TargetHandle, NULL, FALSE, DUPLICATE_CLOSE_SOURCE);
								输出.write((char*)&系统句柄表条目信息头->UniqueProcessId, sizeof(系统句柄表条目信息头->UniqueProcessId));
								return;
							}
							break;
						}
						else if (GetLastError() != ERROR_MORE_DATA)
							break;
						OutBuffer.resize(OutBuffer.size() * 2);
					}
					do
						if (++系统句柄表条目信息头 >= 系统句柄表条目信息尾)
						{
							constexpr ULONG_PTR PID0 = 0;
							输出.write((char*)&PID0, sizeof(PID0));
							return;
						}
					while (OB_TYPE_FILE != 系统句柄表条目信息头->ObjectTypeIndex || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle));
				}
		}
	}
	throw MATLAB::Exception::COM_number_not_found;
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
	constexpr void(*操作列表[])(std::ostringstream&输出) = { Install_path_manager,Uninstall_path_manager,Set_shared_path,Add_shared_path,Remove_shared_path,Builtin_bug_fix,Associate_prj_extension,Get_pathdef_permission,Serialport_snatch };
	提权操作函数 函数序号;
	DWORD NumberOfBytesRead;
	for (;;)
	{
		ReadFile(File, &函数序号, sizeof(函数序号), &NumberOfBytesRead, NULL);
		if ((size_t)函数序号 == std::extent_v<decltype(操作列表)>)
			break;
		DWORD NumberOfBytesWritten;
		constexpr MATLAB::Exception 操作成功 = MATLAB::Exception::Successful;
		static const std::string 成功输出((char*)&操作成功, sizeof(操作成功));
		std::ostringstream 输出(成功输出);
		输出.seekp(sizeof(MATLAB::Exception), std::ios_base::beg);
		try
		{
			SEH安全([操作 = 操作列表[(size_t)函数序号], &输出]()
				{
					操作(输出);
				});
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
		catch (...)
		{
			constexpr MATLAB::Exception 未知异常 = MATLAB::Exception::Unknown_exception;
			WriteFile(File, &未知异常, sizeof(未知异常), &NumberOfBytesWritten, NULL);
		}
	}
}
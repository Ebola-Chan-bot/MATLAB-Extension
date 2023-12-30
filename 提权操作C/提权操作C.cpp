#include"提权操作.h"
#include<phnt_windows.h>
#define PHNT_VERSION 114
#include<phnt.h>
#include<AclAPI.h>
#include<filesystem>
#include<fstream>
#include<unordered_set>
#include<functional>
using namespace std::filesystem;
using namespace 提权操作;
static const wchar_t* EXE路径;
static 懒加载<path>安装目录([]()noexcept
	{
		return  path(EXE路径).parent_path() / L"安装";
	});
static 懒加载<path>数据目录([]()noexcept
	{
		constexpr wchar_t ProgramData[] = L"ProgramData";
		const DWORD Size = GetEnvironmentVariableW(ProgramData, nullptr, 0);
		std::unique_ptr<wchar_t[]>Buffer = std::make_unique_for_overwrite<wchar_t[]>(Size);
		GetEnvironmentVariableW(ProgramData, Buffer.get(), Size);
		return path(Buffer.get()) / L"MathWorks\\埃博拉酱";
	});
static 懒加载<path>共享路径([]()noexcept
	{
		return 数据目录() / L"共享路径.txt";
	});
static 懒加载<path>原文件目录([]()noexcept
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
	UTF8.resize_and_overwrite(UTF16.size() * 3, [&UTF16](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, NULL, UTF16.c_str(), UTF16.size(), 指针, 尺寸, NULL, NULL) - 1; });
	return UTF8;
}
static void 设置文件权限(LPWSTR ObjectName, LPWSTR TrusteeName, DWORD AccessPermissions)
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
static void Install_path_manager()noexcept
{
	const path MatlabRoot(读入UTF16字符串());
	const path MatlabSavePath = MatlabRoot / L"toolbox\\matlab\\general\\savepath.m";
	create_directories(原文件目录());
	copy_file(MatlabSavePath, 原文件目录() / L"savepath.m", copy_options::overwrite_existing);
	copy_file(安装目录() / L"savepath.m", MatlabSavePath, copy_options::overwrite_existing);
	static const path 可执行目录 = 数据目录() / L"可执行";
	static const path internal目录 = 可执行目录 / L"+MATLAB\\+internal";
	create_directories(internal目录);
	copy_file(安装目录() / L"RcAddPath.m", internal目录 / L"RcAddPath.m", copy_options::overwrite_existing);
	if (!is_regular_file(共享路径()))
		std::ofstream(共享路径()).close();
	const path MatlabRC = MatlabRoot / L"toolbox\\local\\matlabrc.m";
	std::ostringstream 输出流 = RC输出流(MatlabRC);
	const int MultiByte = 可执行目录.native().size() * 3 + 1;
	std::unique_ptr<char[]>可执行目录UTF8 = std::make_unique_for_overwrite<char[]>(MultiByte);
	WideCharToMultiByte(CP_UTF8, 0, 可执行目录.c_str(), -1, 可执行目录UTF8.get(), MultiByte, NULL, NULL);
	输出流 << "addpath('" << 可执行目录UTF8.get() << "');MATLAB.internal.RcAddPath;%埃博拉酱";
	std::ofstream(MatlabRC) << 输出流.str();
	const path::string_type PathDef = (MatlabRoot / L"toolbox\\local\\pathdef.m").native();
	const std::unique_ptr<wchar_t[]>路径缓冲 = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
	wcscpy(路径缓冲.get(), PathDef.c_str());
	static wchar_t TrusteeName[] = L"Users";
	设置文件权限(路径缓冲.get(), TrusteeName, GENERIC_READ);
}
static void Uninstall_path_manager()noexcept
{
	path MatlabRoot(读入UTF16字符串());
	rename(原文件目录() / L"savepath.m", MatlabRoot / L"toolbox\\matlab\\general\\savepath.m");
	MatlabRoot /= L"toolbox\\local\\matlabrc.m";
	std::ofstream(MatlabRoot) << RC输出流(MatlabRoot).str();
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
static void 开放新路径权限(const std::unordered_set<std::string>&新路径集合)noexcept
{
	系统指针<PACL, decltype(LocalFree)*>Dacl(LocalFree);
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
		GetNamedSecurityInfoA(路径缓冲.get(), SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &Dacl, NULL, &SecurityDescriptor);
		BuildExplicitAccessWithNameA(&ExplicitAccess, Users, GENERIC_READ | GENERIC_EXECUTE, GRANT_ACCESS, SUB_CONTAINERS_AND_OBJECTS_INHERIT);
		SetEntriesInAclA(1, &ExplicitAccess, Dacl, &Dacl);
		SetNamedSecurityInfoA(路径缓冲.get(), SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, Dacl, NULL);
	}
}
static void 写出路径(const std::unordered_set<std::string>& 新路径集合)noexcept
{
	std::ofstream 输出流(共享路径());
	for (const std::string& 路径 : 新路径集合)
		输出流 << 路径 << ';';
}
static void Set_shared_path()noexcept
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
static void Add_shared_path()noexcept
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
static void Remove_shared_path()noexcept
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
static void Builtin_bug_fix()
{
	const path MatlabRoot(读入UTF16字符串());
	constexpr wchar_t 文件名[][32] = { L"getDocumentationXML.m", L"CshDocPageHandler.m", L"Document.m", L"ToolboxConfigurationReader.m", L"getReferencePage.m" };
	constexpr wchar_t 目标目录[][128] =
	{
		L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc",
		L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+ui\\@CshDocPageHandler",
		L"toolbox\\matlab\\codetools\\+matlab\\+desktop\\+editor\\@Document",
		L"toolbox\\matlab\\toolbox_packaging\\+matlab\\+internal\\+addons\\+metadata",
		L"toolbox\\matlab\\helptools\\+matlab\\+internal\\+doc\\+reference"
	};
	size_t 命令数;
	DWORD NumberOfBytes;
	ReadFile(File, &命令数, sizeof(命令数), &NumberOfBytes, NULL);
	std::unique_ptr<int8_t[]>所有命令 = std::make_unique_for_overwrite<int8_t[]>(命令数);
	ReadFile(File, 所有命令.get(), 命令数, &NumberOfBytes, NULL);
	create_directories(原文件目录());
	for (size_t C = 0; C < 命令数; ++C)
	{
		int8_t 命令 = 所有命令[C];
		if (命令 > 0)
		{
			命令--;
			const path Matlab文件路径 = MatlabRoot / 目标目录[命令] / 文件名[命令];
			copy_file(Matlab文件路径, 原文件目录() / 文件名[命令], copy_options::overwrite_existing);
			copy_file(安装目录() / 文件名[命令], Matlab文件路径, copy_options::overwrite_existing);
		}
		else if (命令 < 0)
		{
			命令 = -1 - 命令;
			copy_file(原文件目录() / 文件名[命令], MatlabRoot / 目标目录[命令] / 文件名[命令], copy_options::overwrite_existing);
		}
		else
			throw 提权操作异常::Builtin_bug_fix_command_is_0;
	}
}
static void Associate_prj_extension()noexcept
{
	const path MatlabRoot(读入UTF16字符串());
	const std::wstring MATLAB版本 = 读入UTF16字符串();
	系统指针<HKEY, decltype(RegCloseKey)*>键A(RegCloseKey);
	RegCreateKeyExW(HKEY_CLASSES_ROOT, L".prj", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	const std::wstring prj类 = L"MATLAB.prj." + MATLAB版本 + L".0";
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
	std::wstring RegSz = L"Versions\\" + prj类;
	RegCreateKeyExW(键A, RegSz.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, NULL, &键B, NULL);
	constexpr DWORD FileVersionLS = 0;
	RegSetValueExW(键B, L"FileVersionLS", 0, REG_DWORD, (const BYTE*)&FileVersionLS, sizeof(FileVersionLS));
	std::wistringstream 版本号拆分(MATLAB版本);
	std::getline(版本号拆分, RegSz, L'.');
	DWORD FileVersionMS = std::stoi(RegSz) << 16;
	std::getline(版本号拆分, RegSz, L'.');
	FileVersionMS += std::stoi(RegSz);
	RegSetValueExW(键B, L"FileVersionMS", 0, REG_DWORD, (const BYTE*)&FileVersionMS, sizeof(FileVersionMS));
	RegCreateKeyExW(HKEY_CLASSES_ROOT, prj类.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	RegSz = L"\"" + (MatlabRoot / L"bin\\win64\\osintegplugins\\osintegplugins\\mlproj\\mwmlprojfaplugin.dll").native() + L"\",0";
	RegSetKeyValueW(键A, L"DefaultIcon", NULL, REG_SZ, RegSz.c_str(), (RegSz.size() + 1) * sizeof(wchar_t));
	RegCreateKeyExW(键A, L"Shell\\Open", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键B, NULL);
	constexpr wchar_t Open[] = L"Open";
	RegSetValueExW(键B, NULL, 0, REG_SZ, (const BYTE*)Open, sizeof(Open));
	RegSz = L"\"" + (MatlabRoot / L"bin\\win64\\matlab.exe").native() + L"\" -r \"uiopen('%1',1)\"";
	RegSetKeyValueW(键B, L"command", NULL, REG_SZ, RegSz.c_str(), (RegSz.size() + 1) * sizeof(wchar_t));
	RegCreateKeyExW(键B, L"ddeexec", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_CREATE_SUB_KEY | KEY_SET_VALUE, NULL, &键A, NULL);
	constexpr wchar_t uiopen[] = L"uiopen('%1',1)";
	RegSetValueExW(键A, NULL, 0, REG_SZ, (const BYTE*)uiopen, sizeof(uiopen));
	RegSz = L"ShellVerbs.MATLAB." + MATLAB版本 + L".0";
	RegSetKeyValueW(键A, L"application", NULL, REG_SZ, RegSz.c_str(), (RegSz.size() + 1) * sizeof(wchar_t));
	constexpr wchar_t system[] = L"system";
	RegSetKeyValueW(键A, L"topic", NULL, REG_SZ, system, sizeof(system));
}
static void Get_pathdef_permission()noexcept
{
	const std::wstring PathDef = 读入UTF16字符串();
	const std::unique_ptr<wchar_t[]>ObjectName = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
	wcscpy(ObjectName.get(), PathDef.c_str());
	constexpr wchar_t Name[] = L"USERNAME";
	const DWORD Size = GetEnvironmentVariableW(Name, nullptr, 0);
	std::unique_ptr<wchar_t[]>Buffer = std::make_unique_for_overwrite<wchar_t[]>(Size);
	GetEnvironmentVariableW(Name, Buffer.get(), Size);
	设置文件权限(ObjectName.get(), Buffer.get(), GENERIC_READ | GENERIC_WRITE);
}
using UniqueHandle = 系统指针<HANDLE, decltype(CloseHandle)*>;
static bool 句柄不可用(const SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX* 系统句柄表条目信息头, UniqueHandle& SourceProcessHandle, UniqueHandle& TargetHandle)
{
	static std::unordered_set<ULONG_PTR>无效进程;
	static const HANDLE TargetProcessHandle = GetCurrentProcess();
	if (无效进程.contains(系统句柄表条目信息头->UniqueProcessId))
		return true;
	if (!(SourceProcessHandle = OpenProcess(PROCESS_DUP_HANDLE, FALSE, 系统句柄表条目信息头->UniqueProcessId)))
	{
		无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
		return true;
	}
	DuplicateHandle(SourceProcessHandle, (HANDLE)系统句柄表条目信息头->HandleValue, TargetProcessHandle, &TargetHandle, NULL, FALSE, DUPLICATE_SAME_ACCESS);
	if (!TargetHandle)
	{
		无效进程.insert(系统句柄表条目信息头->UniqueProcessId);
		return true;
	}
	return false;
}
static void Serialport_snatch()
{
	const std::wstring COM = 读入UTF16字符串();
	static const 系统指针<HKEY, decltype(RegCloseKey)*>SERIALCOMM = []()
		{
			系统指针<HKEY, decltype(RegCloseKey)*>返回值(RegCloseKey);
			RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"HARDWARE\\DEVICEMAP\\SERIALCOMM", 0, KEY_READ, &返回值);
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
		const std::wstring DataString((wchar_t*)Data.get(), (wchar_t*)(Data.get() + ValueLen));
		if (COM == DataString)
		{
			static const HMODULE Ntdll = GetModuleHandleA("ntdll.dll");
			static decltype(NtQuerySystemInformation)* const 查询系统信息 = (decltype(NtQuerySystemInformation)*)GetProcAddress(Ntdll, "NtQuerySystemInformation");
			static ULONG SystemInformationLength = sizeof(SYSTEM_HANDLE_INFORMATION_EX);
			static std::unique_ptr<char[]>SystemInformation = std::make_unique_for_overwrite<char[]>(SystemInformationLength);
			ULONG ReturnLength;
			while (查询系统信息(SystemExtendedHandleInformation, SystemInformation.get(), SystemInformationLength, &ReturnLength))
				SystemInformation = std::make_unique_for_overwrite<char[]>(SystemInformationLength = ReturnLength);
			const SYSTEM_HANDLE_INFORMATION_EX* const 系统句柄信息 = (SYSTEM_HANDLE_INFORMATION_EX*)SystemInformation.get();
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
						const OBJECT_TYPE_INFORMATION* const 对象类型信息 = (OBJECT_TYPE_INFORMATION*)ObjectInformation.get();
						if (wcscmp(对象类型信息->TypeName.Buffer, L"File"))
							非文件类型.insert(返回值);
						else
							break;
					};
					return 返回值;
				}();
#pragma pack(push,8)
				struct
				{
					const DWORD CurrentProcessId = GetCurrentProcessId();
					PVOID Object;
					const bool IsFile = true;
					HANDLE DuplicatedHandle;
				}InBuffer;
#pragma pack(pop)
				if (!TargetHandle)
					for (; 系统句柄表条目信息头->ObjectTypeIndex != OB_TYPE_FILE || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle); 系统句柄表条目信息头++);
				for (;;)
				{
					InBuffer.Object = 系统句柄表条目信息头->Object;
					InBuffer.DuplicatedHandle = TargetHandle;
					struct ProcExp_OutBuffer
					{
						ULONG ShareAccess;
						wchar_t* 文件名()const noexcept { return (wchar_t*)(this + 1); }
					};
					static DWORD OutBufferSize = sizeof(ProcExp_OutBuffer);
					static std::unique_ptr<char[]>OutBuffer = std::make_unique_for_overwrite<char[]>(OutBufferSize);
					static const HANDLE ProExp152 = CreateFileW(L"\\\\.\\PROCEXP152", GENERIC_READ | GENERIC_WRITE, NULL, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
					for (;; OutBuffer = std::make_unique_for_overwrite<char[]>(OutBufferSize *= 2))
					{
						if (DeviceIoControl(ProExp152, 0x83350048, &InBuffer, sizeof(InBuffer), OutBuffer.get(), OutBufferSize, nullptr, nullptr))
						{
							const wchar_t* const 文件名 = ((ProcExp_OutBuffer*)OutBuffer.get())->文件名();
							if (DataString == 文件名)
							{
								DuplicateHandle(SourceProcessHandle, (HANDLE)系统句柄表条目信息头->HandleValue, NULL, &TargetHandle, NULL, FALSE, DUPLICATE_CLOSE_SOURCE);
								return;
							}
							break;
						}
						else if (GetLastError() != ERROR_MORE_DATA)
							break;
					}
					do
						if (++系统句柄表条目信息头 >= 系统句柄表条目信息尾)
							return;
					while (OB_TYPE_FILE != 系统句柄表条目信息头->ObjectTypeIndex || 句柄不可用(系统句柄表条目信息头, SourceProcessHandle, TargetHandle));
				}
				break;
		}
	}
	throw 提权操作异常::COM_number_not_found;
}
int wmain(int argc, wchar_t* argv[])
{
	EXE路径 = argv[0];
	const path NamedPipeName = path(L"\\\\.\\pipe") / argv[1];
	WaitNamedPipeW(NamedPipeName.c_str(), NMPWAIT_WAIT_FOREVER);
	File = CreateFileW(NamedPipeName.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
	constexpr void(*操作列表[])() = { Install_path_manager,Uninstall_path_manager,Set_shared_path,Add_shared_path,Remove_shared_path,Builtin_bug_fix,Associate_prj_extension,Get_pathdef_permission,Serialport_snatch };
	提权操作函数 函数序号;
	DWORD NumberOfBytesRead;
	for (;;)
	{
		ReadFile(File, &函数序号, sizeof(函数序号), &NumberOfBytesRead, NULL);
		if ((size_t)函数序号 == std::extent_v<decltype(操作列表)>)
			break;
		DWORD NumberOfBytesWritten;
		try
		{
			操作列表[(size_t)函数序号]();
		}
		catch (提权操作异常 ex)
		{
			WriteFile(File, &ex, sizeof(ex), &NumberOfBytesWritten, NULL);
			continue;
		}
		constexpr 提权操作异常 操作成功 = 提权操作异常::Operation_succeeded;
		WriteFile(File, &操作成功, sizeof(操作成功), &NumberOfBytesWritten, NULL);
	}
}
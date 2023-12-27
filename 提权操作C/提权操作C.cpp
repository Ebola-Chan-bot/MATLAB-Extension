#include"提权操作.h"
#include<Windows.h>
#include<AclAPI.h>
#include<filesystem>
#include<fstream>
#include<unordered_set>
#include<functional>
using namespace std::filesystem;
template<typename 值类型>
struct 懒加载
{
	值类型()取值方法;
	懒加载(值类型()) :取值方法(取值方法) {}
	值类型& operator()()noexcept
	{
		if (!容器.has_value())
			容器 = 取值方法();
		return 容器.value();
	}
	const 值类型& operator()()const noexcept
	{
		if (!容器.has_value())
			容器 = 取值方法();
		return 容器.value();
	}
protected:
	std::optional<值类型>容器;
};
const 懒加载<path>安装目录([]()noexcept
	{
		constexpr auto 函数 = [](wchar_t* 指针, size_t 尺寸)noexcept {return GetModuleFileNameW(NULL, 指针, 尺寸); };
		std::wstring 路径缓冲;
		路径缓冲.resize_and_overwrite(16, 函数);
		while (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
			路径缓冲.resize_and_overwrite(路径缓冲.size() * 2, 函数);
		return  path(路径缓冲).parent_path();
	});
const 懒加载<path>数据目录([]()noexcept
	{
		constexpr wchar_t ProgramData[] = L"ProgramData";
		std::wstring 路径缓冲;
		路径缓冲.resize_and_overwrite(GetEnvironmentVariableW(ProgramData, nullptr, 0), [](wchar_t* 指针, size_t 尺寸) {return GetEnvironmentVariableW(ProgramData, 指针, 尺寸); });
		return path(路径缓冲) / L"MathWorks\\埃博拉酱";
	});
const 懒加载<path>共享路径([]()noexcept
	{
		return 数据目录() / L"共享路径.txt";
	});
std::ostringstream RC输出流(const path& MatlabRc)noexcept
{
	std::ifstream RC输入流(MatlabRc);
	std::string 行;
	std::ostringstream 输出流;
	while (std::getline(RC输入流, 行))
		if (!行.ends_with("%埃博拉酱"))
			输出流 << 行 << std::endl;
	return 输出流;
}
void 公开只读权限(LPWSTR ObjectName)noexcept
{
	PACL Dacl;
	PSECURITY_DESCRIPTOR SecurityDescriptor;
	GetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &Dacl, NULL, &SecurityDescriptor);
	LocalFree(SecurityDescriptor);
	EXPLICIT_ACCESS_A ExplicitAccess;
	char Users[] = "Users";
	BuildExplicitAccessWithNameA(&ExplicitAccess, Users, GENERIC_READ, GRANT_ACCESS, SUB_CONTAINERS_AND_OBJECTS_INHERIT);
	SetEntriesInAclA(1, &ExplicitAccess, Dacl, &Dacl);
	SetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, Dacl, NULL);
	LocalFree(Dacl);
}
HANDLE File;
std::wstring 读入UTF16字符串()noexcept
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
std::string 读入UTF8字符串()noexcept
{
	const std::wstring UTF16 = 读入UTF16字符串();
	std::string UTF8;
	UTF8.resize_and_overwrite(UTF16.size() * 3, [&UTF16](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, NULL, UTF16.c_str(), UTF16.size(), 指针, 尺寸, NULL, NULL) - 1; });
	return UTF8;
}
void Install_path_manager()noexcept
{
	const path MatlabRoot(读入UTF16字符串());
	static const path 安装安装目录 = 安装目录() / L"安装";
	copy_file(安装安装目录 / L"savepath.m", MatlabRoot / L"toolbox\\matlab\\general\\savepath.m", copy_options::overwrite_existing);
	static const path 数据internal目录 = 数据目录() / L"+MATLAB\\+internal";
	create_directories(数据internal目录);
	copy_file(安装安装目录 / L"RcAddPath.m", 数据internal目录 / L"RcAddPath.m", copy_options::overwrite_existing);
	if (!is_regular_file(共享路径()))
		std::ofstream(共享路径()).close();
	const path MatlabRC = MatlabRoot / L"toolbox\\local\\matlabrc.m";
	std::ostringstream 输出流 = RC输出流(MatlabRC);
	std::string 数据目录UTF8;
	数据目录UTF8.resize_and_overwrite(数据目录().native().size() * 3, [](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, 0, 数据目录().c_str(), -1, 指针, 尺寸 + 1, NULL, NULL) - 1; });
	输出流 << "addpath('" << 数据目录UTF8 << "');MATLAB.internal.RcAddPath;%埃博拉酱";
	std::ofstream(MatlabRC) << 输出流.str();
	const path::string_type& PathDef = (MatlabRoot / "toolbox\local\pathdef.m").native();
	const std::unique_ptr<wchar_t[]>路径缓冲 = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
	wcscpy(路径缓冲.get(), PathDef.c_str());
	公开只读权限(路径缓冲.get());
}
void Uninstall_path_manager()noexcept
{
	path Matlab路径(读入UTF16字符串());
	copy_file(安装目录() / L"原文件\savepath.m", Matlab路径 / L"toolbox\matlab\general\savepath.m", copy_options::overwrite_existing);
	Matlab路径 /= L"toolbox\local\matlabrc.m";
	std::ofstream(Matlab路径) << RC输出流(Matlab路径).str();
}
void Set_shared_path()noexcept
{
	std::ofstream(共享路径()) << 读入UTF8字符串();
}
void Add_shared_path()noexcept
{
	std::istringstream 新路径(读入UTF8字符串());
	std::unordered_set<std::string>路径集合;
	std::string 路径;
	while (std::getline(新路径, 路径, ';'))
		路径集合.insert(std::move(路径));
	std::ifstream 旧路径(共享路径());
	while (std::getline(旧路径, 路径, ';'))
		路径集合.insert(std::move(路径));
	旧路径.close();
	std::ofstream 输出流(共享路径());
	for (const std::string& 唯一路径 : 路径集合)
		输出流 << 唯一路径 << ';';
}
void Remove_shared_path()noexcept
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
	std::ofstream 输出流(共享路径());
	for (const std::string& 唯一路径 : 路径集合)
		输出流 << 唯一路径 << ';';
}
void Builtin_bug_fix()
{
	constexpr wchar_t 文件名[][32] = { L"getDocumentationXML.m", L"CshDocPageHandler.m", L"Document.m", L"ToolboxConfigurationReader.m", L"getReferencePage.m" };
	constexpr wchar_t 目标目录[][64] =
	{
		L"toolbox\matlab\helptools\+matlab\+internal\+doc",
		L"toolbox\matlab\helptools\+matlab\+internal\+doc\+ui\@CshDocPageHandler",
		L"toolbox\matlab\codetools\+matlab\+desktop\+editor\@Document",
		L"toolbox\matlab\toolbox_packaging\+matlab\+internal\+addons\+metadata",
		L"toolbox\matlab\helptools\+matlab\+internal\+doc\+reference"
	};
	static const path 新文件目录 = 安装目录() / L"新文件";
	static const path 原文件目录 = 数据目录() / L"原文件";
	size_t 命令数;
	DWORD NumberOfBytes;
	ReadFile(File, &命令数, sizeof(命令数), &NumberOfBytes, NULL);
	std::unique_ptr<int8_t[]>所有命令 = std::make_unique_for_overwrite<int8_t[]>(命令数);
	ReadFile(File, 所有命令.get(), 命令数, &NumberOfBytes, NULL);
	const path MatlabRoot(读入UTF16字符串());
	for (size_t C = 0; C < 命令数; ++C)
	{
		int8_t 命令 = 所有命令[C];
		if (命令 > 0)
		{
			命令--;
			const path Matlab文件路径 = MatlabRoot / 目标目录[命令] / 文件名[命令];
			copy_file(Matlab文件路径, 原文件目录 / 文件名[命令], copy_options::overwrite_existing);
			copy_file(新文件目录 / 文件名[命令], Matlab文件路径, copy_options::overwrite_existing);
		}
		else if (命令 < 0)
		{
			命令 = -1 - 命令;
			copy_file(原文件目录 / 文件名[命令], MatlabRoot / 目标目录[命令] / 文件名[命令], copy_options::overwrite_existing);
		}
		else
			throw 提权操作异常::Builtin_bug_fix_command_is_0;
	}
}
void Associate_prj_extension()noexcept
{
	HKEY 键A;

}
void Get_pathdef_permission()noexcept
{

}
int wmain(int argc, wchar_t* argv[])
{
	const path NamedPipeName = path(L"\\\\.\\pipe") / argv[0];
	WaitNamedPipeW(NamedPipeName.c_str(), NMPWAIT_WAIT_FOREVER);
	const std::unique_ptr<std::remove_pointer_t<HANDLE>, decltype(CloseHandle)*>Object(File = CreateFileW(NamedPipeName.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL), CloseHandle);
	constexpr void(*操作列表[])() = { Install_path_manager,Uninstall_path_manager,Set_shared_path,Add_shared_path,Remove_shared_path,Builtin_bug_fix,Associate_prj_extension,Get_pathdef_permission };
	uint8_t 函数序号;
	DWORD NumberOfBytesRead;
	for (;;)
	{
		ReadFile(File, &函数序号, sizeof(函数序号), &NumberOfBytesRead, NULL);
		if (函数序号 == std::extent_v<decltype(操作列表)>)
			break;
		DWORD NumberOfBytesWritten;
		try
		{
			操作列表[函数序号]();
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
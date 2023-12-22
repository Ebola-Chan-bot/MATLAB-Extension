#include<Windows.h>
#include<AclAPI.h>
#include<filesystem>
#include<fstream>
void 公开只读权限(LPWSTR ObjectName)noexcept
{
	PACL Dacl裸指针;
	PSECURITY_DESCRIPTOR SecurityDescriptor裸指针;
	GetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &Dacl裸指针, NULL, &SecurityDescriptor裸指针);
	std::unique_ptr<void, void(*)(PSECURITY_DESCRIPTOR)>SecurityDescriptor(SecurityDescriptor裸指针, [](PSECURITY_DESCRIPTOR 指针) {LocalFree(指针); });
	EXPLICIT_ACCESS_A ExplicitAccess;
	char Users[] = "Users";
	BuildExplicitAccessWithNameA(&ExplicitAccess, Users, GENERIC_READ, GRANT_ACCESS, SUB_CONTAINERS_AND_OBJECTS_INHERIT);
	SetEntriesInAclA(1, &ExplicitAccess, Dacl裸指针, &Dacl裸指针);
	std::unique_ptr<ACL, void(*)(PACL)>Dacl(Dacl裸指针, [](PACL 指针) {LocalFree(指针); });
	SetNamedSecurityInfoW(ObjectName, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, Dacl裸指针, NULL);
}
using namespace std::filesystem;
path 取埃博拉酱目录()noexcept
{
	constexpr wchar_t ProgramData[] = L"ProgramData";
	std::wstring 路径缓冲;
	路径缓冲.resize_and_overwrite(GetEnvironmentVariableW(ProgramData, nullptr, 0), [](wchar_t* 指针, size_t 尺寸) {return GetEnvironmentVariableW(ProgramData, 指针, 尺寸); });
	return path(路径缓冲) / L"MathWorks\\埃博拉酱";
}
path 取EXE目录()noexcept
{
	constexpr auto 函数 = [](wchar_t* 指针, size_t 尺寸)noexcept {return GetModuleFileNameW(NULL, 指针, 尺寸); };
	std::wstring 路径缓冲;
	路径缓冲.resize_and_overwrite(16, 函数);
	while (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
		路径缓冲.resize_and_overwrite(路径缓冲.size() << 1, 函数);
	return path(路径缓冲);
}
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
enum class 提权操作 :uint8_t
{
	Install_Path_Manager,
	Uninstall_Path_Manager,
	Set_shared_path,
	Add_shared_path,
	Remove_shared_path,
	Builtin_bug_fix,
	Associate_prj_extension,
	Get_pathdef_permission,
};
struct 内存映射参数
{
	const 提权操作* const 指针;
	内存映射参数(const char* UUID)noexcept :句柄(OpenFileMappingA(FILE_MAP_READ, FALSE, UUID)), 指针((提权操作*)MapViewOfFile(句柄, FILE_MAP_READ, 0, 0, 0)) {}
	~内存映射参数()noexcept
	{
		UnmapViewOfFile(指针);
		CloseHandle(句柄);
	}
	内存映射参数(const 内存映射参数&) = delete;
protected:
	const HANDLE 句柄;
};
std::string 读入UTF8参数(const 内存映射参数&参数)
{
	const uint8_t* 字符串长度 = (uint8_t*)(参数.指针 + 1);
	std::string 路径缓冲;
	路径缓冲.resize_and_overwrite(*字符串长度 * 3, [字符串长度](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, 0, (wchar_t*)(字符串长度 + 1), *字符串长度, 指针, 尺寸 + 1, NULL, NULL); });
	return 路径缓冲;
}
int main(int argc, char* argv[])
{
	const 内存映射参数 参数(argv[0]);
	switch (*参数.指针)
	{
	case 提权操作::Install_Path_Manager:
	{
		const uint8_t* 字符串长度 = (uint8_t*)(参数.指针 + 1);
		const path MatlabRoot(std::wstring((wchar_t*)(字符串长度 + 1), *字符串长度));
		const path 安装目录 = 取EXE目录() / L"安装";
		copy_file(安装目录 / L"savepath.m", MatlabRoot / L"toolbox\\matlab\\general\\savepath.m", copy_options::overwrite_existing);
		const path 埃博拉酱目录 = 取埃博拉酱目录();
		const path 埃博拉酱internal目录 = 埃博拉酱目录 / L"+MATLAB\\internal";
		create_directories(埃博拉酱internal目录);
		copy_file(安装目录 / L"RcAddPath.m", 埃博拉酱internal目录 / L"RcAddPath.m", copy_options::overwrite_existing);
		const path 共享路径 = 埃博拉酱目录 / L"共享路径.txt";
		if (!is_regular_file(共享路径))
			std::ofstream(共享路径).close();
		const path MatlabRC = MatlabRoot / L"toolbox\\local\\matlabrc.m";
		std::ostringstream 输出流 = RC输出流(MatlabRC);
		std::string 埃博拉酱目录UTF8;
		埃博拉酱目录UTF8.resize_and_overwrite(埃博拉酱目录.native().size() * 3, [&埃博拉酱目录](char* 指针, size_t 尺寸) {return WideCharToMultiByte(CP_UTF8, 0, 埃博拉酱目录.c_str(), -1, 指针, 尺寸 + 1, NULL, NULL) - 1; });
		输出流 << "addpath('" << 埃博拉酱目录UTF8 << "');MATLAB.internal.RcAddPath;%埃博拉酱";
		std::ofstream(MatlabRC) << 输出流.str();
		const path::string_type& PathDef = (MatlabRoot / "toolbox\local\pathdef.m").native();
		const std::unique_ptr<wchar_t[]>路径缓冲 = std::make_unique_for_overwrite<wchar_t[]>(PathDef.size() + 1);
		wcscpy(路径缓冲.get(), PathDef.c_str());
		公开只读权限(路径缓冲.get());
	}
	break;
	case 提权操作::Uninstall_Path_Manager:
	{
		const uint8_t* 字符串长度 = (uint8_t*)(参数.指针 + 1);
		path Matlab路径(std::wstring((wchar_t*)(字符串长度 + 1), *字符串长度));
		copy_file(取EXE目录() / L"原文件\savepath.m", Matlab路径 / L"toolbox\matlab\general\savepath.m", copy_options::overwrite_existing);
		Matlab路径 /= L"toolbox\local\matlabrc.m";
		std::ofstream(Matlab路径) << RC输出流(Matlab路径).str();
	}
	break;
	case 提权操作::Set_shared_path:
		std::ofstream(取埃博拉酱目录() / L"共享路径.txt") << 读入UTF8参数(参数);
		break;
	case 提权操作::Add_shared_path:
	{
		const std::string 新路径 = 读入UTF8参数(参数);
		const path 共享路径 = 取埃博拉酱目录() / L"共享路径.txt";		
		std::ifstream 输入流(共享路径);
		std::string 路径;
		std::getline(输入流, 路径, ';');
	}
	}
}
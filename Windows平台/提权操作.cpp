#include"pch.h"
#include"MATLAB异常.h"
#include<提权操作.h>
#include<Mex工具.h>
#include<shellapi.h>
#pragma comment(lib,"Shell32.lib")
#include<rpc.h>
#pragma comment(lib,"Rpcrt4.lib")
#include<objbase.h>
#pragma comment(lib,"Ole32.lib")
#include<filesystem>
#include<span>
static HANDLE 特权服务器;
static bool 已连接 = false;
using namespace 提权操作;
void 关闭特权服务器()noexcept
{
	if (已连接)
	{
		constexpr 提权操作函数 ShutdownServer = 提权操作函数::Shutdown_server;
		DWORD NumberOfBytesWritten;
		WriteFile(特权服务器, &ShutdownServer, sizeof(ShutdownServer), &NumberOfBytesWritten, NULL);
		CloseHandle(特权服务器);
	}
}
extern HMODULE Module;
extern std::shared_ptr<matlab::engine::MATLABEngine> Engine;
static 懒加载<std::string>MatlabRoot参数头([]()noexcept
	{
		const String MatlabRoot = Engine->feval<CharArray>("matlabroot").toUTF16();
		const size_t Size = MatlabRoot.size();
		std::stringstream 返回值;
		返回值.write(0, sizeof(提权操作函数));
		返回值.write((char*)&Size, sizeof(Size));
		返回值.write((char*)MatlabRoot.c_str(), Size * sizeof(std::remove_pointer_t<decltype(MatlabRoot.c_str())>));
		return 返回值.str();
	});
void 特权调用(const std::string& 参数)
{
	if (!已连接)
	{
		UUID Uuid;
		UuidCreate(&Uuid);
		RPC_WSTR Parameters;
		UuidToStringW(&Uuid, &Parameters);
		const std::filesystem::path Name = std::filesystem::path(L"\\\\.\\pipe") / (wchar_t*)Parameters;
		DWORD BufferSize = 128;
		特权服务器 = CreateNamedPipeW(Name.c_str(), PIPE_ACCESS_DUPLEX, 0, 1, BufferSize, BufferSize, 0, NULL);
		std::unique_ptr<wchar_t[]>Filename;
		for (;;)
		{
			Filename = std::make_unique_for_overwrite<wchar_t[]>(BufferSize);
			GetModuleFileNameW(Module, Filename.get(), BufferSize);
			if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
				BufferSize *= 2;
			else
				break;
		}
		CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
		ShellExecuteW(NULL, L"runas", (std::filesystem::path(Filename.get()).parent_path().parent_path() / L"提权操作C.exe").c_str(), (LPCWSTR)Parameters, NULL, 0);
		RpcStringFreeW(&Parameters);
		CoUninitialize();
		ConnectNamedPipe(特权服务器, NULL);
		已连接 = true;
	}
	static DWORD NumberOfBytes;
	WriteFile(特权服务器, 参数.data(), 参数.size(), &NumberOfBytes, NULL);
	提权操作异常 结果;
	ReadFile(特权服务器, &结果, sizeof(结果), &NumberOfBytes, NULL);
	if (结果 != 提权操作异常::Operation_succeeded)
		throw MATLAB异常((MATLAB异常类型)((std::underlying_type_t<MATLAB异常类型>)MATLAB异常类型::提权操作成功 + (std::underlying_type_t<decltype(结果)>)结果));
}
API声明(Install_path_manager)
{
	static const std::string 参数 = []()
		{
			std::stringstream 返回值(MatlabRoot参数头());
			constexpr 提权操作函数 函数 = 提权操作函数::Install_Path_Manager;
			返回值.write((char*)&函数, sizeof(函数));
			return 返回值.str();
		}();
		特权调用(参数);
}
API声明(Uninstall_path_manager)
{
	static const std::string 参数 = []()
		{
			std::stringstream 返回值(MatlabRoot参数头());
			constexpr 提权操作函数 函数 = 提权操作函数::Uninstall_Path_Manager;
			返回值.write((char*)&函数, sizeof(函数));
			return 返回值.str();
		}();
		特权调用(参数);
}
void SAR_shared_path(ArgumentList& inputs, 提权操作函数 SAR)
{
	const String SharedPath = Mex工具::万能转码<String>(inputs[1]);
	std::stringstream 参数;
	参数.write((char*)&SAR, sizeof(SAR));
	const size_t Size = SharedPath.size();
	参数.write((char*)&Size, sizeof(Size));
	参数.write((char*)SharedPath.data(), Size * sizeof(std::remove_pointer_t<decltype(SharedPath.data())>));
	特权调用(参数.str());
}
API声明(Set_shared_path)
{
	SAR_shared_path(inputs, 提权操作函数::Set_shared_path);
}
API声明(Add_shared_path)
{
	SAR_shared_path(inputs, 提权操作函数::Add_shared_path);
}
API声明(Remove_shared_path)
{
	SAR_shared_path(inputs, 提权操作函数::Remove_shared_path);
}
API声明(Builtin_bug_fix)
{
	TypedArray<int8_t>Command(inputs[1]);
	std::stringstream 参数(MatlabRoot参数头());
	constexpr 提权操作函数 函数 = 提权操作函数::Builtin_bug_fix;
	参数.write((char*)&函数, sizeof(函数));
	参数.seekp(0, std::ios_base::end);
	const size_t Size = Command.getNumberOfElements();
	参数.write((char*)&Size, sizeof(Size));
	const buffer_ptr_t<int8_t>Buffer = Command.release();
	参数.write((char*)Buffer.get(), Size);
	特权调用(参数.str());
}
API声明(Associate_prj_extension)
{
	static const String Version = Mex工具::万能转码<String>(Engine->feval<StructArray>("ver", Mex工具::万能转码<CharArray>(L"MATLAB"))[0]["Version"]);
	const 缓冲区& 参数头 = MatlabRoot参数头();
}
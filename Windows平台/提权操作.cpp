#include"pch.h"
#include"MATLAB异常.h"
#include<提权操作.h>
#include<Mex工具.h>
#include<shellapi.h>
#pragma comment(lib,"Shell32.lib")
#include<filesystem>
#include<rpc.h>
#pragma comment(lib,"Rpcrt4.lib")
#include<objbase.h>
#pragma comment(lib,"Ole32.lib")
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
void 启动特权服务器()
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
}
extern std::shared_ptr<matlab::engine::MATLABEngine> Engine;
API声明(Install_path_manager)
{
	启动特权服务器();
	static const String MatlabRoot = Engine->feval<CharArray>("matlabroot").toUTF16();
	static const size_t Size = MatlabRoot.size();
	static const DWORD NumberOfBytesToWrite = sizeof(提权操作函数) + sizeof(Size) + Size * sizeof(char16_t);
	static const std::unique_ptr<char[]>参数缓冲 = []()
		{
			std::unique_ptr<char[]>返回值 = std::make_unique_for_overwrite<char[]>(NumberOfBytesToWrite);
			void* 指针 = 返回值.get();
			*(提权操作函数*)指针 = 提权操作函数::Install_Path_Manager;
			*(size_t*)(指针 = (提权操作函数*)指针 + 1) = Size;
			std::copy_n(MatlabRoot.c_str(), Size, (char16_t*)((size_t*)指针 + 1));
			return 返回值;
		}();
	static DWORD NumberOfBytes;
	WriteFile(特权服务器, 参数缓冲.get(), NumberOfBytesToWrite, &NumberOfBytes, NULL);
	提权操作异常 结果;
	ReadFile(特权服务器, &结果, sizeof(结果), &NumberOfBytes, NULL);
}
API声明(Uninstall_path_manager)
{
	启动特权服务器();

}
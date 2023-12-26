#include"pch.h"
#include"MATLAB异常.h"
#include<Mex工具.h>
#include<shellapi.h>
#pragma comment(lib,"Shell32.lib")
#include<filesystem>
#include<rpc.h>
#pragma comment(lib,"Rpcrt4.lib")
#include<objbase.h>
#pragma comment(lib,"Ole32.lib")
RPC_WSTR Parameters = nullptr;
HANDLE 特权服务器 = 0;
bool COM已初始化 = false;
void 关闭特权服务器()noexcept
{
	if (COM已初始化)
		CoUninitialize();
	if (特权服务器)
		CloseHandle(特权服务器);
	if (Parameters)
		RpcStringFreeW(&Parameters);
}
extern HMODULE Module;
void UAC请求()
{
	DWORD Size = 32;
	std::unique_ptr<wchar_t[]>Filename;
	for (;;)
	{
		Filename = std::make_unique_for_overwrite<wchar_t[]>(Size);
		GetModuleFileNameW(Module, Filename.get(), Size);
		if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
			Size *= 2;
		else
			break;
	}
	if (!COM已初始化)
		CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
	const INT_PTR 错误代码 = (INT_PTR)ShellExecuteW(NULL, L"runas", (std::filesystem::path(Filename.get()).parent_path().parent_path() / L"提权操作C.exe").c_str(), (LPCWSTR)Parameters, NULL, 0);
	if (错误代码 <= 32)
		throw MATLAB异常(MATLAB异常类型::特权服务器启动失败, 内部异常类型::Win32异常, 错误代码);
}
void 启动特权服务器()
{
	if (!Parameters)
	{
		UUID Uuid;
		UuidCreate(&Uuid);
		UuidToStringW(&Uuid, &Parameters);
	}
	if (!特权服务器)
	{
		const std::filesystem::path Name = std::filesystem::path(L"\\\\.\\pipe") / (wchar_t*)Parameters;
		constexpr DWORD BufferSize = 32;
		特权服务器 = CreateNamedPipeW(Name.c_str(), PIPE_ACCESS_DUPLEX, 0, 1, BufferSize, BufferSize, 50, NULL);
		UAC请求();
	}
	if (!ConnectNamedPipe(特权服务器, NULL))
		throw MATLAB异常(MATLAB异常类型::特权服务器连接失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(Install_path_manager)
{

}
#include "pch.h"
#include"实用工具.h"
#include <MATLAB异常.h>
using namespace Mex工具;
Mex工具API(MemoryMapping_Create)
{
	LPCWSTR Name = nullptr;
	String 名称;
	if (输入[4].getNumberOfElements())
	{
		名称 = 万能转码<String>(输入[4]);
		Name = (LPCWSTR)名称.c_str();
	}
	size_t 总字节数; 
	CellArray 输入元胞 = 元胞字节化(输入[5], 总字节数);
	LARGE_INTEGER 文件大小{ .QuadPart = 万能转码<LONGLONG>(std::move(输入[3])) };
	const HANDLE 文件句柄 = 万能转码<HANDLE>(std::move(输入[1]));
	if (文件大小.QuadPart)
	{
		if (总字节数 > 文件大小.QuadPart)[[unlikely]]
			EnumThrow(MATLAB::Exception::Fill_data_out_of_memory_range);
	}
	else if (文件句柄 == INVALID_HANDLE_VALUE)
		文件大小.QuadPart = 总字节数;
	else
	{
		GetFileSizeEx(文件句柄, &文件大小);
		文件大小.QuadPart = max(文件大小.QuadPart, 总字节数);
	}
	const DWORD Protect = 万能转码<DWORD>(std::move(输入[2]));
	std::unique_ptr<void, decltype(CloseHandle)*> 映射句柄{ CreateFileMapping(文件句柄, nullptr, Protect, 文件大小.HighPart, 文件大小.LowPart, Name),CloseHandle };
	if (!映射句柄)[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_create_a_file_mapping);
	输出[0] = 万能转码(映射句柄.get());
	const bool 输出指针 = 输出.size() > 1;
	if (!输入元胞.isEmpty() || 输出指针)
	{
		LPVOID 映射指针 = MapViewOfFile(映射句柄.get(), Protect == PAGE_READONLY ? FILE_MAP_READ : FILE_MAP_WRITE, 0, 0, 0);
		if (!映射指针)[[unlikely]]
			CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
		for (Array 输入 : 输入元胞)
			万能转码(std::move(输入), 映射指针);
		if (输出指针)
		{
			输出[1] = 万能转码(映射指针);
			自动析构(映射指针, UnmapViewOfFile);
		}
		else
			UnmapViewOfFile(映射指针);
	}
	自动析构(映射句柄.release(), CloseHandle);
}
Mex工具API(MemoryMapping_Open)
{
	const String Name = 万能转码<String>(std::move(输入[2]));
	const DWORD DesiredAccess = 万能转码<DWORD>(std::move(输入[1]));
	std::unique_ptr<void, decltype(CloseHandle)*> 映射句柄{ OpenFileMappingW(DesiredAccess, false, (LPCWSTR)Name.c_str()),CloseHandle };
	if (映射句柄)
		输出[0] = 万能转码(映射句柄.get());
	else[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_open_file_mapping);
	if (输出.size() > 2)
	{
		const LPVOID 映射指针 = MapViewOfFile(映射句柄.get(), DesiredAccess, 0, 0, 0);
		if (映射指针)
		{
			输出[1] = 万能转码(映射指针);
			自动析构(映射指针, UnmapViewOfFile);
		}
		else[[unlikely]]
			CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
	}
	自动析构(映射句柄.release(), CloseHandle);
}
Mex工具API(MemoryMapping_View)
{
	const LARGE_INTEGER FileOffset{ .QuadPart = 万能转码<LONGLONG>(std::move(输入[3])) };
	const LPVOID 映射指针 = MapViewOfFile(万能转码<HANDLE>(std::move(输入[1])), 万能转码<DWORD>(std::move(输入[2])), FileOffset.HighPart, FileOffset.LowPart, 万能转码<SIZE_T>(std::move(输入[4])));
	if (映射指针)
	{
		输出[0] = 万能转码(映射指针);
		自动析构(映射指针, UnmapViewOfFile);
	}
	else[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
}
Mex工具API(MemoryMapping_Unview)
{
	const LPVOID 映射视图 = 万能转码<LPVOID>(std::move(输入[1]));
	if (手动析构(映射视图))
		UnmapViewOfFile(映射视图);
}
Mex工具API(MemoryMapping_Close)
{
	const HANDLE 映射句柄 = 万能转码<HANDLE>(std::move(输入[1]));
	if (手动析构(映射句柄))
		CloseHandle(映射句柄);
}
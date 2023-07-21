#include "pch.h"
#include "MATLAB异常.h"
#include"实用工具.h"
#include<Mex工具.h>
using namespace Mex工具;
API声明(MemoryMapping_Create)
{
	LPCWSTR Name = nullptr;
	String 名称;
	if (inputs[4].getNumberOfElements())
	{
		名称 = 万能转码<String>(inputs[4]);
		Name = (LPCWSTR)名称.c_str();
	}
	size_t 总字节数; 
	CellArray 输入元胞 = 元胞字节化(inputs[5], 总字节数);
	LARGE_INTEGER 文件大小{ .QuadPart = 万能转码<LONGLONG>(inputs[3]) };
	const HANDLE 文件句柄 = (HANDLE)万能转码<uint64_t>(inputs[1]);
	if (文件大小.QuadPart)
	{
		if(总字节数 > 文件大小.QuadPart)
			throw MATLAB异常(MATLAB异常类型::填充数据超出内存范围);
	}
	else if (文件句柄 == INVALID_HANDLE_VALUE)
		文件大小.QuadPart = 总字节数;
	else
	{
		GetFileSizeEx(文件句柄, &文件大小);
		文件大小.QuadPart = max(文件大小.QuadPart, 总字节数);
	}
	const DWORD Protect = 万能转码<uint32_t>(inputs[2]);
	const HANDLE 映射句柄 = CreateFileMapping(文件句柄, nullptr, Protect, 文件大小.HighPart, 文件大小.LowPart, Name);
	if (!映射句柄)
		throw MATLAB异常(MATLAB异常类型::创建文件映射失败, 内部异常类型::Win32异常, GetLastError());
	outputs[1] = 万能转码(映射句柄);
	const bool 输出指针 = outputs.size() > 2;
	if (!输入元胞.isEmpty() || 输出指针)
	{
		void* 映射指针 = MapViewOfFile(映射句柄, Protect == PAGE_READONLY ? FILE_MAP_READ : FILE_MAP_WRITE, 0, 0, 0);
		if (!映射指针)
		{
			const MATLAB异常 异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
			CloseHandle(映射句柄);
			throw 异常;
		}
		outputs[2] = 万能转码(映射指针);
		for (const Array& 输入 : 输入元胞)
			万能转码(输入, 映射指针);
		if (!输出指针)
			UnmapViewOfFile(映射指针);
	}
}
API声明(MemoryMapping_Open)
{
	const String Name = 万能转码<String>(inputs[2]);
	const DWORD DesiredAccess = 万能转码<DWORD>(inputs[1]);
	const HANDLE 映射句柄 = OpenFileMappingW(DesiredAccess, false, (LPCWSTR)Name.c_str());
	if (映射句柄)
		outputs[1] = 万能转码(映射句柄);
	else
		throw MATLAB异常(MATLAB异常类型::打开文件映射失败, 内部异常类型::Win32异常, GetLastError());
	if (outputs.size() > 2)
	{
		const LPVOID 映射指针 = MapViewOfFile(映射句柄, DesiredAccess, 0, 0, 0);
		if (映射指针)
			outputs[2] = 万能转码(映射指针);
		else
		{
			const MATLAB异常 异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
			CloseHandle(映射句柄);
			throw 异常;
		}
	}
}
API声明(MemoryMapping_View)
{
	const LARGE_INTEGER FileOffset{ .QuadPart = 万能转码<LONGLONG>(inputs[3]) };
	const LPVOID 映射指针 = MapViewOfFile(万能转码<HANDLE>(inputs[1]), 万能转码<DWORD>(inputs[2]), FileOffset.HighPart, FileOffset.LowPart, 万能转码<SIZE_T>(inputs[4]));
	if (映射指针)
		outputs[1] = 万能转码(映射指针);
	else
		throw MATLAB异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(MemoryMapping_Unview)
{
	UnmapViewOfFile(万能转码<LPCVOID>(inputs[1]));
}
API声明(MemoryMapping_Close)
{
	CloseHandle(万能转码<HANDLE>(inputs[1]));
}
#include "pch.h"
#include "MexAPI.h"
#include"MATLAB异常.h"
#include <limits>
using namespace Mex工具;
API声明(File_Create)
{
	const String FileName = 万能转码<String>(std::move(inputs[1]));
	const HANDLE 文件句柄 = CreateFileW((LPCWSTR)FileName.c_str(), 万能转码<uint32_t>(std::move(inputs[2])), 万能转码<uint32_t>(std::move(inputs[3])), NULL, 万能转码<uint32_t>(std::move(inputs[4])), 万能转码<uint32_t>(std::move(inputs[5])), NULL);
	if (文件句柄 == INVALID_HANDLE_VALUE)
		throw MATLAB异常(MATLAB异常类型::文件创建失败, 内部异常类型::Win32异常, GetLastError());
	outputs[1] = 万能转码(文件句柄);
}
API声明(File_GetSize)
{
	LARGE_INTEGER 文件大小;
	if (GetFileSizeEx(万能转码<HANDLE>(std::move(inputs[1])), &文件大小))
		outputs[1] = 万能转码(文件大小.QuadPart);
	else
		throw MATLAB异常(MATLAB异常类型::获取文件大小失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(File_Read)
{
	LARGE_INTEGER 文件指针{ .QuadPart = 0 };
	const HANDLE 文件句柄 = (HANDLE)万能转码<uint64_t>(std::move(inputs[1]));
	SetFilePointerEx(文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	const ArrayType 读入类型 = (ArrayType)万能转码<int>(std::move(inputs[3]));
	LARGE_INTEGER 文件大小;
	GetFileSizeEx(文件句柄, &文件大小);
	const uint64_t 可读入个数 = (文件大小.QuadPart - 文件指针.QuadPart) / 类型尺寸[(int)读入类型];
	const uint64_t 读入个数 = 万能转码<uint64_t>(std::move(inputs[2]));
	
	const std::unique_ptr<动态类型缓冲>输出 = 动态类型缓冲::创建(读入类型, min(读入个数, 可读入个数));
	if (输出->字节数 < UINT32_MAX)
	{
		DWORD 实际读入数;
		if (!ReadFile(文件句柄, 输出->指针, 输出->字节数, &实际读入数, nullptr))
			throw MATLAB异常(MATLAB异常类型::读入文件失败, 内部异常类型::Win32异常, GetLastError());
	}
	else[[unlikely]]
	{
		const HANDLE 映射句柄 = CreateFileMapping(文件句柄, nullptr, PAGE_READONLY, 0, 0, nullptr);
		if (!映射句柄)
			throw MATLAB异常(MATLAB异常类型::创建文件映射失败, 内部异常类型::Win32异常, GetLastError());
		const void* const 映射指针 = MapViewOfFile(映射句柄, FILE_MAP_READ, 文件指针.HighPart, 文件指针.LowPart, 输出->字节数);
		if (!映射指针)
		{
			const MATLAB异常 异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
			CloseHandle(映射句柄);
			throw 异常;
		}
		try
		{
			memcpy(输出->指针, 映射指针, 输出->字节数);
		}
		catch (...)
		{
			UnmapViewOfFile(映射指针);
			CloseHandle(映射句柄);
			throw MATLAB异常(MATLAB异常类型::内存拷贝失败);
		}
		UnmapViewOfFile(映射指针);
		CloseHandle(映射句柄);
		文件指针.QuadPart = 输出->字节数;
		SetFilePointerEx(文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	}
	outputs[1] = 输出->打包();
}
API声明(File_SetEnd)
{
	if (!SetEndOfFile((HANDLE)万能转码<uint64_t>(std::move(inputs[1]))))
		throw MATLAB异常(MATLAB异常类型::设置文件结束失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(File_SetPointer)
{
	LARGE_INTEGER 位置{ .QuadPart = 万能转码<LONGLONG>(std::move(inputs[2])) };
	if (SetFilePointerEx(万能转码<HANDLE>(std::move(inputs[1])), 位置, &位置, 万能转码<uint32_t>(std::move(inputs[3]))))
		outputs[1] = 万能转码(位置.QuadPart);
	else
		throw MATLAB异常(MATLAB异常类型::设置文件指针失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(File_Write)
{
	const HANDLE 文件句柄 = (HANDLE)万能转码<uint64_t>(std::move(inputs[1]));
	const uint8_t 输入个数 = inputs[2].getNumberOfElements();
	const CellArray 所有输入(std::move(inputs[2]));
	uint64_t 字节数 = 0;
	for (const Array& a : 所有输入)
		字节数 += 数组字节数(a);
	//这里必须用内存映射文件，不考虑WriteFile，因为数据来源不是指针，只能用迭代器拷贝到内存
	LARGE_INTEGER 文件指针{ .QuadPart = 0 };
	SetFilePointerEx(文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	const LARGE_INTEGER 文件大小{ 文件指针.QuadPart + 字节数 };
	const HANDLE 映射句柄 = CreateFileMapping(文件句柄, nullptr, PAGE_READWRITE, 文件大小.HighPart, 文件大小.LowPart, nullptr);
	if (!映射句柄)
		throw MATLAB异常(MATLAB异常类型::创建文件映射失败, 内部异常类型::Win32异常, GetLastError());
	void* const 映射指针 = MapViewOfFile(映射句柄, FILE_MAP_WRITE, 文件指针.HighPart, 文件指针.LowPart, 字节数);
	if (!映射指针)
	{
		const MATLAB异常 异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
		CloseHandle(映射句柄);
		throw 异常;
	}
	try
	{
		void* 写出头 = 映射指针;
		for (Array&& a : 所有输入)
			万能转码(std::move(a), 写出头);
	}
	catch (Mex异常 异常)
	{
		UnmapViewOfFile(映射指针);
		CloseHandle(映射句柄);
		throw MATLAB异常(MATLAB异常类型::内存拷贝失败, 内部异常类型::Mex异常, 异常);
	}
	UnmapViewOfFile(映射指针);
	CloseHandle(映射句柄);
	SetFilePointerEx(文件句柄, 文件大小, &文件指针, FILE_BEGIN);
}
API声明(File_Close)
{
	CloseHandle((HANDLE)万能转码<uint64_t>(std::move(inputs[1])));
}
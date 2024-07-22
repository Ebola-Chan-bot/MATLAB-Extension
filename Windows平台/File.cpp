#include "pch.h"
#include"实用工具.h"
#include<MATLAB异常.h>
#include <Mex工具.hpp>
import std;
using namespace Mex工具;
using namespace matlab::data;
#undef min
struct UniqueHandle :std::unique_ptr<std::remove_pointer_t<HANDLE>, decltype(&CloseHandle)>
{
	using deleter = decltype(&CloseHandle);
	UniqueHandle(HANDLE h, deleter 删除器 = CloseHandle) :std::unique_ptr<std::remove_pointer_t<HANDLE>, deleter>(h, 删除器) {}
	operator HANDLE()const noexcept { return get(); }
	virtual ~UniqueHandle() = default;
};
Mex工具API(File_Create)
{
	const String FileName = 万能转码<String>(输入[1]);
	const UniqueHandle 文件句柄 = CreateFileW((LPCWSTR)FileName.c_str(), 万能转码<DWORD>(输入[2]), 万能转码<DWORD>(输入[3]), NULL, 万能转码<DWORD>(输入[4]), 万能转码<DWORD>(输入[5]), NULL);
	if (文件句柄 == INVALID_HANDLE_VALUE)
		CheckLastError(MATLAB::Exception::File_creation_failed);
	输出[1] = 万能转码(文件句柄);
}
Mex工具API(File_GetSize)
{
	LARGE_INTEGER 文件大小;
	if (GetFileSizeEx(万能转码<HANDLE>(输入[1]), &文件大小))
		输出[1] = 万能转码(文件大小.QuadPart);
	else
		CheckLastError(MATLAB::Exception::Failed_to_get_file_size);
}
Mex工具API(File_Read)
{
	LARGE_INTEGER 文件指针{ .QuadPart = 0 };
	const UniqueHandle 文件句柄 = 万能转码<HANDLE>(输入[1]);
	SetFilePointerEx(文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	const ArrayType 读入类型 = 万能转码<ArrayType>(输入[3]);
	LARGE_INTEGER 文件大小;
	GetFileSizeEx(文件句柄, &文件大小);
	const size_t 元素字节数 = 类型字节数(读入类型);
	const size_t 应读入个数= std::min(万能转码<uint64_t>(输入[2]), (文件大小.QuadPart - 文件指针.QuadPart) / 元素字节数);
	const size_t 应读入字节数 = 应读入个数 * 元素字节数;
		const UniqueHandle 映射句柄 = CreateFileMapping(文件句柄, nullptr, PAGE_READONLY, 0, 0, nullptr);
		if (!映射句柄)
			CheckLastError(MATLAB::Exception::Failed_to_create_a_file_mapping);
		const LPVOID 映射指针 = MapViewOfFile(映射句柄, FILE_MAP_READ, 文件指针.HighPart, 文件指针.LowPart, 应读入字节数);
		if (!映射指针)
			CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
		文件指针.QuadPart = 应读入字节数;
		SetFilePointerEx(文件句柄, 文件指针, &文件指针, FILE_CURRENT);
}
Mex工具API(File_SetEnd)
{
	if (!SetEndOfFile((HANDLE)万能转码<uint64_t>(输入[1])))
		throw MATLAB异常(MATLAB异常类型::设置文件结束失败, 内部异常类型::Win32异常, GetLastError());
}
Mex工具API(File_SetPointer)
{
	LARGE_INTEGER 位置{ .QuadPart = 万能转码<LONGLONG>(输入[2]) };
	if (SetFilePointerEx(万能转码<HANDLE>(输入[1]), 位置, &位置, 万能转码<uint32_t>(输入[3])))
		输出[1] = 万能转码(位置.QuadPart);
	else
		throw MATLAB异常(MATLAB异常类型::设置文件指针失败, 内部异常类型::Win32异常, GetLastError());
}
Mex工具API(File_Write)
{
	const HANDLE 文件句柄 = (HANDLE)万能转码<uint64_t>(输入[1]);
	const uint8_t 输入个数 = 输入[2].getNumberOfElements();
	const CellArray 所有输入(输入[2]);
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
		for (const Array& a : 所有输入)
			万能转码(a, 写出头);
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
Mex工具API(File_Close)
{
	CloseHandle((HANDLE)万能转码<uint64_t>(输入[1]));
}
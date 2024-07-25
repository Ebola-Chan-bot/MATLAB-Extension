#include "pch.h"
#include"实用工具.h"
#include<MATLAB异常.h>
#include <Mex工具.hpp>
using namespace Mex工具;
using namespace matlab::data;
#undef min
struct 文件
{
	~文件()
	{
		CloseHandle(映射句柄);
		CloseHandle(文件句柄);
	}
	HANDLE 文件句柄;
	HANDLE 映射句柄 = NULL;
};
Mex工具API(File_Create)
{
	const String FileName = 万能转码<String>(std::move(输入[1]));
	const HANDLE 文件句柄 = CreateFileW((LPCWSTR)FileName.c_str(), 万能转码<DWORD>(std::move(输入[2])), 万能转码<DWORD>(std::move(输入[3])), NULL, 万能转码<DWORD>(std::move(输入[4])), 万能转码<DWORD>(std::move(输入[5])), NULL);
	if (文件句柄 == INVALID_HANDLE_VALUE) [[unlikely]]
		CheckLastError(MATLAB::Exception::File_creation_failed);
		文件* const 文件指针 = new 文件{ 文件句柄 };
	自动析构(文件指针);
	输出[0] = 万能转码(文件指针);
}
Mex工具API(File_GetSize)
{
	LARGE_INTEGER 文件大小;
	if (GetFileSizeEx(万能转码<文件*>(std::move(输入[1]))->文件句柄, &文件大小))
		输出[0] = 万能转码(文件大小.QuadPart);
	else [[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_get_file_size);
}
Mex工具API(File_Read)
{
	LARGE_INTEGER 文件指针{ .QuadPart = 0 };
	文件* const 文件对象 = 万能转码<文件*>(std::move(输入[1]));
	SetFilePointerEx(文件对象->文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	const ArrayType 读入类型 = 万能转码<ArrayType>(std::move(输入[3]));
	LARGE_INTEGER 文件大小;
	GetFileSizeEx(文件对象->文件句柄, &文件大小);
	const size_t 元素字节数 = 类型字节数(读入类型);
	const size_t 应读入个数 = std::min(万能转码<uint64_t>(std::move(输入[2])), (文件大小.QuadPart - 文件指针.QuadPart) / 元素字节数);
	const size_t 应读入字节数 = 应读入个数 * 元素字节数;
	if (!文件对象->映射句柄) [[unlikely]]
		文件对象->映射句柄 = CreateFileMapping(文件对象->文件句柄, nullptr, PAGE_READWRITE, 0, 0, nullptr);
	if (!文件对象->映射句柄) [[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_create_a_file_mapping);
	LPVOID 映射指针 = MapViewOfFile(文件对象->映射句柄, FILE_MAP_COPY, 文件指针.HighPart, 文件指针.LowPart, 应读入字节数);
	if (!映射指针) [[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
	输出[0] = 万能转码(读入类型, 映射指针, { 应读入个数 }, [](LPVOID 指针) {UnmapViewOfFile(指针); });
}
Mex工具API(File_SetEnd)
{
	if (!SetEndOfFile(万能转码<文件*>(std::move(输入[1]))->文件句柄))[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_set_end_of_file);
}
Mex工具API(File_SetPointer)
{
	LARGE_INTEGER 位置{ .QuadPart = 万能转码<LONGLONG>(std::move(输入[2])) };
	if (SetFilePointerEx(万能转码<文件*>(std::move(输入[1]))->文件句柄, 位置, &位置, 万能转码<DWORD>(std::move(输入[3]))))
		输出[0] = 万能转码(位置.QuadPart);
	else[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_set_the_file_pointer);
}
Mex工具API(File_Write)
{
	文件* const 文件对象 = 万能转码<文件*>(std::move(输入[1]));
	const CellArray 所有输入(std::move(输入[2]));
	uint64_t 字节数 = 0;
	for (const Array& a : 所有输入)
		字节数 += 数组字节数(a);
	//这里必须用内存映射文件，不考虑WriteFile，因为数据来源不是指针，只能用迭代器拷贝到内存
	LARGE_INTEGER 文件指针{ .QuadPart = 0 };
	SetFilePointerEx(文件对象->文件句柄, 文件指针, &文件指针, FILE_CURRENT);
	const LARGE_INTEGER 写入大小{ 文件指针.QuadPart + 字节数 };
	LARGE_INTEGER 实际大小;
	GetFileSizeEx(文件对象->文件句柄, &实际大小);
	if (写入大小.QuadPart > 实际大小.QuadPart)
	{
		if (文件对象->映射句柄)
			CloseHandle(文件对象->映射句柄);
		if (!(文件对象->映射句柄 = CreateFileMapping(文件对象->文件句柄, nullptr, PAGE_READWRITE, 写入大小.HighPart, 写入大小.LowPart, nullptr)))[[unlikely]]
			CheckLastError(MATLAB::Exception::Failed_to_create_a_file_mapping);
	}
	const std::unique_ptr<void, decltype(UnmapViewOfFile)*> 映射指针(MapViewOfFile(文件对象->映射句柄, FILE_MAP_WRITE, 文件指针.HighPart, 文件指针.LowPart, 字节数), UnmapViewOfFile);
	if (!映射指针)[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_map_the_file_view);
	try
	{
		void* 写出头 = 映射指针.get();
		for (Array a : 所有输入)
			万能转码(std::move(a), 写出头);
	}
	catch (const std::exception&)
	{
		throw;
	}
	catch (...)
	{
		EnumThrow(MATLAB::Exception::Memory_copy_failed);
	}
	SetFilePointerEx(文件对象->文件句柄, 写入大小, &文件指针, FILE_BEGIN);
}
Mex工具API(File_Close)
{
	文件*const 指针 = 万能转码<文件*>(std::move(输入[1]));
	if (手动析构(指针))
		delete 指针;
}
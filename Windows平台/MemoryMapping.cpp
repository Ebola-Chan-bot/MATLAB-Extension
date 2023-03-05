#include "pch.h"
#include "MexAPI.h"
#include "MATLAB异常.h"
API声明(MemoryMapping_Create)
{
	LPCWSTR Name = nullptr;
	String 名称;
	if (inputs[4].getNumberOfElements())
	{
		名称 = 万能转码<String>(std::move(inputs[4]));
		Name = (LPCWSTR)名称.c_str();
	}
	const CellArray 数据数组(std::move(inputs[5]));
	const uint8_t 数据个数 = 数据数组.getNumberOfElements();
	const std::unique_ptr<std::unique_ptr<无类型数组>[]>无类型数据 = std::make_unique_for_overwrite<std::unique_ptr<无类型数组>[]>(数据个数);
	uint64_t 总字节数 = 0;
	for (uint8_t a = 0; a < 数据个数; ++a)
		总字节数 += (无类型数据[a] = 无类型数组::创建(数据数组[a]))->字节数;
	LARGE_INTEGER 文件大小{ .QuadPart = 万能转码<LONGLONG>(std::move(inputs[3])) };
	const HANDLE 文件句柄 = (HANDLE)万能转码<uint64_t>(std::move(inputs[1]));
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
	const DWORD Protect = 万能转码<uint32_t>(std::move(inputs[2]));
	const HANDLE 映射句柄 = CreateFileMapping(文件句柄, nullptr, Protect, 文件大小.HighPart, 文件大小.LowPart, Name);
	if (!映射句柄)
		throw MATLAB异常(MATLAB异常类型::创建文件映射失败, 内部异常类型::Win32异常, GetLastError());
	outputs[1] = 万能转码(映射句柄);
	void* 映射指针 = nullptr;
	if ((数据个数 || outputs.size() > 2) && !(映射指针 = MapViewOfFile(映射句柄, Protect == PAGE_READONLY ? FILE_MAP_READ : FILE_MAP_WRITE, 0, 0, 0)))
	{
		const MATLAB异常 异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
		CloseHandle(映射句柄);
		throw 异常;
	}
	if (数据个数)
	{
		char* 写出头 = (char*)映射指针;
		for (uint8_t a = 0; a < 数据个数; ++a)
		{
			无类型数据[a]->拷贝(写出头);
			写出头 += 无类型数据[a]->字节数;
		}
	}
	if (映射指针)
		if (outputs.size() > 2)
			outputs[2] = 万能转码(映射指针);
		else
			UnmapViewOfFile(映射指针);
}
API声明(MemoryMapping_View)
{
	const LARGE_INTEGER FileOffset{ .QuadPart = 万能转码<LONGLONG>(std::move(inputs[3])) };
	const LPVOID 映射指针 = MapViewOfFile((HANDLE)万能转码<uint64_t>(std::move(inputs[1])), 万能转码<uint32_t>(std::move(inputs[2])), FileOffset.HighPart, FileOffset.LowPart, 万能转码<uint64_t>(std::move(inputs[4])));
	if (映射指针)
		outputs[1] = 万能转码(映射指针);
	else
		throw MATLAB异常(MATLAB异常类型::映射文件视图失败, 内部异常类型::Win32异常, GetLastError());
}
API声明(MemoryMapping_Unview)
{
	UnmapViewOfFile(万能转码<LPCVOID>(std::move(inputs[1])));
}
API声明(MemoryMapping_Close)
{
	CloseHandle((HANDLE)万能转码<uint64_t>(std::move(inputs[1])));
}
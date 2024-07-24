#include "pch.h"
#include"实用工具.h"
#include <MATLAB异常.h>
#include<Mex工具.hpp>
using namespace Mex工具;
Mex工具API(Pointer_Allocate)
{
	size_t NumBytes = 万能转码<size_t>(输入[1]);
	size_t 总字节数;
	CellArray 输入元胞 = 元胞字节化(输入[2], 总字节数);
	if (!NumBytes)
		NumBytes = 总字节数;
	if (总字节数 > NumBytes)[[unlikely]]
		EnumThrow(MATLAB::Exception::Fill_data_out_of_memory_range);
	std::unique_ptr<void, decltype(free)*> 内存指针{ malloc(NumBytes),free };
	void* 指针头 = 内存指针.get();
	输出[0] = 万能转码(指针头);
	for (Array 输入 : 输入元胞)
		万能转码(std::move(输入), 指针头);
	自动析构(内存指针.release(), free);
}
Mex工具API(Pointer_Read)
{
	const ArrayType 类型 = 万能转码<ArrayType>(std::move(输入[3]));
	const size_t 元素数 = 万能转码<size_t>(std::move(输入[2]));
	const std::unique_ptr<动态类型缓冲>缓冲 = 动态类型缓冲::创建(类型, 元素数);
	安全拷贝(缓冲->get(), 万能转码<void*>(std::move(输入[1])), 元素数 * 类型字节数(类型));
	输出[0] = 缓冲->创建数组({ 元素数 });
}
Mex工具API(Pointer_Write)
{
	void* 写出头 = 万能转码<void*>(std::move(输入[1]));
	for (Array 输入 : CellArray(std::move(输入[2])))
		万能转码(std::move(输入), 写出头);
}
Mex工具API(Pointer_Copy)
{
	安全拷贝(万能转码<void*>(std::move(输入[1])), 万能转码<void*>(std::move(输入[2])), 万能转码<size_t>(std::move(输入[3])));
}
Mex工具API(Pointer_Release)
{
	void* 指针 = 万能转码<void*>(std::move(输入[1]));
	if (手动析构(指针))
		free(指针);
}
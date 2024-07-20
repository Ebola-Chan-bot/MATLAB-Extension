#include "pch.h"
#include"实用工具.h"
#include <MATLAB异常.h>
#include<Mex工具.hpp>
using namespace Mex工具;
Mex工具Api(Pointer_Allocate)
{
	size_t NumBytes = 万能转码<size_t>(inputs[1]);
	size_t 总字节数;
	CellArray 输入元胞 = 元胞字节化(inputs[2], 总字节数);
	if (!NumBytes)
		NumBytes = 总字节数;
	if (总字节数 > NumBytes)
		throw MATLAB异常(MATLAB异常类型::填充数据超出内存范围);
	void* 内存指针 = malloc(NumBytes);
	outputs[1] = 万能转码(内存指针);
	for (const Array& 输入 : 输入元胞)
		万能转码(输入, 内存指针);
}
Mex工具Api(Pointer_Read)
{
	const std::unique_ptr<动态类型缓冲>缓冲 = 动态类型缓冲::创建((ArrayType)万能转码<int>(inputs[3]), 万能转码<uint64_t>(inputs[2]));
	安全拷贝(缓冲->指针, 万能转码<void*>(inputs[1]), 缓冲->字节数);
	outputs[1] = 缓冲->打包();
}
Mex工具Api(Pointer_Write)
{
	void* 写出头 = 万能转码<void*>(inputs[1]);
	for (const Array& 输入 : CellArray(inputs[2]))
		万能转码(输入, 写出头);
}
Mex工具Api(Pointer_Copy)
{
	安全拷贝(万能转码<void*>(inputs[1]), 万能转码<void*>(inputs[2]), 万能转码<size_t>(inputs[3]));
}
Mex工具Api(Pointer_Release)
{
	free(万能转码<void*>(inputs[1]));
}
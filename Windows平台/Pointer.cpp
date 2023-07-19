#include "pch.h"
#include "MATLAB异常.h"
#include<Mex工具.h>
using namespace Mex工具;
CellArray 元胞字节化(Array&& 输入, size_t& 总字节数);
void 安全拷贝(void* 目标, const void* 来自, size_t 字节数);
API声明(Pointer_Allocate)
{
	size_t NumBytes = 万能转码<size_t>(std::move(inputs[1]));
	size_t 总字节数;
	CellArray 输入元胞 = 元胞字节化(std::move(inputs[2]), 总字节数);
	if (!NumBytes)
		NumBytes = 总字节数;
	if (总字节数 > NumBytes)
		throw MATLAB异常(MATLAB异常类型::填充数据超出内存范围);
	void* 内存指针 = malloc(NumBytes);
	outputs[1] = 万能转码(内存指针);
	for (Array&& 输入 : 输入元胞)
		万能转码(std::move(输入), 内存指针);
}
API声明(Pointer_Read)
{
	const std::unique_ptr<动态类型缓冲>缓冲 = 动态类型缓冲::创建((ArrayType)万能转码<int>(std::move(inputs[3])), 万能转码<uint64_t>(std::move(inputs[2])));
	安全拷贝(缓冲->指针, 万能转码<void*>(std::move(inputs[1])), 缓冲->字节数);
	outputs[1] = 缓冲->打包();
}
API声明(Pointer_Write)
{
	void* 写出头 = 万能转码<void*>(std::move(inputs[1]));
	for (Array&& 输入 : CellArray(std::move(inputs[2])))
		万能转码(std::move(输入), 写出头);
}
API声明(Pointer_Copy)
{
	安全拷贝(万能转码<void*>(std::move(inputs[1])), 万能转码<void*>(std::move(inputs[2])), 万能转码<size_t>(std::move(inputs[3])));
}
API声明(Pointer_Release)
{
	free(万能转码<void*>(std::move(inputs[1])));
}
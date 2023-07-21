#include"pch.h"
#include"实用工具.h"
#include"MATLAB异常.h"
#include<Mex工具.h>
void 安全拷贝(void* 目标, const void* 来自, size_t 字节数)
{
	try
	{
		memcpy(目标, 来自, 字节数);
	}
	catch (...)
	{
		throw MATLAB异常(MATLAB异常类型::内存拷贝失败);
	}
}
CellArray 元胞字节化(const Array& 输入, size_t& 总字节数)
{
	CellArray 输入元胞 = [](const Array& 输入)
	{
		if (输入.getType() == ArrayType::CELL)
			return CellArray(输入);
		else
			return Mex工具::数组工厂.createCellArray({ 1 }, 输入);
	}(输入);
	总字节数 = 0;
	for (const Array& 输入 : 输入元胞)
		总字节数 += Mex工具::数组字节数(输入);
	return 输入元胞;
}
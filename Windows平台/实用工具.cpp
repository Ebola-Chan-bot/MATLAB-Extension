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
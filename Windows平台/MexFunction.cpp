#include "pch.h"
#include <Mex实现.h>
#include "MATLAB异常.h"
#include "MexAPI.h"
void MexFunction::operator()(ArgumentList& outputs, ArgumentList& inputs)
{
	static const StructArray 异常结构 = 数组工厂.createStructArray({ 1 }, { "ExceptionType","WindowsErrorCode" });
	API索引
	{
		CopyFile,
		Delete,
		MoveFile,
	};
	try
	{
		API调用;
	}
	catch (MATLAB异常 异常)
	{
		outputs[0] = 异常;
		异常输出补全(outputs);
		return;
	}
	static const StructArray 成功结构 = MATLAB异常();
	outputs[0] = 成功结构;
}
#include "pch.h"
#include <Mex工具.h>
#include <shellapi.h>
enum MATLAB异常类型:uint8_t
{
	成功,
	输入不是字符串,
	文件操作失败
};
struct MATLAB异常
{
	MATLAB异常类型 异常类型;
	int Windows错误代码 = 0;
};
String 字符串转换(Array& 输入)
{
	switch (输入.getType())
	{
	case ArrayType::CHAR:
	{
		String 返回 = CharArray(std::move(输入)).toUTF16();
		返回.push_back(0);
		return std::move(返回); 
	}
	case ArrayType::MATLAB_STRING:
	{
		StringArray 数组(std::move(输入));
		String 返回 = std::move(数组[0]);
		返回.push_back(0);
		const size_t 数组长度 = 数组.getNumberOfElements();
		for (uint8_t a = 1; a < 数组长度; ++a)
			返回.append(数组[a]).push_back(0);
		return std::move(返回);
	}
	case ArrayType::CELL:
	{
		CellArray 数组(std::move(输入));
		String 返回 = CharArrayRef(数组[0]).toUTF16();
		返回.push_back(0);
		const size_t 数组长度 = 数组.getNumberOfElements();
		for (uint8_t a = 1; a < 数组长度; ++a)
			返回.append(CharArrayRef(数组[a]).toUTF16()).push_back(0);
		return std::move(返回);
	}
	default:
		throw MATLAB异常{ 输入不是字符串 };
	}
}
TypedArray<bool> 执行操作(SHFILEOPSTRUCTW& 操作结构)
{
	const int 异常 = SHFileOperationW(&操作结构);
	if (异常&&异常!=ERROR_CANCELLED)
		throw MATLAB异常{ 文件操作失败,异常 };
	else
		return 数组工厂.createScalar<bool>(操作结构.fAnyOperationsAborted);
}
TypedArray<bool> CopyMove(ArgumentList& inputs,UINT wFunc)
{
	String From = 字符串转换(inputs[1]);
	FILEOP_FLAGS Flags = FOF_ALLOWUNDO;
	Array& ArrayTo = inputs[2];
	if (ArrayTo.getNumberOfElements() > 1 && ArrayTo.getType() != ArrayType::CHAR)
		Flags |= FOF_MULTIDESTFILES;
	String To = 字符串转换(ArrayTo);
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = wFunc,.pFrom = (wchar_t*)From.c_str() ,.pTo = (wchar_t*)To.c_str(),.fFlags = Flags };
	return 执行操作(操作结构);
}
#ifdef CopyFile
#undef CopyFile
#endif
API声明(CopyFile)
{
	outputs[1] = CopyMove(inputs, FO_COPY);
}
API声明(Delete)
{
	const String From = 字符串转换(inputs[1]);
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = FO_DELETE,.pFrom = (wchar_t*)From.c_str(),.fFlags = FOF_ALLOWUNDO };
	outputs[1] = 执行操作(操作结构);
}
#ifdef MoveFile
#undef MoveFile
#endif
API声明(MoveFile)
{
	outputs[1] = CopyMove(inputs, FO_MOVE);
}
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
		StructArray 返回 = 异常结构;
		返回[0]["ExceptionType"] = 数组工厂.createScalar<uint8_t>(异常.异常类型);
		返回[0]["WindowsErrorCode"] = 数组工厂.createScalar(异常.Windows错误代码);
		outputs[0] = 返回;
		异常输出补全(outputs);
		return;
	}
	static const StructArray 成功结构 = [](StructArray 异常结构)
	{
		异常结构[0]["ExceptionType"] = 数组工厂.createScalar<uint8_t>(成功);
		return 异常结构;
	}
	(异常结构);
	outputs[0] = 成功结构;
}
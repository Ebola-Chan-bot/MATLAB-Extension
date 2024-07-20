#include "pch.h"
#include <MATLAB异常.h>
#include <shellapi.h>
#include<Mex工具.hpp>
using namespace Mex工具;
void 字符串转换(const Array& 输入, String& 输出)
{
	switch (输入.getType())
	{
	case ArrayType::CHAR:
		输出.append(CharArray(输入).toUTF16()).push_back(0);
		break;
	case ArrayType::MATLAB_STRING:
		for (const String& 元素 : StringArray(输入))
			输出.append(元素).push_back(0);
		break;
	case ArrayType::CELL:
		for (const CharArrayRef& 元素 : CellArray(输入))
			输出.append(元素.toUTF16()).push_back(0);
		break;
	default:
		throw MATLAB异常(MATLAB异常类型::输入不是字符串);
	}
}
TypedArray<bool> 执行操作(SHFILEOPSTRUCTW& 操作结构)
{
	const int 异常 = SHFileOperationW(&操作结构);
	if (异常 && 异常 != ERROR_CANCELLED)
		throw MATLAB异常(MATLAB异常类型::文件操作失败, 内部异常类型::Win32异常, 异常);
	else
		return 万能转码<bool>(操作结构.fAnyOperationsAborted);
}
TypedArray<bool> CopyMove(ArgumentList& inputs, UINT wFunc)
{
	String From;
	字符串转换(inputs[1],From);
	FILEOP_FLAGS Flags = FOF_ALLOWUNDO;
	Array& ArrayTo = inputs[2];
	if (ArrayTo.getNumberOfElements() > 1 && ArrayTo.getType() != ArrayType::CHAR)
		Flags |= FOF_MULTIDESTFILES;
	String To;
	字符串转换(ArrayTo,To);
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = wFunc,.pFrom = (wchar_t*)From.c_str() ,.pTo = (wchar_t*)To.c_str(),.fFlags = Flags };
	return 执行操作(操作结构);
}
Mex工具Api(SHFile_Copy)
{
	outputs[1] = CopyMove(inputs, FO_COPY);
}
Mex工具Api(SHFile_Delete)
{
	String From;
	字符串转换(inputs[1],From);
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = FO_DELETE,.pFrom = (wchar_t*)From.c_str(),.fFlags = FILEOP_FLAGS(FOF_ALLOWUNDO | 万能转码<uint32_t>(inputs[2])) };
	outputs[1] = 执行操作(操作结构);
}
Mex工具Api(SHFile_Move)
{
	outputs[1] = CopyMove(inputs, FO_MOVE);
}
#include "pch.h"
#include <MATLAB异常.h>
#include<Mex工具.hpp>
#include <shellapi.h>
using namespace Mex工具;
using namespace matlab::data;
static String 字符串转换(Array&& 输入)
{
	String 输出;
	switch (输入.getType())
	{
	case ArrayType::CHAR:
		输出.append(CharArray(std::move(输入)).toUTF16()).push_back(0);
		break;
	case ArrayType::MATLAB_STRING:
		for (const String& 元素 : StringArray(std::move(输入)))
			输出.append(元素).push_back(0);
		break;
	case ArrayType::CELL:
		for (const CharArrayRef& 元素 : CellArray(std::move( 输入)))
			输出.append(元素.toUTF16()).push_back(0);
		break;
	default:
		EnumThrow(MATLAB::Exception::The_input_is_not_a_string);
	}
	return 输出;
}
static TypedArray<bool> 执行操作(SHFILEOPSTRUCTW& 操作结构)
{
	const int 异常 = SHFileOperationW(&操作结构);
	if (异常 && 异常 != ERROR_CANCELLED)
		CheckLastError(MATLAB::Exception::File_operation_failed);
	else
		return 数组工厂.createScalar<bool>(操作结构.fAnyOperationsAborted);
}
static TypedArray<bool> CopyMove(matlab::mex::ArgumentList& 输入, UINT wFunc)
{
	const String From = 字符串转换(std::move(输入[1]));
	FILEOP_FLAGS Flags = FOF_ALLOWUNDO;
	Array& ArrayTo = 输入[2];
	if (ArrayTo.getNumberOfElements() > 1 && ArrayTo.getType() != ArrayType::CHAR)
		Flags |= FOF_MULTIDESTFILES;
	const String To = 字符串转换(std::move(ArrayTo));
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = wFunc,.pFrom = (wchar_t*)From.c_str() ,.pTo = (wchar_t*)To.c_str(),.fFlags = Flags };
	return 执行操作(操作结构);
}
Mex工具API(SHFile_Copy)
{
	输出[0] = CopyMove(输入, FO_COPY);
}
Mex工具API(SHFile_Delete)
{
	const String From = 字符串转换(std::move(输入[1]));
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = FO_DELETE,.pFrom = (wchar_t*)From.c_str(),.fFlags = FOF_ALLOWUNDO | 万能转码<FILEOP_FLAGS>(std::move(输入[2])) };
	输出[0] = 执行操作(操作结构);
}
Mex工具API(SHFile_Move)
{
	输出[0] = CopyMove(输入, FO_MOVE);
}
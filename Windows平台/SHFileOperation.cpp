#include "pch.h"
#include <MATLAB异常.h>
#include<Mex工具.hpp>
#include <shellapi.h>
using namespace Mex工具;
using namespace matlab::data;
static std::unique_ptr<wchar_t[]> 字符串展开(Array&& 输入)
{
	std::vector<String>本地字符串;
	switch (输入.getType())
	{
	case ArrayType::CHAR:
		本地字符串.push_back(CharArray{ std::move(输入) }.toUTF16());
		break;
	case ArrayType::MATLAB_STRING:
	{
		StringArray 托管字符串{ std::move(输入) };
		本地字符串.insert(本地字符串.end(), 托管字符串.cbegin(), 托管字符串.cend());
	}
	break;
	case ArrayType::CELL:
	{
		CellArray const 托管字符串{ std::move(输入) };
		本地字符串.reserve(托管字符串.getNumberOfElements());
		for (CharArray const& 元素 : 托管字符串)
			本地字符串.push_back(元素.toUTF16());
	}
	break;
	default:
		EnumThrow(MATLAB::Exception::The_input_is_not_a_string);
	}
	DWORD 展开大小 = 0;
	for (String const& 元素 : 本地字符串)
		展开大小 += ExpandEnvironmentStringsW(reinterpret_cast<LPCWSTR>(元素.c_str()), nullptr, 0);
	std::unique_ptr<wchar_t[]>输出;
	if (展开大小)
	{
		输出 = std::make_unique_for_overwrite<wchar_t[]>(展开大小 + 1);
		LPWSTR 写入位置 = 输出.get();
		LPWSTR const 结束位置 = 写入位置 + 展开大小;
		for (String const& 元素 : 本地字符串)
			写入位置 += ExpandEnvironmentStringsW(reinterpret_cast<LPCWSTR>(元素.c_str()), 写入位置, 结束位置 - 写入位置);
		*结束位置 = 0;
	}
	else
	{
		输出 = std::make_unique_for_overwrite<wchar_t[]>(2);
		输出[0] = 0;
		输出[1] = 0;
	}
	return 输出;
}
static TypedArray<bool> 执行操作(SHFILEOPSTRUCTW& 操作结构)
{
	int const 异常 = SHFileOperationW(&操作结构);
	if (异常 == ERROR_SUCCESS || 异常 == ERROR_CANCELLED)//取消操作也算成功
		return 数组工厂.createScalar<bool>(操作结构.fAnyOperationsAborted);
	else
		EnumThrow(MATLAB::Exception::File_operation_failed, WindowsErrorMessage(异常));
}
static TypedArray<bool> CopyMove(matlab::mex::ArgumentList& 输入, UINT wFunc)
{
	std::unique_ptr<wchar_t[]>const From = 字符串展开(std::move(输入[1]));
	FILEOP_FLAGS Flags = FOF_ALLOWUNDO;
	Array& ArrayTo = 输入[2];
	if (ArrayTo.getNumberOfElements() > 1 && ArrayTo.getType() != ArrayType::CHAR)
		Flags |= FOF_MULTIDESTFILES;
	std::unique_ptr<wchar_t[]>const To = 字符串展开(std::move(ArrayTo));
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = wFunc,.pFrom = From.get() ,.pTo = To.get(),.fFlags = Flags };
	return 执行操作(操作结构);
}
Mex工具API(SHFile_Copy)
{
	输出[0] = CopyMove(输入, FO_COPY);
}
Mex工具API(SHFile_Delete)
{
	std::unique_ptr<wchar_t[]>const From = 字符串展开(std::move(输入[1]));
	SHFILEOPSTRUCTW 操作结构{ .hwnd = nullptr,.wFunc = FO_DELETE,.pFrom = From.get(),.fFlags = FILEOP_FLAGS(FOF_ALLOWUNDO | 万能转码<int>(std::move(输入[2]))) };//按位与运算总是用int类型，所以只能算完再转换
	输出[0] = 执行操作(操作结构);
}
Mex工具API(SHFile_Move)
{
	输出[0] = CopyMove(输入, FO_MOVE);
}
#pragma once
#include <Mex类型.h>
using namespace matlab::data;
enum MATLAB异常类型 :uint8_t
{
	成功,
	输入不是字符串,
	文件操作失败,
	Zip打开失败,
	Zip文件名搜索失败,
	Zip文件打开失败,
	输入参数类型错误,
	Zip文件读入失败,
	输入参数数目错误,
	Zip档案无效,
	Zip文件名获取失败,
};
enum 内部异常类型 :uint8_t
{
	无,
	Win32异常,
	LibZip异常,
};
struct MATLAB异常
{
	MATLAB异常类型 异常类型 = 成功;
	内部异常类型 内部异常 = 无;
	int 错误代码 = 0;
	size_t 第几个 = 0;
	constexpr MATLAB异常() {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型) :异常类型(异常类型) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, size_t 第几个) : 异常类型(异常类型), 第几个(第几个) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, 内部异常类型 内部异常, int 错误代码) : 异常类型(异常类型), 内部异常(内部异常), 错误代码(错误代码) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, 内部异常类型 内部异常, int 错误代码, size_t 第几个) : 异常类型(异常类型), 内部异常(内部异常), 错误代码(错误代码), 第几个(第几个) {}
	operator StructArray()const noexcept;
};
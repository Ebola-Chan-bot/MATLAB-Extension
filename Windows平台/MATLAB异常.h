#pragma once
#include"MATLAB异常类型.h"
import MexTools;
using namespace matlab::data;
enum class 内部异常类型
{
	无,
	Win32异常,
	LibZip异常,
	Mex异常,
	COM异常,
	LibWebP异常,
	提权操作异常,
};
struct MATLAB异常
{
	MATLAB异常类型 异常类型 = MATLAB异常类型::成功;
	内部异常类型 内部异常 = 内部异常类型::无;
	//不能用long，因为MATLAB不支持
	int 错误代码 = 0;
	size_t 第几个 = -1;
	constexpr MATLAB异常() {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型) :异常类型(异常类型) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, size_t 第几个) : 异常类型(异常类型), 第几个(第几个) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, 内部异常类型 内部异常, int 错误代码) : 异常类型(异常类型), 内部异常(内部异常), 错误代码(错误代码) {}
	constexpr MATLAB异常(MATLAB异常类型 异常类型, 内部异常类型 内部异常, int 错误代码, size_t 第几个) : 异常类型(异常类型), 内部异常(内部异常), 错误代码(错误代码), 第几个(第几个) {}
	operator StructArray()const noexcept;
};
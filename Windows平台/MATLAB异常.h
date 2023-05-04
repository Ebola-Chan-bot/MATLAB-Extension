#pragma once
#include <Mex类型.h>
using namespace matlab::data;
enum class MATLAB异常类型 :uint8_t
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
	Zip文件明细获取失败,
	Zip未记录文件大小,
	文件创建失败,
	获取文件大小失败,
	读入文件失败,
	设置文件结束失败,
	设置文件指针失败,
	写出文件失败,
	关闭文件失败,
	创建文件映射失败,
	映射文件视图失败,
	内存拷贝失败,
	不支持的读入类型,
	不支持的写出类型,
	不支持的数组类型,
	Mex异常,
	填充数据超出内存范围,
	打开文件映射失败,
	指定设备未找到,
	填充颜色数据类型错误,
	无效指针,
	未知异常,
	保存快捷方式失败,
};
enum class 内部异常类型 :uint8_t
{
	无,
	Win32异常,
	LibZip异常,
	Mex异常,
	COM异常,
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
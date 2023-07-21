#pragma once
#include<Mex类型.h>
using namespace matlab::data;
void 安全拷贝(void* 目标, const void* 来自, size_t 字节数);
CellArray 元胞字节化(const Array& 输入, size_t& 总字节数);
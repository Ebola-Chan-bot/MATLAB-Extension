#include"pch.h"
#include"MexAPI.h"
#include"MATLAB异常.h"
using namespace Mex工具;
API声明(TypeCast)
{
	const ArrayType 类型 = 万能转码<ArrayType>(std::move(inputs[2]));
	const std::unique_ptr<动态类型缓冲>输出 = 动态类型缓冲::创建(类型, 数组字节数(inputs[1]) / 类型尺寸[(int)类型]);
	万能转码(std::move(inputs[1]), 输出->指针);
	outputs[1] = 输出->打包();
}
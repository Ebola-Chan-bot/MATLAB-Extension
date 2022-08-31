#include "pch.h"
#include "MATLAB异常.h"
#include <Mex工具.h>
MATLAB异常::operator StructArray()const noexcept
{
	StructArray 返回 = 数组工厂.createStructArray({ 1 }, { "ExceptionType","InnerException","ErrorCode","Index"});
	返回[0]["ExceptionType"] = 数组工厂.createScalar<uint8_t>(异常类型);
	返回[0]["InnerException"] = 数组工厂.createScalar<uint8_t>(内部异常);
	返回[0]["ErrorCode"] = 数组工厂.createScalar(错误代码);
	返回[0]["Index"] = 数组工厂.createScalar(第几个 + 1);
	return 返回;
}
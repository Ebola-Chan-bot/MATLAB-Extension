#include"pch.h"
#include"MexAPI.h"
#include"MATLAB异常.h"
API声明(TypeCast)
{
	const std::unique_ptr<无类型数组>输入 = 无类型数组::创建(std::move(inputs[1]));
	const ArrayType 类型 = (ArrayType)万能转码<int>(std::move(inputs[2]));
	const std::unique_ptr<无类型缓冲>输出 = 无类型缓冲::创建(类型, 输入->字节数 / 类型尺寸[(int)类型]);
	输入->拷贝(输出->指针);
	outputs[1] = 输出->打包();
}
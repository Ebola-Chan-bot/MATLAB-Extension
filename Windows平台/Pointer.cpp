#include "pch.h"
#include "MexAPI.h"
#include "MATLAB异常.h"
#include"实用工具.h"
API声明(Pointer_Allocate)
{
	uint64_t NumBytes = 万能转码<uint64_t>(std::move(inputs[1]));
	uint8_t 数据个数;
	std::unique_ptr<std::unique_ptr<无类型数组>[]>无类型数据;
	uint64_t 总字节数 = 0;
	if (inputs[2].getType() == ArrayType::CELL)
	{
		const CellArray 数据数组(std::move(inputs[2]));
		无类型数据 = std::make_unique_for_overwrite<std::unique_ptr<无类型数组>[]>(数据个数 = 数据数组.getNumberOfElements());
		for (uint8_t a = 0; a < 数据个数; ++a)
			总字节数 += (无类型数据[a] = 无类型数组::创建(数据数组[a]))->字节数;
	}
	else
		总字节数 = ((无类型数据 = std::make_unique_for_overwrite<std::unique_ptr<无类型数组>[]>(数据个数 = 1))[0] = 无类型数组::创建(std::move(inputs[2])))->字节数;
	if (!NumBytes)
		NumBytes = 总字节数;
	if (总字节数 > NumBytes)
		throw MATLAB异常(MATLAB异常类型::填充数据超出内存范围);
	char* 内存指针 = (char*)malloc(NumBytes);
	outputs[1] = 万能转码(内存指针);
	if(总字节数)
		for (uint8_t a = 0; a < 数据个数; ++a)
		{
			无类型数据[a]->拷贝(内存指针);
			内存指针 += 无类型数据[a]->字节数;
		}
}
API声明(Pointer_Read)
{
	const std::unique_ptr<无类型缓冲>缓冲 = 无类型缓冲::创建((ArrayType)万能转码<int>(std::move(inputs[3])), 万能转码<uint64_t>(std::move(inputs[2])));
	安全拷贝(缓冲->指针, 万能转码<void*>(std::move(inputs[1])), 缓冲->字节数);
	outputs[1] = 缓冲->打包();
}
API声明(Pointer_Write)
{
	char* 写出头 = 万能转码<char*>(std::move(inputs[1]));
	for (Array&& 输入 : CellArray(std::move(inputs[2])))
	{
		const std::unique_ptr<无类型数组>数组 = 无类型数组::创建(std::move(输入));
		数组->拷贝(写出头);
		写出头 += 数组->字节数;
	}
}
API声明(Pointer_Copy)
{
	安全拷贝(万能转码<void*>(std::move(inputs[1])), 万能转码<void*>(std::move(inputs[2])), 万能转码<size_t>(std::move(inputs[3])));
}
API声明(Pointer_Release)
{
	free(万能转码<void*>(std::move(inputs[1])));
}
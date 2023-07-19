#include"pch.h"
#include"投影文件系统.h"
#include<Mex工具.h>
using namespace Mex工具;
API声明(PFS_Create)
{
	const String 虚拟根目录 = 万能转码<String>(std::move(inputs[1]));
	const StructArray 回调(std::move(inputs[2]));
	for (const std::string 字段 : 回调.getFieldNames())
	{
		
	}
}
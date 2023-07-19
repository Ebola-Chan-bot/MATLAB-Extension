#pragma once
#include<projectedfslib.h>
#pragma comment(lib,"ProjectedFSLib.lib")
#include<Mex类型.h>
class 投影文件系统
{
	PRJ_NAMESPACE_VIRTUALIZATION_CONTEXT 命名空间虚拟化上下文;
public:
	投影文件系统(PCWSTR 虚拟根目录, const matlab::data::StructArray& 回调, PRJ_NOTIFY_TYPES 通知类型);
	std::optional<matlab::data::ObjectArray>目录枚举;
	std::optional<matlab::data::ObjectArray>获取占位符信息;
	std::optional<matlab::data::ObjectArray>获取文件数据;
	std::optional<matlab::data::ObjectArray>查询文件名;
	std::optional<matlab::data::ObjectArray>通知;
	~投影文件系统();
	投影文件系统(const 投影文件系统&) = delete;
};
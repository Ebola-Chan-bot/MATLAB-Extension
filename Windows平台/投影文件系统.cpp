#include"pch.h"
#include "投影文件系统.h"
#include"MATLAB异常.h"
#include<ShlObj.h>
#pragma comment(lib,"Shell32.lib")
#include<Mex工具.h>
using namespace matlab::engine;
extern std::shared_ptr<MATLABEngine>MATLAB引擎;
using namespace Mex工具;
struct 条目结构
{
	String 文件名;
	PRJ_FILE_BASIC_INFO 文件基本信息;
};
struct 枚举会话
{
	static std::unordered_map<GUID, std::unique_ptr<枚举会话>>所有会话;
	const std::unique_ptr<条目结构[]>所有条目;
	const 条目结构* const 条目尾;
	条目结构* 当前条目;
	枚举会话(std::unique_ptr<条目结构[]>&& 所有条目, const 条目结构* 条目尾) :当前条目(所有条目.get()), 条目尾(条目尾), 所有条目(std::move(所有条目)) {}
};
std::unordered_map<GUID, std::unique_ptr<枚举会话>>枚举会话::所有会话;
Array 回调用户函数(const std::vector<Array>& 参数)
{
	constexpr HRESULT 函数失败 = HRESULT_FROM_WIN32(ERROR_FUNCTION_FAILED);
	Array 查询结果;
	try
	{
		查询结果 = MATLAB引擎->feval("feval", 参数);
	}
	catch (MATLABExecutionException ex)
	{
		String ID = 万能转码<String>(ex.getMessageID().c_str());
		MATLAB引擎->feval("error", { 数组工厂.createScalar(ID),数组工厂.createScalar(ID + u"：" + ex.getMessageText())});
		throw 函数失败;
	}
	catch (MATLABSyntaxException ex)
	{
		String ID = 万能转码<String>(ex.getMessageID().c_str());
		MATLAB引擎->feval("error", { 数组工厂.createScalar(ID),数组工厂.createScalar(ID + u"：" + ex.getMessageText()) });
		throw 函数失败;
	}
	catch (...)
	{
		MATLAB引擎->eval(u"MATLAB.Lang.MatlabException.DirectoryEnumeration_unexpected_exception.Throw");
		throw 函数失败;
	}
	if (查询结果.getType() == ArrayType::STRUCT)
		[[likely]]return 查询结果;
	HRESULT 代码;
	try
	{
		代码 = HRESULT_FROM_WIN32(万能转码<int32_t>(std::move(查询结果)));
	}
	catch(InvalidArrayTypeException ex)
	{
		MATLAB引擎->eval(u"MATLAB.Lang.MatlabException.DirectoryEnumeration_unexpected_output.Throw");
		throw HRESULT_FROM_WIN32(ERROR_INVALID_DATA);
	}
	if (代码 == S_OK)
	{
		MATLAB引擎->eval(u"MATLAB.Lang.MatlabException.DirectoryEnumeration_unexpected_output.Throw");
		throw HRESULT_FROM_WIN32(ERROR_INVALID_DATA);
	}
	else
		[[likely]]throw 代码;
}
HRESULT PrjStartDirectoryEnumerationCb(
	[in] const PRJ_CALLBACK_DATA* callbackData,
	[in] const GUID* enumerationId
)noexcept
{
	Array 查询结果;
	try
	{
		查询结果 = 回调用户函数({ ((投影文件系统*)callbackData->InstanceContext)->目录枚举.value(), 万能转码<CharArray>(callbackData->FilePathName) });
	} 
	catch (HRESULT 错误代码)
	{
		return 错误代码;
	}
	const StructArray 结构数组 = 查询结果;
	const Struct 结构体 = 结构数组[0];
	const StringArray 文件名 = 结构体["FileName"];
	std::unique_ptr<条目结构[]>所有条目 = std::make_unique<条目结构[]>(文件名.getNumberOfElements());
	条目结构* 当前条目 = 所有条目.get();
	for (const std::string 字段 : 结构数组.getFieldNames())
		if (字段 == "FileName")
			for (String&& a : 文件名)
				(当前条目++)->文件名 = std::move(a);
		else if (字段 == "IsDirectory")
			for (const bool a : TypedArray<bool>(结构体[字段]))
				(当前条目++)->文件基本信息.IsDirectory = a;
		else if (字段 == "FileSize")
			for (const int64_t a : TypedArray<int64_t>(结构体[字段]))
				(当前条目++)->文件基本信息.FileSize = a;
	枚举会话::所有会话[*enumerationId] = std::make_unique<枚举会话>(std::move(所有条目), 当前条目);
	return S_OK;
}
HRESULT PrjGetDirectoryEnumerationCb(
	[in]           const PRJ_CALLBACK_DATA* callbackData,
	[in]           const GUID* enumerationId,
	[in, optional] PCWSTR searchExpression,
	[in]           PRJ_DIR_ENTRY_BUFFER_HANDLE dirEntryBufferHandle
)noexcept
{
	枚举会话& 枚举 = *枚举会话::所有会话[*enumerationId];
	if (callbackData->Flags & PRJ_CB_DATA_FLAG_ENUM_RESTART_SCAN)
		[[unlikely]]枚举.当前条目 = 枚举.所有条目.get();
	if (枚举.当前条目 >= 枚举.条目尾)
		[[unlikely]]return S_OK;
	PCWSTR 文件名 = (PCWSTR)枚举.当前条目->文件名.c_str();
	while (searchExpression && !PrjFileNameMatch(文件名, searchExpression))
	{
		if (++枚举.当前条目 >= 枚举.条目尾)
			[[unlikely]]return S_OK;
		文件名 = (PCWSTR)枚举.当前条目->文件名.c_str();
	}
	constexpr HRESULT 缓冲不足 = HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER);
	if (PrjFillDirEntryBuffer(文件名, &枚举.当前条目->文件基本信息, dirEntryBufferHandle) == 缓冲不足)
		[[unlikely]]return 缓冲不足;
	while (++枚举.当前条目 < 枚举.条目尾)[[likely]]
	{
		文件名 = (PCWSTR)枚举.当前条目->文件名.c_str();
		if ((!searchExpression || PrjFileNameMatch(文件名, searchExpression)) && PrjFillDirEntryBuffer(文件名, &枚举.当前条目->文件基本信息, dirEntryBufferHandle) == 缓冲不足)
			[[unlikely]]return S_OK;
	}
	return S_OK;
}
HRESULT PrjEndDirectoryEnumerationCb(
	[in] const PRJ_CALLBACK_DATA* callbackData,
	[in] const GUID* enumerationId
)noexcept
{
	枚举会话::所有会话.erase(*enumerationId);
	return S_OK;
}
HRESULT PrjGetPlaceholderInfoCb(
	[in] const PRJ_CALLBACK_DATA* callbackData
)noexcept
{
	Array 查询结果;
	try
	{
		查询结果 = 回调用户函数({ ((投影文件系统*)callbackData->InstanceContext)->获取占位符信息.value(), 万能转码<CharArray>(callbackData->FilePathName) });
	}
	catch (HRESULT 错误代码)
	{
		return 错误代码;
	}
	const StructArray 结构数组 = 查询结果;
	const Struct 结构体 = 结构数组[0];
	PCWSTR 目标文件名 = callbackData->FilePathName;
	String 可选目标文件名;
	PRJ_PLACEHOLDER_INFO 占位符信息 = {};
	for (const std::string 字段 : 结构数组.getFieldNames())
		if (字段 == "DestinationFileName")
		{
			可选目标文件名 = 万能转码<String>(结构体[字段]);
			目标文件名 = (PCWSTR)可选目标文件名.c_str();
		}
		else if (字段 == "IsDirectory")
			占位符信息.FileBasicInfo.IsDirectory = 万能转码<BOOLEAN>(结构体[字段]);
		else if (字段 == "FileSize")
			占位符信息.FileBasicInfo.FileSize = 万能转码<INT64>(结构体[字段]);
	const HRESULT 结果 = PrjWritePlaceholderInfo(callbackData->NamespaceVirtualizationContext, 目标文件名, &占位符信息, sizeof(占位符信息));
	if (FAILED(结果))[[unlikely]]
		MATLAB引擎->feval("Throw", { MATLAB引擎->feval("MATLAB.Lang.MatlabException", 数组工厂.createScalar(u"PrjWritePlaceholderInfo_failed")), 数组工厂.createScalar(结果) });
	return 结果;
}
HRESULT PrjGetFileDataCb(
	[in] const PRJ_CALLBACK_DATA* callbackData,
	[in] UINT64 byteOffset,
	[in] UINT32 length
)noexcept
{
	constexpr HRESULT 函数失败 = HRESULT_FROM_WIN32(ERROR_FUNCTION_FAILED);
	std::vector<Array> 查询结果;
	try
	{
		查询结果 = MATLAB引擎->feval("feval", 2, { ((投影文件系统*)callbackData->InstanceContext)->获取文件数据.value(),万能转码<CharArray>(callbackData->FilePathName),数组工厂.createScalar(byteOffset),数组工厂.createScalar(length) });
	}
	catch (MATLABExecutionException ex)
	{
		String ID = 万能转码<String>(ex.getMessageID().c_str());
		MATLAB引擎->feval("error", { 数组工厂.createScalar(ID),数组工厂.createScalar(ID + u"：" + ex.getMessageText()) });
		return 函数失败;
	}
	catch (MATLABSyntaxException ex)
	{
		String ID = 万能转码<String>(ex.getMessageID().c_str());
		MATLAB引擎->feval("error", { 数组工厂.createScalar(ID),数组工厂.createScalar(ID + u"：" + ex.getMessageText()) });
		return 函数失败;
	}
	catch (...)
	{
		MATLAB引擎->eval(u"MATLAB.Lang.MatlabException.DirectoryEnumeration_unexpected_exception.Throw");
		return 函数失败;
	}
	HRESULT 结果 = 万能转码<HRESULT>(查询结果[0]);
	if (FAILED(结果)) [[unlikely]]
		return 结果;
	const Array& 文件数据 = 查询结果[1];
	void* const 对齐缓冲 = PrjAllocateAlignedBuffer(callbackData->NamespaceVirtualizationContext, 数组字节数(文件数据));
	万能转码(文件数据, 对齐缓冲);
	结果=PrjWriteFileData(callbackData->NamespaceVirtualizationContext,&callbackData->DataStreamId)
}
HRESULT PrjQueryFileNameCb(
	[in] const PRJ_CALLBACK_DATA* callbackData
)
{}
HRESULT PrjNotificationCb(
	[in]           const PRJ_CALLBACK_DATA* callbackData,
	[in]           BOOLEAN isDirectory,
	[in]           PRJ_NOTIFICATION notification,
	[in, optional] PCWSTR destinationFileName,
	[in, out]      PRJ_NOTIFICATION_PARAMETERS* operationParameters
)
{}
using namespace matlab::data;
投影文件系统::投影文件系统(PCWSTR 虚拟根目录, const StructArray& MATLAB回调, PRJ_NOTIFY_TYPES 通知类型)
{
	const int 错误代码 = SHCreateDirectory(NULL, 虚拟根目录);
	if (!(错误代码 == ERROR_SUCCESS || 错误代码 == ERROR_FILE_EXISTS || 错误代码 == ERROR_ALREADY_EXISTS))
		throw MATLAB异常(MATLAB异常类型::创建目录失败, 内部异常类型::Win32异常, 错误代码);
	PRJ_STARTVIRTUALIZING_OPTIONS 开始虚拟化选项 = {};
	开始虚拟化选项.NotificationMappingsCount = 1;
	PRJ_NOTIFICATION_MAPPING 通知映射{ .NotificationBitMask = 通知类型,.NotificationRoot = L"" };
	开始虚拟化选项.NotificationMappings = &通知映射;
	PRJ_CALLBACKS Prj回调 = {};
	const Struct& 回调元素 = MATLAB回调[0];
	for (const std::string 字段 : MATLAB回调.getFieldNames())
	{
		ObjectArray 函数句柄(std::move(回调元素[字段]));
		if (字段 == "DirectoryEnumeration")
		{
			Prj回调.StartDirectoryEnumerationCallback = PrjStartDirectoryEnumerationCb;
			Prj回调.GetDirectoryEnumerationCallback = PrjGetDirectoryEnumerationCb;
			Prj回调.EndDirectoryEnumerationCallback = PrjEndDirectoryEnumerationCb;
			目录枚举 = 函数句柄;
		}
		else if (字段 == "GetPlaceholderInfo")
		{
			Prj回调.GetPlaceholderInfoCallback = PrjGetPlaceholderInfoCb;
			获取占位符信息 = 函数句柄;
		}
		else if (字段 == "GetFileData")
		{
			Prj回调.GetFileDataCallback = PrjGetFileDataCb;
			获取文件数据 = 函数句柄;
		}
		else if (字段 == "QueryFileName")
		{
			Prj回调.QueryFileNameCallback = PrjQueryFileNameCb;
			查询文件名 = 函数句柄;
		}
		else if (字段 == "Notification")
		{
			Prj回调.NotificationCallback = PrjNotificationCb;
			通知 = 函数句柄;
		}
	}
	HRESULT 结果 = PrjStartVirtualizing(虚拟根目录, &Prj回调, this, &开始虚拟化选项, &命名空间虚拟化上下文);
	while (FAILED(结果))[[unlikely]]
	{
		if (结果 == HRESULT_FROM_WIN32(ERROR_REPARSE_TAG_MISMATCH))
		{
			GUID 全局唯一标识符;
			CoCreateGuid(&全局唯一标识符);
			结果 = PrjMarkDirectoryAsPlaceholder(虚拟根目录, nullptr, nullptr, &全局唯一标识符);
			if (FAILED(结果))
				throw MATLAB异常(MATLAB异常类型::将目录标记为占位符失败, 内部异常类型::COM异常, 结果);
		}
		else[[likely]]
			throw MATLAB异常(MATLAB异常类型::开始虚拟化失败, 内部异常类型::COM异常, 结果);
		结果 = PrjStartVirtualizing(虚拟根目录, &Prj回调, this, &开始虚拟化选项, &命名空间虚拟化上下文);
	}
}
投影文件系统::~投影文件系统()
{
	PrjStopVirtualizing(命名空间虚拟化上下文);
}
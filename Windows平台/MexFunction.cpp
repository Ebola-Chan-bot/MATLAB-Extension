#include "pch.h"
#include "MATLAB异常.h"
#include "MexAPI.h"
#include <Mex实现.h>
void MexFunction::operator()(ArgumentList& outputs, ArgumentList& inputs)
{
	static const StructArray 异常结构 = 数组工厂.createStructArray({ 1 }, { "ExceptionType","WindowsErrorCode" });
	API索引
	{
		CopyFile,
		Delete,
		MoveFile,
		ZipOpen,
		ZipNameLocate,
		ZipFopen,
		ZipFread,
		ZipFclose,
		ZipDiscard,
		ZipGetSize,
		ZipGetName,
		ZipGetNumEntries,
		File_Create,
		File_GetSize,
		File_Read,
		File_SetEnd,
		File_SetPointer,
		File_Write,
		File_Close,
		MemoryMapping_Create,
		MemoryMapping_View,
		MemoryMapping_Unview,
		MemoryMapping_Close,
		Pointer_Allocate,
		Pointer_Read,
		Pointer_Write,
		Pointer_Copy,
		Pointer_Release,
		TypeCast
	};
	try
	{
		API调用;
	}
	catch (MATLAB异常 异常)
	{
		outputs[0] = 异常;
		异常输出补全(outputs);
		return;
	}
	catch (Mex异常 异常)
	{
		outputs[0] = MATLAB异常(MATLAB异常类型::Mex异常, 内部异常类型::Mex异常, 异常);
		异常输出补全(outputs);
		return;
	}
	static const StructArray 成功结构 = MATLAB异常();
	outputs[0] = 成功结构;
}
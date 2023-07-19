#include "pch.h"
#include"MATLAB异常.h"
#include"窗口.h"
#include<Mex实现.h>
#include<Mex工具.h>
//SHFileOperation

#ifdef CopyFile
#undef CopyFile
#endif
API声明(CopyFile);
API声明(Delete);
#ifdef MoveFile
#undef MoveFile
#endif
API声明(MoveFile);

//LibZip

API声明(ZipOpen);
API声明(ZipNameLocate);
API声明(ZipFopen);
API声明(ZipFread);
API声明(ZipFclose);
API声明(ZipDiscard);
API声明(ZipGetSize);
API声明(ZipGetName);
API声明(ZipGetNumEntries);

//File

API声明(File_Create);
API声明(File_GetSize);
API声明(File_Read);
API声明(File_SetEnd);
API声明(File_SetPointer);
API声明(File_Write);
API声明(File_Close);

//MemoryMapping

API声明(MemoryMapping_Create);
API声明(MemoryMapping_Open);
API声明(MemoryMapping_View);
API声明(MemoryMapping_Unview);
API声明(MemoryMapping_Close);

//Pointer

API声明(Pointer_Allocate);
API声明(Pointer_Read);
API声明(Pointer_Write);
API声明(Pointer_Copy);
API声明(Pointer_Release);

//Window

API声明(Window_Create);
API声明(Window_Destroy);
API声明(Window_Image);
API声明(Window_Screens);
API声明(Window_Clear);
API声明(Window_Fill);
API声明(Window_RemoveVisual);

//ProjectFileSystem
API声明(PFS_Create);

//杂项

API声明(TypeCast);
API声明(LnkShortcut);
API声明(Crash);
API声明(Pause);

using namespace Mex工具;
std::shared_ptr<matlab::engine::MATLABEngine>MATLAB引擎;
MexFunction::MexFunction()
{
	MATLAB引擎 = getEngine();
}
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
		MemoryMapping_Open,
		MemoryMapping_View,
		MemoryMapping_Unview,
		MemoryMapping_Close,
		Pointer_Allocate,
		Pointer_Read,
		Pointer_Write,
		Pointer_Copy,
		Pointer_Release,
		TypeCast,
		Window_Create,
		Window_Destroy,
		Window_Image,
		Window_Screens,
		Window_Clear,
		Window_Fill,
		Window_RemoveVisual,
		LnkShortcut,
		Crash,
		Pause,
		PFS_Create,
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
	catch (...)
	{
		outputs[0] = MATLAB异常(MATLAB异常类型::未知异常);
		异常输出补全(outputs);
		return;
	}
	static const StructArray 成功结构 = MATLAB异常();
	outputs[0] = 成功结构;
}
MexFunction::~MexFunction()
{
	窗口::销毁所有();
}
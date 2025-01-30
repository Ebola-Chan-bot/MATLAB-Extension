#include "pch.h"
#include"窗口.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>

//SHFileOperation
Mex工具API(SHFile_Copy);
Mex工具API(SHFile_Delete);
Mex工具API(SHFile_Move);

//LibZip

Mex工具API(ZipOpen);
Mex工具API(ZipNameLocate);
Mex工具API(ZipFopen);
Mex工具API(ZipFread);
Mex工具API(ZipFclose);
Mex工具API(ZipDiscard);
Mex工具API(ZipGetSize);
Mex工具API(ZipGetName);
Mex工具API(ZipGetNumEntries);

//File

Mex工具API(File_Create);
Mex工具API(File_GetSize);
Mex工具API(File_Read);
Mex工具API(File_SetEnd);
Mex工具API(File_SetPointer);
Mex工具API(File_Write);
Mex工具API(File_Close);

//MemoryMapping

Mex工具API(MemoryMapping_Create);
Mex工具API(MemoryMapping_Open);
Mex工具API(MemoryMapping_View);
Mex工具API(MemoryMapping_Unview);
Mex工具API(MemoryMapping_Close);

//Pointer

Mex工具API(Pointer_Allocate);
Mex工具API(Pointer_Read);
Mex工具API(Pointer_Write);
Mex工具API(Pointer_Copy);
Mex工具API(Pointer_Release);

//Window

Mex工具API(Window_Create);
Mex工具API(Window_Destroy);
Mex工具API(Window_Image);
Mex工具API(Window_Screens);
Mex工具API(Window_Clear);
Mex工具API(Window_Fill);
Mex工具API(Window_RemoveVisual);

//杂项

Mex工具API(TypeCast);
Mex工具API(LnkShortcut);
Mex工具API(Crash);
Mex工具API(Pause);
Mex工具API(ArrayType_FromData);
Mex工具API(WebpRead);

//提权操作

Mex工具API(Install_path_manager);
Mex工具API(Uninstall_path_manager);
Mex工具API(Set_shared_path);
Mex工具API(Add_shared_path);
Mex工具API(Remove_shared_path);
Mex工具API(Builtin_bug_fix);
Mex工具API(Associate_prj_extension);
Mex工具API(Get_pathdef_permission);
Mex工具API(Serialport_snatch);

//Database

Mex工具API(Database_MariaDB);
Mex工具API(Database_DeleteMariaDB);
Mex工具API(Database_UpdateByPrimary);
Mex工具API(Database_Dump);
Mex工具API(Database_ExecuteStatement);
Mex工具API(Database_ExecuteQuery);

using namespace Mex工具;
void Mex工具::初始化()noexcept {}
Mex工具API(Mex工具::执行)
{
	constexpr Mex工具::API 跳转表[]=
	{
		SHFile_Copy,
		SHFile_Delete,
		SHFile_Move,
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
		ArrayType_FromData,
		WebpRead,
		Install_path_manager,
		Uninstall_path_manager,
		Set_shared_path,
		Add_shared_path,
		Remove_shared_path,
		Builtin_bug_fix,
		Associate_prj_extension,
		Get_pathdef_permission,
		Serialport_snatch,
		Database_MariaDB,
		Database_DeleteMariaDB,
		Database_UpdateByPrimary,
		Database_Dump,
		Database_ExecuteStatement,
		Database_ExecuteQuery,
	};
	跳转表[万能转码<size_t>(std::move(输入[0]))](输出, 输入);
};
void Mex工具::清理()noexcept
{
}
classdef WindowsAPI<uint64
	enumeration
		SHFile_Copy(0)
		SHFile_Delete(1)
		SHFile_Move(2)	
		ZipOpen(3)
		ZipNameLocate(4)
		ZipFopen(5)
		ZipFread(6)
		ZipFclose(7)
		ZipDiscard(8)
		ZipGetSize(9)
		ZipGetName(10)
		ZipGetNumEntries(11)
		File_Create(12)
		File_GetSize(13)
		File_Read(14)
		File_SetEnd(15)
		File_SetPointer(16)
		File_Write(17)
		File_Close(18)
		MemoryMapping_Create(19)
		MemoryMapping_Open(20)
		MemoryMapping_View(21)
		MemoryMapping_Unview(22)
		MemoryMapping_Close(23)
		Pointer_Allocate(24)
		Pointer_Read(25)
		Pointer_Write(26)
		Pointer_Copy(27)
		Pointer_Release(28)
		TypeCast(29)
		Window_Create(30)
		Window_Destroy(31)
		Window_Image(32)
		Window_Screens(33)
		Window_Clear(34)
		Window_Fill(35)
		Window_RemoveVisual(36)
		LnkShortcut(37)
		Crash(38)
		Pause(39)
		ArrayType_FromData(40)
		WebpRead(41)
		Install_path_manager(42)
		Uninstall_path_manager(43)
		Set_shared_path(44)
		Add_shared_path(45)
		Remove_shared_path(46)
		Builtin_bug_fix(47)
		Associate_prj_extension(48)
		Get_pathdef_permission(49)
		Serialport_snatch(50)
		Database_UpdateByPrimary(51)
	end
	methods
		function varargout=Call(obj,varargin)
			[varargout{1:nargout}]=WindowsCall(uint64(obj),varargin{:});
		end
	end
end
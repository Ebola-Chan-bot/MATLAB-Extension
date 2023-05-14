classdef ElevatedOperation<uint8
	enumeration
		Install_Path_Manager(0)
		Uninstall_Path_Manager(1)
		Set_shared_path(2)
		Add_shared_path(3)
		Remove_shared_path(4)
		Builtin_bug_fix(5)
		Associate_prj_extension(6)
	end
	methods
		function Call(obj,varargin)
			persistent Operator
			if isempty(Operator)
				Operator=['"',fullfile(fileparts(mfilename('fullpath')),'net7.0-windows\提权操作.exe'),'" '];
			end
			Name=char(matlab.lang.internal.uuid);
			MM=MATLAB.IOFun.MemoryMapping.Create(Name=Name,FillData=[{uint8(obj)},varargin]);
			system([Operator Name],'-runAsAdmin');
		end
	end
end
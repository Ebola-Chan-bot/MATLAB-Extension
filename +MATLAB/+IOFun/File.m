classdef File<handle
	%使用 Win32 API 的文件读写操作，比MATLAB内置文件操作更灵活丰富
	properties(SetAccess=immutable)
		%文件句柄
		Handle
	end
	methods
		function obj = File(FileName,options)
			%打开或创建文件
			%# 语法
			% ```
			% obj=MATLAB.IOFun.File(FileName,Name=Value);
			% ```
			%# 输入参数
			% FileName(1,1)string，文件路径
			% ## 名称值参数
			%  DesiredAccess，
			arguments
				FileName
				options.DesiredAccess=MATLAB.Flags.GENERIC_READ
				options.ShareMode=MATLAB.Flags.FILE_SHARE_READ+MATLAB.Flags.FILE_SHARE_WRITE+MATLAB.Flags.FILE_SHARE_DELETE
				options.CreationDisposition=MATLAB.Flags.OPEN_EXISTING
				options.FlagsAndAttributes=MATLAB.Flags.FILE_ATTRIBUTE_NORMAL
			end
			obj.Handle=MATLAB.internal.WindowsAPI.File_Create.Call(FileName,uint32(options.DesiredAccess),uint32(options.ShareMode),uint32(options.CreationDisposition),uint32(options.FlagsAndAttributes));
		end
		function FileSize=GetSize(obj)
			FileSize=MATLAB.internal.WindowsAPI.File_GetSize.Call(obj.Handle);
		end
		function Data=Read(obj,varargin)
			Number=intmax('uint64');
			Type=MATLAB.DataTypes.ArrayType.UINT8;
			for V=1:numel(varargin)
				Arg=varargin{V};
				if isnumeric(Arg)&&~isa(Arg,'MATLAB.DataTypes.ArrayType')
					Number=Arg;
				else
					Type=MATLAB.DataTypes.ArrayType(Arg);
				end
			end
			Data=MATLAB.internal.WindowsAPI.File_Read.Call(obj.Handle,Number,int32(Type));
		end
		function SetEnd(obj)
			MATLAB.internal.WindowsAPI.File_SetEnd.Call(obj.Handle);
		end
		function NewFilePointer=SetPointer(obj,DistanceToMove,MoveMethod)
			switch nargin
				case 1
					DistanceToMove=0;
					MoveMethod=MATLAB.Flags.FILE_CURRENT;
				case 2
					MoveMethod=MATLAB.Flags.FILE_BEGIN;
			end
			NewFilePointer=MATLAB.internal.WindowsAPI.File_SetPointer.Call(obj.Handle,DistanceToMove,uint32(MoveMethod));
		end
		function Write(obj,varargin)
			MATLAB.internal.WindowsAPI.File_Write.Call(obj.Handle,varargin);
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.File_Close.Call(obj.Handle);
		end
	end
end
classdef Pointer<uint64
	methods(Static)
		function obj=Allocate(options)
			arguments
				options.NumBytes=0;
				options.FillData cell={};
			end
			obj=MATLAB.General.Pointer(MATLAB.internal.WindowsAPI.Pointer_Allocate.Call(options.NumBytes,options.FillData));
		end
		function Copy(ToPointer,FromPointer,NumBytes)
			MATLAB.internal.WindowsAPI.Pointer_Copy.Call(uint64(ToPointer),uint64(FromPointer),NumBytes);
		end
	end
	methods
		function Data=Read(obj,Number,Type)
			arguments
				obj
				%读入元素个数
				Number
				%读入数据类型
				Type MATLAB.DataTypes.ArrayType=MATLAB.DataTypes.ArrayType.UINT8;
			end
			Data=MATLAB.internal.WindowsAPI.Pointer_Read.Call(uint64(obj),Number,int32(Type));
		end
		function Write(obj,varargin)
			MATLAB.internal.WindowsAPI.Pointer_Write.Call(uint64(obj),varargin);
		end
		function Release(obj)
			MATLAB.internal.WindowsAPI.Pointer_Release.Call(uint64(obj));
		end
		function obj=plus(obj,Offset)
			obj=MATLAB.General.Pointer(uint64(obj)+Offset);
		end
		function obj=minus(obj,Offset)
			obj=MATLAB.General.Pointer(uint64(obj)-Offset);
		end
	end
end
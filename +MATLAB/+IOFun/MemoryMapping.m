classdef MemoryMapping<handle
	properties(SetAccess=immutable,GetAccess=private)
		Handle
	end
	methods(Access=private)
		function obj = MemoryMapping(Handle)
			obj.Handle=Handle;
		end
	end
	methods(Static)
		function Unview(Pointer)
			MATLAB.internal.WindowsAPI.MemoryMapping_Unview.Call(uint64(Pointer));
		end
		function varargout=Create(options)
			arguments
				options.File=intmax('uint64')
				options.Protect %这里即使限定uint32也不会对MATLAB.Flags进行转换，因此必须手动转换uint32
				options.MaximumSize=0
				options.Name=''
				options.FillData cell={}
			end
			if isa(options.File,'MATLAB.IOFun.File')
				File=options.File.Handle;
			else
				File=options.File;
			end
			if isfield(options,'Protect')
				Protect=options.Protect;
			elseif ~isempty(options.FillData)||options.File==intmax('uint64')&&options.Name==""
				Protect=MATLAB.Flags.PAGE_READWRITE;
			else
				Protect=MATLAB.Flags.PAGE_READONLY;
			end
			varargout=cell(1,nargout);
			[varargout{:}]=MATLAB.internal.WindowsAPI.MemoryMapping_Create.Call(File,uint32(Protect),options.MaximumSize,options.Name,options.FillData);
			varargout{1}=MATLAB.IOFun.MemoryMapping(varargout{1});
			if nargout>1
				varargout{2}=MATLAB.General.Pointer(varargout{2});
			end
		end
	end
	methods
		function Pointer=View(obj,options)
			arguments
				obj
				options.DesiredAccess=MATLAB.Flags.FILE_MAP_READ
				options.FileOffset=0
				options.NumberOfBytesToMap=0
			end
			Pointer=MATLAB.General.Pointer(MATLAB.internal.WindowsAPI.MemoryMapping_View.Call(obj.Handle,uint32(options.DesiredAccess),options.FileOffset,options.NumberOfBytesToMap));
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.MemoryMapping_Close.Call(obj.Handle);
		end
	end
end
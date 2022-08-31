classdef WindowsAPI<uint8
	enumeration
		CopyFile(0)
		Delete(1)
		MoveFile(2)	
		ZipOpen(3)
		ZipNameLocate(4)
		ZipFopen(5)
		ZipFread(6)
		ZipFclose(7)
		ZipDiscard(8)
		ZipGetSize(9)
		ZipGetName(10)
		ZipGetNumEntries(11)
	end
	methods
		function varargout=Call(obj,varargin)
			import MATLAB.internal.InnerException
			varargout=cell(1,nargout);
			[Error,varargout{:}]=WindowsCall(uint8(obj),varargin{:});
			ExceptionType=MATLAB.MatlabException(Error.ExceptionType);
			if ExceptionType~=MATLAB.MatlabException.Success
				switch InnerException(Error.InnerException)
					case InnerException.None
						ExceptionType.Throw;
					case InnerException.Win32Exception
						Detail.InnerException=MATLAB.WindowsErrorCode(Error.ErrorCode);
					case InnerException.LibzipException
						Detail.InnerException=MATLAB.IO.LibzipException(Error.ErrorCode);
				end
				if Error.Index
					Detail.Index=Error.Index;
					ExceptionType.Throw(sprintf('%s 错误发生在第%u个元素',Detail.InnerException,Detail.Index),Detail=Detail);
				else
					ExceptionType.Throw(Detail.InnerException,Detail=Detail);
				end
			end
		end
	end
end
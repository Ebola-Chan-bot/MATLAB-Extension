classdef WindowsAPI<uint8
	enumeration
		CopyFile(0)
		Delete(1)
		MoveFile(2)
	end
	methods
		function varargout=Call(obj,varargin)
			varargout=cell(1,nargout);
			[Error,varargout{:}]=WindowsCall(uint8(obj),varargin{:});
			ExceptionType=MATLAB.MatlabException(Error.ExceptionType);
			if ExceptionType~=MATLAB.MatlabException.Success
				if Error.WindowsErrorCode
					WindowsErrorCode=MATLAB.WindowsErrorCode(Error.WindowsErrorCode);
					ExceptionType.Throw(WindowsErrorCode,Detail=struct(MATLABException=ExceptionType,WindowsAPI=obj,WindowsErrorCode=WindowsErrorCode));
				else
					ExceptionType.Throw(Detail=struct(MATLABException=ExceptionType,WindowsAPI=obj));
				end
			end
		end
	end
end
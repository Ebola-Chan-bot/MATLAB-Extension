classdef ReferenceTemplate<MATLAB.internal.ReferenceBase
	%此类作为模板使用，不应直接构造对象。使用时将Reference替换为具体类名，SpecialMethod方法作为模板实例化为具体的方法。
	methods
		function obj = ReferenceTemplate(Referable)
			obj@MATLAB.internal.ReferenceBase(Referable);
		end
		function varargout=SpecialMethod(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=SpecialMethod(varargin{:});
		end
	end
end
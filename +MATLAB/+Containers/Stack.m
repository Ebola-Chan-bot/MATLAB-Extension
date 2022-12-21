classdef Stack<handle
	%STL风格的先进后出栈实现，但不要求栈中对象具有相同的数据类型
	properties(Access=private)
		iTop
	end
	properties(SetAccess=private)
		%栈中对象个数
		Size=0;
	end
	properties(Dependent)
		%获取或设置栈顶对象。如果栈为空，将发生错误
		Top
	end
	methods
		function Pop(obj)
			%将栈顶对象弹出栈。如果栈为空，将发生错误
			if isempty(obj.iTop)
				MATLAB.MatlabException.Stack_is_empty.Throw;
			else
				obj.iTop=obj.iTop.Link;
				obj.Size=obj.Size-1;
			end
		end
		function Push(obj,Value)
			%将一个对象压入栈
			obj.iTop=MATLAB.internal.UniLink(Value,obj.iTop);
			obj.Size=obj.Size+1;
		end
		function Value=get.Top(obj)
			if isempty(obj.iTop)
				MATLAB.MatlabException.Stack_is_empty.Throw;
			else
				Value=obj.iTop.Value;
			end
		end
		function set.Top(obj,Value)
			if isempty(obj.iTop)
				MATLAB.MatlabException.Stack_is_empty.Throw;
			else
				obj.iTop.Value=Value;
			end
		end
	end
end
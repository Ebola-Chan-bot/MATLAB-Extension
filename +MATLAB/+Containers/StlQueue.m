classdef StlQueue<handle
	%STL风格的先进先出队列实现，但不要求队列中对象具有相同的数据类型
	properties(Access=private)
		iFront
		iBack
	end
	properties(Dependent)
		%获取或设置队尾对象。如果队列为空，将发生错误
		Back
		%获取或设置队首对象。如果队列为空，将发生错误
		Front
	end
	properties(SetAccess=private)
		%队列中对象个数
		Size=0;
	end
	methods
		function Value=get.Back(obj)
			if isempty(obj.iBack)
				MATLAB.Lang.MatlabException.Queue_is_empty.Throw;
			else
				Value=obj.iBack.Value;
			end
		end
		function set.Back(obj,Value)
			if isempty(obj.iBack)
				MATLAB.Lang.MatlabException.Queue_is_empty.Throw;
			else
				obj.iBack.Value=Value;
			end
		end
		function Value=get.Front(obj)
			if isempty(obj.iFront)
				MATLAB.Lang.MatlabException.Queue_is_empty.Throw;
			else
				Value=obj.iFront.Value;
			end
		end
		function set.Front(obj,Value)
			if isempty(obj.iFront)
				MATLAB.Lang.MatlabException.Queue_is_empty.Throw;
			else
				obj.iFront.Value=Value;
			end
		end
		function Pop(obj)
			%将队首对象弹出队列。如果队列为空，将发生错误
			if obj.Size
				obj.iFront=obj.iFront.Link;
				if isempty(obj.iFront)
					obj.iBack=obj.iFront;
					obj.Size=0;
				else
					obj.Size=obj.Size-1;
				end
			else
				MATLAB.Lang.MatlabException.Queue_is_empty.Throw;
			end
		end
		function Push(obj,Value)
			%将一个对象压入队尾
			if isempty(obj.iFront)
				obj.iFront=MATLAB.internal.UniLink(Value,obj.iFront);
				obj.iBack=obj.iFront;
				obj.Size=1;
			else
				obj.iBack.Link=MATLAB.internal.UniLink(Value,[]);
				obj.iBack=obj.iBack.Link;
				obj.Size=obj.Size+1;
			end
		end
	end
end
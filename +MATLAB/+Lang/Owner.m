classdef Owner<handle&matlab.mixin.indexing.RedefinesDot
	%为句柄对象制定一个所有者，托管其生命周期
	%MATLAB句柄对象维护一个引用计数。只有在引用计数为0时，才会调用其delete方法，释放资源。但是MATLAB系统也会维护一些不在工作区中显示的内部全局对象（如串口、计时器回调
	% 等），如果让这些内部对象持有了句柄对象的引用，那么即使在工作区中清空变量，对象的引用计数仍然不为0，不会delete，因而也不会释放资源。这就造成了一种隐患：一个句柄对
	% 象可能忘记delete就从工作区中被清除，而该对象仍然被不可访问的内部全局对象引用着而无法触发自动delete，其所持有的资源也就永远无法被释放，直到MATLAB会话结束。
	%使用Owner可以解决此问题。将句柄对象托管在Owner中，Owner本身应当只存在于工作区而不被任何其它对象引用。这样清除工作区中的Owner变量时，Owner引用计数就会归零，自动触
	% 发delete，而Owner的delete函数只做一件事，就是强制delete它所持有的对象，而无论其引用计数是否为0。
	%为了方便使用，Owner支持对对象的透明访问。即你可以直接对Owner使用其所拥有对象的点索引属性和方法，但与Owner自身相冲突的属性和方法除外。
	properties(Access=private)
		iObject
	end
	properties(Dependent)
		%Owner所持有的句柄对象。Owner被delete时，该对象将强制被delete。
		Object
	end
	methods
		function Value=get.Object(obj)
			Value=obj.iObject;
		end
		function set.Object(obj,Object)
			if isa(Object,'handle')
				obj.iObject=Object;
			else
				MATLAB.MatlabException.Cannot_own_a_non_handle_value.Throw;
			end
		end
		function obj = Owner(Object)
			%为句柄对象构造一个Owner
			obj.Object=Object;
		end
		function delete(obj)
			delete(obj.iObject);
		end
		function C=class(obj)
			C=split(class(obj.iObject),'.');
			C=['Owner<' C{end} '>'];
		end
	end
	methods(Access=protected)
        function varargout = dotReference(obj,indexOp)
            [varargout{1:nargout}] = obj.iObject.(indexOp);
		end
        function obj = dotAssign(obj,indexOp,varargin)
            [obj.iObject.(indexOp)] = varargin{:};
		end        
        function n = dotListLength(obj,indexOp,indexContext)
            n = listLength(obj.iObject,indexOp,indexContext);
        end
	end
end
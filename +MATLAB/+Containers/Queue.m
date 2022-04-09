classdef Queue<matlab.mixin.Copyable&MATLAB.Containers.IQueue
	%MALTAB.Containers.IQueue的简单基本实现
	properties(Access=private)
		Data
		Head=0
		Tail
		Capacity
	end
	methods(Access=private)
		function TI=TraverseIndex(obj)
			if obj.Head>obj.Tail
				TI=[obj.Head+1:obj.Capacity 1:obj.Tail];
			else
				TI=obj.Head+1:obj.Tail;
			end
		end
	end
	methods
		function obj=Queue(varargin)
			% 初始化 Queue 类的新实例。
			% # 语法
			% ```
			% import MATLAB.Containers.Queue
			% obj=Queue
			% %初始化 Queue 类的新实例，该实例为空
			%
			% obj=Queue(Element1,Element2,…)
			% %初始化 Queue 类的新实例，该实例从头到尾包含指定顺序的多个元素。
			% ```
			% 输入参数：Element，要放入队列的初始元素。重复输入此参数，以从头到尾排列多个元素。
			obj.Data=[varargin {[]}];
			obj.Capacity=numel(obj.Data);
			obj.Tail=obj.Capacity-1;
		end
		function C=Count(obj)
			C=mod(obj.Tail-obj.Head,obj.Capacity);
		end
		function Clear(obj)
			obj.Head=obj.Tail;
			obj.Data=cell(1,obj.Capacity);
		end
		function C=Contains(obj,varargin)
			C=MATLAB.Ops.IsMemberN(varargin,obj.Data(obj.TraverseIndex),2);
		end
		function Elements=Dequeue(obj,Number)
			arguments
				obj
				Number=1
			end
			NewHead=mod(obj.Head+min(Number,obj.Count),obj.Capacity);
			if NewHead<obj.Head
				Elements=obj.Data([obj.Head+1:end 1:NewHead]);
			else
				Elements=obj.Data(obj.Head+1:NewHead);
			end
			obj.Head=NewHead;
		end
		function Enqueue(obj,varargin)
			NumAdd=numel(varargin);
			NeedCapacity=obj.Count+NumAdd+1;
			if NeedCapacity>obj.Capacity
				NewCapacity=NeedCapacity*2;
				NewData=cell(1,NewCapacity);
				Index=obj.TraverseIndex;
				Number=numel(Index);
				NewData(1:Number)=obj.Data(Index);
				obj.Data=NewData;
				obj.Capacity=NewCapacity;
				obj.Head=0;
				obj.Tail=Number;
			end
			NewTail=mod(obj.Tail+NumAdd,obj.Capacity);
			if NewTail<obj.Tail
				obj.Data([obj.Tail+1:end 1:NewTail])=varargin;
			else
				obj.Data(obj.Tail+1:NewTail)=varargin;
			end
			obj.Tail=NewTail;
			if NumAdd
				notify(obj,'DataEnqueued');
			end
		end
		function Data=Peek(obj)
			if obj.IsEmpty
				Data={};
			else
				Data=obj.Data(obj.Head+1);
			end
		end
		function Array=ToArray(obj)
			Array=obj.Data(obj.TraverseIndex);
		end
		function E=IsEmpty(obj)
			E=obj.Head==obj.Tail;
		end
	end
end
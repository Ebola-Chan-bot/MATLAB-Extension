classdef Queue<matlab.mixin.Copyable
	% 表示对象的先进先出集合。
	% Queue是一个对象的流水线，对象被一个接一个插入队尾，然后按照插入的顺序一个接一个从队首取出，而不支持随机插入、取出中间的对象。
	% 可以对 Queue 及其元素执行三个主要操作：
	% - Enqueue 将一个元素添加到队列的末尾。
	% - Dequeue 从队列的开头移除最旧的元素。
	% - Peek 返回位于队列开头的最旧元素，但不会将其从队列中删除。
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
			% 获取 Queue 中包含的元素数。
			% 返回值：(1,1)double，Queue 中包含的元素数。
			C=mod(obj.Tail-obj.Head,obj.Capacity);
		end
		function Clear(obj)
			% 从 Queue 中移除所有对象。
			% 注意，此方法不会立即释放集合中的对象，也不会显式delete。对于必须立即释放的元素，您必须使用Dequeue取出然后手动释放。
			obj.Head=obj.Tail;
			obj.Data=cell(1,obj.Capacity);
		end
		function C=Contains(obj,varargin)
			% 确定某些元素是否在 Queue 中。
			% # 语法
			% ```
			% C=obj.Contains(Element1,Element2,…)
			% ```
			% 输入参数：Element，要在队列中定位的对象。重复输入此参数可以一次性确定多个对象。
			% 返回值：C(1,:)logical，按照Element的输入顺序返回每个Element是否存在的逻辑值。
			C=MATLAB.Ops.IsMemberN(varargin,obj.Data(obj.TraverseIndex),2);
		end
		function Elements=Dequeue(obj,Number)
			% 移除并返回位于 Queue 开始处的对象。
			% 此方法类似于 Peek 方法，但 Peek 不修改 Queue。
			% # 语法
			% ```
			% obj.Dequeue
			% %移除队首的第1个对象
			%
			% obj.Dequeue(Number)
			% %从队首开始移除多个对象
			%
			% Elements=obj.Dequeue(___)
			% %返回被移除的对象，可以与上述任意语法组合使用
			% ```
			% 输入参数：Number，要移除的对象个数。
			% 返回值：Elements(1,:)cell，被移除的对象，按照它们在队列中从头到尾的顺序，并用元胞包装。
			% 提示：如果Number>obj.Count，将仅取出obj.Count个对象，而不产生错误。因此您可以指定Number为Inf以取出所有对象。
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
			% 将对象添加到 Queue 的结尾处。
			% # 语法
			% ```
			% obj.Enqueue(Element1,Element2,…)
			% ```
			% 输入参数：Element，要添加到 Queue 的对象。重复输入此参数可以依次插入多个对象。
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
		end
		function Data=Peek(obj)
			% 返回位于 Queue 开始处的对象但不将其移除。
			% 返回值：(1,:)cell。如果队列为空，返回空元胞{}；否则返回包装着队首元素的元胞标量。
			if obj.Head==obj.Tail
				Data={};
			else
				Data=obj.Data(obj.Head+1);
			end
		end
		function Array=ToArray(obj)
			% 将 Queue 元素复制到新数组。
			% 返回值：(1,:)cell，包含从 Queue 复制的元素的新数组，每个元素都用元胞包装。
			Array=obj.Data(obj.TraverseIndex);
		end
	end
end
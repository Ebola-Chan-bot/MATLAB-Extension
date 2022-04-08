classdef(Abstract)IQueue<handle
	% 表示对象的先进先出集合。
	% IQueue是一个对象的流水线，对象被一个接一个插入队尾，然后按照插入的顺序一个接一个从队首取出，而不支持随机插入、取出中间的对象。
	% 可以对 IQueue 及其元素执行三个主要操作：
	% - Enqueue 将一个元素添加到队列的末尾。
	% - Dequeue 从队列的开头移除最旧的元素。
	% - Peek 返回位于队列开头的最旧元素，但不会将其从队列中删除。
	events
		%有元素被添加到队列中时引发此事件
		DataEnqueued
	end
	methods(Abstract)
		% 移除并返回位于 IQueue 开始处的对象。
		% 此方法类似于 Peek 方法，但 Peek 不修改 IQueue。
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
		Elements=Dequeue(obj,Number)
		% 将对象添加到 IQueue 的结尾处。
		% # 语法
		% ```
		% obj.Enqueue(Element1,Element2,…)
		% ```
		% 输入参数：Element，要添加到 IQueue 的对象。重复输入此参数可以依次插入多个对象。
		Enqueue(obj,varargin)
	end
	%某些方法的默认实现。子类可以重写成性能更高的实现。
	methods
		function C=Count(obj)
			% 获取 Queue 中包含的元素数。
			% 返回值：(1,1)double，IQueue 中包含的元素数。
			C=numel(obj.ToArray);
		end
		function Clear(obj)
			% 从 IQueue 中移除所有对象。
			% 注意，此方法不会立即释放集合中的对象，也不会显式delete。对于必须立即释放的元素，您必须使用Dequeue取出然后手动释放。
			obj.Dequeue(Inf);
		end
		function C=Contains(obj,varargin)
			% 确定某些元素是否在 IQueue 中。
			% # 语法
			% ```
			% C=obj.Contains(Element1,Element2,…)
			% ```
			% 输入参数：Element，要在队列中定位的对象。重复输入此参数可以一次性确定多个对象。
			% 返回值：C(1,:)logical，按照Element的输入顺序返回每个Element是否存在的逻辑值。
			C=MATLAB.Ops.IsMemberN(varargin,obj.ToArray,2);
		end
		function P=Peek(obj)
			% 返回位于 IQueue 开始处的对象但不将其移除。
			% 返回值：(1,:)cell。如果队列为空，返回空元胞{}；否则返回包装着队首元素的元胞标量。
			P=obj.ToArray;
			if ~isempty(P)
				P=P(1);
			end
		end
		function Array=ToArray(obj)
			% 将 IQueue 元素复制到新数组。
			% 返回值：(1,:)cell，包含从 IQueue 复制的元素的新数组，每个元素都用元胞包装。
			Array=obj.Dequeue(Inf);
			obj.Enqueue(Array{:});
		end
		function E=IsEmpty(obj)
			% 检查队列是否为空
			% 返回值：(1,1)logical，若队列为空，true；否则false
			E=isempty(obj.Peek);
		end
	end
end
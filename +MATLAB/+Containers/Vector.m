classdef Vector<handle
	%STL风格的向量实现，向量中的元素必须具有相同的数据类型，且该类型必须是基本数据类型，或具有默认无参构造函数
	properties(Access=private)
		Container
	end
	properties(SetAccess=private)
		%向量中的元素个数
		Size=0
	end
	properties(Dependent)
		%获取或设置向量中的最后一个元素。如果向量为空，将发生错误
		Back
		%获取或设置向量中的第一个元素。如果向量为空，将发生错误
		Front
	end
	methods
		function Value=At(obj,Index,Value)
			%获取或设置向量中指定位置的元素。
			%# 语法
			% ```
			% Value=obj.At(Index);
			% %获取向量指定位置的元素
			%
			% obj.At(Index,Value);
			% %设置向量指定位置的元素
			% ```
			%# 输入参数
			% Index(1,:)，要获取或设置的向量位置索引。不能超出向量长度，否则将出错
			% Value(1,:)，要设置的值
			%# 返回值
			% Value(1,:)，获取到的值，长度与Index一致。
			if any(Index>obj.Size)
				MATLAB.MatlabException.Index_exceeds_vector_size.Throw;
			elseif nargin>=3
				obj.Container(Index)=Value;
			else
				Value=obj.Container(Index);
			end
		end
		function Value=get.Back(obj)
			if obj.Size
				Value=obj.Container(obj.Size);
			else
				MATLAB.MatlabException.Vector_is_empty.Throw;
			end
		end
		function set.Back(obj,Value)
			if obj.Size
				obj.Container(obj.Size)=Value;
			else
				MATLAB.MatlabException.Vector_is_empty.Throw;
			end
		end
		function C=Capacity(obj)
			%返回在不分配更多的存储的情况下向量可以包含的元素数。
			C=numel(obj.Container);
		end
		function Clear(obj)
			%清除向量的元素。
			%处于性能考虑，如果向量包含句柄对象，此方法不会立刻减少句柄的引用计数，因而也不会释放内存。只有当那些对象在内存中被新对象覆盖时才会减少引用计数。如果需要释
			% 放内存，请在此方法后再调用ShrinkToFit。
			obj.Size=0;
		end
		function D=Data(obj)
			%以MATLAB数组形式返回向量中所有元素
			D=obj.Container(1:obj.Size);
		end
		function Erase(obj,Index)
			%从指定位置删除向量中的元素
			%# 语法
			% ```
			% obj.Erase(Index);
			% ```
			%# 输入参数
			% Index(1,:)，要删除的元素索引。本函数不检查Index是否超出Size范围，也不一定会引发错误。
			obj.Container(Index)=[];
			obj.Size=obj.Size-nnz(Index<=obj.Size);
		end
		function Value=get.Front(obj)
			if obj.Size
				Value=obj.Container(1);
			else
				MATLAB.MatlabException.Vector_is_empty.Throw;
			end
		end
		function set.Front(obj,Value)
			if obj.Size
				obj.Container(1)=Value;
			else
				MATLAB.MatlabException.Vector_is_empty.Throw;
			end
		end
		function Insert(obj,Values,StartIndex)
			%将元素插入到向量的指定位置。
			%# 语法
			% ```
			% obj.Insert(Values,StartIndex);
			% ```
			%# 输入参数
			% Values(1,:)，要插入的值
			% StartIndex(1,1)，要插入的位置。插入后将满足`isequal(Values,obj.At(StartIndex:StartIndex+numel(Values)-1)`。本函数不检查StartIndex是否超出Size范围，
			%  也不一定会引发错误。
			obj.Container=[obj.Container(1:StartIndex-1),Values,obj.Container(StartIndex:obj.Size)];
			obj.Size=obj.Size+numel(Values);
		end
		function PopBack(obj)
			%删除向量末尾处的元素。如果向量为空，将引发错误。
			if obj.Size
				obj.Size=obj.Size-1;
			else
				MATLAB.MatlabException.Vector_is_empty.Throw;
			end
		end
		function PushBack(obj,Value)
			%在向量末尾处添加一个元素
			NewSize=obj.Size+numel(Value);
			if NewSize>obj.Capacity
				obj.Container(NewSize*2)=Value(1);
			end
			obj.Container(obj.Size+1:NewSize)=Value;
			obj.Size=NewSize;
		end
		function Reserve(obj,Capacity,Value)
			%为向量对象保留最小的存储长度，必要时为其分配空间。
			%如果已知数据的最小可能长度，可以用此方法进行预分配空间，性能较高。此方法不会改变向量的有效尺寸。
			%# 语法
			% ```
			% obj.Reserve(Capacity,Value);
			% %保留指定的存储长度，并用指定值填充预分配空间
			%
			% obj.Reserve(Capacity);
			% %如果向量不为空，填充值可以省略。
			% ```
			%# 输入参数
			% Capacity(1,1)，要分配给向量的最小存储长度
			% Value(1,1)，预分配空间的填充值。
			if obj.Capacity<Capacity
				if exist('Value','var')
					obj.Container(Capacity)=Value;
				elseif isempty(obj.Container)
					MATLAB.MatlabException.Empty_vector_must_specify_a_padding_value.Throw;
				else
					obj.Container(Capacity)=obj.Capacity(1);
				end
			end
		end
		function Resize(obj,NewSize,Value)
			%为向量指定新的尺寸。
			%如果向量的尺寸小于目标尺寸，则会添加元素，直到达到请求的尺寸；反之会删除最接近末尾的元素，直到达到目标尺寸。如果当前尺寸与目标尺寸相同，则不采取任何操作。
			%# 语法
			% ```
			% obj.Resize(NewSize,Value);
			% %指定新尺寸，如果发生尺寸增加则用指定值填充
			%
			% obj.Resize(NewSize);
			% %如果向量不为空，可以省略填充值
			%# 输入参数
			% NewSize(1,1)，目标尺寸
			% Value(1,1)，尺寸增加时的填充值
			if exist('Value','var')
				if NewSize>obj.Capacity
					obj.Container(NewSize*2)=Value;
				end
				if NewSize>obj.Size
					obj.Container(obj.Size+1:NewSize)=Value;
				end
				obj.Size=NewSize;
			elseif isempty(obj.Container)
				if NewSize
					MATLAB.MatlabException.Empty_vector_must_specify_a_padding_value.Throw;
				end
			else
				if NewSize>obj.Capacity
					obj.Container(NewSize*2)=obj.Container(1);
				end
				obj.Size=NewSize;
			end
		end
		function ShrinkToFit(obj)
			%释放向量保留的额外内存，其中的句柄对象引用计数将减一。
			obj.Container(obj.Size+1:end)=[];
		end
	end
end
classdef Set<handle
	%模拟 C++ std::set，一个句柄类型的无重复元素集合
	properties(Access=protected)
		Raw(1,:)
		ValidCount
		Capacity
		Sorted=true
	end
	properties(Dependent)
		%返回集合中的所有无重复元素
		Range
	end
	methods
		function R=get.Range(obj)
			R=obj.Raw(1:obj.ValidCount);
			if~obj.Sorted
				R=unique(R);
				obj.ValidCount=numel(R);
				obj.Raw(1:obj.ValidCount)=R;
			end
		end
		function Insert(obj,New)
			%插入新元素
			%# 语法
			% ```
			% obj.Insert(New);
			% ```
			%# 输入参数
			% New(1,:)，新元素
			NewCount=obj.ValidCount+numel(New);
			obj.Sorted=NewCount>obj.Capacity;
			if obj.Sorted
				NewRaw=union(obj.Raw(1:obj.ValidCount),New);
				obj.ValidCount=numel(NewRaw);
				if obj.ValidCount>obj.Capacity
					obj.Capacity=obj.ValidCount*2;
					obj.Raw=[NewRaw,NewRaw];
				else
					obj.Raw(1:obj.ValidCount)=NewRaw;
				end				
			else
				obj.Raw(obj.ValidCount+1:NewCount)=New;
				obj.ValidCount=NewCount;
			end
		end
		function Erase(obj,Old)
			%擦除已有元素
			%# 语法
			% ```
			% obj.Erase(Old);
			% ```
			%# 输入参数
			% Old(1,:)，要擦除的元素
			NewRaw=setdiff(obj.Raw(1:obj.ValidCount),Old);
			obj.ValidCount=numel(NewRaw);
			obj.Raw(1:obj.ValidCount)=NewRaw;
			obj.Sorted=true;
		end
	end
end
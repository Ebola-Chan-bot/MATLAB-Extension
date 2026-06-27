classdef Set<handle
	%模拟 C++ std::set，一个句柄类型的无重复元素集合
	properties(Access=protected)
		Raw=dictionary
	end
	properties(Dependent)
		%返回集合中的所有无重复元素
		Range
	end
	methods
		function R=get.Range(obj)
			if obj.Raw.isConfigured
				R=obj.Raw.keys;
			else
				R=[];
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
			obj.Raw(New)=0x0;
		end
		function Erase(obj,Old)
			%擦除已有元素
			%# 语法
			% ```
			% obj.Erase(Old);
			% ```
			%# 输入参数
			% Old(1,:)，要擦除的元素
			obj.Raw(Old)=[];
		end
	end
end
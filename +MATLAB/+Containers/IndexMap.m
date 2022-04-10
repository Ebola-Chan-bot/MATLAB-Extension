classdef IndexMap<handle
	% IndexMap是一种自动分配键的映射
	% 添加值时不能手动指定键，只能接受自动分配的返回键；访问时则跟映射相同，用键访问。
	properties(Access=private)
		CellArray cell
		ValidLogical logical
	end
	methods
		function C=Count(obj)
			% 返回对象中的键-值对组的数量
			C=sum(obj.ValidLogical);
		end
		function Values=Items(obj,Keys,varargin)
			% 获取或设置与指定的键关联的值。
			% # 语法
			% Values=obj.Items
			% %以元胞数组的形式返回输入 IndexMap 对象的所有值。
			%
			% Values=obj.Items(Keys)
			% %返回与Keys中指定的键对应的值。输出参数 Values 的大小与 Keys 相同。
			%
			% obj.Items(Keys,Value1,Value2,…)
			% %设置指定键的值
			% # 输入参数
			% Keys，要设置或指定的键向量。请使用从Add返回的键，自定义键可能会产生意外问题。如不指定此参数，将返回所有值。
			% Value1,Value2,…，可选，要设置的键值。如果设置此参数，键向量长度和值的个数必须相同。
			% # 返回值
			% Values，指定键对应的值排列成元胞向量。如未指定Keys，将返回所有值。
			if nargin>1
				if ~isempty(varargin)
					obj.CellArray(Keys)=varargin;
				end
				Values=obj.CellArray(Keys);
			else
				Values=obj.CellArray(obj.ValidLogical);
			end
		end
		function Keys=Add(obj,varargin)
			% 将指定的值添加到IndexMap中，返回自动分配的新键。
			% # 语法
			% Keys=obj.Add(Value1,Value2,…)
			% # 输入参数
			% Value1,Value2,…，要添加的元素的值，可以重复指定多个要添加的新值
			% # 返回值
			% Keys，为添加的元素分配的新键，与每个输入值一一对应。
			NumAdd=numel(varargin);
			NewCount=NumAdd+obj.Count;
			if NewCount>numel(obj.ValidLogical)
				NewCapacity=NewCount*2;
				obj.CellArray{NewCapacity}=[];
				obj.ValidLogical(NewCapacity)=false;
			end
			Keys=find(~obj.ValidLogical,NumAdd);
			obj.CellArray(Keys)=varargin;
			obj.ValidLogical(Keys)=true;
		end
		function Clear(obj)
			% 将所有键和值从IndexMap中移除。
			% Count属性设置为0，但不会立即释放对集合的元素的其他对象的引用。如有必要请先手动delete对象。
			obj.ValidLogical(:)=false;
		end
		function IK=IsKey(obj,Keys)
			% 确定 IndexMap 对象是否包含键
			% # 语法
			% IK=obj.IsKey(Keys)
			% %如果 obj 包含指定的键，将返回 1 (true)，否则将返回 0 (false)。如果 Keys 是指定多个键的数组，则 IK 是具有相同大小的逻辑数组。
			% # 输入参数
			% Keys，要在 IndexMap 对象中搜索的键向量
			% # 返回值
			% IK，指示每个键是否存在的逻辑向量。
			IK=Keys<=numel(obj.ValidLogical);
			IK(IK)=obj.ValidLogical(Keys(IK));
		end
		function K=Keys(obj)
			% 返回一个向量，其中包含 IndexMap 对象中的所有键。
			K=find(obj.ValidLogical);
		end
		function Remove(obj,Keys)
			% 从 IndexMap 对象中删除键-值对组
			% # 语法
			% obj.Remove(Keys)
			% %从输入 IndexMap 对象中删除指定的键以及与它们关联的值。
			% # 输入参数
			% Keys，要从 IndexMap 对象中删除的键-值对组的键。对应的值也被删除，但不会立即释放对集合的元素的其他对象的引用。如有必要请先手动delete对象。
			obj.ValidLogical(Keys)=false;
		end
	end
end
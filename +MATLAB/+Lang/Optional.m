classdef Optional<handle
	%一个值的句柄容器，可选为空。
	%此类可用于利用输入参数作为返回值，在不方便收取返回值的场合使用。
	%See also MATLAB.Lang.Capture
	properties(Access=protected)
		%实际保存值的属性，不对外暴露，应用依赖属性访问
		rValue
	end
	properties(SetAccess=protected)
		%指示容器是否为空
		HasValue
	end
	properties(Dependent)
		%容器容纳的值。如果容器当前为空，访问此值将出错。
		Value
	end
	methods
		function obj = Optional(Value)
			%构造Optional容器
			%# 语法
			% ```
			% obj=MATLAB.Lang.Optional;
			% %构造一个空的容器
			%
			% obj=MATLAB.Lang.Optional(Value);
			% %构造一个具有初始值的容器
			% ```
			%# 输入参数
			% Value，容器包含的初始值
			obj.HasValue=logical(nargin);
			if nargin
				obj.rValue=Value;
			end
		end	
		function V=get.Value(obj)
			if obj.HasValue
				V=obj.rValue;
			else
				MATLAB.Exception.Optional_value_not_set.Throw;
			end
		end
		function set.Value(obj,V)
			obj.rValue=V;
			obj.HasValue=true;
		end
		function V=ValueOr(obj,V)
			%返回容纳值。如果容器为空，则返回替代值。
			%# 语法
			% ```
			% V=obj.ValueOr(Default);
			% ```
			%# 输入参数
			% Default，如果容器为空，将返回此默认值
			%# 返回值
			% V，容纳值。如果容器为空，将返回Default。
			if obj.HasValue
				V=obj.rValue;
			end
		end
	end
end
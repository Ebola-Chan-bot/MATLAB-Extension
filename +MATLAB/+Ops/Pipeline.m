classdef Pipeline
	%实现管线|运算符
	%此类型是一个包装值类型，包装后可以支持or（|）运算符作为管线运算符，以对特定数据依次调用一连串函数
	%% 语法
	% ```
	% PipeEnd=MATLAB.Ops.Pipeline(Value)|Operation1|Operation2|Operation3|…
	% ```
	%% 示例
	% ```
	% RandSum=MATLAB.Ops.Pipeline(4)|@rand|{@sum,'all'};
	% RandSum.Value
	% %求随机4阶方阵的总和
	%
	% MATLAB.Ops.Pipeline(4)|@rand|{@sum,'all'}|@disp
	% %求随机4阶方阵的总和并显示在命令行窗口中
	% ```
	%% 输入参数
	% Value，管线起始值
	% Operation1,Operation2,Operation3,…，管线操作，支持以下类型参数：
	% - function_handle，此函数句柄必须支持仅输入一个参数的语法，将把上一个管线操作的唯一输出值作为此函数句柄的输入参数。
	% - (1,:)cell，此元胞数组的首个元素必须是function_handle，此函数句柄必须接受上一个管线操作的唯一输出值作为第1个输入参数，接受元胞数组的后续其它元素依次作为后续输
	%  入参数
	%% 返回值
	% PipeEnd(1,1)Pipeline，包装最后一个管线操作的唯一输出值。使用Value属性获取包装内的值。如果不获取输出值，则管线操作序列中的最后一个操作函数句柄可以不返回值。
	properties(SetAccess=immutable)
		%包装的值。通过此属性从管线末端取出计算结果。
		Value
	end
	methods
		function obj = Pipeline(Value)
			%将一个值包装起来作为管线起始，以支持后续管线运算。
			obj.Value=Value;
		end
		function varargout=or(obj,Operation)
			%管线运算符实现
			import MATLAB.Ops.Pipeline
			try
				if iscell(Operation)
					varargout={MATLAB.Ops.Pipeline(Operation{1}(obj.Value,Operation{2:end}))};
				else
					varargout={MATLAB.Ops.Pipeline(Operation(obj.Value))};
				end
			catch ME
				if ME.identifier=="MATLAB:maxlhs"&&~nargout
					if iscell(Operation)
						Operation{1}(obj.Value,Operation{2:end});
					else
						Operation(obj.Value)
					end
				else
					ME.rethrow;
				end
			end
		end
	end
end
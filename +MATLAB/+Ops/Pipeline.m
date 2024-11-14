classdef Pipeline
	%实现管线|运算符
	%此类型是一个包装值类型，包装后可以支持or（|）运算符作为管线运算符，以对特定数据依次调用一连串函数
	%% 语法
	% ```
	% %先构造管线对象，然后不断连接各种操作
	% PipeEnd=MATLAB.Ops.Pipeline(Value)|Operation1|Operation2|Operation3|…|{};
	%
	% %可以直接用管线运算符将任意对象包入管线对象
	% PipeEnd=Value|MATLAB.Ops.Pipeline|Operation1|Operation2|Operation3|…|{};
	%
	% %不返回运算结果，而是将其交给某个终端消费函数
	% Value|MATLAB.Ops.Pipeline|Operation1|Operation2|Operation3|…|OperationEnd;
	%
	% %将运算结果设为某个当前工作区的变量名
	% Value|MATLAB.Ops.Pipeline|Operation1|Operation2|Operation3|…|VariableName;
	% ```
	%% 示例
	% ```
	% import MATLAB.Ops.Pipeline
	%
	% RandSum=MATLAB.Ops.Pipeline(4)|@rand|{@sum,'all'}|{}
	% %求随机4阶方阵的总和
	%
	% 4|MATLAB.Ops.Pipeline|@rand|{@sum,'all'}|@disp
	% %求随机4阶方阵的总和并显示在命令行窗口中}|{}
	%
	% 4|MATLAB.Ops.Pipeline|@rand|{@sum,'all'}|'RandSum'
	% %求随机4阶方阵的总和并赋值给变量RandSum
	% ```
	%% 输入参数
	% Value，管线起始值
	% Operation1,Operation2,Operation3,…,OperationEnd，管线操作，支持以下类型参数：
	% - function_handle，此函数句柄必须支持仅输入一个参数的语法，将把上一个管线操作的第一个输出值作为此函数句柄的输入参数。
	% - (1,:)cell，此元胞数组的首个元素必须是function_handle，此函数句柄必须接受上一个管线操作的唯一输出值作为第1个输入参数，接受元胞数组的后续其它元素依次作为后续输
	%  入参数。特别地，OperationEnd可以为空，此时直接返回计算结果值
	% VariableName(1,1)string，要赋值的变量名。可以放在管线末端，输出值将被赋给具有该名称的工作区变量。这个工作区是调用管线运算符的工作区。
	%% 返回值
	% PipeEnd，包装最后一个管线操作（空元胞之前的最后一个）的唯一输出值。如果不获取输出值，则管线操作序列中的最后一个操作函数句柄可以不返回值。
	properties(SetAccess=immutable)
		%包装的值。通过此属性从管线末端取出计算结果。
		Value
	end
	methods
		function obj = Pipeline(Value)
			%将一个值包装起来作为管线起始，以支持后续管线运算。
			if nargin
				obj.Value=Value;
			end
		end
		function varargout=or(obj,Operation)
			%管线运算符实现
			import MATLAB.Ops.Pipeline
			if isempty(Operation)
				varargout={obj.Value};
			elseif isa(Operation,'MATLAB.Ops.Pipeline')
				varargout={Pipeline(obj)};
			elseif isvarname(Operation)
				assignin('caller',Operation,obj.Value);
			else
				try
					if iscell(Operation)
						varargout={Pipeline(Operation{1}(obj.Value,Operation{2:end}))};
					else
						varargout={Pipeline(Operation(obj.Value))};
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
end
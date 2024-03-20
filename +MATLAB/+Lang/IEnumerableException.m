classdef IEnumerableException
	%可枚举异常，提供一种方便的异常接口类
	%本类是接口类，使用者必须定义自己的实体类，继承本类。最推荐的方法是用一个枚举类继承本类，实现方便的Throw方法：
	%```
	%classdef MyException<MATLAB.Lang.IEnumerableException
	%	enumeration
	%		File_open_failed
	%		Memory_mapping_failed
	%		File_contains_no_blocks
	%		%… And so on, list all your custom exceptions
	%	end
	%end
	%```
	%如上例，定义异常枚举类MyException。抛出异常时，直接对枚举使用继承的Throw成员方法：
	%```
	%>> MyException.File_open_failed.Throw
	%MyException:File_open_failed
	%```
	%本接口类不定义任何属性，因此您的枚举类还可以继承自基本数据类型，实现错误代码，如：
	%```
	%classdef MyException<uint8&MATLAB.Lang.IEnumerableException
	%	%对基本数据类型的继承必须放在前面
	%	enumeration
	%		File_open_failed(0)
	%		Memory_mapping_failed(1)
	%		File_contains_no_blocks(2)
	%		%… And so on, list all your custom exceptions
	%	end
	%end
	%```
	%然后就可以将错误代码解释为异常抛出：
	%```
	%>> MyException(1).Throw('内存映射失败');
	%MyException:Memory_mapping_failed：内存映射失败
	%```
	%此外，还支持将异常当作警告抛出，详见MATLAB.Lang.IEnumerableException.Warn
	%See also MATLAB.Lang.IEnumerableException.Warn
	methods
		function Throw(obj,Message,options)
			%抛出异常，可选指定更多详细信息
			%此方法抛出的异常被捕获为MATLAB.Lang.MException而不是内置MException。MATLAB.Lang.MException是对内置MException的扩展，支持额外的Detail属性以包含更多错误相关详细信息。
			%# 语法
			% ```
			% obj.Throw;
			% %抛出异常，只显示异常类名和标识符
			%
			% obj.Throw(Message);
			% %抛出异常，额外显示文字说明
			%
			% obj.Throw(___,Detail=Detail);
			% %包含额外的异常追溯信息，可以与上述任意语法结合使用
			% ```
			%# 输入参数
			% Message(1,1)，错误相关的文字说明。如果此输入不是字符串，会自动转换成字符串。
			% Detail，错误的其它详细信息，作为抛出MATLAB.Lang.MException的Detail属性值
			%See also MATLAB.Lang.MException
			arguments
				obj
				Message=missing
				options.Detail=obj
			end
			%标识符不能含有.号
			Identifier=replace(sprintf('%s:%s',class(obj),obj),'.',':');
			if isequaln(Message,missing)
				MATLAB.Lang.MException(Identifier=Identifier,Message=Identifier,Detail=options.Detail).throwAsCaller;
			else
				MATLAB.Lang.MException(Identifier=Identifier,Message=sprintf('%s：%s',Identifier,AnyToText(Message)),Detail=options.Detail).throwAsCaller;
			end
		end
		function Warn(obj,varargin)
			%将异常当作警告抛出
			%# 语法
			% ```
			% obj.Warn;
			% %简单抛出警告，只显示标识符
			%
			% obj.Warn(Message);
			% %额外指定警告信息字符串
			%
			% obj.Warn(___,BackTrace);
			% %与上述任意语法组合使用，额外指定是否显示堆栈跟踪
			% ```
			%# 输入参数
			% Message(1,1)，要显示的消息字符串，将接在标识符后面。如果此输入不是字符串，将自动转换为字符串。
			% BackTrace(1,1)logical，是否显示堆栈跟踪。如果不指定此参数，将使用MATLAB当前默认值。使用内置`warning query backtrace`命令查看当前默认值。
			%See also warning
			Identifier=replace(sprintf('%s:%s',class(obj),obj),'.',':');
			Message=Identifier;
			BackTrace=missing;
			for V=1:numel(varargin)
				if islogical(varargin{V})
					BackTrace=varargin{V};
				else
					Message=sprintf('%s：%s',Message,AnyToText(varargin{V}));
				end
			end
			HasBackTrace=~ismissing(BackTrace);
			if HasBackTrace
				State=warning('query','backtrace').state;
				if BackTrace
					warning('on','backtrace');
				else
					warning('off','backtrace');
				end
			end
			warning(Identifier,Message);
			if HasBackTrace
				warning(State,'backtrace');
			end
		end
		function Assert(obj,Condition,varargin)
			%断言条件，如果为false就抛出异常
			%# 语法
			% ```
			% obj.Assert(Condition);
			% %如果条件为false就抛出异常，否则什么都不做
			%
			% obj.Assert(Condition,Message);
			% %额外指定抛出异常时显示的消息
			%
			% obj.Assert(___,Detail=Detail);
			% %与上述任意语法组合使用，抛出额外的附加信息
			% ```
			%# 输入参数
			% Condition(1,1)logical，断言条件，为false时抛出异常
			% Message(1,1)，错误相关的文字消息。如果此输入不是字符串，将自动转换为字符串。
			% ## 名称值参数
			%  Detail，错误的其它详细信息，作为抛出MATLAB.Lang.MException的Detail属性值
			%See also MATLAB.Lang.IEnumerableException.Throw
			if(~Condition)
				obj.Throw(varargin{:});
			end
		end
	end
end
function Text=AnyToText(Text)
Text=formattedDisplayText(Text);
if contains(Text,newline)
	Text=newline+Text;
end
end
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
	%错误使用 MATLAB.Lang.IEnumerableException/Throw
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
	%错误使用 MATLAB.Lang.IEnumerableException/Throw
	%MyException:Memory_mapping_failed：内存映射失败
	%```
	methods
		function Throw(obj,Message)
			%抛出异常，可选指定更多详细信息
			%# 语法
			% ```
			% obj.Throw;
			% %抛出异常，只显示异常类名和标识符
			%
			% obj.Throw(Message);
			% %抛出异常，额外显示文字说明
			% ```
			%# 输入参数
			% Message(1,1)string，错误相关的文字说明
			Identifier=sprintf('%s:%s',class(obj),obj);
			if nargin>1
				error(Identifier,'%s：%s',Identifier,Message);
			else
				error(Identifier,Identifier);
			end
		end
	end
end
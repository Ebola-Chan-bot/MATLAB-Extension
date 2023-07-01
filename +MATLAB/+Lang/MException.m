classdef MException<MException
	%内置MException的扩展，支持更灵活的构造和额外的Detail属性
	%See also MException
	properties
		%异常的其它详细信息
		Detail
	end
	methods
		function obj=MException(options)
			%使用全员可选的名称值参数构造对象
			%# 语法
			%```
			% obj=MATLAB.MException(Name=Value);
			%```
			%# 名称值参数
			% Detail，异常的其它详细信息
			% Identifier(1,1)string=''，错误的唯一标识符
			% Message(1,1)string=''，错误消息
			% Causes(1,:)MException，异常的其他原因
			% Correction(1,1)matlab.lang.correction.Correction，异常的建议修复
			%# 提示
			% 除Detail外，其它名称值参数的意义与内置MException的同名属性相同。
			%See also MException
			arguments
				options.Detail
				options.Identifier=''
				options.Message=''
				options.Causes(1,:)
				options.Correction
			end
			obj@MException(options.Identifier,'%s',options.Message);
			HasNames=num2cell(ismember(["Detail","Causes","Correction"],fieldnames(options)));
			[HasDetail,HasCauses,HasCorrection]=HasNames{:};
			if HasDetail
				obj.Detail=options.Detail;
			end
			if HasCauses
				for C=options.Causes
					obj.addCause(C);
				end
			end
			if HasCorrection
				obj.addCorrection(options.Correction);
			end
		end
	end
end
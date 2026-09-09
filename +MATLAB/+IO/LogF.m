%[text] 向文件ID输出一行日志。
%[text] 此函数语法类似于fprintf，不同之处在于：
%[text] - 必须指定文件ID。但可以指定为0，此时不做任何事，而不会出错。
%[text] - 实际输出到文件的文本，除了输入内容外，还会被前缀日期时间，后缀'\\n'。 \
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.IO.LogF(FileID,Format,Argument1,Argument2,…);
%[text] ```
%[text] ## 输入参数
%[text] FileID(1,1)double，文件ID，使用fopen获取。可以设为0，此时不做任何事，不会出错。
%[text] Format(1,:)char，格式字符向量，与内置fprintf相同。
%[text] Argument1,Argument2,…，格式参数，与内置fprintf相同。
%[text] **See also** [fprintf](<matlab:doc fprintf>) [fopen](<matlab:doc fopen>)
function LogF(FileID,Format,varargin)
if FileID
	fprintf(FileID,"%s "+Format+"\n",datetime,varargin{:});
end
end

%[appendix]{"version":"1.0"}
%---

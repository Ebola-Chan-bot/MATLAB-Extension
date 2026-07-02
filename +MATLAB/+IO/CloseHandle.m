%[text] 关闭指定进程ID的指定句柄
%[text] 通常使用FindLocking查询占用文件的句柄，然后用此函数关闭句柄而无需结束那个进程。但是，对那个进程来说句柄被意外关闭可能造成未知影响。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.IO.CloseHandle(Handle,ProcessId);
%[text] ```
%[text] ## 输入参数
%[text] Handle(:,1)uint64，要关闭的句柄
%[text] ProcessId(:,1)uint32，要关闭句柄的进程ID，与Handle一一对应
%[text] **See also** [MATLAB.IO.FindLocking](<matlab:doc MATLAB.IO.FindLocking>)
function CloseHandle(Handle,ProcessId)
arguments
	Handle uint64
	ProcessId uint32
end
MATLAB.internal.WindowsAPI.IO_CloseHandle(Handle,ProcessId);
end

%[appendix]{"version":"1.0"}
%---

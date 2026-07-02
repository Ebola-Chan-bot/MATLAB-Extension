%[text] 查找占用指定文件的进程和句柄。
%[text] 你可以根据进程PID，通过任务管理器或其它方式获取进程相关信息，然后决定是否要解除占用。使用CloseHandle可以在不直接结束进程的情况下解除文件占用。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [Handle,ProcessId]=MATLAB.IO.FindLocking(FilePath)
%[text] ```
%[text] ## 输入参数
%[text] FilePath(1,1)string，文件路径
%[text] ## 返回值
%[text] Handle(:,1)uint64，占用该文件的所有句柄
%[text] ProcessId(:,1)uint32，占用该文件的进程ID，与Handle一一对应
%[text] **See also** [MATLAB.IO.CloseHandle](<matlab:doc MATLAB.IO.CloseHandle>)
function [Handle,ProcessId]=FindLocking(FilePath)
[Handle,ProcessId]=MATLAB.internal.WindowsAPI.IO_FindLocking(FilePath);
end

%[appendix]{"version":"1.0"}
%---

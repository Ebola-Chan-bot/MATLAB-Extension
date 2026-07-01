%[text] 查找占用指定文件的进程和句柄
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] LockTable=MATLAB.IO.FindLocking(FilePath)
%[text] ```
%[text] ## 输入参数
%[text] FilePath(1,1)string，文件路径
%[text] ## 返回值
%[text] LockTable(:,2)table，占用该文件的进程和句柄列表，包含以下列：
%[text] - Handle(1,1)uint32，文件句柄
%[text] - ProcessId(1,1)uint32，进程ID \
function LockTable=FindLocking(FilePath)
LockTable=MATLAB.internal.WindowsAPI.IO_FindLocking()
end

%[appendix]{"version":"1.0"}
%---

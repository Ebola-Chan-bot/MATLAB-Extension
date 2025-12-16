%[text] 暂停执行MATLAB，不可中止
%[text] 此方法基本同内置pause，但无法用暂停、停止等命令按钮或Ctrl+C中止暂停，只能强制结束线程/进程。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.Pause;
%[text] %永久挂起当前线程
%[text] 
%[text] MATLAB.Pause(Seconds);
%[text] %挂起线程指定秒数
%[text] ```
%[text] ## 输入参数
%[text] Seconds(1,1)double=Inf，要挂起的秒数
%[text] **See also** [pause](<matlab:doc pause>) [Inf](<matlab:doc Inf>)
function Pause(varargin)
%命名空间：TimeFun
MATLAB.internal.WindowsAPI.Pause.Call(varargin{:});

%[appendix]{"version":"1.0"}
%---

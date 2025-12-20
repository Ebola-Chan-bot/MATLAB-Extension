%[text] 抢夺被占用的串口
%[text] 内置serialport遇到串口被其它进程占用的情况时就会报错。遇到这种情况，传统地，需要用户手动查找占用串口的进程并结束之。如果找不到那个进程，就只能重启。但使用此函数，就可以直接从先占进程手中抢夺串口，而不需要结束那个进程，但需要管理员权限。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [SP,PID]=MATLAB.SnatchSerialport(Port,Baudrate,Name=Value);
%[text] ```
%[text] ## 输入参数
%[text] 此函数输入参数与内置serialport相同，请直接查看内置函数文档
%[text] ## 返回值
%[text] SP internal.Serialport，抢夺到的串口对象。如果抢夺失败，返回空值
%[text] PID(1,1)uint32，之前占用串口的进程ID。如果串口未被先占，返回0
%[text] **See also** [serialport](<matlab:doc serialport>)
function [SP,PID] = SnatchSerialport(Port,Baudrate,NameValues)
%命名空间：SerialPort
arguments
	Port
	Baudrate
end
arguments(Repeating)
	NameValues
end
try
	SP=serialport(Port,Baudrate,NameValues{:});
catch ME
	if ME.identifier=="serialport:serialport:ConnectionFailed"
		PID=MATLAB.internal.WindowsAPI.Serialport_snatch.Call(Port);
		SP=serialport(Port,Baudrate,NameValues{:});
		return;
	end
end
PID=0;

%[appendix]{"version":"1.0"}
%---

%[text] 为MATLAB安装补丁，修复已知bug
%[text] MATLAB存在一些一直未有修复，并且种种原因导致可能永远不会修复的bug。本函数收集这些bug并尝试修复。一旦完成修复，补丁将不再依赖工具箱的存在，计算机上所有用户都能享受此修复。即使卸载工具箱，补丁依然有效，只有使用本函数的负数语法才能还原。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] import MATLAB.Lang.BuiltinBugFix
%[text] 
%[text] BugList=BuiltinBugFix
%[text] %列出所有可修复的bug
%[text] 
%[text] BuiltinBugFix(Command);
%[text] %修复/还原指定序号的bug
%[text] 
%[text] BuiltinBugFix(Command,RestartDisposition);
%[text] %额外指定修复后是否重启MATLAB
%[text] ```
%[text] ## 输入参数
%[text] Command(1,:)=0，要修复/还原的bug序号。如果指定为正数，将修复指定序号的bug。如果指定为0，将列出所有可修复的bug，其排列顺序就是序号。如果指定为负数，将还原指定序号的bug。
%[text] RestartDisposition(1,1)MATLAB.Flags=MATLAB.Flags.Inquire，修复后是否重启MATLAB。重启后修复才能生效。详见Flags代码文件。
%[text] ## 返回值
%[text] BugList(:,1)string，列出所有可修复的bug
%[text] **See also** [MATLAB.Flags](<matlab:edit MATLAB.Flags>)
function BugList = BuiltinBugFix(Command,RestartDisposition)
arguments
	Command(1,:)int8=0
	RestartDisposition=MATLAB.Flags.Inquire
end
persistent BugListCache
if isempty(BugListCache)
	switch ver('MATLAB').Version
		case '23.2'
			BugListCache=[
				"doc无法正确显示包内类下成员实时函数"
				"doc无法打开多个帮助窗口"
				"edit无法打开含有非ASCII字符的主机名SMB共享的.m代码文件"
				"打包为工具箱时访问美国服务器失败，也不尝试中国CDN"
				"doc无法找到MATLAB包下和内置函数只有大小写不同的函数"
				];
		case '24.1'
			BugListCache=[
				"doc无法正确显示命名空间下的实时函数"
				"doc无法打开多个帮助窗口"
				"edit无法打开含有非ASCII字符的主机名SMB共享的.m代码文件"
				"打包为工具箱时访问美国服务器失败，也不尝试中国CDN"
				];
		case '24.2'
			BugListCache=[
				"doc无法打开多个帮助窗口"
				"edit无法打开含有非ASCII字符的主机名SMB共享的.m代码文件"
				"打包为工具箱时访问美国服务器失败，也不尝试中国CDN"
				];
		case '25.1'
			BugListCache=[
				"doc无法打开多个帮助窗口"
				"打包为工具箱时访问美国服务器失败，也不尝试中国CDN"
				"打包工具箱时，如果依赖其它 File Exchange 附加功能，将会失败"
				];
        case '25.2'
			BugListCache=[
				"doc无法打开多个帮助窗口"
				"打包为工具箱时访问美国服务器失败，也不尝试中国CDN"
				"打包工具箱时，如果依赖其它 File Exchange 附加功能，将会失败"
				];
		otherwise
			MATLAB.Exception.Current_MATLAB_version_not_supported.Throw;
	end
end
if isequal(Command,0)
	BugList=BugListCache;
else
	Logical=uint8(abs(Command))>numel(BugListCache);
	if any(Logical)
		MATLAB.Exception.Unexpected_patch_number.Throw(Command(Logical));
	end
	MATLAB.internal.WindowsAPI.Builtin_bug_fix.Call(Command);
	switch RestartDisposition
		case MATLAB.Flags.Inquire
			if questdlg('必须重启MATLAB才能应用更改','立即重启？','是','否','是')=="是"
				!matlab &
				quit
			end
		case MATLAB.Flags.Restart_now
			!matlab &
			quit
		case MATLAB.Flags.Do_not_restart
		otherwise
			MATLAB.Exception.Invalid_RestartDisposition.Throw;
	end
end

%[appendix]{"version":"1.0"}
%---

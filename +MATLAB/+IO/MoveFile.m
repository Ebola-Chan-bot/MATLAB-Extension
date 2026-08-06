%[text] 调用 Win32 ShellAPI 执行可撤销的批量文件移动
%[text] 不同于内置movefile，本函数执行后可以在Windows文件资源管理器上下文菜单中撤销操作（被覆盖的文件无法恢复）。此外，源和目标都可以是字符串数组，以便执行批量移动操作，不需要具有相似的文件名模式。通配符也同样支持。
%[text] 操作过程中出现文件已存在、目录不存在等异常，都可以手动确认操作，与Windows文件资源管理器深度整合。
%[text] 不支持内置movefile的f旗帜。
%[text] ## 输入参数
%[text] Source(:,1)string，源路径，可以是多个文件、目录的混合，也可以使用通配符
%[text] Destination(:,1)string，目标路径，可以是多个文件、目录的混合。如果有多个目标路径，数目必须和源路径相同，一一对应。**不**可以使用通配符。
%[text] ## 返回值
%[text] AnyOperationCanceled(1,1)logical，指示用户是否在UI中手动取消了操作。
%[text] **See also** [movefile](<matlab:doc movefile>)
function AnyOperationCanceled = MoveFile(Source,Destination)
AnyOperationCanceled=MATLAB.internal.WindowsAPI.SHFile_Move(Source,Destination);

%[appendix]{"version":"1.0"}
%---

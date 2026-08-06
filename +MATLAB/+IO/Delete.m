%[text] 调用 Win32 ShellAPI 执行可撤销的批量文件、目录删除
%[text] 不同于内置delete，本函数执行后可以在Windows文件资源管理器上下文菜单中撤销操作（移动到回收站）。此外，删除目标可以是字符串向量，以便执行批量删除操作，不需要具有相似的文件名模式。通配符也同样支持。此外，本函数还支持删除整个非空目录，可替代rmdir。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.IO.Delete(Paths);
%[text] %删除一个或多个文件或目录，将其移动到回收站
%[text] 
%[text] MATLAB.IO.Delete(Paths,MATLAB.Flags.FOF_NOCONFIRMATION)
%[text] %额外规定，删除过程中出现的所有确认对话框，都以“是”进行响应。注意，这可能导致较大的文件/目录被静默地永久删除，无法撤销。
%[text] ```
%[text] ## 输入参数
%[text] Paths(:,1)string，要删除的所有文件、目录路径。可以是绝对路径或相对路径，并且可以包含通配符 (\*)。
%[text] Flags(1,1)MATLAB.Flags，额外指定的旗帜选项，详见MATLAB.Flags枚举类代码文件的Delete节。只允许指定FOF\_NOCONFIRMATION，指定其它值将导致意外结果。注意，较大的文件/目录被删除时可能无法移动到回收站，默认会提示确认，但指定此旗帜后将不会确认直接永久删除。
%[text] ## 返回值
%[text] AnyOperationCanceled(1,1)logical，指示用户是否在UI中手动取消了操作。
%[text] **See also** [delete](<matlab:doc delete>) [rmdir](<matlab:doc rmdir>) [MATLAB.Flags](<matlab:edit MATLAB.Flags>)
function AnyOperationCanceled=Delete(Paths,Flags)
arguments
	Paths
	Flags(1,1)MATLAB.Flags=0
end
AnyOperationCanceled=MATLAB.internal.WindowsAPI.SHFile_Delete(Paths,uint32(Flags));

%[appendix]{"version":"1.0"}
%---

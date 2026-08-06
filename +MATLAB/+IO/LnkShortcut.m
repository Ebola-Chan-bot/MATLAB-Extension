%[text] 创建 Windows lnk 快捷方式
%[text] 此方法不同于内置createSymbolicLink，创建的是Windows特定的LNK快捷方式文件，不是符号链接，也不需要管理员权限。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.IO.LnkShortcut(From,To);
%[text] %为From指定的文件或目录创建快捷方式，保存到To路径
%[text] 
%[text] MATLAB.IO.LnkShortcut(From);
%[text] %可以省略To，在当前工作目录下保存快捷方式文件，文件名与From相同，扩展名lnk
%[text] ```
%[text] ## 输入参数
%[text] From(1,1)string，要创建快捷方式的文件或目录路径。不会检查指向的文件或目录是否存在，即使不存在也不会出错，将创建一个无效的快捷方式。
%[text] To(1,1)string，快捷方式保存到的路径。如果是已存在的目录，则在目录下创建与From同名的lnk快捷方式，否则将路径解释为文件路径，如果不以.lnk结尾则自动添加.lnk扩展名。
%[text] **See also** [createSymbolicLink](<matlab:doc createSymbolicLink>)
function LnkShortcut(varargin)
MATLAB.internal.WindowsAPI.LnkShortcut(varargin{:});

%[appendix]{"version":"1.0"}
%---

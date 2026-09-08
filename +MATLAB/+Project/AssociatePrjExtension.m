%[text] 为Windows添加.prj文件扩展名关联
%[text] 添加关联后，可以在Windows文件资源管理器中双击打开.prj工程文件
function AssociatePrjExtension
MATLAB.internal.WindowsAPI.Associate_prj_extension();

%[appendix]{"version":"1.0"}
%---

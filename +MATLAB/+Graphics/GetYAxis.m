%[text] 获取图形对象隶属的Y轴
%[text] 此函数通常在使用yyaxis的双Y轴坐标区中使用，输入图形对象即可查询其所属的Y轴。但是，此函数实际上利用自动调整范围的特性试探性实现功能，性能较低，最佳的做法还是在作图时就记录好每个对象的所属Y轴。此函数仅用于最佳做法不可行时的补充。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] YAxis=MATLAB.Graphics.GetYAxis(GObject);
%[text] ```
%[text] ## 输入参数
%[text] GObject(1,1)matlab.graphics.Graphics，要查询的图形对象
%[text] ## 返回值
%[text] YAxis(1,1)matlab.graphics.Graphics，输入对象所属的Y轴
function YAxis=GetYAxis(GObject)
Ax=GObject.Parent; % 获取图形对象的坐标区
Ax.
end

%[appendix]{"version":"1.0"}
%---

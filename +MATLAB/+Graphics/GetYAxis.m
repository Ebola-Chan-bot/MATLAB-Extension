%[text] 获取图形对象隶属的Y轴
%[text] MATLAB官方文档未曾描述过此获取方法，感谢[网友的智慧](https://ww2.mathworks.cn/matlabcentral/cody/problems/60989-which-yaxis-does-this-graphic-object-belong-to/solutions/14723411)
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] YAxis=MATLAB.Graphics.GetYAxis(GObject);
%[text] ```
%[text] ## 输入参数
%[text] GObject(1,1)matlab.graphics.Graphics，要查询的图形对象
%[text] ## 返回值
%[text] YAxis(1,1)matlab.graphics.Graphics，输入对象所属的Y轴
function YAxis=GetYAxis(GObject)
Ax=GObject.Parent;
if isscalar(Ax.YAxis)
	YAxis=Ax.YAxis;
else
	Location=Ax.YAxisLocation;
	yyaxis(Ax,'right');
	YAxis=Ax.YAxis(1+any(Ax.Children==GObject));
	yyaxis(Ax,Location);
end
end

%[appendix]{"version":"1.0"}
%---

%[text] 获取图形对象隶属的Y轴
%[text] MATLAB官方文档未曾描述过此获取方法，感谢[网友的智慧](https://ww2.mathworks.cn/matlabcentral/cody/problems/60989-which-yaxis-does-this-graphic-object-belong-to/solutions/14723411)
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] YAxis=MATLAB.Graphics.GetYAxis(GObjects);
%[text] ```
%[text] ## 输入参数
%[text] GObjects matlab.graphics.Graphics，要查询的图形对象。如果输入多个，必须属于同一个坐标区。
%[text] ## 返回值
%[text] YAxis matlab.graphics.Graphics，输入对象所属的Y轴
function YAxis=GetYAxis(GObjects)
Ax=GObjects(1).Parent;
ReturnSize=size(GObjects);
if isscalar(Ax.YAxis)
	YAxis=repmat(Ax.YAxis,ReturnSize);
else
	Location=Ax.YAxisLocation;
	yyaxis(Ax,'right');
	YAxis=reshape(Ax.YAxis(1+ismember(GObjects,Ax.Children)),ReturnSize);
	yyaxis(Ax,Location);
end
end

%[appendix]{"version":"1.0"}
%---

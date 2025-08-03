%[text] 统一各坐标区的XYZC轴范围
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.Graphics.UnifyAxesLims(Axes);
%[text] %统一所有输入坐标区的XYZC轴范围
%[text] 
%[text] [Lim1,Lim2,…]=MATLAB.Graphics.UnifyAxesLims(Axes,Lim1,Lim2,…);
%[text] %仅统一坐标区的指定轴范围，返回最终统一到的范围
%[text] ```
%[text] ## 输入参数
%[text] Axes matlab.graphics.axis.Axes，要统一轴范围的坐标区，至少输入2个。
%[text] Lim1,Lim2,…(1,1)function\_handle，周范围设置函数句柄，可选 @xlim @ylim @zlim @clim 的任意组合
%[text] ## 返回值
%[text] Lim1,Lim2,…(1,2)double，各输入轴最终设置的范围值下限和上限
%[text] **See also** [xlim](<matlab:doc xlim>) [ylim](<matlab:doc ylim>) [zlim](<matlab:doc zlim>) [clim](<matlab:doc clim>)
function varargout=UnifyAxesLims(Axes,varargin)
NumLims=numel(varargin);
if ~NumLims
	varargin={@xlim,@ylim,@zlim,@clim};
	NumLims=4;
end
%不同轴可能是不同的单位，不能合并
if numel(Axes)<2
	MATLAB.Exception.A_minimum_of_2_Axes_is_required.Throw;
end
varargout=cell(1,NumLims);
for L=1:NumLims
	LimValues=varargin{L}(Axes);
	LimValues=vertcat(LimValues{:});
	varargout{L}=[min(LimValues(:,1)),max(LimValues(:,2))];
	varargin{L}(Axes,varargout{L});
end

%[appendix]{"version":"1.0"}
%---

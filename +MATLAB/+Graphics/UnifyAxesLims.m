%[text] 统一各坐标区的ACXYZ轴范围
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.Graphics.UnifyAxesLims(Axes);
%[text] %统一所有输入坐标区的ACXYZ轴范围
%[text] 
%[text] MATLAB.Graphics.UnifyAxesLims(Axes,BoundOrRange);
%[text] %额外指定要完美统一上下界，还是只统一上下界的差值
%[text] 
%[text] [Lim1,Lim2,…]=MATLAB.Graphics.UnifyAxesLims(Axes,Lim1,Lim2,…);
%[text] %仅统一坐标区的指定轴范围，返回最终统一到的范围
%[text] ```
%[text] ## 输入参数
%[text] Axes matlab.graphics.axis.Axes，要统一轴范围的坐标区，至少输入2个。
%[text] BoundOrRange(1,1)MATLAB.Flags=MATLAB.Flags.Bound，二选一：
%[text] - Bound，统一具体的上下界值
%[text] - Range，只统一上下界差值，使得图形尺度可比 \
%[text] Lim1,Lim2,…(1,1)function\_handle，轴范围设置函数句柄，可选 @alim @clim @xlim @ylim @zlim 的任意组合。所有要统一的坐标轴必须具有相同的类型，但不支持matlab.graphics.axis.decorator.CategoricalRuler类型。如果输入包含@ylim，所有输入的坐标区必须具有相同数目的Y轴。
%[text] ## 返回值
%[text] Lim1,Lim2,…(1:2,2,:)，返回各输入Lim最终设置的范围值下限和上限。第1维是两个Y轴（如有），第2维是下限和上限，第3维（如有）是坐标区
%[text:table]{"ignoreHeader":true}
%[text] | <p align="center">返回张量尺寸，注意@ylim可能有2个</p> | <p align="center">@ylim且坐标区有2个Y轴</p> | <p align="center">其它Lim</p> |
%[text] | --- | --- | --- |
%[text] | <p align="center">Bound，此时所有坐标区上下限相同</p> | <p align="center">(2,2)</p> | <p align="center">(1,2)</p> |
%[text] | <p align="center">Range，此时各坐标区上下限可能不同</p> | <p align="center">(2,2,:)</p> | <p align="center">(1,2,:)</p> |
%[text:table]
%[text] **See also** [alim](<matlab:doc alim>) [clim](<matlab:doc clim>) [xlim](<matlab:doc xlim>) [ylim](<matlab:doc ylim>) [zlim](<matlab:doc zlim>) [yyaxis](<matlab:doc yyaxis>) [matlab.graphics.axis.decorator.CategoricalRuler](<matlab:doc matlab.graphics.axis.decorator.CategoricalRuler>)
function varargout=UnifyAxesLims(Axes,varargin)
if numel(Axes)<2
	MATLAB.Exception.Nonsense_to_unify_a_single_axe.Throw;
end
if isempty(varargin)||isa(varargin{1},'function_handle')
	BoundOrRange=MATLAB.Flags.Bound;
else
	BoundOrRange=varargin{1};
	varargin(1)=[];
end
if isempty(varargin)
	varargin={@alim,@clim,@xlim,@ylim,@zlim};
end
switch BoundOrRange
	case MATLAB.Flags.Bound
		LimitsFh={@BoundLimits,@BoundY};
	case MATLAB.Flags.Range
		LimitsFh={@RangeLimits,@RangeY};
	otherwise
		MATLAB.Exception.Unexpected_enumeration.Throw(BoundOrRange);
end
varargout=cellfun(@(LimFun)LimitsFh{isequal(LimFun,@ylim)+1}(Axes,LimFun),varargin,UniformOutput=false);
end
function Limits=YAxesLimits(Axes)
try
	Limits=[Axes.YAxis];
catch ME
	if ME.identifier=="MATLAB:catenate:dimensionMismatch"
		MATLAB.Exception.Axes_have_different_YAxis.Throw;
	else
		ME.rethrow;
	end
end
Limits=reshape(vertcat(Limits.Limits),[],numel(Axes),2);
end
function Limits=BoundY(Axes,~)
Limits=YAxesLimits(Axes);
Limits=[min(Limits(:,:,1),[],2),max(Limits(:,:,2),[],2)];
for A=1:numel(Axes)
	for Y=1:height(Limits)
		Axes(A).YAxis(Y).Limits=Limits(Y,:);
	end
end
end
function Limits=RangeY(Axes,~)
Limits=YAxesLimits(Axes);
Radius=max(Limits(:,:,2)-Limits(:,:,1),[],2)/2;
Center=mean(Limits,3);
Limits=cat(3,Center-Radius,Center+Radius);
for A=1:numel(Axes)
	for Y=1:height(Limits)
		Axes(A).YAxis(Y).Limits=Limits(Y,A,:);
	end
end
end
function Limits=BoundLimits(Axes,LimFun)
Limits=LimFun(Axes);
Limits=vertcat(Limits{:});
Limits=[min(Limits(:,1)),max(Limits(:,2))];
LimFun(Axes,Limits);
end
function Limits=RangeLimits(Axes,LimFun)
Limits=LimFun(Axes);
Limits=vertcat(Limits{:});
Center=mean(Limits,2);
Radius=max(Limits(:,2)-Limits(:,1))/2;
Limits=[Center-Radius,Center+Radius];
LimFun(Axes,Limits);
end

%[appendix]{"version":"1.0"}
%---

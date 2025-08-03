%[text] 统一各坐标区的ACXYZ轴范围
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.Graphics.UnifyAxesLims(Axes);
%[text] %统一所有输入坐标区的ACXYZ轴范围
%[text] 
%[text] [Lim1,Lim2,…]=MATLAB.Graphics.UnifyAxesLims(Axes,Lim1,Lim2,…);
%[text] %仅统一坐标区的指定轴范围，返回最终统一到的范围
%[text] ```
%[text] ## 输入参数
%[text] Axes matlab.graphics.axis.Axes，要统一轴范围的坐标区，至少输入2个。
%[text] Lim1,Lim2,…(1,1)function\_handle，轴范围设置函数句柄，可选 @alim @clim @xlim @ylim @zlim 的任意组合。所有要统一的坐标轴必须具有相同的类型，但不支持matlab.graphics.axis.decorator.CategoricalRuler类型。如果输入包含@ylim，所有输入的坐标区必须具有相同数目的Y轴。
%[text] ## 返回值
%[text] Lim1,Lim2,…(1:2,2)，各输入轴最终设置的范围值下限和上限。如果指定了@ylim且坐标区有2个Y轴，那个对应位置将返回(2,2)矩阵；其它情况均返回(1,2)。
%[text] **See also** [alim](<matlab:doc alim>) [clim](<matlab:doc clim>) [xlim](<matlab:doc xlim>) [ylim](<matlab:doc ylim>) [zlim](<matlab:doc zlim>) [yyaxis](<matlab:doc yyaxis>) [matlab.graphics.axis.decorator.CategoricalRuler](<matlab:doc matlab.graphics.axis.decorator.CategoricalRuler>)
function varargout=UnifyAxesLims(Axes,varargin)
NumLims=numel(varargin);
if ~NumLims
	varargin={@alim,@clim,@xlim,@ylim,@zlim};
	NumLims=5;
end
%不同轴可能是不同的单位，不能合并
NumAxes=numel(Axes);
if NumAxes<2
	MATLAB.Exception.A_minimum_of_2_Axes_is_required.Throw;
end
varargout=cell(1,NumLims);
for L=1:NumLims
	LimFun=varargin{L};
	if LimFun==@ylim
		Limits=[Axes.YAxis];
		Limits=reshape(vertcat(Limits.Limits),[],NumAxes,2);
		Limits=[min(Limits(:,:,1),[],2),max(Limits(:,:,2),[],2)];
		for A=1:NumAxes
			for Y=1:height(Limits)
				Axes(A).YAxis(Y).Limits=Limits(Y,:);
			end
		end
	else
		LimValues=varargin{L}(Axes);
		LimValues=vertcat(LimValues{:});
		varargout{L}=[min(LimValues(:,1)),max(LimValues(:,2))];
		varargin{L}(Axes,varargout{L});
	end
end

%[appendix]{"version":"1.0"}
%---

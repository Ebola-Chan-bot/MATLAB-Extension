%[text] 搜索数值序列的拐点
%[text] 本函数对数值序列进行尽可能少的平滑和差分，以使得差分后的序列变成只有指定个数零点的折线，那个点对应原序列中的位置就是拐点。
%[text] 一般来说，差分越多，拐点越多；平滑越多，拐点越少。因此可以让差分等级和平滑等级对抗，多退少补地获得期待的拐点个数；但不保证一定能找到拐点，一些特殊的序列形态可能就是不存在期待数目的拐点，无论如何平滑、几阶差分。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [TurningPoint,DifferentiatedRanks,SmoothLevel] = MATLAB.DataFun.TurningPoint(Data)
%[text] %从数值序列中寻找一个拐点
%[text] 
%[text] [TurningPoint,DifferentiatedRanks,SmoothLevel] = MATLAB.DataFun.TurningPoint(Data,NumPoints)
%[text] %从数值序列中寻找指定数量的拐点
%[text] ```
%[text] ## 输入参数
%[text] Data，数值向量
%[text] NumPoints(1,1:2)=1，期待找到的拐点个数。可以指定单个值，表示拐点最多不超过这个数目；也可以指定两个值，表示拐点不少于第一个值，不多于第二个值。
%[text] ## 返回值
%[text] TurningPoint(:,1)，所有找到的拐点位置，可能是整数或半整数。如果找到，向量长度在NumPoints规定的范围内；如果没找到，返回空数组。
%[text] DifferentiatedRank(1,1)，表示这些拐点出现在第几级差分；至少1级
%[text] SmoothLevel(1,1)，平滑等级，表示这些拐点出现在对数据做了多大窗口的滑动平均后；1级表示未做任何平滑。
%[text] **See also** [diff](<matlab:doc diff>) [movmean](<matlab:doc movmean>)
function [TurningPoints,DifferentiatedRank,SmoothLevel] = TurningPoint(Data,NumPoints)
arguments
	Data(:,1)
	NumPoints=[1,1]
end
if isscalar(NumPoints)
	NumPoints=[1,NumPoints];
end
SmoothLevel=1;
DiffData=Data;
MaxDiff=numel(DiffData)-1;
while true
	for DifferentiatedRank=1:MaxDiff
		DiffData=diff(DiffData);
		SwitchPoints=DiffData(1:end-1).*DiffData(2:end)<0;
		SwitchZeros=DiffData(1:end-2).*DiffData(3:end)<0&DiffData(2:end-1)==0;
		NumTurningPoints=nnz(SwitchPoints)+nnz(SwitchZeros);
		if NumTurningPoints<NumPoints(1)
			continue;
		end
		if NumTurningPoints>NumPoints(2)
			break;
		end
		TurningPoints=sort([find(SwitchPoints)+(DifferentiatedRank+1)/2;find(SwitchZeros,1)+DifferentiatedRank/2+1]);
		return;
	end
	if NumTurningPoints<NumPoints(1)
		break;
	end
	SmoothLevel=SmoothLevel+1;
	DiffData=movmean(Data,SmoothLevel);
end
TurningPoints=[];
end

%[appendix]{"version":"1.0"}
%---

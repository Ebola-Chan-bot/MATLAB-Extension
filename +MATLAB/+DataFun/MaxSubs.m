%[text] 返回数组的最大值以及所在的坐标。
%[text] MATLAB自带的max函数只能返回多维数组最大值的线性索引。本函数一口气返回最大值以及多维坐标，方便易用
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] import MATLAB.DataFun.MaxSubs
%[text] 
%[text] [Value,S1,S2,…,Sn]=MaxSubs(Data);
%[text] %返回整个多维数组的全局最大值及其坐标
%[text] 
%[text] [___]=MaxSubs(Data,Dimensions);
%[text] %仅在指定维度上取最大值，返回指定维度上的最大值坐标
%[text] 
%[text] [___]=MaxSubs(Data,Dimensions,K);
%[text] %额外指定要返回几个最大值
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] %对于有多个最大值的数组，返回线性索引最小的那个位置的坐标：
%[text] [M,S1,S2]=MATLAB.DataFun.MaxSubs([9 9 1;1 4 4;9 8 9])
%[text] %{
%[text] M =
%[text] 
%[text]      9
%[text] 
%[text] 
%[text] S1 =
%[text] 
%[text]      1
%[text] 
%[text] 
%[text] S2 =
%[text] 
%[text]      1
%[text] %}
%[text] %还可以指定运算维度。如将一个3维数组的后两维求最大值和下标，则返回的最大值和下标都是沿第1维的向量，且只返回最大值在后两维的下标
%[text] [M,S2,S3]=MATLAB.DataFun.MaxSubs(rand(3,3,3),[2 3])
%[text] %坐标维度输出顺序与输入的指定Dimension有关
%[text] [M,S3,S2]=MATLAB.DataFun.MaxSubs(rand(3,3,3),[3 2])
%[text] ```
%[text] ## 输入参数
%[text] Data，要寻找最大值的多维数组。
%[text] Dimensions(1,:)=\[\]，要取最大值的维度。如果设为空，将把所有维度都参与运算，即返回单一标量作为整个数组的最大值，并按顺序返回该最大值各个维度的坐标。
%[text] K=1，要取几个最大值。
%[text] ## 返回值
%[text] Value，最大值。在Dimensions(1)指定的维度上（如果Dimensions为空，则在第1维度上）长度为K，在Dimensions(2:end)指定的维度上（如果Dimensions为空，则在2:ndims(Data)维度上）长度为1，在其它维度上长度与Data相同。
%[text] S1,S2, …, Sn，最大值所在的位置中，线性索引最小的那个位置的坐标。每个返回值依次代表各维度的坐标。如果指定了Dimensions不为空，将只包含Dimensions维度的坐标`，并按照Dimensions指定的顺序排列输出。这些坐标值数组的尺寸与Value相同，一一对应。`
%[text] **See also** [max](<matlab:doc max>) [maxk](<matlab:doc maxk>)
function [Value,varargout] = MaxSubs(Data,Dimensions,K)
arguments
	Data
	Dimensions(1,:)=[]
	K=1
end
NumDimensions=numel(Dimensions);
if nargout>1
	if K>1
		switch NumDimensions
			case 0
				[Value,LinearIndex]=maxk(Data(:),K);
				[varargout{1:max(nargout-1,ndims(Data))}]=ind2sub(size(Data),LinearIndex);
			case 1
				[Value,varargout{1}]=maxk(Data,K,Dimensions);
			otherwise
				OtherDimensions=setdiff(1:max([Dimensions,ndims(Data)]),Dimensions);
				Permuter=[Dimensions,OtherDimensions];
				DimensionsSize=size(Data,Dimensions);
				[Value,LinearIndex]=maxk(reshape(permute(Data,Permuter),[prod(DimensionsSize),ones(1,NumDimensions-1),size(Data,OtherDimensions)]),K,1);
				Value=ipermute(Value,Permuter);
				[varargout{1:NumDimensions}]=ind2sub(DimensionsSize,ipermute(LinearIndex,Permuter));
		end
	else
		switch NumDimensions
			case 0
				[Value,LinearIndex]=max(Data(:));
				[varargout{1:max(nargout-1,ndims(Data))}]=ind2sub(size(Data),LinearIndex);
			case 1
				[Value,varargout{1}]=max(Data,[],Dimensions);
			otherwise
				%必需ndims，不能用nargout，否则ind2sub会把后面维度都乘起来
				DimIndex=1:max([ndims(Data),Dimensions]);

				[Value,LinearIndex]=max(Data,[],Dimensions,'linear');
				%max的linear是全局线性坐标，而不是指定维度上的线性坐标

				[varargout{DimIndex}]=ind2sub(size(Data,DimIndex),LinearIndex);
				varargout=varargout(Dimensions);
		end
	end
elseif K>1
	switch NumDimensions
		case 0
			Value=maxk(Data(:),K);
		case 1
			Value=maxk(Data,K,Dimensions);
		otherwise
			OtherDimensions=setdiff(1:max([Dimensions,ndims(Data)]),Dimensions);
			Permuter=[Dimensions,OtherDimensions];
			Value=ipermute(maxk(reshape(permute(Data,Permuter),[prod(size(Data,Dimensions)),ones(1,NumDimensions-1),size(Data,OtherDimensions)]),K,1),Permuter);
	end
elseif NumDimensions
	Value=max(Data,[],Dimensions);
else
	Value=max(Data(:));
end

%[appendix]{"version":"1.0"}
%---

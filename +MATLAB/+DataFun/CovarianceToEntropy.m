%[text] 根据多元高斯分布的协方差计算联合和分摊信息熵（比特）
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [JointEntropy,FeatureEntropy]=MATLAB.DataFun.CovarianceToEntropy(Covariance);
%[text] %将Covariance视为多页矩阵，为每一页计算信息熵
%[text] 
%[text] [JointEntropy,FeatureEntropy]=MATLAB.DataFun.CovarianceToEntropy(Covariance,FeatureA,FeatureB);
%[text] %将指定的两个维度视为特征维度，其它维度视为分页
%[text] ```
%[text] ## 输入参数
%[text] Covariance，协方差张量，必须正定。采样数据相关性较高时，用内置cov估计的协方差可能不正定，此时考虑用ShrinkageCov。
%[text] FeatureA(1,1)=1，Covariance的第一个特征维度
%[text] FeatureB(1,1)=2，Covariance的第二个特征维度
%[text] ## 返回值
%[text] JointEntropy，联合信息熵，在两个特征维度上长度为1，在其它维度上长度与Covariance相同。
%[text] FeatureEntropy，分摊信息熵，为每个特征的边缘信息熵乘上（联合信息熵与（所有边缘信息熵的总和）之比），其总和保证等于联合信息熵。在FeatureA上长度为1，其它维度长度与Covariance相同。
%[text] **See also** [MATLAB.DataFun.ShrinkageCov](<matlab:doc MATLAB.DataFun.ShrinkageCov>)
function [JointEntropy,FeatureEntropy]=CovarianceToEntropy(Covariance,FeatureA,FeatureB)
arguments
	Covariance
	FeatureA=1
	FeatureB=2
end
% Bring feature dimensions to the front: [k, k, pages...]
OtherSizes=max([ndims(Covariance),FeatureA,FeatureB]);
Permuter=[FeatureA,FeatureB];
Permuter=[Permuter,setdiff(1:OtherSizes,Permuter)];

CovPages=permute(Covariance,Permuter);
OtherSizes=size(CovPages,3:OtherSizes);

JointEntropy=zeros([1,1,OtherSizes]);
NeedFeature=nargout>1;
if NeedFeature
	FeatureEntropy=zeros([1,size(CovPages,1),OtherSizes]);
end
persistent Log2_2PiED2
if isempty(Log2_2PiED2)
	% Use base-2 logs so the result is in bits.
	Log2_2PiED2=log2(2*pi*exp(1))/2;
end
nFeatures=size(Covariance,FeatureA);
ConstTerm=nFeatures*Log2_2PiED2;
for p=1:prod(OtherSizes)
	% Use Cholesky for numerical stability; requires positive definite.
	JointEntropy(p)=ConstTerm+sum(log2(diag(chol(CovPages(:,:,p)))));
	if NeedFeature
		MarginalEntropy=Log2_2PiED2+log2(diag(CovPages(:,:,p)))/2;
		FeatureEntropy(1,:,p)=(MarginalEntropy.' .* (JointEntropy(p)/sum(MarginalEntropy)));
	end
end

% Output has singleton feature dimensions, other dimensions preserved.
JointEntropy=ipermute(JointEntropy,Permuter);
if NeedFeature
	FeatureEntropy=ipermute(FeatureEntropy,Permuter);
end
end

%[appendix]{"version":"1.0"}
%---

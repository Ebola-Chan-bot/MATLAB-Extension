%[text] 估计高斯采样张量的联合信息熵
%[text] 此函数假定你输入的张量是多维高斯分布随机变量的采样值，返回估计的联合信息熵。缺失值会被忽略，尽可能仍计算出最终结果。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [Entropy,FeatureEntropy]=MATLAB.DataFun.JointEntropyGaussian(Tensor,FeatureDimensions,SampleDimensions);
%[text] %计算
%[text] ```
%[text] ## 输入参数
%[text] Tensor，任意维度张量，包含采样值
%[text] FeatureDimensions(1,:)，Tensor的特征维度
%[text] SampleDimensions(1,:)，Tensor的采样维度
%[text] ## 返回值
%[text] Entropy，在FeatureDimensions和SampleDimensions上长度为1，在其它维度上长度和Tensor相同。单位比特。
%[text] FeatureEntropy，每个特征的熵贡献（单位比特），在SampleDimensions上长度为1；在FeatureDimensions上长度与Tensor相同；在其它维度上长度与Tensor相同。其在FeatureDimensions上求和等于Entropy（按特征线性化顺序进行条件熵分解）。
%[text] **See also** [MATLAB.DataFun.ShrinkageCov](<matlab:doc MATLAB.DataFun.ShrinkageCov>)
function [Entropy,FeatureEntropy] = JointEntropyGaussian(Tensor,FeatureDimensions,SampleDimensions)
arguments
	Tensor
	FeatureDimensions(1,:)
	SampleDimensions(1,:)
end

OtherDimensions=setdiff(1:max([ndims(Tensor),FeatureDimensions,SampleDimensions]),[FeatureDimensions,SampleDimensions]);

% 计算 reshape 所需的维度信息（与 ShrinkageCov 内部一致）
FeatCount=numel(FeatureDimensions);
OtherCount=numel(OtherDimensions);
Permuter=[FeatureDimensions,OtherDimensions,SampleDimensions];
SizesPerm=size(permute(Tensor,Permuter));
FeatSize=prod(SizesPerm(1:FeatCount));
OtherSizes=SizesPerm(FeatCount+1:FeatCount+OtherCount);
OtherSize=prod(OtherSizes);

% 估计协方差：维度顺序为 [FeatureDims, FeatureDims, OtherDims]
Covariance=reshape(MATLAB.DataFun.ShrinkageCov(Tensor,SampleDimensions,FeatureDimensions),[FeatSize,FeatSize,OtherSize]);

Entropy=nan(OtherSize,1);
FeatureEntropy=nan(FeatSize,OtherSize);
Const=log(2*pi*exp(1));
Ln22=log(2)*2;

if anymissing(Covariance)
	for pg=1:OtherSize
		S=Covariance(:,:,pg);
		keep=1:FeatSize;

		if any(isnan(S),'all')
			[S,keep]=local_largest_nonmissing_subcov(S);
			if isempty(S)
				Entropy(pg)=nan;
				continue;
			end
		end

		[R,p]=chol((S+S')/2);
		if p~=0
			Entropy(pg)=nan;
			continue;
		end

		diagR=diag(R);
		diagR(diagR<=0)=realmin(class(diagR));
		hi=(Const+2*log(diagR))./Ln22;
		Entropy(pg)=sum(hi);
		FeatureEntropy(keep,pg)=hi;
	end
else
	% 无缺失值快路径：逐 page Cholesky（兼容 chol 仅支持二维矩阵的版本）
	for pg=1:OtherSize
		S=Covariance(:,:,pg);
		[R,p]=chol((S+S')/2);
		if p
			MATLAB.Exception.Covariance_not_positive_definite.Throw("Page "+string(pg));
		end

		diagR=diag(R);
		diagR(diagR<=0)=realmin(class(gather(diagR)));
		hi=(Const+2*log(diagR))./Ln22;
		FeatureEntropy(:,pg)=hi;
		Entropy(pg)=sum(hi);
	end
end

% 在 permuted 坐标下构造输出：特征维/采样维长度为 1，其它维度保持
if OtherCount==0
	Entropy=Entropy(1);
elseif OtherCount==1
	% reshape 的 size 向量必须至少包含两个元素
	Entropy=reshape(Entropy,[OtherSizes,1]);
else
	Entropy=reshape(Entropy,OtherSizes);
end

Entropy=ipermute(reshape(Entropy,[ones(1,FeatCount),OtherSizes,ones(1,numel(SampleDimensions))]),Permuter);

% FeatureEntropy：在 permuted 坐标下形状为 [FeatureSizes, OtherSizes, ones(SampleDimensions)]
FeatureSizes=SizesPerm(1:FeatCount);
if OtherCount==0
	FeatureEntropy=reshape(FeatureEntropy,[FeatureSizes,1]);
elseif OtherCount==1
	FeatureEntropy=reshape(FeatureEntropy,[FeatureSizes,OtherSizes,1]);
else
	FeatureEntropy=reshape(FeatureEntropy,[FeatureSizes,OtherSizes]);
end
FeatureEntropy=ipermute(reshape(FeatureEntropy,[FeatureSizes,OtherSizes,ones(1,numel(SampleDimensions))]),Permuter);
end

function [Ssub,keep]=local_largest_nonmissing_subcov(S)
% 尽可能从含 NaN 的协方差中取出一个没有 NaN 的子协方差矩阵。
diagS=diag(S);
keep=~isnan(diagS) & diagS>0;
if ~any(keep)
	Ssub=[];
	keep=[];
	return;
end
keep=find(keep);
Ssub=S(keep,keep);

while any(isnan(Ssub),'all')
	bad=any(isnan(Ssub),2) | any(isnan(Ssub),1).';
	if ~any(bad)
		break;
	end
	keep2=~bad;
	if ~any(keep2)
		Ssub=[];
		keep=[];
		return;
	end
	keep=keep(keep2);
	Ssub=Ssub(keep2,keep2);
end
end

%[appendix]{"version":"1.0"}
%---

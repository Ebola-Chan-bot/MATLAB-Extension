%[text] 估计高斯采样张量的联合信息熵
%[text] 此函数假定你输入的张量是多维高斯分布随机变量的采样值，返回估计的联合信息熵。缺失值会被忽略，尽可能仍计算出最终结果。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Entropy=MATLAB.DataFun.JointEntropyGaussian(Tensor,FeatureDimensions,SampleDimensions);
%[text] ```
%[text] ## 输入参数
%[text] Tensor，任意维度张量，包含采样值
%[text] FeatureDimensions(1,:)，Tensor的特征维度
%[text] SampleDimensions(1,:)，Tensor的采样维度
%[text] ## 返回值
%[text] Entropy，在FeatureDimensions和SampleDimensions上长度为1，在其它维度上长度和Tensor相同。单位比特。
%[text] **See also** [MATLAB.DataFun.ShrinkageCov](<matlab:doc MATLAB.DataFun.ShrinkageCov>)
function Entropy = JointEntropyGaussian(Tensor,FeatureDimensions,SampleDimensions)
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
Const=log(2*pi*exp(1));
Ln22=log(2)*2;


if anymissing(Covariance)
	for pg=1:OtherSize
		S=Covariance(:,:,pg);

		if any(isnan(S),'all')
			S=local_largest_nonmissing_subcov(S);
			if isempty(S)
				Entropy(pg)=nan;
				continue;
			end
		end

		S=(S+S')/2;
		d=size(S,1);
		if~d
			Entropy(pg)=nan;
			continue;
		end

		Entropy(pg)=(d.*Const+local_logdet_psd(S))./Ln22;
	end
else
	% 快路径：无缺失值时尝试 page-wise 向量化计算 log(det(Sigma))
	Entropy=(FeatSize.*Const+local_page_logdet_psd((Covariance+pagetranspose(Covariance))./2))./Ln22;
end

% 在 permuted 坐标下构造输出：特征维/采样维长度为 1，其它维度保持
if OtherCount==0
	EntropyOther=Entropy(1);
elseif OtherCount==1
	% reshape 的 size 向量必须至少包含两个元素
	EntropyOther=reshape(Entropy,[OtherSizes,1]);
else
	EntropyOther=reshape(Entropy,OtherSizes);
end

Entropy=ipermute(reshape(EntropyOther,[ones(1,FeatCount),OtherSizes,ones(1,numel(SampleDimensions))]),Permuter);
end

function Ssub=local_largest_nonmissing_subcov(S)
% 尽可能从含 NaN 的协方差中取出一个没有 NaN 的子协方差矩阵。
diagS=diag(S);
keep=~isnan(diagS) & diagS>0;
if ~any(keep)
	Ssub=[];
	return;
end
Ssub=S(keep,keep);

while any(isnan(Ssub),'all')
	bad=any(isnan(Ssub),2) | any(isnan(Ssub),1).';
	if ~any(bad)
		break;
	end
	keep2=~bad;
	if ~any(keep2)
		Ssub=[];
		return;
	end
	Ssub=Ssub(keep2,keep2);
end
end

function logdet=local_logdet_psd(S)
% 对称半正定矩阵的 log(det(S))，数值不稳定时回退到特征值法。
S=(S+S')/2;
[R,p]=chol(S);
if p==0
	logdet=diag(R);
	logdet(logdet<=0)=realmin(class(logdet));
	logdet=2*sum(log(logdet));
else
	logdet=eig(S);
	logdet=real(logdet);
	logdet(logdet<=0)=realmin(class(logdet));
	logdet=sum(log(logdet));
end
end

function logdetPages=local_page_logdet_psd(S)
% page-wise 计算 log(det(S(:,:,pg)))；假定最新版 MATLAB 支持 pageeig。
logdetPages=pageeig(gather(S));

% 兼容不同输出形状：期望最终为 [FeatSize,OtherSize]
if ndims(logdetPages)==3
	logdetPages=reshape(logdetPages,size(logdetPages,1),[]);
end
if isvector(logdetPages) && size(S,3)>1
	logdetPages=reshape(logdetPages,[],size(S,3));
end
logdetPages(logdetPages<=0)=realmin(class(logdetPages));
logdetPages=sum(log(logdetPages),1).';
end

%[appendix]{"version":"1.0"}
%---

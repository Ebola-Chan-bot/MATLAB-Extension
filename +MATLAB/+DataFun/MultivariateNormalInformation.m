%[text] 多元正态分布信息量
%[text] 此函数根据已知的多元正态分布均值和协方差，计算每个给定采样数据的分摊信息量（单位比特）。对每个采样，所有维度的分摊信息量之和就是该采样的联合信息量，这些维度之间的信息量之比等于每个维度的边缘信息量之比，但总和会更小，因为变量之间还存在互信息，从联合信息量中排除。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Information=MATLAB.DataFun.MultivariateNormalInformation(ParametricSamples);
%[text] ```
%[text] ## 输入参数
%[text] ParametricSamples tabular，分布参数和采样值，一行一个变量维度，必须包含以下列：
%[text] - Mean(:,1)，每个变量的总体均值
%[text] - Covariance(:,:)，所有变量的协方差。协方差必须正定，如果你用内置cov计算的协方差不正定，可以尝试使用MATLAB.DataFun.ShrinkageCov
%[text] - Samples，采样张量，除第1维必须是变量维度以外，可以具有任意多维度。 \
%[text] ## 返回值
%[text] Information，比ParametricSamples多一列的表：
%[text] - Information，信息张量，与Samples各维长度相同 \
%[text] **See also** [MATLAB.DataFun.ShrinkageCov](<matlab:doc MATLAB.DataFun.ShrinkageCov>) [MATLAB.DataFun.JointEnropyGaussian](<matlab:doc MATLAB.DataFun.JointEnropyGaussian>)
function Information=MultivariateNormalInformation(Information)

Mean=Information.Mean;
Covariance=Information.Covariance;
Samples=Information.Samples;

% tabular 的每列天然按“行”对齐，这里不做过度的尺寸一致性检查。
DimCount=numel(Mean);

% 计算：Information(x) = -log2 p(x)
R=chol((Covariance+Covariance')/2);

diagR=diag(R);
diagR(diagR<=0)=realmin(class(gather(diagR)));
persistent Ln22 Ln2Pi
if isempty(Ln22)
	Ln22=1/(2*log(2));
	Ln2Pi=log(2*pi);
end

% 顺序无关的逐变量信息量分摊：
% 1) 计算联合信息量 I_joint(x) = -log2 p(x)
% 2) 计算各变量边缘信息量 I_i(x_i) = -log2 p(x_i)
% 3) 按比例分摊：I_i_share = I_i * I_joint / sum_j I_j
X=reshape(Samples-Mean,DimCount,[]);
JointInformation=(DimCount.*Ln2Pi+2.*sum(log(diagR))+sum((R'\X).^2,1)).*Ln22;

MarginalVar=diag(Covariance);
MarginalVar(MarginalVar<=0)=realmin(class(gather(MarginalVar)));
MarginalInformation=(Ln2Pi+log(MarginalVar)+(X.^2).*(1./MarginalVar)).*Ln22;
SumMarginalInformation=sum(MarginalInformation,1);

Ratio=JointInformation./SumMarginalInformation;
Bad=~isfinite(Ratio) | (SumMarginalInformation==0);
SharedInformation=MarginalInformation.*Ratio;
if any(Bad)
	SharedInformation(:,Bad)=JointInformation(Bad)./DimCount;
end

Information.Information=reshape(SharedInformation,[DimCount,size(Samples,2:ndims(Samples))]);
end

%[appendix]{"version":"1.0"}
%---

%[text] 张量协方差
%[text] 内置cov仅支持矩阵或向量协方差，不能对高维张量的指定维度计算协方差。本函数解决此问题，允许指定高维张量的采样维度和特征维度，其它维度并行计算。
%[text] 归一化权重为0，缺失值的处理方式采用内置cov中的'partialrows'方法。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Covariance=MATLAB.DataFun.Cov(Tensor,SampleDimension,FeatureDimension);
%[text] ```
%[text] ## 输入参数
%[text] Tensor，输入张量，可以是任意维度
%[text] SampleDimension，采样维度
%[text] FeatureDimension，特征维度
%[text] ## 返回值
%[text] Covariance，协方差张量。此张量在采样维度上的长度和Tensor的特征维度长度相同，其它维度长度均与Tensor的对应维度长度相同。
%[text] **See also** [cov](<matlab:doc cov>) [MATLAB.DataFun.ShrinkageCov](<matlab:doc MATLAB.DataFun.ShrinkageCov>)
function Covariance=Cov(Tensor,SampleDimension,FeatureDimension)
AmbiguousDimensions=intersect(SampleDimension,FeatureDimension);
if~isempty(AmbiguousDimensions)
	MATLAB.Exception.Ambiguous_dimensions.Throw(AmbiguousDimensions);
end
OtherDimensions=setdiff(1:max([ndims(Tensor),SampleDimension,FeatureDimension]),[SampleDimension,FeatureDimension]);
if anymissing(Tensor)
    Tensor=permute(Tensor,[FeatureDimension,OtherDimensions,SampleDimension]);
    Sizes=size(Tensor);
    Tensor=reshape(Tensor,Sizes(1),[],Sizes(end));
    Covariance=zeros(size(Tensor,[1,2,1]),'like',Tensor([])); % using x([]) so that c is always real
    for j = 2:Sizes(1)
        ThisFeature=Tensor(j,:,:);
        x1 = repmat(ThisFeature, j-1,1,1);
        x2 = Tensor(1:j-1,:,:);

        % make x1, x2 have the same nan patterns
        x1(isnan(x2)) = nan;
        x2(:,isnan(ThisFeature)) = nan;

        Covariance(1:j-1,:,j)  = localcov_elementwise(x1, x2);
    end
    Covariance=permute(Covariance,[2,1,3])+permute(Covariance,[2,3,1]);
    Covariance(:,1:Sizes(1)+1:end)=localcov_elementwise(pagetranspose(Tensor));
    Covariance=ipermute(reshape(Covariance,Sizes([2:end-1,1,1])),[OtherDimensions,SampleDimension,FeatureDimension]);
else
    Permuter=[FeatureDimension,SampleDimension,OtherDimensions];
    Tensor=permute(Tensor - mean(Tensor,SampleDimension),Permuter);
    Covariance = ipermute(pagemtimes(Tensor,'none',Tensor,'ctranspose')./ (size(Tensor,2)-1),Permuter);
end
end
function c = localcov_elementwise(x,y)
%LOCALCOV Return c(i) = cov of x(:, i) and y(:, i), for all i
% with no error checking and assuming NaNs are removed
% returns 1xn vector c
% x, y must be of the same size, with identical nan patterns
xy = sum(~isnan(x), 3);

denom = xy - 1;
denom(xy == 1) = 1;
denom(xy == 0) = 0;
if nargin==1
    xy=x - (sum(x, 3, 'omitnan') ./ xy);
    xy= conj(xy) .* xy;
else
    xy = conj(x - (sum(x, 3, 'omitnan') ./ xy)) .* (y - (sum(y, 3, 'omitnan') ./ xy));
end
c = sum(xy, 3, 'omitnan') ./ denom;

% Don't omit NaNs caused by computation (not missing data)
c(any(isnan(xy) & ~isnan(x), 3)) = nan;
end

%[appendix]{"version":"1.0"}
%---

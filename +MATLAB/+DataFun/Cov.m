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
%[text] **See also** [cov](<matlab:doc cov>)
function Covariance=Cov(Tensor,SampleDimension,FeatureDimension)
NumDimensions=max([ndims(Tensor),SampleDimension,FeatureDimension]);
FullDimensions=1:NumDimensions;
OtherDimensions=setdiff(FullDimensions,[SampleDimension,FeatureDimension]);
Tensor=permute(Tensor,[OtherDimensions,SampleDimension,FeatureDimension]);
NumFeatures=size(Tensor,NumDimensions);
NumDimensions_1=NumDimensions-1;

Covariance=zeros([size(Tensor,1:NumDimensions-2),NumFeatures,NumFeatures],'like',Tensor([])); % using x([]) so that c is always real

% First fill in the diagonal:
Subs=repmat({':'},1,NumDimensions-2);
Covariance(Subs{:},1:NumFeatures+1:end)=localcov_elementwise(Tensor, NumDimensions_1);

Permuter=[NumDimensions,1:NumDimensions_1];
Tensor=permute(Tensor,Permuter);
Covariance=permute(Covariance,Permuter);

Repeater=ones(1,NumDimensions_1);

% Now compute off-diagonal entries
for j = 2:NumFeatures
    ThisFeature=Tensor(j,Subs{:},:);
    x1 = repmat(ThisFeature, [j-1,Repeater]);
    x2 = Tensor(1:j-1,Subs{:});

    % make x1, x2 have the same nan patterns
    x1(isnan(x2)) = nan;
    x2(:,isnan(ThisFeature)) = nan;

    Covariance(1:j-1,Subs{:},j)  = localcov_elementwise(x1, x2, NumDimensions);
end
c = c + tril(c,-1)';
end
function c = localcov_elementwise(x,y,SampleDimension)
%LOCALCOV Return c(i) = cov of x(:, i) and y(:, i), for all i
% with no error checking and assuming NaNs are removed
% returns 1xn vector c
% x, y must be of the same size, with identical nan patterns
if nargin==2
    SampleDimension=y;
end
xy = sum(~isnan(x), SampleDimension);

denom = xy - 1;
denom(xy == 1) = 1;
denom(xy == 0) = 0;
if nargin==2
    xy=x - (sum(x, SampleDimension, 'omitnan') ./ xy);
    xy= conj(xy) .* xy;
else
    xy = conj(x - (sum(x, SampleDimension, 'omitnan') ./ xy)) .* (y - (sum(y, SampleDimension, 'omitnan') ./ xy));
end
c = sum(xy, SampleDimension, 'omitnan') ./ denom;

% Don't omit NaNs caused by computation (not missing data)
c(any(isnan(xy) & ~isnan(x), SampleDimension)) = nan;
end

%[appendix]{"version":"1.0"}
%---

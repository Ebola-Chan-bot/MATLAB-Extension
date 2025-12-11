%[text] Ledoit–Wolf shrinkage 协方差估计函数
%[text] Cov的升级版，适用于采样数少于特征数的情形，避免得到奇异的协方差。
%[text] 某些数据特征可能会导致特征维度之间的协方差矩阵只有对角线值，这是正常的。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Covariance=MATLAB.DataFun.ShrinkageCov(Tensor,SampleDimension,FeatureDimension);
%[text] ```
%[text] ## 输入参数
%[text] Tensor，输入张量，可以是任意维度
%[text] SampleDimension，采样维度（可为多个维度）
%[text] FeatureDimension，特征维度（可为多个维度）
%[text] ## 返回值
%[text] Covariance，收缩后的协方差张量。维度顺序：\[FeatureDimension,FeatureDimension,其它维度（不含采样维度）\]，其余维度与输入对应。
%[text] **See also** [MATLAB.DataFun.Cov](<matlab:doc MATLAB.DataFun.Cov>)
function Covariance=ShrinkageCov(Tensor,SampleDimension,FeatureDimension)
% Ledoit–Wolf 收缩到缩放单位阵，支持多采样维/多特征维。

AmbiguousDimensions=intersect(SampleDimension,FeatureDimension);
if~isempty(AmbiguousDimensions)
    MATLAB.Exception.Ambiguous_dimensions.Throw(AmbiguousDimensions);
end

% 将特征维、其它维、样本维排到一起，便于统一计算
OtherDimensions=setdiff(1:max([ndims(Tensor),SampleDimension,FeatureDimension]),[SampleDimension,FeatureDimension]);
Permuter=[FeatureDimension,OtherDimensions,SampleDimension];
Tensor=permute(Tensor,Permuter);
Sizes=size(Tensor);
FeatCount=numel(FeatureDimension);
OtherCount=numel(OtherDimensions);
FeatSize=prod(Sizes(1:FeatCount));
OtherSize=prod(Sizes(FeatCount+1:FeatCount+OtherCount));
SampleSize=prod(Sizes(FeatCount+OtherCount+1:end));

% reshape 到 [特征, 样本, 其它] 的三维视图
Tensor=reshape(Tensor,FeatSize,OtherSize,SampleSize);
Tensor=permute(Tensor,[1,3,2]); % => [feat, sample, page]

SC=zeros(FeatSize,FeatSize,OtherSize,'like',Tensor);

if anymissing(Tensor)
    for pg=1:OtherSize
        Tpage=Tensor(:,:,pg);              % [feat x sample]
        mask=~isnan(Tpage);
        if ~any(mask,'all')
            SC(:,:,pg)=nan(FeatSize,FeatSize,'like',Tensor);
            continue;
        end

        % 局部均值（忽略 NaN）并中心化；NaN 置 0 以便矩阵乘法
        count_feat=sum(mask,2);
        Xfill=Tpage;
        Xfill(~mask)=0;
        mean_feat=Xfill*ones(size(Tpage,2),1)./max(count_feat,1);
        Xc=Xfill-mean_feat.*mask;

        % pairwise 有效样本数（partialrows）
        counts_pair=mask*mask.';                        % 同时非 NaN 的样本数
        denom=max(counts_pair-1,1);                     % 避免除零

        % 协方差估计（partialrows 风格）
        S_num=Xc*Xc.';                                  % 缺失样本贡献为 0
        S=S_num./denom;
        S(counts_pair<=1)=nan;                          % 无有效样本时置 NaN

        % 目标矩阵：缩放单位阵（仅用有效对角均值）
        diag_mask=diag(counts_pair)>1;
        if any(diag_mask)
            mu=mean(diag(S),'omitnan');
        else
            mu=0;
        end
        F=mu*eye(FeatSize,'like',Tensor);

        % 估计 phi：对每个样本仅累积有效对的 diff^2
        phi_sum=0;
        valid_pairs=counts_pair>1;
        for k=1:size(Tpage,2)
            mk=mask(:,k);
            if ~any(mk), continue; end
            xk=Xc(:,k);
            outer=xk*xk.';
            outer(~(mk&mk.'))=0;                         % 仅保留同时有效的对
            diff=outer-S;
            diff(~valid_pairs)=0;
            phi_sum=phi_sum+sum(diff.^2,'all','omitnan');
        end
        n_eff=mean(counts_pair(valid_pairs),'omitnan');
        if isnan(n_eff) || n_eff<=0
            SC(:,:,pg)=nan(FeatSize,FeatSize,'like',Tensor);
            continue;
        end
        phi_hat=phi_sum/max(n_eff,1);

        % gamma = ||S-F||_F^2，仅在有效对上累积
        gamma_mask=valid_pairs;
        gamma_hat=sum(((S-F).^2).*gamma_mask,'all','omitnan');

        if gamma_hat==0
            lambda=1;
        else
            lambda=min(1,max(0,(phi_hat/gamma_hat)/n_eff));
        end
        SC(:,:,pg)=lambda*F+(1-lambda)*S;
    end
else
    % 去均值
    Tensor=Tensor-mean(Tensor,2);

    % 样本协方差（未偏）：page-wise
    S=pagemtimes(Tensor,'none',Tensor,'ctranspose')./SampleSize; % [f,f,page]

    % 目标矩阵：缩放单位阵
    mu=squeeze(sum(S.*reshape(eye(FeatSize,'like',Tensor),FeatSize,FeatSize,1),[1,2]))./FeatSize; % [page,1]
    F=reshape(mu,1,1,[]).*reshape(eye(FeatSize,'like',Tensor),FeatSize,FeatSize,1);

    % 估计 phi（方差项）：1/n * sum ||x_i x_i^T - S||_F^2
    phi_sum=zeros(FeatSize,FeatSize,OtherSize,'like',Tensor);
    for k=1:SampleSize
        xk=Tensor(:,k,:);                         % [f,1,page]
        outer=pagemtimes(xk,'none',xk,'ctranspose'); % [f,f,page]
        diff=outer-S;
        phi_sum=phi_sum+diff.^2;
    end
    phi_hat=squeeze(sum(phi_sum,[1,2]))./SampleSize; % [page,1]

    % gamma = ||S-F||_F^2
    gamma_hat=squeeze(sum((S-F).^2,[1,2]));

    lambda=zeros(size(gamma_hat),'like',Tensor);
    nonZero=gamma_hat>0;
    lambda(nonZero)=min(1,max(0,(phi_hat(nonZero)./gamma_hat(nonZero))./SampleSize));
    lambda(~nonZero)=1;
    lambda=reshape(lambda,1,1,[]); % broadcast over feature dims

    SC=lambda.*F+(1-lambda).*S;
end

% 还原到原特征维度 x 原特征维度 x 其它维度 的形状
Covariance=reshape(SC,[Sizes(1:FeatCount),Sizes(1:FeatCount),Sizes(FeatCount+1:FeatCount+OtherCount)]);
end

%[appendix]{"version":"1.0"}
%---

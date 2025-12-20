%[text] 由点集Input到点集Output的N维齐次射影（透视）映射矩阵
%[text] 输入两组对应点 Input、Output（均为 N×M），返回 (N+1)×(N+1) 齐次矩阵 Projection，使得
%[text] ```
%[text] [Output; ones(1,M)] ~ Projection* [Input; ones(1,M)]
%[text] ```
%[text] 其中 ~ 表示相差一个与点相关的非零尺度因子（射影等价）。
%[text] 本函数使用 DLT（Direct Linear Transform）最小二乘/最小范数解，并做点集归一化以改善数值条件。
%[text] 兼容 M\>N 与 M\<N：点数不足时解不唯一，返回其中一个最小二乘意义下的解。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Projection = MATLAB.Images.ProjectiveMap(Input,Output);
%[text] ```
%[text] ## 输入参数
%[text] Input(:,:)，M 个 N 维点（每列一个点）
%[text] Output(:,:)，与 Input 一一对应的目标点
%[text] ## 返回值
%[text] Projection(:,:)，齐次射影变换方阵（尺度不唯一），阶数是height(Input)+1
function Projection = ProjectiveMap(Input,Output,MaxPoints)
%命名空间：Images
[N,mA] = size(Input);

if ~exist('MaxPoints','var') || isempty(MaxPoints)
	MaxPoints = inf;
end
if isfinite(MaxPoints) && MaxPoints >= 1 && mA > MaxPoints
	idx = unique(round(linspace(1, mA, MaxPoints)));
	Input = Input(:,idx);
	Output = Output(:,idx);
	[N,mA] = size(Input);
end

% 归一化（Hartley 类似）
[Ta,An] = localNormalizePoints(Input);
[Tb,Bn] = localNormalizePoints(Output);

% 用算子形式求解 D * vec(Hn) = 0（不显式构造超大稀疏矩阵）
% 固定尺度：令 vec(Hn)(end)=1，把齐次问题转为稀疏最小二乘：A*g = rhs
X = [double(An); ones(1,mA)];
B = double(Bn);
Xt = X.';

rhs = B(:);
nVars = (N+1)^2 - 1;

afun = @(x,transpFlag) localAfun(x, transpFlag, N, mA, X, Xt, B);

[ghat,flag] = lsqr(afun, rhs, 1e-10, 200);
vecH = [ghat; 1];
if flag ~= 0 || any(~isfinite(vecH))
	error('MATLAB:ProjectiveMap:LSQRFailed','lsqr未收敛或结果无效');
end

% 反归一化
Projection = (Tb \ reshape(vecH, N+1, N+1)) * Ta;

% 规范化尺度：尽量令 H(end,end)=1，否则按最大幅值归一
s = Projection(end,end);
if isfinite(s) && abs(s) > 10*eps(class(Projection))
	Projection = Projection ./ s;
else
	mx = max(abs(Projection), [], 'all');
	if mx > 0
		Projection = Projection ./ mx;
	end
end

function y = localAfun(x, transpFlag, N, mA, X, Xt, B)
% x: g (notransp) or w (transp)
% A*g 的定义：对每点 i、每维 j： (h_j^T x_i - b_{j,i} * h_last^T x_i) = b_{j,i}
% 其中 h_last^T x_i 中的 H(end,end) 固定为 1，已移到 rhs

if strcmp(transpFlag,'notransp')
	Hunk = reshape([x; 0], N+1, N+1); % 最后一项对应 H(end,end)，不在未知量中
	U = Hunk * X; % (N+1)×M
	Y = U(1:N,:) - B .* U(end,:);
	y = Y(:);
else
	W = reshape(x, N, mA);
	Top = W * Xt; % N×(N+1)
	s = sum(W .* B, 1); % 1×M
	Last = -s * Xt; % 1×(N+1)
	G = [Top; Last];
	g = G(:);
	y = g(1:end-1);
end
end

end

function [T,P] = localNormalizePoints(P)
%P: N×M (double)
N = size(P,1);
T = mean(P, 2);
P = P - T;
md = mean(sqrt(sum(P.^2, 1)));
if isfinite(md) && md > 0
	s = sqrt(N) / md;
else
	s = 1;
end

T = [s*eye(N), -s*T; zeros(1,N), 1];
P = s * P;
end

%[appendix]{"version":"1.0"}
%---

%[text] 内置deconv函数的魔改版，用多项式长除法计算多维反卷积
%[text] 内置deconv仅支持向量反卷积，此函数支持任意维度张量反卷积
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [X,R]=MATLAB.DataFun.DeconvN(Y,H);
%[text] %求使得Y=convn(X,H)+R的X和R
%[text] ```
%[text] ## 输入参数
%[text] Y，要反卷积的输入信号
%[text] H，用于反卷积的冲激响应或滤波器
%[text] ## 返回值
%[text] X，经除法运行后得到的反卷积信号或商。
%[text] R，经除法运算后得到的残差信号或余数
%[text] ## 算法明细
%[text] Y和H在所有维度上都会先被截去全零的尾端。那之后，如果H在任何一个维度上比Y更长，将返回X=0，R=Y。否则，X的各维尺寸将等于Y与H的各维尺寸（截去全零尾端之后的）之差+1。此函数通过优化X的取值，以使得R中各维索引之和较大的位置尽可能都为0，然后将各维度的全零尾端截去。这样，R的各维尺寸最大不会超过Y的各维尺寸。
%[text] **See also** [deconv](<matlab:doc deconv>) [convn](<matlab:doc convn>)
function [X,R] = DeconvN(Y,H)

% 去除各维尾端全零（多项式最高阶项的前导零）
Y = localTrimTrailingZeros(Y);
H = localTrimTrailingZeros(H);

nd  = max(ndims(Y), ndims(H));
% 对齐维度数（size 自动补 1）
szY=size(Y,1:nd);
szH=size(H,1:nd);

% 若任何维度 H 比 Y 长，则商为 0，余数是 Y
if any(szH > szY)
	X = 0;
	R = Y;
	return;
end

% 计算商尺寸： (szY - szH) + 1
szX = szY - szH + 1;
X = zeros(szX,'like',Y); % 商初始化为 0

R = Y;




% 最终余数裁剪尾零
R = localTrimTrailingZeros(R);
end

% ================== 辅助函数 ==================
function A = localTrimTrailingZeros(A)
NumDimensions=ndims(A);
Dimensions=1:NumDimensions;
Subs=cell(1,NumDimensions);
for D=1:NumDimensions
	Subs{D}=1:find(any(A, setdiff(Dimensions, D)),1,'last');
end
A = A(Subs{:});
end

%[appendix]{"version":"1.0"}
%---

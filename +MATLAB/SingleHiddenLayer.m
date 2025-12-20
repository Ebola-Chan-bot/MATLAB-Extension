%[text] 求解最优单隐层
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [HiddenInput,HiddenOutput] = MATLAB.SingleHiddenLayer(Input,Output);
%[text] %对矩阵方程Input*HiddenInput*HiddenOutput==Output，已知Input和Output，此函数求解最优化的HiddenInput和HiddenOutput
%[text] 
%[text] [HiddenInput,HiddenOutput] = MATLAB.SingleHiddenLayer(Input,Output,HiddenSize);
%[text] %额外指定中间隐藏层大小
%[text] ```
%[text] ## 输入参数
%[text] Input(:,:)，输入矩阵
%[text] Output(:,:)，输出矩阵，第1维长度必须和Input相同
%[text] HiddenSize(1,1)，中间隐藏层维数，默认等于Input的秩
%[text] ## 返回值
%[text] HiddenInput(:,:)，输入中间层的全连接权重
%[text] HiddenOutput(:,:)，从中间层输出的全连接权重
%[text] **See also** [svd](<matlab:doc svd>)
function [HiddenInput,HiddenOutput] = SingleHiddenLayer(Input,Output,HiddenSize)
%命名空间：MatFun
arguments
	Input
	Output
	HiddenSize=rank(Input)
end
[U,S,V] = svd(Input\Output,'econ');
rr = min([HiddenSize, size(S,1), size(S,2)]);

% split S as sqrt for balanced scaling
Sh = sqrt(S(1:rr,1:rr));
HiddenInput  = U(:,1:rr)*Sh;       % n×r
HiddenOutput  = Sh*V(:,1:rr).';     % r×n
end

%[appendix]{"version":"1.0"}
%---

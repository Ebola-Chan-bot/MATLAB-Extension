%[text] 内置polyfit的魔改版，支持任意维度张量
%[text] 此方法输入输出语法与内置不同，请注意鉴别。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Coefficients = MATLAB.PolyFit(X,Y,NumTimes,Dimension)
%[text] ```
%[text] ## 输入参数
%[text] X，查询点，可以是任意维度张量
%[text] Y，查询点位置的拟合值，可以是任意维度张量
%[text] Dimension(1,1)，要计算多项式系数的维度。X和Y在指定维度上的长度必须大于NumTimes
%[text] NumTimes(1,1)=1，多项式拟合的次数
%[text] ## 返回值
%[text] Coefficients，多项式系数。在Dimension维度上长度为NumTimes+1，依次排列从0到NumTimes次的多项式系数；在其它维度上长度等于X和Y在此维度上长度较大者。
%[text] **See also** [polyfit](<matlab:doc polyfit>)
function Coefficients = PolyFit(X,Y,Dimension,NumTimes)
%命名空间：PolyFun
arguments
	X
	Y
	Dimension
	NumTimes=1
end
NumDimensions=max([ndims(X),ndims(Y),Dimension]);
Permuter=[Dimension,NumDimensions+1,1:Dimension-1,Dimension+1:NumDimensions];
Coefficients=ipermute(pagemldivide(permute(X,Permuter).^(0:NumTimes),permute(Y,Permuter)),Permuter);
end

%[appendix]{"version":"1.0"}
%---

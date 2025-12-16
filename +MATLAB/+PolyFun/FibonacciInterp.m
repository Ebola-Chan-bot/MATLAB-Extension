%[text] 斐波那契插值
%[text] 此函数根据通项公式对斐波那契数列解析延拓，得到斐波那契函数，允许查询该函数在任意位置的值。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] QueryValues=MATLAB.PolyFun.FibonacciInterp(QueryIndices);
%[text] %查询从0、1起始的斐波那契数列中的值
%[text] 
%[text] QueryValues=MATLAB.PolyFun.FibonacciInterp(QueryIndices,ReferenceValues);
%[text] %额外指定1、2位置的参考值
%[text] 
%[text] QueryValues=MATLAB.PolyFun.FibonacciInterp(QueryIndices,ReferenceValues,ReferenceIndices);
%[text] %额外指定参考值所在的位置
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] import MATLAB.PolyFun.FibonacciInterp
%[text] 
%[text] %简单斐波那契数列查询
%[text] FibonacciInterp(1:10)
%[text] %{
%[text] ans =
%[text] 
%[text]    -0.0000    1.0000    1.0000    2.0000    3.0000    5.0000    8.0000   13.0000   21.0000   34.0000
%[text] %}
%[text] 
%[text] %可以返回任意形状数组
%[text] FibonacciInterp(reshape(1:8,2,2,2))
%[text] %{
%[text] ans(:,:,1) =
%[text] 
%[text]    -0.0000    1.0000
%[text]     1.0000    2.0000
%[text] 
%[text] 
%[text] ans(:,:,2) =
%[text] 
%[text]     3.0000    8.0000
%[text]     5.0000   13.0000
%[text] %}
%[text] 
%[text] %额外指定起始两项的值
%[text] FibonacciInterp(1:10,[-1,1])
%[text] %{
%[text] ans =
%[text] 
%[text]    -1.0000    1.0000    0.0000    1.0000    1.0000    2.0000    3.0000    5.0000    8.0000   13.0000
%[text] %}
%[text] 
%[text] %额外指定参考值的位置
%[text] FibonacciInterp(1:10,[1,1],[3,9])
%[text] %{
%[text] ans =
%[text] 
%[text]     2.5000   -1.5000    1.0000   -0.5000    0.5000   -0.0000    0.5000    0.5000    1.0000    1.5000
%[text] %}
%[text] 
%[text] %允许指定负数和非整数位置，可能导致返回复数
%[text] FibonacciInterp(-5:0.5:5,[1,1],[-2.5,2.5])
%[text] %{
%[text] ans =
%[text] 
%[text]   列 1 至 6
%[text] 
%[text]    0.0293 - 3.0055i   2.4000 + 0.0000i   0.0474 + 1.8575i  -1.4000 + 0.0000i   0.0767 - 1.1480i   1.0000 + 0.0000i
%[text] 
%[text]   列 7 至 12
%[text] 
%[text]    0.1240 + 0.7095i  -0.4000 + 0.0000i   0.2007 - 0.4385i   0.6000 + 0.0000i   0.3247 + 0.2710i   0.2000 + 0.0000i
%[text] 
%[text]   列 13 至 18
%[text] 
%[text]    0.5254 - 0.1675i   0.8000 + 0.0000i   0.8501 + 0.1035i   1.0000 + 0.0000i   1.3755 - 0.0640i   1.8000 + 0.0000i
%[text] 
%[text]   列 19 至 21
%[text] 
%[text]    2.2257 + 0.0395i   2.8000 + 0.0000i   3.6012 - 0.0244i
%[text] 
%[text] %}
%[text] ```
%[text] ## 输入参数
%[text] QueryIndices，指示要查询的斐波那契函数自变量值，可以是任意尺寸的数组。如果指定非整数，可能返回复数结果。
%[text] ReferenceValues(1,2)=\[0,1\]，指定两个参考值
%[text] ReferenceIndices(1,2)=\[1,2\]，指定两个参考值的位置。如果指定非整数，可能返回复数结果。
%[text] ## 返回值
%[text] QueryValues，查询到的斐波那契函数指定位置的值，此数组的各维尺寸与QueryIndices相同
%[text] **See also** [interp1](<matlab:doc interp1>)
function QueryValues = FibonacciInterp(QueryIndices,ReferenceValues,ReferenceIndices)
%命名空间：PolyFun
arguments
	QueryIndices
	ReferenceValues(1,2)=[0,1]
	ReferenceIndices(1,2)=[1,2]
end
persistent Constants
if isempty(Constants)
	Constants=([1;-1]*sqrt(5)+1)/2;
end
QueryValues=shiftdim(pagemtimes(ReferenceValues/Constants.^ReferenceIndices,Constants.^shiftdim(QueryIndices,-1)),1);

%[appendix]{"version":"1.0"}
%---

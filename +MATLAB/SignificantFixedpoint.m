%[text] 将数值转换为具有指定有效位数的定点计数法字符串
%[text] 内置的sprintf和compose都只能将数值转换为定点数字符串，或者有效位数科学计数法字符串，并没有提供不使用科学计数法的选项。本函数允许指定有效数字位数并不使用科学计数法地转换为定点数字符串。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Fixedpoints = MATLAB.SignificantFixedpoint(Numbers,Significance)
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] MATLAB.SignificantFixedpoint([123456789,12567890000000000000000000,135;-0.115,0.000000000000000000000000125,-0.135;1,1.2,12.3;0,0.0996,0],2)
%[text] %{
%[text] ans = 
%[text] 
%[text]   4×3 string 数组
%[text] 
%[text]     "120000000"    "13000000000000000000000000"      "140"  
%[text]     "-0.12"        "0.00000000000000000000000012"    "-0.14"
%[text]     "1.0"          "1.2"                             "12"   
%[text]     "0.0"          "1.0"                             "0.0"  
%[text] %}
%[text] ```
%[text] ## 输入参数
%[text] Numbers，要转换的数组
%[text] Significance(1,1)，有效数字位数
%[text] ## 返回值
%[text] Fixedpoints string，定点数字符串，数组尺寸与Numbers相同
%[text] **See also** [compose](<matlab:doc compose>) [sprintf](<matlab:doc sprintf>) [num2str](<matlab:doc num2str>)
function FixedPoints = SignificantFixedpoint(Numbers,Significance)
%命名空间：StrFun
Negative=Numbers<0;
Zeros=Numbers==0;
Numbers=abs(Numbers);
Level=floor(log10(Numbers))+1;
Level(Zeros)=1;
LevelMultiplier=10.^Level;
SignificanceMultiplier=10.^Significance;
Logical=SignificanceMultiplier.*(LevelMultiplier-Numbers)<LevelMultiplier*0.5;
Level(Logical)=Level(Logical)+1;
LevelMultiplier(Logical)=LevelMultiplier(Logical)*10;
FixedPoints=compose('%.0f',gather(Numbers.*SignificanceMultiplier./LevelMultiplier));
FixedPoints(Zeros)={repmat('0',1,Significance)};
for F=1:numel(FixedPoints)
	L=Level(F);
	if L<1
		FixedPoints{F}=['0.',repmat('0',1,-L),FixedPoints{F}];
	elseif L<Significance
		FixedPoints{F}=[FixedPoints{F}(1:L),'.',FixedPoints{F}(L+1:end)];
	else
		FixedPoints{F}=[FixedPoints{F},repmat('0',1,L-Significance)];
	end
end
FixedPoints=string(FixedPoints);
FixedPoints(Negative)="-"+FixedPoints(Negative);

%[appendix]{"version":"1.0"}
%---

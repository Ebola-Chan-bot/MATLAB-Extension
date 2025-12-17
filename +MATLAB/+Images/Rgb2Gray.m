%[text] 将任意维度的RGB图像转换为灰度图
%[text] 内置rgb2gray只能转换m×n×3的RGB图像。本函数可以执行任意指定维度的转换，并且可以同时转换多图数组。但不同于内置rgb2gray，本函数不能转换c×3样式的颜色图。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Gray=MATLAB.Rgb2Gray(RGB);
%[text] %将标准m×n×3的RGB图像转换为灰度图
%[text] 
%[text] Gray=MATLAB.Rgb2Gray(RGB,Dimension);
%[text] %将非标准RGB颜色数组转换为灰度图，使用指定的维度作为RGB维度
%[text] ```
%[text] ## 输入参数
%[text] RGB，具有RGB颜色通道的图像数组，其RGB维度长度应当为3
%[text] Dimension(1,1)uint8，要视为RGB维度的维度序号。如果不指定此参数，将按以下规则确定默认值：
%[text] 1. 如果size(RGB,3)==3，Dimension=3
%[text] 2. 否则，将从小到大遍历RGB各维长度，直到遇到第一个长度为3的维度作为RGB维度
%[text] 3. 如果没有长度为3的维度，将出错 \
%[text] ## 返回值
%[text] Gray，灰度图，具有和输入RGB相同的各维长度和数据类型，除了RGB维度长度为1。
%[text] **See also** [rgb2gray](<matlab:doc rgb2gray>)
function Image = Rgb2Gray(Image,Dimension)
%命名空间：Images
if ~exist('Dimension','var')
	Dimension=[3,1:ndims(Image)];
	Dimension=Dimension(find(size(Image,Dimension)==3,1));
end
Subs=repmat({':'},1,ndims(Image));
Subs{Dimension}=1;
Image(Subs{:})=tensorprod(double(Image),[0.2989,0.5870,0.1140],Dimension,2);
Image=Image(Subs{:});

%[appendix]{"version":"1.0"}
%---

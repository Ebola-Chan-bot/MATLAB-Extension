%[text] 内置imread的升级版，额外支持WebP格式图像
%[text] 此函数将首先尝试调用内置imread，如果失败将尝试调用libwebp。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [___]=MATLAB.ImageSci.ImRead(___);
%[text] %此函数支持与内置imread相同的输入和输出
%[text] 
%[text] WebP=MATLAB.ImageSci.ImRead(WebpPath);
%[text] %额外支持内置imread所不支持的WebP格式图像
%[text] ```
%[text] ## 输入参数
%[text] 此函数支持内置imread的所有参数。除此之外还支持：
%[text] WebpPath(1,1)string，WebP格式图像文件路径
%[text] ## 返回值
%[text] 对于一般图像格式，返回值与内置imread相同。对于WebP图像格式，仅返回以下参数：
%[text] WebP(:,:,3:4)uint8，WebP图像数组。第1维高度，第2维宽度，第3维RGB或RGBA，取决于图像文件本身是否具有透明通道。
%[text] **See also** [imread](<matlab:doc imread>)
function varargout = ImRead(varargin)
%命名空间：Im
try
	[varargout{1:nargout}]=imread(varargin{:});
catch ME
	if ME.identifier=="MATLAB:imagesci:imread:fileFormat"
		varargout{1}=permute(MATLAB.internal.WindowsAPI.WebpRead.Call(varargin{1}),[3,2,1]);
	else
		ME.rethrow;
	end
end

%[appendix]{"version":"1.0"}
%---

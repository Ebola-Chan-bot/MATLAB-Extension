classdef Window<handle
	properties(SetAccess=immutable)
		Pointer
	end
	methods(Access=private)
		function obj=Window(Pointer)
			obj.Pointer=Pointer;
		end
	end
	methods(Static)
		function S=Screens
			%不能用持久变量，因为可能插拔新的屏幕
			S=struct2table(MATLAB.internal.WindowsAPI.Window_Screens.Call);
		end
		function obj=Create(varargin)
			%在指定屏幕的指定位置创建指定大小的窗口
			%# 语法
			% ```
			% obj=MATLAB.Graphics.Window.Create(Name=Value);
			% ```
			%# 名称值参数
			% DeviceName(1,1)string，显示器设备名，指定要显示窗口的显示器设备名称，必须完全匹配Screens函数返回表的DeviceName列中的某一个设备名。如果不指定此参数，默
			%  认选择当前系统主要显示器。
			% PositionXY(1,2)uint16=[0,0]，窗口左上角坐标，相对于指定的显示器设备，
			% SizeWH(1,2)uint16，窗口的宽度和高度。如果不指定，窗口将一直扩张到屏幕右下角。
			%# 返回值
			% obj(1,1)MATLAB.Graphics.Window，创建的窗口对象
			obj=MATLAB.Graphics.Window(MATLAB.internal.WindowsAPI.Window_Create.Call(varargin{:}));
		end
	end
	methods
		function delete(obj)
			MATLAB.internal.WindowsAPI.Window_Destroy.Call(obj.Pointer);
		end
		function Image(obj,BGRAp,Rectangle)
			%在窗口上显示图像
			%# 语法
			% ```
			% obj.Image(BGRAp)
			% %在窗口左上角显示不缩放的图像
			%
			% obj.Image(BGRAp,Rectangle);
			% %将图像显示在指定矩形框中
			% ```
			%# 示例
			% ```
			% [I,~,A]=imread('图标.png');
			% obj.Image(permute(cat(3,uint8(single(I(:,:,[3,2,1]).*single(A)/255),A),[3,2,1]));
			% ```
			%# 输入参数
			% ## BGRAp(4,:,:)uint8
			%  BGRAp图像数组。此图像格式，1个像素用4个字节表示：
			%  1. 蓝色通道B，范围0~A
			%  2. 绿色通道G，范围0~A
			%  3. 红色通道R，范围0~A
			%  4. 不透明度A，范围0~255
			%  注意，BGR三个通道值是预乘(premultiplied, p)了不透明度的，因此它们的值都不应超过不透明度值。BGRAp图像是一个3维数组，第1维排列BGRA四个通道，第2维图像宽
			%   度，第3维图像高度，简称BGRAp-X-Y格式。而常用的MATLAB内置imread函数读入的图像格式，第1个返回值是Y-X-RGBs，即第1维图像高度，第2维图像宽度，第3维是未预乘
			%   的直通(straight, s)RGB三通道；第3个返回值是Y-X-A，即不透明度。要将imread读入的图像用于显示，必须进行格式转换，即先进行不透明度预乘，然后拼接、换维等操
			%   作。详见示例代码。
			% ## Rectangle(1,4)single
			%  要显示图像位置的矩形框，4个single值分别代表矩形框的左上角XY坐标和右下角XY坐标。
			%See also cat imread permute
			arguments
				obj
				BGRAp
				Rectangle single=single([0,0,size(BGRAp,2:3)]);
			end
			MATLAB.internal.WindowsAPI.Window_Image.Call(obj.Pointer,BGRAp,Rectangle);
		end
	end
end
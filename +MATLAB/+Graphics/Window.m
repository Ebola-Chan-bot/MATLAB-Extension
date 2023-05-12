classdef Window<handle
	%创建一个全透明Windows窗口，可以在其上显示图像
	%窗口默认是完全透明的，只有在添加了视觉元素后才会有任何显示。此窗口可以在任务栏中关闭，也可以从工作区中删除变量来关闭窗口。可以使用 clear mex 来关闭所有窗口。
	%在窗口上绘图需要使用Image和Fill方法，这两个方法分别绘制特定图像和颜色填充，都会返回一个视觉元素指针。后续可以将指针交给RemoveVisual方法来删除此视觉元素，或者用
	% Clear方法直接清空所有视觉元素。
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
			%查询所有显示器信息
			%# 语法
			% ```
			% ScreenTable=MATLAB.Graphics.Window.Screens;
			% ```
			%# 返回值
			% ScreenTable(:,4)table，列出所有显示器信息的表格。包含以下列：
			% - DeviceName(1,1)string，显示器设备名称，可用于Create方法，作为创建窗口的基础显示器
			% - Description(1,1)string，显示器设备描述，一般是显卡的品牌型号等信息
			% - Rectangle(1,4)int32，显示范围矩形，相对于主显示器左上角，用4个int32分别表示显示器左上角的XY坐标和右下角的XY坐标。
			% - IsPrimary(1,1)logical，是否是主显示器，主显示器的左上角是坐标原点。
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
		function Visual=Image(obj,BGRAp,Rectangle)
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
			% ## Rectangle(1,4)single=single([0,0,size(BGRAp,2:3)])
			%  要显示图像位置的矩形框，4个single值分别代表矩形框的左上角XY坐标和右下角XY坐标，相对于窗口左上角。
			%# 返回值
			% Visual(1,1)uint64，指向新建的视觉元素的指针，将该指针传递给RemoveVisual方法可以定向移除此视觉元素。
			%See also cat imread permute MATLAB.Graphics.Window.RemoveVisual
			arguments
				obj
				BGRAp(4,:,:)uint8
				Rectangle(1,4)single=single([0,0,size(BGRAp,2:3)]);
			end
			Visual=MATLAB.internal.WindowsAPI.Window_Image.Call(obj.Pointer,BGRAp,Rectangle);
		end
		function Clear(obj)
			%清空窗口，变成完全透明。此窗口创建的所有视觉元素指针将变为无效。
			MATLAB.internal.WindowsAPI.Window_Clear.Call(obj.Pointer);
		end
		function Visual=Fill(obj,Color)
			%用指定颜色填满整个窗口。
			%# 语法
			% ```
			% obj.Fill(Color);
			% ```
			%# 示例
			% 注意，输入颜色值严格要求为uint8类型，可以用十六进制语法指定uint8字面类型常量
			% ```
			% obj.Fill([0xff,0,0,0]);
			% %将窗口填充全黑色
			%
			% obj.Fill([0x80,255,255,255]);
			% %将窗口填充半透明白色
			% ```
			%# 输入参数
			% Color(1,4)uint8，用4个字节分别表示颜色的ARGB（不透明度，红，绿，蓝）通道值（不预乘）。注意此处的颜色格式不同于Image方法的要求。
			%# 返回值
			% Visual(1,1)uint64，指向新建的视觉元素的指针，将该指针传递给RemoveVisual方法可以定向移除此视觉元素。
			%See also MATLAB.Graphics.Window.RemoveVisual
			Visual=MATLAB.internal.WindowsAPI.Window_Fill.Call(obj.Pointer,Color);
		end
		function RemoveVisual(obj,Visual)
			%移除指定的视觉元素
			%# 语法
			% ```
			% obj.RemoveVisual(Visual);
			% ```
			%# 输入参数
			% Visual uint64，指向要移除的视觉元素的指针。如果指针无效，将直接跳过，不会出错。
			arguments
				obj
				Visual uint64
			end
			MATLAB.internal.WindowsAPI.Window_RemoveVisual.Call(obj.Pointer,Visual);
		end
	end
end
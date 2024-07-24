#pragma once
#include<winrt/windows.ui.composition.h>
#include<winrt/windows.ui.composition.desktop.h>
#include<d2d1_3.h>
namespace winrt
{
	using namespace winrt::Windows::UI::Composition;
	using namespace winrt::Windows::Graphics;
}
struct 窗口
{
	const winrt::VisualCollection 视觉集合;
	窗口(const 窗口&) = delete;
	static 窗口* 创建(int X, int Y, int W, int H);
	winrt::SpriteVisual 画图(const void* 像素缓冲, D2D1_SIZE_U 图像尺寸, const D2D1_RECT_F& 图像位置)const;
	winrt::SpriteVisual 填充(winrt::Windows::UI::Color 颜色)const;
	~窗口() { DestroyWindow(窗口句柄); }
protected:
	const HWND 窗口句柄;
	const winrt::Desktop::DesktopWindowTarget 桌面窗口目标;
	const uint16_t 窗口宽度;
	const uint16_t 窗口高度;
	//此对象无法在窗口间共享
	窗口(HWND 窗口句柄, winrt::Desktop::DesktopWindowTarget 桌面窗口目标, winrt::VisualCollection 视觉集合, uint16_t 窗口宽度, uint16_t 窗口高度) :窗口句柄(窗口句柄), 桌面窗口目标(桌面窗口目标), 视觉集合(视觉集合), 窗口宽度(窗口宽度), 窗口高度(窗口高度) {}
};
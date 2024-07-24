#include"pch.h"
#include"窗口.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
using namespace Mex工具;
using namespace matlab::data;
struct 设备查询_s
{
	const wchar_t* 设备名称;
	RECT 矩形范围;
	bool 找到 = false;
};
static BOOL CALLBACK 查找显示器(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData)
{
	设备查询_s* const 设备查询 = (设备查询_s*)dwData;
	MONITORINFOEXW 当前显示器;
	当前显示器.cbSize = sizeof(MONITORINFOEXW);
	GetMonitorInfoW(hMonitor, &当前显示器);
	if (wcscmp(当前显示器.szDevice, 设备查询->设备名称))
		return TRUE;
	else
	{
		设备查询->矩形范围 = *lprcMonitor;
		设备查询->找到 = true;
		return FALSE;
	}
}
Mex工具API(Window_Create)
{
	std::optional<String>显示器名;
	struct
	{
		int16_t X;
		int16_t Y;
	}XY = { 0,0 };
	struct WH_s
	{
		uint16_t W;
		uint16_t H;
	};
	std::optional<WH_s>WH;
	for (size_t a = 1; a < 输入.size(); a += 2)
	{
		const String 参数名 = 万能转码<String>(std::move(输入[a]));
		const wchar_t* const 参数名指针 = (wchar_t*)参数名.c_str();
		if (!wcscmp(参数名指针, L"DeviceName"))
			显示器名 = 万能转码<String>(std::move(输入[a + 1]));
		else if (!wcscmp(参数名指针, L"PositionXY"))
			万能转码(std::move(输入[a + 1]), (int16_t*)&XY);
		else if (!wcscmp(参数名指针, L"SizeWH"))
		{
			WH_s 缓冲;
			万能转码(std::move(输入[a + 1]),(uint16_t*)&缓冲);
			WH = 缓冲;
		}
	}
	if (显示器名)
	{
		设备查询_s 设备查询{ .设备名称 = (wchar_t*)显示器名.value().c_str() };
		EnumDisplayMonitors(NULL, NULL, 查找显示器, (LPARAM)&设备查询);
		if (设备查询.找到)
		{
			RECT& 矩形范围 = 设备查询.矩形范围;
			XY.X += 矩形范围.left;
			XY.Y += 矩形范围.top;
			if (!WH)
				WH = { uint16_t(矩形范围.right - XY.X), uint16_t(矩形范围.bottom - XY.Y) };
		}
		else
			EnumThrow(MATLAB::Exception::Specified_device_not_found);
	}
	else if (!WH)
		WH = { (uint16_t)GetSystemMetrics(SM_CXSCREEN), (uint16_t)GetSystemMetrics(SM_CYSCREEN) };
	const WH_s WH_v = WH.value();
	输出[0] = 万能转码(窗口::创建(XY.X, XY.Y, WH_v.W, WH_v.H));
}
Mex工具API(Window_Destroy)
{
	//销毁函数本身不会抛出异常，不需要额外try
	窗口::销毁(万能转码<窗口*>(输入[1]));
}
Mex工具API(Window_Image)
{
	const ArrayDimensions 图像尺寸 = 输入[2].getDimensions();	
	const buffer_ptr_t<uint8_t>像素缓冲 = TypedArray<uint8_t>(std::move(输入[2])).release();
	const buffer_ptr_t<float>图像位置 = TypedArray<float>(std::move(输入[3])).release();
	const 窗口* const 窗口指针 = 万能转码<窗口*>(std::move(输入[1]));
	const uint8_t* const 像素指针 = 像素缓冲.get();
	const D2D1_SIZE_U D2D尺寸 = D2D1::SizeU(图像尺寸[1], 图像尺寸[2]);
	const D2D1_RECT_F& D2D矩形 = *(D2D1_RECT_F*)图像位置.get();
	winrt::SpriteVisual 精灵视觉(nullptr);
	try
	{
		精灵视觉 = 窗口指针->画图(像素指针, D2D尺寸, D2D矩形);
	}
	catch (...)
	{
		EnumThrow(MATLAB::Exception::Invalid_pointer);
	}
	输出[0] = 万能转码(winrt::get_abi(精灵视觉));
}
static BOOL CALLBACK 枚举显示器(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData)
{
	MONITORINFOEXW* const 当前显示器 = (*(MONITORINFOEXW**)dwData)++;
	当前显示器->cbSize = sizeof(MONITORINFOEXW);
	GetMonitorInfoW(hMonitor, 当前显示器);
	return TRUE;
}
Mex工具API(Window_Screens)
{
	const uint8_t 显示器个数 = GetSystemMetrics(SM_CMONITORS);
	const std::unique_ptr<MONITORINFOEXW[]>所有显示器 = std::make_unique<MONITORINFOEXW[]>(显示器个数);
	MONITORINFOEXW* 当前显示器 = 所有显示器.get();
	EnumDisplayMonitors(NULL, NULL, 枚举显示器, (LPARAM)&当前显示器);
	DISPLAY_DEVICE dd{ .cb = sizeof(DISPLAY_DEVICE) };
	StructArray 输出结构 = 数组工厂.createStructArray({ 显示器个数,1 }, { "DeviceName","Description","Rectangle","IsPrimary" });
	for (uint8_t a = 0; a < 显示器个数; ++a)
	{
		DWORD devNum = 0;
		while (EnumDisplayDevicesW(NULL, devNum++, &dd, 0))
			if (!wcscmp(所有显示器[a].szDevice, dd.DeviceName))
			{
				//Reference不能const，否则无法修改信息结构
				Reference<Struct>信息结构 = 输出结构[a];
				信息结构["DeviceName"] = 万能转码<StringArray>(dd.DeviceName);
				信息结构["Description"] = 万能转码<StringArray>(dd.DeviceString);
				信息结构["Rectangle"] = 万能转码((int32_t*)&所有显示器[a].rcMonitor, { 1,4 });
				信息结构["IsPrimary"] = 数组工厂.createScalar<bool>(所有显示器[a].dwFlags);
				break;
			}
	}
	输出[0] = 输出结构;
}
Mex工具API(Window_Clear)
{
	const 窗口* const 窗口指针 = 万能转码<窗口*>(std::move(输入[1]));
	try
	{
		窗口指针->视觉集合.RemoveAll();
	}
	catch (...)
	{
		EnumThrow(MATLAB::Exception::Invalid_pointer);
	}
}
Mex工具API(Window_Fill)
{
	const 窗口* const 窗口指针 = 万能转码<窗口*>(std::move(输入[1]));
	winrt::Windows::UI::Color 颜色;
	switch (输入[2].getType())
	{
	case ArrayType::UINT8:
		if (输入[2].getNumberOfElements() > 4)[[unlikely]]
			EnumThrow(MATLAB::Exception::Incorrect_fill_color_data_type);
		万能转码(std::move(输入[2]), (void*)&颜色);
		break;
	case ArrayType::UINT32:
		*(uint32_t*)&颜色 = 万能转码<uint32_t>(std::move(输入[2]));
		break;
	default:
		EnumThrow(MATLAB::Exception::Incorrect_fill_color_data_type);
	}
	winrt::SpriteVisual 精灵视觉(nullptr);
	try
	{
		精灵视觉 = 窗口指针->填充(颜色);
	}
	catch (...)
	{
		EnumThrow(MATLAB::Exception::Invalid_pointer);
	}
	输出[0] = 万能转码(winrt::get_abi(精灵视觉));
}
Mex工具API(Window_RemoveVisual)
{
	const 窗口* const 窗口指针 = 万能转码<窗口*>(std::move(输入[1]));
	const TypedArray<size_t> 数组(std::move(输入[2]));
	const uint8_t 个数 = 数组.getNumberOfElements();
	winrt::SpriteVisual 精灵视觉(nullptr);
	for (size_t a : 数组)
	{
		winrt::attach_abi(精灵视觉, (void*)a);
		try
		{
			窗口指针->视觉集合.Remove(精灵视觉);
		}
		catch (...) {}
		//不做这一步可能导致Release析构时出错
		winrt::detach_abi(精灵视觉);
	}
}
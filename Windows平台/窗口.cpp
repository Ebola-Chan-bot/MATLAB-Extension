#include "pch.h"
#include "窗口.h"
#include"MATLAB异常.h"
#include<windows.ui.composition.interop.h>
#include<winrt/windows.system.h>
#include<DispatcherQueue.h>
#include<d3d11_4.h>
#include<list>
#include<memory>
#pragma comment(lib,"windowsapp.lib")
#pragma comment(lib,"d3d12.lib")
#pragma comment(lib,"d2d1.lib")
namespace ABI
{
	using namespace ABI::Windows::UI::Composition;
}
void 窗口::安全删除(窗口* 旧窗口)noexcept
{
	//如果指针无效，delete将会抛出debugbreak，此异常十分特殊，只能用__try__except捕获，并且不能和try-catch出现在同一个函数内
	__try
	{
		delete 旧窗口;
	}
	__except (EXCEPTION_EXECUTE_HANDLER) {}
}
std::list<窗口*>所有窗口;
//不能在DllMain阶段初始化，但可以析构
winrt::Compositor 合成器(nullptr);
winrt::com_ptr<ABI::Desktop::ICompositorDesktopInterop>合成器互操作;
窗口* 窗口::创建(int X, int Y, int W, int H)
{
	if (!合成器)
	{
		if (!winrt::Windows::System::DispatcherQueue::GetForCurrentThread())
		{
			static winrt::Windows::System::DispatcherQueueController 调度进程队列控制器(nullptr);
			CreateDispatcherQueueController({ sizeof(DispatcherQueueOptions),DQTYPE_THREAD_CURRENT,DQTAT_COM_ASTA }, (PDISPATCHERQUEUECONTROLLER*)winrt::put_abi(调度进程队列控制器));
		}
		合成器 = winrt::Compositor();
		合成器互操作 = 合成器.as<ABI::Desktop::ICompositorDesktopInterop>();
	}
	const HWND 窗口句柄 = CreateWindowExA(WS_EX_LAYERED, "STATIC", NULL, WS_VISIBLE | WS_POPUP, X, Y, W, H, NULL, NULL, GetModuleHandle(NULL), NULL);
	winrt::Desktop::DesktopWindowTarget 桌面窗口目标(nullptr);
	合成器互操作->CreateDesktopWindowTarget(窗口句柄, true, (ABI::Desktop::IDesktopWindowTarget**)winrt::put_abi(桌面窗口目标));
	const winrt::ContainerVisual 容器视觉 = 合成器.CreateContainerVisual();
	桌面窗口目标.Root(容器视觉);
	窗口* const 新窗口 = new 窗口(窗口句柄, 桌面窗口目标, 容器视觉.Children(), W, H);
	所有窗口.push_back(新窗口);
	return 新窗口;
}
void 窗口::销毁(窗口*旧窗口)noexcept
{
	安全删除(旧窗口);
	try
	{
		所有窗口.remove(旧窗口);
	}
	catch (...) {}
}
winrt::com_ptr<ID2D1Device6>D2D设备;
winrt::SpriteVisual 窗口::画图(const void* 像素缓冲, D2D1_SIZE_U 图像尺寸, const D2D1_RECT_F& 图像位置)const
{
	if(!D2D设备)
	{
		winrt::com_ptr<ID3D11Device>D3D设备;
		constexpr D3D_FEATURE_LEVEL D3D功能等级 = D3D_FEATURE_LEVEL_11_1;
		D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, 0, D3D11_CREATE_DEVICE_BGRA_SUPPORT, &D3D功能等级, 1, D3D11_SDK_VERSION, D3D设备.put(), nullptr, nullptr);
		winrt::com_ptr<ID2D1Factory7>D2D工厂;
		D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, __uuidof(D2D工厂), nullptr, D2D工厂.put_void());
		D2D工厂->CreateDevice(D3D设备.as<IDXGIDevice4>().get(), D2D设备.put());
	}
	winrt::com_ptr<ABI::ICompositionGraphicsDevice>合成图形设备接口;
	合成器.as<ABI::ICompositorInterop>()->CreateGraphicsDevice(D2D设备.get(), 合成图形设备接口.put());
	winrt::CompositionGraphicsDevice 合成图形设备 = 合成图形设备接口.as<winrt::CompositionGraphicsDevice>();
	const winrt::CompositionDrawingSurface 合成绘图表面 = 合成图形设备.CreateDrawingSurface2(winrt::Windows::Graphics::SizeInt32(图像尺寸.width, 图像尺寸.height), winrt::DirectX::DirectXPixelFormat::B8G8R8A8UIntNormalized, winrt::DirectX::DirectXAlphaMode::Premultiplied);
	const winrt::com_ptr<ABI::ICompositionDrawingSurfaceInterop>合成绘图表面互操作 = 合成绘图表面.as<ABI::ICompositionDrawingSurfaceInterop>();
	winrt::com_ptr<ID2D1DeviceContext>D2D设备上下文;
	POINT 偏移;
	合成绘图表面互操作->BeginDraw(nullptr, __uuidof(D2D设备上下文), D2D设备上下文.put_void(), &偏移);
	winrt::com_ptr<ID2D1Bitmap>D2D位图;
	D2D设备上下文->CreateBitmap(图像尺寸, 像素缓冲, 图像尺寸.width * 4, D2D1::BitmapProperties(D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED)), D2D位图.put());
	D2D设备上下文->DrawBitmap(D2D位图.get());
	合成绘图表面互操作->EndDraw();
	const winrt::SpriteVisual 精灵视觉 = 合成器.CreateSpriteVisual();
	精灵视觉.Size({ 图像位置.right - 图像位置.left,图像位置.bottom - 图像位置.top });
	const winrt::CompositionSurfaceBrush 合成表面画笔 = 合成器.CreateSurfaceBrush(合成绘图表面);
	合成表面画笔.Stretch(winrt::CompositionStretch::Fill);
	精灵视觉.Brush(合成表面画笔);
	精灵视觉.Offset({ 图像位置.left,图像位置.top,0 });
	视觉集合.InsertAtTop(精灵视觉);
	return 精灵视觉;
}
void 窗口::销毁所有()noexcept
{
	for (窗口* a : 所有窗口)
		安全删除(a);
	//手动销毁不能在DllMain阶段销毁的对象
	D2D设备 = nullptr;
}
winrt::SpriteVisual 窗口::填充(winrt::Windows::UI::Color 颜色)const
{
	const winrt::SpriteVisual 精灵视觉 = 合成器.CreateSpriteVisual();
	精灵视觉.Brush(合成器.CreateColorBrush(颜色));
	精灵视觉.Size({ (float)窗口宽度,(float)窗口高度 });
	精灵视觉.Offset({ 0,0,0 });
	视觉集合.InsertAtTop(精灵视觉);
	return 精灵视觉;
}
#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#include<ShlObj.h>
#include<wrl/client.h>
#include<webp/decode.h>
#include<filesystem>
using namespace Mex工具;
using namespace matlab::data;
Mex工具API(TypeCast)
{
	const ArrayType 类型 = 万能转码<ArrayType>(std::move(输入[2]));
	const size_t 元素数 = 数组字节数(输入[1]) / 类型字节数(类型);
	const std::unique_ptr<动态类型缓冲>缓冲 = 动态类型缓冲::创建(类型, 元素数);
	万能转码(std::move(输入[1]), 缓冲->get());
	输出[0] = 缓冲->创建数组({ 元素数 });
}
Mex工具API(LnkShortcut)
{
	constexpr char16_t 扩展名[] = u".lnk";
	const String 来源路径 = 万能转码<String>(std::move(输入[1]));
	String 目标路径;
	if (输入.size() > 2)
	{
		目标路径 = 万能转码<String>(std::move(输入[2]));
		const std::filesystem::path 目标(目标路径);
		if (std::filesystem::is_directory(目标))
		{
			const std::filesystem::path 来源(来源路径);
			目标路径 = (目标 / (来源.has_stem() ? 来源.stem().u16string() : 来源路径.substr(0, 1))).u16string();
		}
		if (!目标路径.ends_with(扩展名))
			目标路径 += 扩展名;
	}
	else
	{
		const std::filesystem::path 来源(来源路径);
		目标路径 = (来源.has_stem() ? 来源.stem().u16string() : 来源路径.substr(0, 1)) + 扩展名;
	}
	Microsoft::WRL::ComPtr<IShellLinkW>外壳链接;
	CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, IID_IShellLinkW, (LPVOID*)外壳链接.GetAddressOf());
	外壳链接->SetPath((LPCWSTR)来源路径.c_str());
	Microsoft::WRL::ComPtr<IPersistFile>持久文件;
	外壳链接->QueryInterface(IID_IPersistFile, (void**)持久文件.GetAddressOf());
	const HRESULT 结果 = 持久文件->Save((LPCOLESTR)目标路径.c_str(), TRUE);
	if (FAILED(结果))[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_save_the_shortcut);
}
[[noreturn]] Mex工具API(Crash)
{
	throw;
}
Mex工具API(Pause)
{
	if (输入.size() > 1)
	{
		double 秒数 = 万能转码<double>(std::move(输入[1]));
		if (秒数 < std::numeric_limits<double>::infinity())
			std::this_thread::sleep_for(std::chrono::milliseconds((uint64_t)(秒数 * 1000)));
		return;
	}
	while (true)
#undef max
		std::this_thread::sleep_for(std::chrono::years::max());
}
Mex工具API(ArrayType_FromData)
{
	输出[0] = 数组工厂.createScalar<uint8_t>((int)输入[1].getType());
}
Mex工具API(WebpRead)
{
	const String 路径 = 万能转码<String>(std::move(输入[1]));
	HANDLE 句柄 = CreateFileW((LPCWSTR)路径.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (句柄 == INVALID_HANDLE_VALUE)[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_open_the_file);
	const std::unique_ptr<void, decltype(&CloseHandle)>文件句柄(句柄, CloseHandle);
	LARGE_INTEGER 文件大小;
	GetFileSizeEx(句柄, &文件大小);
	句柄 = CreateFileMapping(句柄, NULL, PAGE_READONLY, 0, 0, nullptr);
	if (!句柄)[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_open_the_file);
	const std::unique_ptr<void, decltype(&CloseHandle)>映射句柄(句柄, CloseHandle);
	句柄 = MapViewOfFile(句柄, FILE_MAP_READ, 0, 0, 0);
	if (!句柄)[[unlikely]]
		CheckLastError(MATLAB::Exception::Failed_to_open_the_file);
	const std::unique_ptr<uint8_t, decltype(&UnmapViewOfFile)>映射指针((uint8_t*)句柄, UnmapViewOfFile);
	WebPBitstreamFeatures 元数据;
	const VP8StatusCode 结果 = WebPGetFeatures(映射指针.get(), 文件大小.QuadPart, &元数据);
	if (结果)[[unlikely]]
		EnumThrow(结果);
	if (元数据.has_alpha)
	{
		const int 字节数 = 元数据.height * 元数据.width * 4;
		buffer_ptr_t<uint8_t>缓冲 = 数组工厂.createBuffer<uint8_t>(字节数);
		if (!WebPDecodeRGBAInto(映射指针.get(), 文件大小.QuadPart, 缓冲.get(), 字节数, 元数据.width * 4))[[unlikely]]
			EnumThrow(MATLAB::Exception::Failed_to_decode_pixel_values);
		输出[0] = 数组工厂.createArrayFromBuffer({ 4,(size_t)元数据.width,(size_t)元数据.height }, std::move(缓冲));
	}
	else
	{
		const int 字节数 = 元数据.height * 元数据.width * 3;
		buffer_ptr_t<uint8_t>缓冲 = 数组工厂.createBuffer<uint8_t>(字节数);
		if (!WebPDecodeRGBInto(映射指针.get(), 文件大小.QuadPart, 缓冲.get(), 字节数, 元数据.width * 3))[[unlikely]]
			EnumThrow(MATLAB::Exception::Failed_to_decode_pixel_values);
		输出[0] = 数组工厂.createArrayFromBuffer({ 3,(size_t)元数据.width,(size_t)元数据.height }, std::move(缓冲));
	}
}
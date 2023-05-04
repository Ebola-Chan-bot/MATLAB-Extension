#include"pch.h"
#include"MexAPI.h"
#include"MATLAB异常.h"
#include<ShlObj.h>
#include<wrl/client.h>
#include<filesystem>
using namespace Mex工具;
API声明(TypeCast)
{
	const ArrayType 类型 = 万能转码<ArrayType>(std::move(inputs[2]));
	const std::unique_ptr<动态类型缓冲>输出 = 动态类型缓冲::创建(类型, 数组字节数(inputs[1]) / 类型尺寸[(int)类型]);
	万能转码(std::move(inputs[1]), 输出->指针);
	outputs[1] = 输出->打包();
}
API声明(LnkShortcut)
{
	constexpr char16_t 扩展名[] = u".lnk";
	const String 来源路径 = 万能转码<String>(std::move(inputs[1]));
	String 目标路径;
	if (inputs.size() > 2)
	{
		目标路径 = 万能转码<String>(std::move(inputs[2]));
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
	if (FAILED(结果))
		throw MATLAB异常(MATLAB异常类型::保存快捷方式失败, 内部异常类型::COM异常, 结果);
}
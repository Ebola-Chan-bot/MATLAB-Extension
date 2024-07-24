#include "pch.h"
#include <MATLAB异常.h>
#include <Mex工具.hpp>
#include <zip.h>
using namespace Mex工具;
using namespace matlab::data;
static zip_int64_t 取文件数目(zip_t* Zip)
{
	const zip_int64_t 数目 = zip_get_num_entries(Zip, 0);
	if (数目 == -1)[[unlikely]]
		EnumThrow(MATLAB::Exception::The_Zip_file_is_invalid);
	return 数目;
}
template<typename...消息类型>
[[noreturn]]static void ZipThrow(MATLAB::Exception 标识符, int 错误代码, 消息类型...消息)
{
	std::unique_ptr<zip_error_t, decltype(&zip_error_fini)>错误结构(nullptr, zip_error_fini);
	zip_error_init_with_code(错误结构.get(), 错误代码);
	EnumThrow(标识符, zip_error_strerror(错误结构.get()), 消息...);
}
Mex工具API(ZipOpen)
{
	const std::string path = 万能转码<std::string>(std::move(输入[1]));
	int 错误代码;
	if (zip_t* const Zip = zip_open(path.c_str(), ZIP_RDONLY, &错误代码))
	{
		输出[0] = 万能转码(Zip);
		自动析构(Zip, [](void* 指针) {zip_discard((zip_t*)指针); });
	}
	else[[unlikely]]
		ZipThrow(MATLAB::Exception::Zip_failed_to_open, 错误代码);
}
constexpr zip_flags_t 文件名旗帜 = ZIP_FL_NOCASE | ZIP_FL_ENC_UTF_8;
Mex工具API(ZipNameLocate)
{
	zip_t* const Zip = 万能转码<zip_t*>(输入[1]);
	const size_t 个数 = 输入[2].getNumberOfElements();
	TypedArray<zip_int64_t>Locate = 数组工厂.createArray<zip_int64_t>({ 个数 });
	const std::unique_ptr<std::string[]>UTF8 = std::make_unique_for_overwrite<std::string[]>(个数);
	万能转码(std::move(输入[2]),UTF8.get());
	for (size_t a = 0; a < 个数; ++a)
		if ((Locate[a] = zip_name_locate(Zip, UTF8[a].c_str(), 文件名旗帜)) == -1) [[unlikely]]
		{
			const int 错误代码 = zip_get_error(Zip)->zip_err;
			if (错误代码 != ZIP_ER_NOENT)
				ZipThrow(MATLAB::Exception::Zip_file_name_search_failed, 错误代码, "：", UTF8[a]);
		}
	输出[0] = std::move(Locate);
}
Mex工具API(ZipFopen)
{
	zip_t* const Zip = 万能转码<zip_t*>(输入[1]);
	switch(输入.size())
	{
	case 2:
	{
		const zip_int64_t 文件数目 = 取文件数目(Zip);
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ (size_t)文件数目 });
		for (zip_int64_t a = 0; a < 文件数目; ++a)
		{
			zip_file_t* 文件 = zip_fopen_index(Zip, a, 0);
			if (!(返回列表[a] = (uint64_t)文件)) [[unlikely]]
				ZipThrow(MATLAB::Exception::Zip_failed_to_open, zip_get_error(Zip)->zip_err, "出错序号：", a);
			自动析构(文件, [](void* 指针) {zip_fclose((zip_file_t*)指针); });
		}
		输出[0] = std::move(返回列表);
	}
	break;
	case 3:
	{
		Array&& 文件参数 = std::move(输入[2]);
		const size_t 文件数目 = 文件参数.getNumberOfElements();
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ 文件数目 });
		switch (文件参数.getType())
		{
		case ArrayType::CELL:
		case ArrayType::CHAR:
		case ArrayType::MATLAB_STRING:
		{
			const std::unique_ptr<std::string[]>文件名 = std::make_unique_for_overwrite<std::string[]>(文件数目);
			万能转码(std::move(文件参数), 文件名.get());
			for (size_t a = 0; a < 文件数目; ++a)
			{
				zip_file_t* 文件 = zip_fopen(Zip, 文件名[a].c_str(), 文件名旗帜);
				if (!(返回列表[a] = (uint64_t)文件)) [[unlikely]]
					ZipThrow(MATLAB::Exception::Zip_failed_to_open, zip_get_error(Zip)->zip_err, "出错序号：", a);
				自动析构(文件, [](void* 指针) {zip_fclose((zip_file_t*)指针); });
			}
		}
		break;
		case ArrayType::UINT64:
		{
			TypedArray<uint64_t>文件索引(文件参数);
			for (size_t a = 0; a < 文件数目; ++a)
			{
				zip_file_t* 文件 = zip_fopen_index(Zip, 文件索引[a], 0);
				if (!(返回列表[a] = (uint64_t)文件)) [[unlikely]]
					ZipThrow(MATLAB::Exception::Zip_failed_to_open, zip_get_error(Zip)->zip_err, "出错序号：", a);
				自动析构(文件, [](void* 指针) {zip_fclose((zip_file_t*)指针); });
			}
		}
		break;
		default:
			EnumThrow(MATLAB::Exception::Input_parameter_type_is_incorrect, 2);
		}
		输出[0] = std::move(返回列表); 
	}
	break;
	default:
		EnumThrow(MATLAB::Exception::The_number_of_entered_parameters_is_incorrect);
	}
}
Mex工具API(ZipFread)
{
	TypedArray<uint64_t>文件列表(std::move(输入[1]));
	const zip_uint64_t nbytes = 万能转码<uint64_t>(std::move(输入[2]));
	const size_t 文件数目 = 文件列表.getNumberOfElements();
	buffer_ptr_t<uint8_t>读入字节 = 数组工厂.createBuffer<uint8_t>(文件数目 * nbytes);
	TypedArray<zip_int64_t>实际读数 = 数组工厂.createArray<zip_int64_t>({ 1,文件数目 });
	uint8_t* 写出头 = 读入字节.get();
	for (size_t a = 0; a < 文件数目; ++a)
	{
		zip_file_t* const 文件 = (zip_file_t*)(uint64_t)文件列表[a];
		if ((实际读数[a] = zip_fread(文件, 写出头, nbytes)) == -1) [[unlikely]]
			ZipThrow(MATLAB::Exception::Failed_to_read_the_Zip_file, zip_file_get_error(文件)->zip_err, "出错序号：", a);
		写出头 += nbytes;
	}
	输出[0] = 数组工厂.createArrayFromBuffer({ nbytes,文件数目 }, std::move(读入字节));
	输出[1] = std::move(实际读数);
}
Mex工具API(ZipFclose)
{
	for (const uint64_t 文件 : TypedArray<uint64_t>(std::move(输入[1])))
		if (手动析构((zip_file_t*)文件))
			zip_fclose((zip_file_t*)文件);
}
Mex工具API(ZipDiscard)
{
	zip_t*const 指针 = 万能转码<zip_t*>(std::move(输入[1]));
	if (手动析构(指针))
		zip_discard(指针);
}
Mex工具API(ZipGetSize)
{
	zip_t* const Zip = 万能转码<zip_t*>(std::move(输入[1]));
	zip_stat_t Stat;
	switch (输入.size())
	{
	case 2:
	{
		const zip_int64_t 文件数目 = 取文件数目(Zip);
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ (size_t)文件数目 });
		for (zip_int64_t a = 0; a < 文件数目; ++a)
		{
			if (zip_stat_index(Zip, a, 0, &Stat) == -1) [[unlikely]]
				ZipThrow(MATLAB::Exception::Failed_to_obtain_the_Zip_file_details, zip_get_error(Zip)->zip_err, "出错序号：", a);
			if (Stat.valid & ZIP_STAT_SIZE)
				返回列表[a] = Stat.size;
			else[[unlikely]]
				EnumThrow(MATLAB::Exception::Zip_does_not_record_file_size, "出错序号：", a);
		}
		输出[0] = std::move(返回列表);
	}
	break;
	case 3:
	{
		Array& 文件参数 = 输入[2];
		const size_t 文件数目 = 文件参数.getNumberOfElements();
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ 文件数目 });
		switch (文件参数.getType())
		{
		case ArrayType::CELL:
		case ArrayType::CHAR:
		case ArrayType::MATLAB_STRING:
		{
			std::unique_ptr<std::string[]>文件名 = 万能转码<std::unique_ptr<std::string[]>>(文件参数);
			for (size_t a = 0; a < 文件数目; ++a)
			{
				if (zip_stat(Zip, 文件名[a].c_str(), 0, &Stat) == -1) [[unlikely]]
					ZipThrow(MATLAB::Exception::Failed_to_obtain_the_Zip_file_details, zip_get_error(Zip)->zip_err, "出错序号：", a);
				if (Stat.valid & ZIP_STAT_SIZE)
					返回列表[a] = Stat.size;
				else [[unlikely]]
					EnumThrow(MATLAB::Exception::Zip_does_not_record_file_size, "出错序号：", a);
			}
		}
		break;
		case ArrayType::UINT64:
		{
			TypedArray<uint64_t>文件索引(文件参数);
			for (size_t a = 0; a < 文件数目; ++a)
			{
				if (zip_stat_index(Zip, 文件索引[a], 0, &Stat) == -1) [[unlikely]]
					ZipThrow(MATLAB::Exception::Failed_to_obtain_the_Zip_file_details, zip_get_error(Zip)->zip_err, "出错序号：", a);
				if (Stat.valid & ZIP_STAT_SIZE)
					返回列表[a] = Stat.size;
				else [[unlikely]]
					EnumThrow(MATLAB::Exception::Zip_does_not_record_file_size, "出错序号：", a);
			}
		}
		break;
		default:
			EnumThrow(MATLAB::Exception::Input_parameter_type_is_incorrect, 2);
		}
		输出[0] = std::move(返回列表);
	}
	break;
	default:
		EnumThrow(MATLAB::Exception::The_number_of_entered_parameters_is_incorrect);
	}
}
Mex工具API(ZipGetName)
{
	zip_t* const Zip = 万能转码<zip_t*>(std::move(输入[1]));
	switch (输入.size())
	{
	case 2:
	{
		const size_t 文件数目 = 取文件数目(Zip);
		StringArray 所有文件名 = 数组工厂.createArray<MATLABString>({ 文件数目 });
		for (size_t a = 0; a < 文件数目; ++a)
			if (const char* 文件名 = zip_get_name(Zip, a, 0))
				所有文件名[a] = 万能转码<MATLABString>(文件名);
			else[[unlikely]]
				ZipThrow(MATLAB::Exception::Failed_to_obtain_the_Zip_file_name, zip_get_error(Zip)->zip_err, "出错序号：", a);
		输出[0] = std::move(所有文件名);
	}
	break;
	case 3:
	{
		TypedArray<uint64_t> 文件索引(输入[2]);
		const size_t 文件数目 = 文件索引.getNumberOfElements();
		StringArray 文件名列表 = 数组工厂.createArray<MATLABString>({ 文件数目 });
		for (size_t a = 0; a < 文件数目; ++a)
			if (const char* 文件名 = zip_get_name(Zip, 文件索引[a], 0))
				文件名列表[a] = 万能转码<MATLABString>(文件名);
			else[[unlikely]]
				ZipThrow(MATLAB::Exception::Failed_to_obtain_the_Zip_file_name, zip_get_error(Zip)->zip_err, "出错序号：", a);
		输出[0] = std::move(文件名列表);
	}
	break;
	default:
		EnumThrow(MATLAB::Exception::The_number_of_entered_parameters_is_incorrect);
	}
}
Mex工具API(ZipGetNumEntries)
{
	输出[0] = 万能转码(取文件数目(万能转码<zip_t*>(输入[1])));
}
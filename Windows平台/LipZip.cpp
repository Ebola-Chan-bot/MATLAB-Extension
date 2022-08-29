#include "pch.h"
#include "MexAPI.h"
#include <zip.h>
#include "MATLAB异常.h"
zip_int64_t 取文件数目(zip_t* Zip)
{
	const zip_int64_t 数目 = zip_get_num_entries(Zip, 0);
	if (数目 == -1) [[unlikely]]
		throw MATLAB异常(Zip档案无效);
}
API声明(ZipOpen)
{
	std::string path = 万能转码<std::string>(std::move(inputs[1]));
	int 错误代码;
	if (const zip_t* const Zip = zip_open(path.c_str(), ZIP_RDONLY, &错误代码))
		outputs[1] = 数组工厂.createScalar((uint64_t)Zip);
	else[[unlikely]]
		throw MATLAB异常(Zip打开失败, LibZip异常, 错误代码);
}
constexpr zip_flags_t 文件名旗帜 = ZIP_FL_NOCASE | ZIP_FL_ENC_UTF_8;
API声明(ZipNameLocate)
{
	zip_t* const Zip = 万能转码<zip_t*>(std::move(inputs[1]));
	Array&UTF16 = inputs[2];
	const size_t 个数 = UTF16.getNumberOfElements();
	TypedArray<zip_int64_t>Locate = 数组工厂.createArray<zip_int64_t>({ 个数 });
	const std::unique_ptr<std::string[]>UTF8 = 万能转码<std::unique_ptr<std::string[]>>(std::move(UTF16));
	for (size_t a = 0; a < 个数; ++a)
		if ((Locate[a] = zip_name_locate(Zip, UTF8[a].c_str(), 文件名旗帜)) == -1) [[unlikely]]
		{
			const int 错误代码 = zip_get_error(Zip)->zip_err;
			if (错误代码 != ZIP_ER_NOENT) [[unlikely]]
				throw MATLAB异常(Zip文件名搜索失败, LibZip异常, 错误代码, a);
		}
	outputs[1] = std::move(Locate);
}
API声明(ZipFopen)
{
	zip_t* const Zip = 万能转码<zip_t*>(std::move(inputs[1]));
	switch(inputs.size())
	{
	case 2:
	{
		const zip_int64_t 文件数目 = 取文件数目(Zip);
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ (size_t)文件数目 });
		for (zip_int64_t a = 0; a < 文件数目; ++a)
			if (!(返回列表[a] = (uint64_t)zip_fopen_index(Zip, a, 0))) [[unlikely]]
				throw MATLAB异常(Zip文件打开失败, LibZip异常, zip_get_error(Zip)->zip_err, a);
		outputs[1] = std::move(返回列表);
	}
	break;
	case 3:
	{
		Array& 文件参数 = inputs[2];
		const size_t 文件数目 = 文件参数.getNumberOfElements();
		TypedArray<uint64_t>返回列表 = 数组工厂.createArray<uint64_t>({ 文件数目 });
		switch (文件参数.getType())
		{
		case ArrayType::CELL:
		case ArrayType::CHAR:
		case ArrayType::MATLAB_STRING:
		{
			std::unique_ptr<std::string[]>文件名 = 万能转码<std::unique_ptr<std::string[]>>(std::move(文件参数));
			for (size_t a = 0; a < 文件数目; ++a)
				if (!(返回列表[a] = (uint64_t)zip_fopen(Zip, 文件名[a].c_str(), 文件名旗帜))) [[unlikely]]
					throw MATLAB异常(Zip文件打开失败, LibZip异常, zip_get_error(Zip)->zip_err, a);
		}
		break;
		case ArrayType::UINT64:
		{
			TypedArray<uint64_t>文件索引(std::move(文件参数));
			for (size_t a = 0; a < 文件数目; ++a)
				if (!(返回列表[a] = (uint64_t)zip_fopen_index(Zip, 文件索引[a], 0))) [[unlikely]]
					throw MATLAB异常(Zip文件打开失败, LibZip异常, zip_get_error(Zip)->zip_err, a);
		}
		break;
		[[unlikely]] default:
			throw MATLAB异常(输入参数类型错误, 2);
		}
		outputs[1] = std::move(返回列表); 
	}
	break;
	[[unlikely]] default:
		throw MATLAB异常(输入参数数目错误);
	}
}
API声明(ZipFread)
{
	TypedArray<uint64_t>文件列表(std::move(inputs[1]));
	const zip_uint64_t nbytes = 万能转码<uint64_t>(std::move(inputs[2]));
	const size_t 文件数目 = 文件列表.getNumberOfElements();
	buffer_ptr_t<uint8_t>读入字节 = 数组工厂.createBuffer<uint8_t>(文件数目 * nbytes);
	TypedArray<zip_int64_t>实际读数 = 数组工厂.createArray<zip_int64_t>({ 文件数目 });
	uint8_t* 写出头 = 读入字节.get();
	for (size_t a = 0; a < 文件数目; ++a)
	{
		zip_file_t* const 文件 = (zip_file_t*)(uint64_t)文件列表[a];
		if ((实际读数[a] = zip_fread(文件, 写出头, nbytes)) == -1) [[unlikely]]
			throw MATLAB异常(Zip文件读入失败, LibZip异常, zip_file_get_error(文件)->zip_err, a);
		写出头 += nbytes;
	}
	outputs[1] = 数组工厂.createArrayFromBuffer({ nbytes,文件数目 }, std::move(读入字节));
	outputs[2] = std::move(实际读数);
}
API声明(ZipFclose)
{
	for (uint64_t 文件 : TypedArray<uint64_t>(std::move(inputs[1])))
		zip_fclose((zip_file_t*)文件);
}
API声明(ZipDiscard)
{
	zip_discard(万能转码<zip_t*>(std::move(inputs[1])));
}
API声明(ZipGetName)
{
	zip_t* const Zip = 万能转码<zip_t*>(std::move(inputs[1]));
	switch (inputs.size())
	{
	case 2:
	{
		const zip_int64_t 文件数目 = 取文件数目(Zip);
		std::unique_ptr<const char* []>文件名列表 = std::make_unique_for_overwrite<const char* []>(文件数目);
		for (zip_int64_t a = 0; a < 文件数目; ++a)
			if (!(文件名列表[a] = zip_get_name(Zip, a, 0))) [[unlikely]]
				throw MATLAB异常(Zip文件名获取失败, LibZip异常, zip_get_error(Zip)->zip_err, a);
		outputs[1] = 万能转码(文件名列表.get(), 文件数目);
	}
	case 3:
	{
		TypedArray<uint64_t> 文件索引(std::move(inputs[2]));
		const size_t 文件数目 = 文件索引.getNumberOfElements();
		std::unique_ptr<const char* []>文件名列表 = std::make_unique_for_overwrite<const char* []>(文件数目);
		for (size_t a = 0; a < 文件数目; ++a)
			if (!(文件名列表[a] = zip_get_name(Zip, 文件索引[a], 0))) [[unlikely]]
				throw MATLAB异常(Zip文件名获取失败, LibZip异常, zip_get_error(Zip)->zip_err, a);
		outputs[1] = 万能转码(文件名列表.get(), 文件数目);
	}
	break;
	[[unlikely]] default:
		throw MATLAB异常(输入参数数目错误);
	}
}
API声明(ZipGetNumEntries)
{
	outputs[1] = 数组工厂.createScalar(取文件数目(万能转码<zip_t*>(std::move(inputs[1]))));
}
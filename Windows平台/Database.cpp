#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#include<mariadb/conncpp.hpp>
#include<numeric>
using namespace Mex工具;
Mex工具API(Database_MariaDB)
{
	std::string URL;
	switch (输入.size())
	{
	case 1:
		URL = 万能转码<std::string>(std::move(输入[0]));
		break;
	case 4:
		URL = (std::ostringstream("jdbc:mariadb://") << 万能转码<std::string>(std::move(输入[0])) << ":3306/" << 万能转码<std::string>(std::move(输入[1])) << "?user=" << 万能转码<std::string>(std::move(输入[2])) << "&password=" << 万能转码<std::string>(std::move(输入[3]))).str();
		break;
	case 5:
		URL = (std::ostringstream("jdbc:mariadb://") << 万能转码<std::string>(std::move(输入[0])) << ":" << 万能转码<uint16_t>(std::move(输入[1])) << "/" << 万能转码<std::string>(std::move(输入[2])) << "?user=" << 万能转码<std::string>(std::move(输入[3])) << "&password=" << 万能转码<std::string>(std::move(输入[4]))).str();
		break;
	default:
		EnumThrow(MATLAB::Exception::The_number_of_entered_parameters_is_incorrect);
	}
	sql::Connection* const 连接 = sql::DriverManager::getConnection(URL);
	自动析构(连接);
	输出[0] = 万能转码(连接);
}
using namespace matlab::data;
struct 通用列适配器
{
	std::string MariaDB类型;
	virtual void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号) = 0;
	virtual ~通用列适配器() {}
};
template<typename T>
struct 特殊列适配器 :通用列适配器
{
	TypedArray<T> MATLAB数组;
	TypedArray<T>::const_iterator 迭代器;
	void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)override;
	特殊列适配器(TypedArray<T>&& MATLAB数组);
};
constexpr struct
{
	template<typename T>
	通用列适配器* operator()(TypedArray<T>&& MATLAB数组);
	通用列适配器* operator()(CellArray&& MATLAB数组)
	{

	}
}访问构造器;
Mex工具API(Database_UpdateByPrimary)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[0]));
	const std::string 表名 = 万能转码<std::string>(std::move(输入[1]));
	Array& 更新表 = 输入[2];
	const ArrayDimensions 行列数 = 更新表.getDimensions();
	const CellArray 所有MATLAB列名 = MATLAB引擎->feval<CellArray>("MATLAB.MixIn.DotReference", MATLAB引擎->feval<Array>("MATLAB.MixIn.DotReference", 更新表, "Properties"), "VariableNames");
	const std::unique_ptr<std::unique_ptr<通用列适配器>[]>所有列 = std::make_unique_for_overwrite<std::unique_ptr<通用列适配器>[]>(行列数[1]);
	for (uint8_t 列 = 0; 列 < 行列数[1]; ++列)
	{
		Array 列内容 = MATLAB引擎->feval<Array>("MATLAB.MixIn.BraceReference", 更新表, ":", 列);
		const ArrayDimensions 列内容尺寸 = 列内容.getDimensions();
		if (列内容尺寸.size() > 2 || 列内容尺寸[1] > 1)
		{
			const size_t 参数长度 = 列内容尺寸.size() - 1;
			buffer_ptr_t<uint8_t>维度参数 = 数组工厂.createBuffer<uint8_t>(参数长度);
			std::iota(维度参数.get(), 维度参数.get() + 参数长度, 2);
			try
			{
				列内容 = MATLAB引擎->feval<Array>("MATLAB.DataTypes.Serialize", std::move(列内容), 数组工厂.createArrayFromBuffer({ 参数长度 }, std::move(维度参数)));
			}
			catch (const matlab::engine::MATLABException& 异常)
			{
				if (异常.getMessageID() == "MATLAB:Exception:Data_does_not_support_typecast")
				{
					列内容[1];
				}
		}
		if (MATLAB引擎->feval<bool>("iscellstr", 列内容))
		{
			StringArray&& 字符串列内容 = 万能转码<StringArray>(std::move(列内容));
			更新表 = MATLAB引擎->feval<Array>("MATLAB.MixIn.DotAssign", 更新表, 所有MATLAB列名[列], 字符串列内容);
			所有列[列] = std::make_unique<特殊列适配器<MATLABString>>(std::move(字符串列内容));
			continue;
		}
	}
	const std::unique_ptr<sql::Statement>语句{ 连接->createStatement() };
	const std::unique_ptr<sql::ResultSet>结果集{ 语句->executeQuery((std::ostringstream("SELECT COUNT(*) FROM ") << 表名 << " LIMIT 1").str()) };
	结果集->next();
	if (结果集->getByte(1))
	{
		
	}
}
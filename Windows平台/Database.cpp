#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#define MAYBE_IN_NEXT_VERSION
#include<mariadb/conncpp.hpp>
#include<numeric>
using namespace Mex工具;
Mex工具API(Database_MariaDB)
{
	std::string URL;
	switch (输入.size())
	{
	case 2:
		URL = 万能转码<std::string>(std::move(输入[1]));
		break;
	case 5:
		URL = (std::ostringstream("jdbc:mariadb://") << 万能转码<std::string>(std::move(输入[1])) << ":3306/" << 万能转码<std::string>(std::move(输入[2])) << "?user=" << 万能转码<std::string>(std::move(输入[3])) << "&password=" << 万能转码<std::string>(std::move(输入[4]))).str();
		break;
	case 6:
		URL = (std::ostringstream("jdbc:mariadb://") << 万能转码<std::string>(std::move(输入[1])) << ":" << 万能转码<uint16_t>(std::move(输入[2])) << "/" << 万能转码<std::string>(std::move(输入[3])) << "?user=" << 万能转码<std::string>(std::move(输入[4])) << "&password=" << 万能转码<std::string>(std::move(输入[5]))).str();
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
	virtual void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号) = 0;
	virtual ~通用列适配器() {}
};
template<typename T>
struct 特殊列适配器 :通用列适配器
{
	TypedArray<T>::const_iterator 迭代器;
	void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)override;
	特殊列适配器(const TypedArray<T>& MATLAB数组) :迭代器(MATLAB数组.cbegin()) {}
};
Mex工具API(Database_UpdateByPrimary)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[1]));
	const std::string 表名 = 万能转码<std::string>(std::move(输入[2]));
	const Reference<Struct>更新表 = StructArray{ std::move(输入[3]) } [0] ;
	const StringArray 所有列名{ 更新表["ColumnName"] };
	const StringArray 所有列类型{ 更新表["ColumnType"] };
	const CellArray 所有列值{ 更新表["ColumnValue"] };
	static const std::unordered_map<String, 通用列适配器* (*)(const Array&)> 适配器表
	{
		{
			u"BIT(1)",[](const Array& 数组)->通用列适配器* {return new 特殊列适配器<bool>(数组); }
		},
	};
	const size_t 列数 = 所有列名.getNumberOfElements();
	std::unique_ptr<std::unique_ptr<通用列适配器>[]> 适配器数组 = std::make_unique_for_overwrite<std::unique_ptr<通用列适配器>[]>(列数);
	size_t 列;
	for (列 = 0; 列 < 列数; ++列)
	{
		String 列类型 = 所有列类型[列];
		if (列类型.starts_with(u"ENUM"))
			列类型 = u"ENUM";
		const auto 适配器查找 = 适配器表.find(列类型);
		if (适配器查找 == 适配器表.end())
			EnumThrow(MATLAB::Exception::Unsupported_column_type);
		适配器数组[列] = std::unique_ptr<通用列适配器>{ 适配器查找->second(所有列值[列]) };
	}
	const std::unique_ptr<sql::Statement> 语句(连接->createStatement());
	std::ostringstream 语句文本("SELECT COUNT(*)FROM ");
	语句文本 << 表名 << " LIMIT 1";
	const std::unique_ptr<sql::ResultSet> 结果集(语句->executeQuery(语句文本.str()));
	结果集->next();
	const std::unique_ptr<std::string[]>UTF8列名 = std::make_unique_for_overwrite<std::string[]>(列数);
	if (结果集->getInt(1))
	{
		语句文本.str("ALTER TABLE ");
		语句文本 << 表名 << " ADD IF NOT EXISTS";
		std::ostringstream 列定义流('(');
		if (列数)
			for (列 = 0;;)
			{
				UTF8列名[列] = 万能转码<std::string>(String{ 所有列名[列] });
				列定义流 << UTF8列名[列] << ' ' << 万能转码<std::string>(所有列类型[列]) << " NULL";
				if (++列 >= 列数)
					break;
				列定义流 << ',';
			}
		列定义流 << ')';
		std::string 列定义文本 = 列定义流.str();
		语句文本 << 列定义文本;
		语句->addBatch(语句文本.str());
		语句文本.str("CREATE TEMPORARY TABLE _MATLAB_临时表");
		语句文本 << 列定义文本;
		语句->addBatch(语句文本.str());
		语句->executeBatch();
		语句文本.str("INSERT _MATLAB_临时表(");
		列定义流.str("");
		if (列数)
			for (列 = 0;;)
			{
				列定义流 << UTF8列名[列];
				if (++列 >= 列数)
					break;
				列定义流 << ',';
			}
		列定义文本 = 列定义流.str();
		语句文本 << 列定义文本 << ")VALUES";
		const size_t 行数 = 所有列值[0].getNumberOfElements();
		size_t 行;
		if (行数 && 列数)
			for (行 = 0;;)
			{
				语句文本 << '(';
				for (列 = 0;;)
				{
					语句文本 << '?';
					if (++列 >= 列数)
						break;
					语句文本 << ',';
				}
				语句文本 << ')';
				if (++行 >= 行数)
					break;
				语句文本 << ',';
			}
		const std::unique_ptr<sql::PreparedStatement> 准备好的语句{ 连接->prepareStatement(语句文本.str()) };
		int32_t 参数序号 = 1;
		if (行数 && 列数)
		{
			for (行 = 0; 行 < 行数; ++行)
				for (列 = 0; 列 < 列数; ++列)
					适配器数组[列]->插入语句(准备好的语句.get(), 参数序号++);
			准备好的语句->execute();
		}
		语句文本.str("INSERT ");
		语句文本 << 表名 << '(' << 列定义文本 << ")SELECT " << 列定义文本 << " FROM _MATLAB_临时表 ON DUPLICATE KEY UPDATE ";
		if (列数)
			for (列 = 0;;)
			{
				语句文本 << 表名 << '.' << UTF8列名[列] << "=_MATLAB_临时表." << UTF8列名[列];
				if (++列 >= 列数)
					break;
				语句文本 << ',';
			}
		语句->execute(语句文本.str());
	}
	else
	{
		语句文本.str("CREATE TABLE ");
		语句文本 << 表名 << '(';
		if (列数)
			for (列 = 0;;)
			{
				UTF8列名[列] = 万能转码<std::string>(所有列名[列]);
				语句文本 << UTF8列名[列] << ' ' << 万能转码<std::string>(所有列类型[列]) << " NULL";
				if (++列 >= 列数)
					break;
				语句文本 << ',';
			}
		语句文本 << ')';
		语句->execute(语句文本.str());
		语句文本.str("INSERT ");
		语句文本 << 表名 << '(';
		if (列数)
			for (列 = 0;;)
			{
				语句文本 << UTF8列名[列];
				if (++列 >= 列数)
					break;
				语句文本 << ',';
			}
		语句文本 << ")VALUES";
		const size_t 行数 = 所有列值[0].getNumberOfElements();
		size_t 行;
		if (行数 && 列数)
			for (行 = 0;;)
			{
				语句文本 << '(';
				for (列 = 0;;)
				{
					语句文本 << '?';
					if (++列 >= 列数)
						break;
					语句文本 << ',';
				}
				语句文本 << ')';
				if (++行 >= 行数)
					break;
				语句文本 << ',';
			}
		const std::unique_ptr<sql::PreparedStatement> 准备好的语句{ 连接->prepareStatement(语句文本.str()) };
		int32_t 参数序号 = 1;
		if (行数 && 列数)
		{
			for (行 = 0; 行 < 行数; ++行)
				for (列 = 0; 列 < 列数; ++列)
					适配器数组[列]->插入语句(准备好的语句.get(), 参数序号++);
			准备好的语句->execute();
		}
	}
}
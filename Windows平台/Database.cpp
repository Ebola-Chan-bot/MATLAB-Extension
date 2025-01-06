#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#include<mariadb/conncpp.hpp>
#pragma comment(lib,"mariadbcpp.lib")
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
		URL = (std::ostringstream("jdbc:mariadb://",std::ios::app) << 万能转码<std::string>(std::move(输入[1])) << ":3306/" << 万能转码<std::string>(std::move(输入[2])) << "?user=" << 万能转码<std::string>(std::move(输入[3])) << "&password=" << 万能转码<std::string>(std::move(输入[4]))).str();
		break;
	case 6:
		URL = (std::ostringstream("jdbc:mariadb://", std::ios::app) << 万能转码<std::string>(std::move(输入[1])) << ":" << 万能转码<uint16_t>(std::move(输入[2])) << "/" << 万能转码<std::string>(std::move(输入[3])) << "?user=" << 万能转码<std::string>(std::move(输入[4])) << "&password=" << 万能转码<std::string>(std::move(输入[5]))).str();
		break;
	default:
		EnumThrow(MATLAB::Exception::The_number_of_entered_parameters_is_incorrect);
	}
	sql::Connection* const 连接 = sql::DriverManager::getConnection(URL);
	自动析构(连接);
	输出[0] = 万能转码(连接);
}
Mex工具API(Database_DeleteMariaDB)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[1]));
	if (手动析构(连接))
		delete 连接;
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
	void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)override
	{
		EnumThrow(MATLAB::Exception::Unexpected_column_type);
	}
	特殊列适配器(const TypedArray<T>& MATLAB数组) :迭代器(MATLAB数组.cbegin()) {}
};
template<>
void 特殊列适配器<bool>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setByte(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<int8_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setByte(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<uint8_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setShort(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<int16_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setShort(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<uint16_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setInt(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<int32_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setInt(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<uint32_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setUInt(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<int64_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setInt64(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<uint64_t>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setUInt64(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<float>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setFloat(参数序号, *迭代器++);
}
template<>
void 特殊列适配器<double>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	准备好的语句->setDouble(参数序号, *迭代器++);
}
template<>
struct 特殊列适配器<MATLABString> :通用列适配器
{
	const std::unique_ptr<std::string[]>容器;
	const std::string* 迭代器;
	特殊列适配器(StringArray&& MATLAB数组) :容器(std::make_unique_for_overwrite<std::string[]>(MATLAB数组.getNumberOfElements())), 迭代器(容器.get())
	{
		万能转码(std::move(MATLAB数组), 容器.get());
	}
	void 插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)override
	{
		准备好的语句->setString(参数序号, *迭代器++);
	}
};
template<>
void 特殊列适配器<Array>::插入语句(sql::PreparedStatement* 准备好的语句, int32_t 参数序号)
{
	TypedArray<int8_t>数组 = *迭代器++;
	const size_t 字节数 = 数组.getNumberOfElements();
	sql::bytes SQL缓冲{ reinterpret_cast<char*>(数组.release().get()), 字节数 };
	准备好的语句->setBytes(参数序号, &SQL缓冲);
}
struct
{
	template<typename T>
	通用列适配器* operator()(TypedArray<T>&& MATLAB数组)const
	{
		return new 特殊列适配器<T>(std::move(MATLAB数组));
	}
	template<typename T>
	通用列适配器* operator()(T&& MATLAB数组)const
	{
		EnumThrow(MATLAB::Exception::Unexpected_column_type);
	}
}适配访问器;
static void SQL捕获(const std::move_only_function<void()const>& 尝试)
{
	try
	{
		尝试();
	}
	catch(const sql::BatchUpdateException&异常)
	{
		throw;
	}
	catch (const sql::IllegalArgumentException& 异常)
	{
		throw;
	}
	catch (const sql::MaxAllowedPacketException& 异常)
	{
		throw;
	}
	catch (const sql::ParseException& 异常)
	{
		throw;
	}
	catch (const sql::SQLDataException& 异常)
	{
		throw;
	}
	catch (const sql::SQLFeatureNotImplementedException& 异常)
	{
		throw;
	}
	catch (const sql::SQLFeatureNotSupportedException& 异常)
	{
		throw;
	}
	catch (const sql::SQLIntegrityConstraintViolationException& 异常)
	{
		throw;
	}
	catch (const sql::SQLInvalidAuthorizationSpecException& 异常)
	{
		throw;
	}
	catch (const sql::SQLNonTransientConnectionException& 异常)
	{
		throw;
	}
	catch (const sql::SQLSyntaxErrorException& 异常)
	{
		throw;
	}
	catch (const sql::SQLTimeoutException& 异常)
	{
		throw;
	}
	catch (const sql::SQLTransactionRollbackException& 异常)
	{
		throw;
	}
	catch (const sql::SQLTransientConnectionException& 异常)
	{
		throw;
	}
	catch (const sql::SQLTransientException& 异常)
	{
		throw;
	}
	catch (const sql::SQLException& 异常)
	{
		throw;
	}
	catch (const std::invalid_argument& 异常)
	{
		throw;
	}
	catch (const std::out_of_range& 异常)
	{
		throw;
	}
	catch (const std::runtime_error& 异常)
	{
		throw;
	}
}
static std::string 合成列定义文本(uint32_t 列数, std::ostringstream& 列定义流, const std::string* 所有列名, const std::string* 所有列类型)
{
	列定义流 << '(';
	if (列数)
		for (uint32_t 列 = 0;;)
		{
			列定义流 << 所有列名[列] << ' ' << 所有列类型[列] << " NULL";
			if (++列 >= 列数)
				break;
			列定义流 << ',';
		}
	列定义流 << ')';
	return 列定义流.str();
}
static void 合成列引用文本(uint32_t 列数, std::ostringstream& 列引用流, const std::string* 所有列名)
{
	if (列数)
		for (uint32_t 列 = 0;;)
		{
			列引用流 << 所有列名[列];
			if (++列 >= 列数)
				break;
			列引用流 << ',';
		}
}
static void 插入语句合成执行(uint32_t 列数, std::ostringstream& 语句文本, CellArray::const_iterator 所有列值, sql::Connection* 连接, const std::unique_ptr<通用列适配器>* 适配器数组)
{
	语句文本 << ")VALUES";
	const uint32_t 行数 = 所有列值[0].getNumberOfElements();
	if (行数 && 列数)
		for (uint32_t 行 = 0;;)
		{
			语句文本 << '(';
			for (uint32_t 列 = 0;;)
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
		for (uint32_t 行 = 0; 行 < 行数; ++行)
			for (uint32_t 列 = 0; 列 < 列数; ++列)
				适配器数组[列]->插入语句(准备好的语句.get(), 参数序号++);
		准备好的语句->execute();
	}
}
Mex工具API(Database_UpdateByPrimary)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[1]));
	const std::string 表名 = 万能转码<std::string>(std::move(输入[2]));
	const StructArray 结构体数组{ std::move(输入[3]) };//必须保留此对象，否则Struct会失效
	const Struct 更新表 = 结构体数组[0];
	const CellArray 所有列值{ 更新表["ColumnValue"] };
	const uint32_t 列数 = 所有列值.getNumberOfElements();
	const std::unique_ptr<std::string[]>所有列名 = std::make_unique_for_overwrite<std::string[]>(列数);
	万能转码(std::move(更新表["ColumnName"]), 所有列名.get());
	const std::unique_ptr<std::string[]>所有列类型 = std::make_unique_for_overwrite<std::string[]>(列数);
	万能转码(std::move(更新表["ColumnType"]), 所有列类型.get());
	std::unique_ptr<std::unique_ptr<通用列适配器>[]> 适配器数组 = std::make_unique_for_overwrite<std::unique_ptr<通用列适配器>[]>(列数);
	uint32_t 列;
	for (列 = 0; 列 < 列数; ++列)
	{
		适配器数组[列] = std::unique_ptr<通用列适配器>{ apply_visitor(std::move(所有列值[列]),适配访问器) };
	}
	const std::unique_ptr<sql::Statement> 语句(连接->createStatement());
	std::ostringstream 语句文本("SELECT COUNT(*)FROM ", std::ios::app);
	语句文本 << 表名 << " LIMIT 1";
	try
	{
		语句->executeQuery(语句文本.str());
	}
	catch (const sql::SQLSyntaxErrorException&)
	{
		语句文本.str("CREATE TABLE ");
		语句文本 << 表名;
		语句->execute(合成列定义文本(列数, 语句文本, 所有列名.get(), 所有列类型.get()));
		语句文本.str("INSERT ");
		语句文本 << 表名 << '(';
		合成列引用文本(列数, 语句文本, 所有列名.get());
		插入语句合成执行(列数, 语句文本, 所有列值.cbegin(), 连接, 适配器数组.get());
		return;
	}
	语句文本.str("ALTER TABLE ");
	语句文本 << 表名 << " ADD IF NOT EXISTS";
	std::ostringstream 列定义流;
	std::string 列定义文本 = 合成列定义文本(列数, 列定义流, 所有列名.get(), 所有列类型.get());
	语句文本 << 列定义文本;
	语句->addBatch(语句文本.str());
	语句文本.str("CREATE OR REPLACE TEMPORARY TABLE _MATLAB_临时表");
	语句文本 << 列定义文本;
	语句->addBatch(语句文本.str());
	语句->executeBatch();
	语句文本.str("INSERT _MATLAB_临时表(");
	列定义流.str("");
	合成列引用文本(列数, 列定义流, 所有列名.get());
	列定义文本 = 列定义流.str();
	语句文本 << 列定义文本;
	插入语句合成执行(列数, 语句文本, 所有列值.cbegin(), 连接, 适配器数组.get());
	语句文本.str("INSERT ");
	语句文本 << 表名 << '(' << 列定义文本 << ")SELECT " << 列定义文本 << " FROM _MATLAB_临时表 ON DUPLICATE KEY UPDATE ";
	if (列数)
		for (列 = 0;;)
		{
			语句文本 << 表名 << '.' << 所有列名[列] << "=_MATLAB_临时表." << 所有列名[列];
			if (++列 >= 列数)
				break;
			语句文本 << ',';
		}
	语句->execute(语句文本.str());
}
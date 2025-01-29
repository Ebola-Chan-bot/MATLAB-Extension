#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#include<conncpp.hpp>
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
	const TypedArray<int8_t>数组 = *迭代器++;
	sql::bytes SQL缓冲(数组.getNumberOfElements());//不能在构造时提供指针，因为会启动不拷贝的重载，然后变成悬空指针
	std::copy(数组.cbegin(), 数组.cend(), SQL缓冲.begin());
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
static inline void SQL捕获(const std::move_only_function<void()const>& 尝试)
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
static std::string 合成列定义文本(uint8_t 列数, std::ostringstream& 列定义流, const std::string* 所有列名, const std::string* 所有列类型)
{
	列定义流 << '(';
	for (uint8_t 列 = 0;;)
	{
		列定义流 << 所有列名[列] << ' ' << 所有列类型[列] << " NULL";
		if (++列 >= 列数)
			break;
		列定义流 << ',';
	}
	列定义流 << ')';
	return 列定义流.str();
}
static void 合成列引用文本(uint8_t 列数, std::ostringstream& 列引用流, const std::string* 所有列名)
{
	for (uint8_t 列 = 0;;)
	{
		列引用流 << 所有列名[列];
		if (++列 >= 列数)
			break;
		列引用流 << ',';
	}
}
static void 合成插入参数文本(std::ostringstream& 语句文本, const std::string& 行文本, uint32_t 行数)
{
	for (uint32_t 行 = 0;;)
	{
		语句文本 << 行文本;
		if (++行 >= 行数)
			break;
		语句文本 << ',';
	}
}
static void 插入语句合成执行(uint32_t 行数, uint8_t 列数, std::ostringstream& 语句文本, CellArray::const_iterator 所有列值, sql::Connection* 连接, const std::unique_ptr<通用列适配器>* 适配器数组)
{
	语句文本 << ")VALUES";
	const std::string 公共前缀 = 语句文本.str();
	std::ostringstream 行流("(", std::ios::app);
	for (uint8_t 列 = 0;;)
	{
		行流 << '?';
		if (++列 >= 列数)
			break;
		行流 << ',';
	}
	行流 << ')';
	const std::string 行文本 = 行流.str();
	const uint8_t 分块数 = 行数 * (列数 * 2 + 2) >> 21;//不含余数
	const uint32_t 分块行数 = 行数 / (分块数 + 1) + 1;
	const uint8_t 余数 = 行数 % 分块行数;
	合成插入参数文本(语句文本, 行文本, 分块行数);
	std::unique_ptr<sql::PreparedStatement> 准备好的语句{ 连接->prepareStatement(语句文本.str()) };
	for (uint8_t 块 = 0; 块 < 分块数; ++块)
	{
		uint32_t 参数序号 = 0;
		for (uint32_t 行 = 0; 行 < 分块行数; ++行)
			for (uint8_t 列 = 0; 列 < 列数; ++列)
				适配器数组[列]->插入语句(准备好的语句.get(), ++参数序号);
		准备好的语句->addBatch();
	}
	准备好的语句->executeBatch();
	语句文本.str(公共前缀);
	合成插入参数文本(语句文本, 行文本, 余数);
	准备好的语句.reset(连接->prepareStatement(语句文本.str()));
	uint32_t 参数序号 = 0;
	for (uint32_t 行 = 0; 行 < 余数; ++行)
		for (uint8_t 列 = 0; 列 < 列数; ++列)
			适配器数组[列]->插入语句(准备好的语句.get(), ++参数序号);
	准备好的语句->execute();
}
Mex工具API(Database_UpdateByPrimary)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[1]));
	const std::string 表名 = 万能转码<std::string>(std::move(输入[2]));
	const StructArray 结构体数组{ std::move(输入[3]) };//必须保留此对象，否则Struct会失效
	const Struct 更新表 = 结构体数组[0];
	const CellArray 所有列值{ 更新表["ColumnValue"] };
	const uint8_t 列数 = 所有列值.getNumberOfElements();
	if (!列数)
		return;
	const uint32_t 行数 = 所有列值[0].getNumberOfElements();
	if (!行数)
		return;
	const std::unique_ptr<std::string[]>所有列名 = std::make_unique_for_overwrite<std::string[]>(列数);
	万能转码(std::move(更新表["ColumnName"]), 所有列名.get());
	const std::unique_ptr<std::string[]>所有列类型 = std::make_unique_for_overwrite<std::string[]>(列数);
	万能转码(std::move(更新表["ColumnType"]), 所有列类型.get());
	std::unique_ptr<std::unique_ptr<通用列适配器>[]> 适配器数组 = std::make_unique_for_overwrite<std::unique_ptr<通用列适配器>[]>(列数);
	for (uint8_t 列 = 0; 列 < 列数; ++列)
		适配器数组[列] = std::unique_ptr<通用列适配器>{ apply_visitor(std::move(所有列值[列]),适配访问器) };
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
		插入语句合成执行(行数, 列数, 语句文本, 所有列值.cbegin(), 连接, 适配器数组.get());
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
	插入语句合成执行(行数, 列数, 语句文本, 所有列值.cbegin(), 连接, 适配器数组.get());
	语句文本.str("INSERT ");
	语句文本 << 表名 << '(' << 列定义文本 << ")SELECT " << 列定义文本 << " FROM _MATLAB_临时表 ON DUPLICATE KEY UPDATE ";
	for (uint8_t 列 = 0;;)
	{
		语句文本 << 表名 << '.' << 所有列名[列] << "=_MATLAB_临时表." << 所有列名[列];
		if (++列 >= 列数)
			break;
		语句文本 << ',';
	}
	语句->execute(语句文本.str());
}
struct 通用列提取器
{
	sql::ResultSet* const 结果集;
	const int32_t 列;
	通用列提取器(sql::ResultSet* 结果集,int32_t 列) :结果集(结果集),列(列) {}
	virtual void 取单元格() = 0;
	virtual Array 取全列()const = 0;
	virtual ~通用列提取器() {}
};
template<typename T,bool 有Null>
struct 特殊列提取器 :通用列提取器
{
	std::vector<T>全列;
	特殊列提取器(sql::ResultSet* 结果集,int32_t 列) :通用列提取器(结果集,列) {}
	void 取单元格()override;
	Array 取全列()const override;
};
struct 日期时间;
struct 持续时间;
struct 分类;
struct 缺失;
static const MATLABString 空字符串;
template<typename T, bool 有Null>
void 特殊列提取器<T, 有Null>::取单元格()
{
	全列.push_back(有Null && 结果集->isNull(列) ? 空字符串 : 万能转码<MATLABString>(结果集->getString(列).c_str()));
}
template<typename T, bool 有Null>
Array 特殊列提取器<T, 有Null>::取全列()const
{
	return 万能转码(全列.cbegin(), { 全列.size() });
}
template<>
void 特殊列提取器<bool, false>::取单元格()
{
	全列.push_back(结果集->getBoolean(列));
}
template<>
void 特殊列提取器<int8_t, false>::取单元格()
{
	全列.push_back(结果集->getByte(列));
}
template<>
void 特殊列提取器<uint8_t, false>::取单元格()
{
	全列.push_back(结果集->getShort(列));
}
template<>
void 特殊列提取器<int16_t, false>::取单元格()
{
	全列.push_back(结果集->getShort(列));
}
template<>
void 特殊列提取器<uint16_t, false>::取单元格()
{
	全列.push_back(结果集->getInt(列));
}
template<>
void 特殊列提取器<int32_t, false>::取单元格()
{
	全列.push_back(结果集->getInt(列));
}
template<>
void 特殊列提取器<uint32_t, false>::取单元格()
{
	全列.push_back(结果集->getUInt(列));
}
template<>
void 特殊列提取器<int64_t, false>::取单元格()
{
	全列.push_back(结果集->getInt64(列));
}
#undef min
template<>
void 特殊列提取器<int64_t, true>::取单元格()
{
	全列.push_back(结果集->isNull(列) ? std::numeric_limits<int64_t>::min() : 结果集->getInt64(列));
}
template<>
void 特殊列提取器<uint64_t, false>::取单元格()
{
	全列.push_back(结果集->getUInt64(列));
}
#undef max
template<>
void 特殊列提取器<uint64_t, true>::取单元格()
{
	全列.push_back(结果集->isNull(列) ? std::numeric_limits<uint64_t>::max() : 结果集->getUInt64(列));
}
template<>
void 特殊列提取器<float, false>::取单元格()
{
	全列.push_back(结果集->getFloat(列));
}
template<>
void 特殊列提取器<float, true>::取单元格()
{
	全列.push_back(结果集->isNull(列) ? std::numeric_limits<float>::quiet_NaN() : 结果集->getFloat(列));
}
template<>
void 特殊列提取器<double, false>::取单元格()
{
	全列.push_back(结果集->getDouble(列));
}
template<>
void 特殊列提取器<double, true>::取单元格()
{
	全列.push_back(结果集->isNull(列) ? std::numeric_limits<double>::quiet_NaN() : 结果集->getDouble(列));
}
void 特殊列提取器<Array, false>::取单元格()
{
	const std::unique_ptr<sql::Blob>二进制{ 结果集->getBlob(列) };
	二进制->seekg(0, std::ios::end);
	const size_t 字节数 = 二进制->tellg();
	buffer_ptr_t<int8_t>缓冲 = 数组工厂.createBuffer<int8_t>(字节数);
	二进制->seekg(0, std::ios::beg);
	二进制->read(reinterpret_cast<char*>(缓冲.get()), 字节数);
	全列.push_back(数组工厂.createArrayFromBuffer({ 字节数 }, std::move(缓冲)));
}
template<bool 有Null>
struct 特殊列提取器<日期时间, 有Null> :特殊列提取器<MATLABString, 有Null>
{
	特殊列提取器(sql::ResultSet* 结果集,int32_t 列) :特殊列提取器<MATLABString, 有Null>(结果集,列) {}
	Array 取全列()const override
	{
		return MATLAB引擎->feval(u"datetime", 万能转码(特殊列提取器<MATLABString, 有Null>::全列.cbegin(), { 特殊列提取器<MATLABString, 有Null>::全列.size() }));
	}
};
template<bool 有Null>
struct 特殊列提取器<持续时间, 有Null> :特殊列提取器<MATLABString, 有Null>
{
	特殊列提取器(sql::ResultSet* 结果集, int32_t 列) :特殊列提取器<MATLABString, 有Null>(结果集, 列) {}
	Array 取全列()const override
	{
		return MATLAB引擎->feval(u"duration", 万能转码(特殊列提取器<MATLABString, 有Null>::全列.cbegin(), { 特殊列提取器<MATLABString, 有Null>::全列.size() }));
	}
};
template<bool 有Null>
struct 特殊列提取器<分类, 有Null> :特殊列提取器<MATLABString, 有Null>
{
	特殊列提取器(sql::ResultSet* 结果集, int32_t 列) :特殊列提取器<MATLABString, 有Null>(结果集, 列) {}
	Array 取全列()const override
	{
		return MATLAB引擎->feval(u"categorical", 万能转码(特殊列提取器<MATLABString, 有Null>::全列.cbegin(), { 特殊列提取器<MATLABString, 有Null>::全列.size() }));
	}
};
template<>
struct 特殊列提取器<缺失, true> :通用列提取器
{
	size_t 行数 = 0;
	特殊列提取器(sql::ResultSet* 结果集, int32_t 列) :通用列提取器(结果集,列) {}
	void 取单元格()override
	{
		++行数;
	}
	Array 取全列()const override
	{
		static std::vector<Array>参数列表{ MATLAB引擎->feval<Array>(u"missing"),数组工厂.createEmptyArray(),数组工厂.createScalar(1) };
		参数列表[1] = 数组工厂.createScalar(行数);
		return MATLAB引擎->feval(u"missing", 参数列表);
	}
};
template<typename T,bool 有Null>
static std::unique_ptr<通用列提取器>创建特殊列提取器(sql::ResultSet* 结果集, int32_t 列)
{
	return std::make_unique<特殊列提取器<T, 有Null>>(结果集, 列);
}
static void 结果集转表(sql::ResultSet* 结果集, StringArray& 表列名, CellArray& 表列)
{
	std::unique_ptr<sql::ResultSetMetaData>结果集元数据{ 结果集->getMetaData() };
	const uint8_t 列数 = 结果集元数据->getColumnCount();
	表列名 = 数组工厂.createArray<MATLABString>({ 1,列数 });
	std::unique_ptr<std::unique_ptr<通用列提取器>[]> 提取器数组 = std::make_unique_for_overwrite<std::unique_ptr<通用列提取器>[]>(列数);
	for (uint8_t 列 = 0; 列 < 列数; ++列)
	{
		uint8_t MariaDB列 = 列 + 1;
		const sql::SQLString 列名 = 结果集元数据->getColumnLabel(MariaDB列);
		表列名[列] = 万能转码<MATLABString>(列名.c_str());
		static const std::unordered_map<std::string, std::unique_ptr<通用列提取器>(*)(sql::ResultSet*, int32_t)>无Null构造器
		{
			{"BOOLEAN",创建特殊列提取器<bool,false>},
			{"TINYINT",创建特殊列提取器<int8_t,false>},
			{"BIT",创建特殊列提取器<uint8_t,false>},
			{"TINYINT UNSIGNED",创建特殊列提取器<uint8_t,false>},
			{"SMALLINT",创建特殊列提取器<int16_t,false>},
			{"YEAR",创建特殊列提取器<uint16_t,false>},
			{"SMALLINT UNSIGNED",创建特殊列提取器<uint16_t,false>},
			{"MEDIUMINT",创建特殊列提取器<int32_t,false>},
			{"MEDIUMINT UNSIGNED",创建特殊列提取器<uint32_t,false>},
			{"INT",创建特殊列提取器<int32_t,false>},
			{"INT UNSIGNED",创建特殊列提取器<uint32_t,false>},
			{"BIGINT",创建特殊列提取器<int64_t,false>},
			{"BIGINT UNSIGNED",创建特殊列提取器<uint64_t,false>},
			{"FLOAT",创建特殊列提取器<float,false>},
			{"DOUBLE",创建特殊列提取器<double,false>},
			{"DATE",创建特殊列提取器<日期时间,false>},
			{"DATETIME",创建特殊列提取器<日期时间,false>},
			{"TIMESTAMP",创建特殊列提取器<日期时间,false>},
			{"TIME",创建特殊列提取器<持续时间,false>},
			{"CHAR",创建特殊列提取器<分类,false>},
			{"VARCHAR",创建特殊列提取器<分类,false>},
			{"ENUM",创建特殊列提取器<分类,false>},
			{"TINYTEXT",创建特殊列提取器<MATLABString,false>},
			{"TEXT",创建特殊列提取器<MATLABString,false>},
			{"MEDIUMTEXT",创建特殊列提取器<MATLABString,false>},
			{"LONGTEXT",创建特殊列提取器 < MATLABString,false>},
			{"JSON",创建特殊列提取器<MATLABString,false>},
			{"DECIMAL",创建特殊列提取器<MATLABString,false>},
			{"BINARY",创建特殊列提取器<Array,false>},
			{"VARBINARY",创建特殊列提取器<Array,false>},
			{"TINYBLOB",创建特殊列提取器<Array,false>},
			{"BLOB",创建特殊列提取器<Array,false>},
			{"MEDIUMBLOB",创建特殊列提取器<Array,false>},
			{"LONGBLOB",创建特殊列提取器<Array,false>}
		};
		static const std::unordered_map<std::string, std::unique_ptr<通用列提取器>(*)(sql::ResultSet*, int32_t)>有Null构造器
		{
			{"BOOLEAN",创建特殊列提取器<float,true>},
			{"TINYINT",创建特殊列提取器<float,true>},
			{"BIT",创建特殊列提取器<float,true>},
			{"TINYINT UNSIGNED",创建特殊列提取器<float,true>},
			{"SMALLINT",创建特殊列提取器<float,true>},
			{"YEAR",创建特殊列提取器<float,true>},
			{"SMALLINT UNSIGNED",创建特殊列提取器<float,true>},
			{"MEDIUMINT",创建特殊列提取器<double,true>},
			{"MEDIUMINT UNSIGNED",创建特殊列提取器<double,true>},
			{"INT",创建特殊列提取器<double,true>},
			{"INT UNSIGNED",创建特殊列提取器<double,true>},
			{"BIGINT",创建特殊列提取器<int64_t,true>},
			{"BIGINT UNSIGNED",创建特殊列提取器<uint64_t,true>},
			{"FLOAT",创建特殊列提取器<float,true>},
			{"DOUBLE",创建特殊列提取器<double,true>},
			{"DATE",创建特殊列提取器<日期时间,true>},
			{"DATETIME",创建特殊列提取器<日期时间,true>},
			{"TIMESTAMP",创建特殊列提取器<日期时间,true>},
			{"TIME",创建特殊列提取器<持续时间,true>},
			{"CHAR",创建特殊列提取器<分类,true>},
			{"VARCHAR",创建特殊列提取器<分类,true>},
			{"ENUM",创建特殊列提取器<分类,true>},
			{"TINYTEXT",创建特殊列提取器<MATLABString,true>},
			{"TEXT",创建特殊列提取器<MATLABString,true>},
			{"MEDIUMTEXT",创建特殊列提取器<MATLABString,true>},
			{"LONGTEXT",创建特殊列提取器<MATLABString,true>},
			{"JSON",创建特殊列提取器 < MATLABString,true>},
			{"DECIMAL",创建特殊列提取器<MATLABString,true>},
			//未定义<Array,true>的情形，一律用false
			{"BINARY",创建特殊列提取器<Array,false>},
			{"VARBINARY",创建特殊列提取器<Array,false>},
			{"TINYBLOB",创建特殊列提取器<Array,false>},
			{"BLOB",创建特殊列提取器<Array,false>},
			{"MEDIUMBLOB",创建特殊列提取器<Array,false>},
			{"LONGBLOB",创建特殊列提取器<Array,false>},
			{"NULL",创建特殊列提取器<缺失,true>}
		};
		提取器数组[列] = (结果集元数据->isNullable(MariaDB列) ? 有Null构造器 : 无Null构造器).at(结果集元数据->getColumnTypeName(MariaDB列).c_str())(结果集, MariaDB列);
	}
	while (结果集->next())
		for (uint8_t 列 = 0; 列 < 列数; ++列)
			提取器数组[列]->取单元格();
	表列 = 数组工厂.createCellArray({ 1,列数 });
	for (uint8_t 列 = 0; 列 < 列数; ++列)
		表列[列] = 提取器数组[列]->取全列();
}
Mex工具API(Database_Dump)
{
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[1]));
	std::list<sql::SQLString>类型 { "TABLE" };
	const std::unique_ptr<sql::ResultSet>所有表结果集{ 连接->getMetaData()->getTables(连接->getCatalog(), sql::SQLString{}, "%", 类型) };
	std::unique_ptr<sql::ResultSetMetaData>结果集元数据{ 所有表结果集->getMetaData() };
	uint8_t 表名列 = 0;
	while (结果集元数据->getColumnName(++表名列) != "TABLE_NAME");
	std::vector<MATLABString>所有表名;
	std::vector<Array>所有表列名;
	std::vector<Array>所有表列;
	while (所有表结果集->next())
	{
		static sql::Statement* const 语句 = 连接->createStatement();
		static const sql::SQLString 语句前缀{ "SELECT * FROM " };
		const sql::SQLString 表名 = 所有表结果集->getString(表名列);
		const std::unique_ptr<sql::ResultSet>单表结果集{ 语句->executeQuery(语句前缀 + 表名) };
		所有表名.push_back(万能转码<MATLABString>(表名.c_str()));
		static StringArray 空表列名 = 数组工厂.createArray<MATLABString>({ 0,1 });
		static CellArray 空表列 = 数组工厂.createArray<Array>({ 0,1 });
		结果集转表(单表结果集.get(), 空表列名, 空表列);
		所有表列名.push_back(std::move(空表列名));
		所有表列.push_back(std::move(空表列));
	}
	输出[0] = 万能转码(所有表名.cbegin(), { 所有表名.size(),1 });
	输出[1] = 万能转码(所有表列名.cbegin(), { 所有表列名.size(),1 });
	输出[2] = 万能转码(所有表列.cbegin(), { 所有表列.size(),1 });
}
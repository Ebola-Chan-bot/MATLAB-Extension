#include"pch.h"
#include<MATLAB异常.h>
#include<Mex工具.hpp>
#include<mariadb/conncpp.hpp>
#include<variant>
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
Mex工具API(Database_UpdateByPrimary)
{
	using namespace matlab::data;
	sql::Connection* const 连接 = 万能转码<sql::Connection*>(std::move(输入[0]));
	const std::string 表名 = 万能转码<std::string>(std::move(输入[1]));
	const Array& 更新表 = 输入[2];
	const ArrayDimensions 行列数 = 更新表.getDimensions();
	const std::unique_ptr<std::string[]>所有列名C = std::make_unique_for_overwrite<std::string[]>(行列数[1]);
	const StringArray 所有列名M = 万能转码<StringArray>(MATLAB引擎->feval<Array>("MATLAB.MixIn.DotReference", MATLAB引擎->feval<Array>("MATLAB.MixIn.DotReference", 更新表, "Properties"), "VariableNames"));
	using 通用列类型 = std::variant<buffer_ptr_t<bool>>;
	struct 类型擦除
	{
		void(*转换方法)(Array&& 列M, 通用列类型& 列C, const void*& 头指针);
		void(*赋值方法)(sql::PreparedStatement* 准备好的语句, int32_t 参数序号, const void*& 头指针);
	};
	//这个顺序不是任意的，必须与ArrayType枚举顺序一致
	constexpr 类型擦除 方法集合[] =
	{
		{
			//LOGICAL
			[](Array&& 列M, 通用列类型& 列C, const void*& 头指针)
			{
				buffer_ptr_t<bool>缓冲 = TypedArray<bool>(std::move(列M)).release();
				头指针 = 缓冲.get();
				列C = std::move(缓冲);
			},
			[](sql::PreparedStatement* 准备好的语句,int32_t 参数序号, const void*& 头指针)
			{
				准备好的语句->setByte(参数序号, *reinterpret_cast<const bool*&>(头指针)++);
			}
		},
		{
			//CHAR
		},
		{
			//MATLAB_STRING
			[](Array&& 列M, 通用列类型& 列C, const void*& 头指针)
			{
				buffer_ptr_t<bool>缓冲 = TypedArray<bool>(std::move(列M)).release();
				头指针 = 缓冲.get();
				列C = std::move(缓冲);
			},
			[](sql::PreparedStatement* 准备好的语句,int32_t 参数序号, const void*& 头指针)
			{
				准备好的语句->setByte(参数序号, *reinterpret_cast<const bool*&>(头指针)++);
			}
		},
	};
	for (uint8_t 列 = 0; 列 < 行列数[1]; ++列)
	{
		所有列名C[列] = 万能转码<std::string>(所有列名M[列]);

	}
	const std::unique_ptr<sql::Statement>语句{ 连接->createStatement() };
	const std::unique_ptr<sql::ResultSet>结果集{ 语句->executeQuery((std::ostringstream("SELECT COUNT(*) FROM ") << 表名 << " LIMIT 1").str()) };
	结果集->next();
	if (结果集->getByte(1))
	{
		
	}
}
classdef MariaDB<handle
	properties(SetAccess=immutable,GetAccess=private)
		Pointer
	end
	methods
		function obj = MariaDB(varargin)
			%建立一个MariaDB数据库的连接
			%# 语法
			% ```
			% obj=Database.MariaDB(Server,DatabaseName,Username,Password);
			% %建立一个MariaDB数据库的连接，端口号采用默认的3306
			%
			% obj=Database.MariaDB(Server,Port,DatabaseName,Username,Password);
			% %额外指定端口号
			%
			% obj=Database.MariaDB(ConnectString);
			% %使用指定的连接字符串连接到MariaDB数据库
			%# 输入参数
			% Server(1,1)string，服务器名称
			% Port(1,1)uint16，端口号
			% DatabaseName(1,1)string，数据库名称
			% Username(1,1)string，用户名
			% Password(1,1)string，密码
			% ConnectString(1,1)，MariaDB连接字符串，格式为jdbc:mariadb://Server:Port/DatabaseName?user=Username&password=Password
			obj.Pointer=MATLAB.internal.WindowsAPI.Database_MariaDB.Call(varargin{:});
		end
		function delete(obj)
			%如果构造失败，Pointer可能是空的
			if ~isempty(obj.Pointer)
				MATLAB.internal.WindowsAPI.Database_DeleteMariaDB.Call(obj.Pointer);
			end
		end
	end
end
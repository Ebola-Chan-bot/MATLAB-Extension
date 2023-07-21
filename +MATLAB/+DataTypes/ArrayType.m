classdef ArrayType<int32
	%枚举MATLAB所有基本数据类型
	enumeration
		LOGICAL(0)
		CHAR(1)
		MATLAB_STRING(2)
		DOUBLE(3)
		SINGLE(4)
		INT8(5)
		UINT8(6)
		INT16(7)
		UINT16(8)
		INT32(9)
		UINT32(10)
		INT64(11)
		UINT64(12)
		COMPLEX_DOUBLE(13)
		COMPLEX_SINGLE(14)
		COMPLEX_INT8(15)
		COMPLEX_UINT8(16)
		COMPLEX_INT16(17)
		COMPLEX_UINT16(18)
		COMPLEX_INT32(19)
		COMPLEX_UINT32(20)
		COMPLEX_INT64(21)
		COMPLEX_UINT64(22)
		CELL(23)
		STRUCT(24)
		OBJECT(25)
		VALUE_OBJECT(26)
		HANDLE_OBJECT_REF(27)
		ENUM(28)
		SPARSE_LOGICAL(29)
		SPARSE_DOUBLE(30)
		SPARSE_COMPLEX_DOUBLE(31)
		UNKNOWN(32)
	end
	methods(Static)
		function obj=FromData(Data)
			%从实际数据取得其类型枚举
			%# 语法
			% ```
			% Type=MATLAB.DataTypes.ArrayType.FromData(Data);
			% ```
			%# 输入参数
			% Data，要取类型的数据
			%# 返回值
			% Type(1,1)MATLAB.DataTypes.ArrayType，数据类型枚举
			obj=MATLAB.DataTypes.ArrayType(MATLAB.internal.WindowsAPI.ArrayType_FromData.Call(Data));
		end
	end
	methods
		function Size=TypeSize(obj)
			%获取POD类型的字节数
			%POD类型是指具有确定字节数的数据类型，包括 logical, char 和数值类型。非POD类型则可能具有不确定
			% 的字节数，如 string, cell, struct 等。
			%对于非POD类型，此方法将返回0值。
			persistent TypeSizes
			if isempty(TypeSizes)
				TypeSizes=load(fullfile(fileparts(mfilename('fullpath')),'数据类型尺寸.mat')).TypeSizes;
			end
			Size=TypeSizes(obj+1);
		end
	end
end
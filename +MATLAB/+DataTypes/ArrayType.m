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
end
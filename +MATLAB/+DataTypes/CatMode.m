classdef CatMode
	enumeration
		%Function的返回值为标量
		Scalar
		%SplitDimensions为标量，且Function的返回值为类型、PackDimensions维度上尺寸均相同的数组
		Linear
		%Function的返回值为数值、逻辑、字符或字段相同的结构体数组，且尺寸完全相同
		EsNlcs
		%Function的返回值为数组，允许尺寸不同，但最终可以拼接成一整个大数组
		CanCat
		%不符合上述任何条件，或返回值为函数句柄
		DontCat
	end
end
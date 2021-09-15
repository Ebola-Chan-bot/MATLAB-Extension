classdef PreviewOptions
	%本类枚举了生成预览的方式。
	enumeration
		%直接读入第1帧作为预览图
		First
		%直接读入最后一帧作为预览图
		Last
		%读取随机某帧作为预览图
		Random
		%取所有帧的平均值作为预览图
		Mean
		%取所有帧的标准差作为预览图
		Std
	end
end
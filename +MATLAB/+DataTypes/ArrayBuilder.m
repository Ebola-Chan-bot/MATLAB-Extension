classdef ArrayBuilder<handle
	%数组累加器
	%将数据向内存中积累时，经常遇到需要不断累加数组的问题，MATLAB会提示预分配内存。但如果读取之前无法得知将会有多少项，预分配就会变成一个十分麻烦的动态任务。本类建立一个增长维度，在此维度上可以不断累加一个内置的数组。用户只需不断Append即可，无需考虑内存分配的问题，本类会自动进行优化的内存管理。
	properties(Access=private)
		%数据存储实体
		Storage cell
		Capacity=0
		%当前在累加维度上的累加数
		Stock=0
	end
	properties(SetAccess=immutable)
		%累加维度
		BuildDimension
	end
	methods
		function obj = ArrayBuilder(BuildDimension)
			%构造ArrayBuilder对象
			%# 语法
			% ```
			% import MATLAB.DataTypes.ArrayBuilder
			%
			% obj=ArrayBuilder;
			% %构造在第1维度上累加的数组
			%
			% obj=ArrayBuilder(BuildDimension)
			% %构造在指定维度上累加的数组
			% ```
			%# 输入参数
			% BuildDimension(1,1)uint8=1，累加维度
			arguments
				BuildDimension=1
			end
			obj.BuildDimension=BuildDimension;
		end
		function Append(obj,New)
			%向数组末尾累加新值
			%# 语法
			% ```
			% obj.Append(New);
			% ```
			%# 输入参数
			% New，累加内容。所有累加内容在累加维度上尺寸可以不一致，但在其它维度上必须一致。
			obj.Stock=obj.Stock+1;
			if obj.Capacity<obj.Stock
				obj.Capacity=obj.Stock*2;
				obj.Storage(obj.Capacity)=cell(1,1);
			end
			obj.Storage{obj.Stock}=New;
		end
		function Array=Harvest(obj)
			%收获累加完毕的MATLAB数组。收获后可以释放本对象，也可以继续累加。
			%# 语法
			% ```
			% Array=obj.Harvest;
			% ```
			%# 返回值
			% Array，目前累加到的数组拼接
			Array=cat(obj.BuildDimension,obj.Storage{1:obj.Stock});
			obj.Storage={Array};
			obj.Stock=1;
			obj.Capacity=1;
		end
		function Clear(obj)
			%清空ArrayBuilder对象
			%# 语法
			% ```
			% obj.Clear;
			% ```
			%注意，此方法不会立即清空缓存中的类对象，因而也不会立即析构它们，您必须手动析构。
			obj.Stock=0;
		end
	end
end
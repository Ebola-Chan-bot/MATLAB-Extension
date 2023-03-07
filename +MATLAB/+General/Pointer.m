classdef Pointer<uint64
	%分配和读写C++内存指针
	%MATLAB并不直接支持内存指针。本类封装一些C++指针操作，可用于与C++代码互操作。指针本质上就是一个uint64数值，因此本类继承uint64，而且可以与uint64任意相互转
	% 换，还支持整数加减法，如同C++中的指针一样。
	%只有POD类型数据支持直接指针读写，非POD类型一般应当序列化为POD类型数组才能写入指针。所谓POD类型，是指长度固定的、内部不引用其它数据类型的基本数据类型，主要
	% 包括 logical, char 和数值的满矩阵类型。非POD类型往往长度不确定，内部会引用其它数据类型。例如string内部是char；cell, struct, table 等复杂数据结构内部都能
	% 包含多种任意数据类型。一般不应当将非POD类型直接写入指针，也不应当直接从指针读入非POD类型。
	%由于本类能直接访问内存指针，它不能保证内存安全。您有义务确保内存访问不越界、不访问已释放或未分配的内存、用正确的方法释放内存等。错误的内存操作可能造成意外
	% 结果。本类所有文字说明中提到的"意外结果"均可能包括数据错误、安全隐患、MATLAB进程崩溃等。
	methods(Static)
		function obj=Allocate(options)
			%获取一个内存指针，指向一段新分配的内存
			%此方法内部使用C标准库的<a href=https://learn.microsoft.com/zh-cn/cpp/c-runtime-library/reference/malloc?view=msvc-170>malloc</a>分配堆内存，不能自动释放，必须用Release成员方法手动释放，否则将造成内存泄漏
			%# 语法
			% ``` 
			% obj=MATLAB.General.Pointer.Allocate(Name=Value);
			% ```
			%# 名称值参数
			% NumBytes(1,1)uint64=0，要分配的字节数。如果不设置此参数，将根据FillData的字节数决定。
			% FillData cell={}，要填充的初始内容，用元胞数组串联填充多种不同类型的POD数组，它们将在内存中连续紧密排列。如果同时还设置了NumBytes参数，则这些初始
			%  内容的总字节数不能超过NumBytes。
			%# 返回值
			% obj(1,1)MATLAB.General.Pointer，拥有分配的新内存的指针，指向内存起始。如果指定了NumBytes，内存的大小为NumBytes；否则为FillData的字节数。
			%See also MATLAB.General.Pointer.Release MATLAB.General.Pointer
			arguments
				options.NumBytes=0;
				options.FillData={};
			end
			obj=MATLAB.General.Pointer(MATLAB.internal.WindowsAPI.Pointer_Allocate.Call(options.NumBytes,options.FillData));
		end
		function Copy(ToPointer,FromPointer,NumBytes)
			%从一个指针向另一个指针拷贝数据
			%此拷贝无视数据类型，直接拷贝原始字节。
			%# 语法
			% ```
			% MATLAB.General.Pointer.Copy(ToPointer,FromPointer,NumBytes);
			% ```
			%# 输入参数
			% ToPointer(1,1)MATLAB.General.Pointer，拷贝目标指针
			% FromPointer(1,1)MATLAB.General.Pointer，拷贝来源指针
			% NumBytes(1,1)uint64，要拷贝的字节数
			%See also MATLAB.General.Pointer
			MATLAB.internal.WindowsAPI.Pointer_Copy.Call(uint64(ToPointer),uint64(FromPointer),NumBytes);
		end
	end
	methods
		function Data=Read(obj,Number,Type)
			%从指针读入指定类型数据
			%可以读入任意POD类型数据，不需要和写入时的类型一致。但不一致的读写可能会造成错误结果，除非您十分了解数据底层的字节排列。
			%# 语法
			% ```
			% Data=obj.Read(Number,Type);
			% ```
			%# 输入参数
			% Number(1,1)uint64，要读入的元素个数。注意不是字节数，而是类型特定的元素个数，实际字节数还要乘上类型本身的大小。
			% Type(1,1)MATLAB.DataTypes.ArrayType=MATLAB.DataTypes.ArrayType.UINT8，要读入的数据类型。不同的类型具有不同的单元素字节数。
			%# 返回值
			% Data，从指针读入的POD类型数据。
			%See also MATLAB.General.Pointer
			arguments
				obj
				Number
				Type MATLAB.DataTypes.ArrayType=MATLAB.DataTypes.ArrayType.UINT8
			end
			Data=MATLAB.internal.WindowsAPI.Pointer_Read.Call(uint64(obj),Number,int32(Type));
		end
		function Write(obj,varargin)
			%向指针写出POD数据。
			%此方法可以一次写出多个POD数组。此方法存在已知问题，暂不支持写出稀疏矩阵，将产生意外结果。将在以后版本中修复。
			%# 语法
			% ```
			% obj.Write(Data1,Data2,…);
			% ```
			%# 输入参数
			% Data1,Data2,…，要写出的POD数组，将在内存中连续紧密排列。
			%See also MATLAB.General.Pointer
			MATLAB.internal.WindowsAPI.Pointer_Write.Call(uint64(obj),varargin);
		end
		function Release(obj)
			%释放内存指针
			%从Allocate方法得到的内存，为其返回的起始指针所有的堆内存。在内存使用完毕后，必须用那个起始指针执行此释放方法，否则该段内存直到MATLAB进程结束都不会
			% 释放，产生内存泄漏。该段内存内其它指针（通常由起始指针加偏移得到）不拥有该段内存，不能用那些指针释放，否则将产生意外结果。释放只能执行一次，多次释
			% 放将产生意外结果。从本类以外的方法得到的指针不能用此方法释放，那些指针应当由指针的提供方负责说明如何释放。
			%See also MATLAB.General.Pointer.Allocate MATLAB.General.Pointer
			MATLAB.internal.WindowsAPI.Pointer_Release.Call(uint64(obj));
		end
		function obj=plus(obj,Offset)
			%为指针增加一个偏移量
			%内存段的起始指针拥有那段内存。起始指针偏移后得到的指针不拥有内存，不能用于释放，否则将产生意外结果。
			%# 语法
			% ```
			% NewPointer=OldPointer+Offset;
			% ```
			%# 输入参数
			% OldPointer MATLAB.General.Pointer，要加偏移的指针
			% Offset int64，要偏移的字节数
			%# 返回值
			% NewPointer MATLAB.General.Pointer，偏移后的指针
			%See also MATLAB.General.Pointer
			obj=MATLAB.General.Pointer(int64(obj)+int64(Offset));
		end
		function obj=minus(obj,Offset)
			%为指针减去一个偏移量，或求两个指针之间相差的字节数
			%内存段的起始指针拥有那段内存。起始指针偏移后得到的指针不拥有内存，不能用于释放，否则将产生意外结果。
			%# 语法
			% ```
			% NewPointer=OldPointer-Offset;
			% %将指针减去一个偏移量得到新指针
			%
			% Offset=Pointer1-Pointer2;
			% %求两个指针的字节数距离
			% ```
			%# 输入参数
			% OldPointer MATLAB.General.Pointer，要减偏移的指针
			% Pointer1,Pointer2 MATLAB.General.Pointer，要求差的指针
			% Offset int64，要偏移的字节数
			%# 返回值
			% NewPointer MATLAB.General.Pointer，偏移后的指针
			% Offset int64，两个指针相差的字节数
			%See also MATLAB.General.Pointer
			obj=int64(obj)-int64(Offset);
			if ~isa(Offset,'MATLAB.General.Pointer')
				obj=MATLAB.General.Pointer(obj);
			end
		end
	end
end
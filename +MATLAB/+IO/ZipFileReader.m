classdef ZipFileReader<handle
	%ZIP文件批量读入器，直接从ZIP档案中读入，不会向磁盘写出解压文件
	%此类不公开构造函数，请从MATLAB.IO.ZipReader.FOpen方法获取对象。
	%ZipFileReader持有创建它的ZipReader的引用。因此在所有ZipFileReader被删除前，创建它的ZipReader都不会被垃圾回收。
	properties(SetAccess=immutable,GetAccess=private)
		Pointer
	end
	properties(SetAccess=immutable)
		%创建该对象的ZipReader
		ZipReader
	end
	methods(Access=?MATLAB.IO.ZipReader)
		function obj=ZipFileReader(Pointer,Reader)
			obj.Pointer=Pointer;
			obj.ZipReader=Reader;
		end
	end
	methods
		function [Data,BytesRead]=Read(objs,NumBytes)
			%从文件读入指定数目的字节
			%# 语法
			% ```
			% [Data,BytesRead]=Read(objs,NumBytes);
			% ```
			%# 输入参数
			% objs(:,1)MATLAB.IO.ZipFileReader，要读入的文件。可以一次从多个文件读入。
			% NumBytes(1,1)uint64，要读入的字节数上限。所有文件尽可能读入字节，直到文件读完或达到该上限值。
			%# 返回值
			% Data(NumBytes,numel(objs))uint8，读入的字节。第1维是单个文件读入的字节，第2维是不同的文件。
			% BytesRead(1,numel(objs))int64，每个文件实际读入的字节数。对应Data每列，只有前BytesRead行是读入的有效字节，其后的字节是未定义的。
			%# 提示
			% 每次读入后内部会保存文件指针，下次从上次读入的末尾开始读。无法手动指定指针位置。要回到文件开头，只能delete该读入器然后重新打开。
			% 使用typecast可以将字节转换为其它数据类型。
			% 使用MATLAB.IO.ZipReader.GetSize获取文件压缩前大小。
			%See also typecast MATLAB.IO.ZipReader.GetSize
			[Data,BytesRead]=MATLAB.internal.WindowsAPI.ZipFread.Call([objs.Pointer],uint64(NumBytes));
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.ZipFclose.Call(obj.Pointer);
		end
	end
end
classdef ZipReader<handle
	%ZIP档案读入器。不同于内置unzip，本类支持直接读入ZIP档案中的文件字节（解压后的），而不需要将其解压到文件。
	%本类底层基于C++库[libzip](https://github.com/Silver-Fang/libzip-NuGet )。暂不支持读入加密的ZIP，不支持修改ZIP档案。
	properties(SetAccess=immutable,GetAccess=private)
		Pointer
	end
    methods
        function obj = ZipReader(ZipPath)
			%构造ZipReader对象，从指定路径打开一个ZIP档案
			%# 语法
			% ```
			% obj=MATLAB.IO.ZipReader(ZipPath);
			% ```
			%# 输入参数
			% ZipPath(1,1)string，ZIP档案路径，不支持加密的ZIP
            obj.Pointer=MATLAB.internal.WindowsAPI.ZipOpen.Call(ZipPath);
		end
		function Locates=NameLocate(obj,Names)
			%查找指定文件名在档案中的索引
			%# 语法
			% ```
			% Locates=obj.NameLocate(Names)
			% ```
			%# 输入参数
			% Names(:,1)string，要查找的文件名，可以一次查找多个文件
			%# 返回值
			% Locates(:,1)int64，对应每个文件名的索引，从0开始。-1表示没找到。
			%See also MATLAB.IO.ZipReader.GetName
			Locates=MATLAB.internal.WindowsAPI.ZipNameLocate.Call(obj.Pointer,Names);
		end
		function FileReader=FOpen(obj,NameOrIndex)
			%打开ZIP档案中的文件以供读入
			%# 语法
			% ```
			% Readers=obj.FOpen;
			% %打开档案中所有的文件
			%
			% Readers=obj.FOpen(Names);
			% %打开档案中具有指定文件名的文件
			%
			% Readers=obj.FOpen(Indices);
			% %打开档案中指定索引处的文件
			% ```
			%# 输入参数
			% Names(:,1)string，要打开的文件名，可以一次打开多个文件
			% Indices(:,1)uint64，要打开的文件索引，从0开始，可以一次打开多个文件
			%# 返回值
			% Readers(:,1)MATLAB.IO.ZipFileReader，对应ZIP内指定顺序的每个文件返回一个ZIP文件读入器
			%See also MATLAB.IO.ZipFileReader
			if nargin>1
				if isreal(NameOrIndex)
					NameOrIndex=uint64(NameOrIndex);
				end
				FileReader=MATLAB.internal.WindowsAPI.ZipFopen.Call(obj.Pointer,NameOrIndex);
			else
				FileReader=MATLAB.internal.WindowsAPI.ZipFopen.Call(obj.Pointer);
			end
			FileReader=arrayfun(@(Pointer)MATLAB.IO.ZipFileReader(Pointer,obj),FileReader);
		end
		function Sizes=GetSize(obj,NameOrIndex)
			%获取档案中指定文件的压缩前大小
			%# 语法
			% ```
			% Sizes=obj.GetSize
			% %获取档案中所有文件的大小
			%
			% Sizes=obj.GetSize(Names);
			% %获取档案中具有指定文件名的文件大小
			%
			% Sizes=obj.GetSize(Indices);
			% %获取档案中指定索引处的文件大小
			% ```
			%# 输入参数
			% Names(:,1)string，要查询大小的文件名，可以一次查询多个文件
			% Indices(:,1)uint64，要查询大小的文件索引，从0开始，可以一次查询多个文件
			%# 返回值
			% Sizes(:,1)uint64，对应ZIP内指定顺序的每个文件返回其压缩前大小
			if nargin>1
				if isreal(NameOrIndex)
					NameOrIndex=uint64(NameOrIndex);
				end
				Sizes=MATLAB.internal.WindowsAPI.ZipGetSize.Call(obj.Pointer,NameOrIndex);
			else
				Sizes=MATLAB.internal.WindowsAPI.ZipGetSize.Call(obj.Pointer);
			end
		end
		function Names=GetName(obj,Indices)
			%根据索引取得文件名
			%# 语法
			% ```
			% Names=obj.GetName;
			% %取得档案中所有文件名
			%
			% Names=obj.GetName(Indices);
			% %取得档案中指定索引的文件名
			% ```
			%# 输入参数
			% Indices(:,1)uint64，要查找的文件索引，从0开始，可以一次查找多个文件
			%# 返回值
			% Names(:,1)string，对应指定索引取得的文件名
			%See also MATLAB.IO.ZipReader.NameLocate MATLAB.IO.ZipReader.GetNumEntries
			if nargin>1
				Names=MATLAB.internal.WindowsAPI.ZipGetName.Call(obj.Pointer,uint64(Indices));
			else
				Names=MATLAB.internal.WindowsAPI.ZipGetName.Call(obj.Pointer);
			end
		end
		function NumEntries=GetNumEntries(obj)
			%获取档案中的文件数目
			%# 语法
			% ```
			% NumEntries=obj.GetNumEntries;
			% ```
			%# 返回值
			% NumEntries(1,1)int64，档案中的文件数目
			%See also MATLAB.IO.ZipReader.GetName
			NumEntries=MATLAB.internal.WindowsAPI.ZipGetNumEntries.Call(obj.Pointer);
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.ZipDiscard.Call(obj.Pointer);
		end
    end
end
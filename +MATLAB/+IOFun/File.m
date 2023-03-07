classdef File<handle
	%使用 Win32 API 的文件读写操作，比MATLAB内置文件操作更灵活丰富
	%仅支持读写POD类型，与General.Pointer类似。但是，您可以写出任意长度的数据，而不需要预先分配空间。文件可以自动延长。不同于MATLAB内置文件操作函数，此文件对象
	% 会自动释放并关闭文件，不需要手动关闭。
	%See also MATLAB.General.Pointer
	properties(SetAccess=immutable)
		%文件句柄，可用于创建内存映射文件等
		Handle
	end
	methods
		function obj = File(FileName,options)
			%创建或打开文件或 I/O 设备。
			%最常用的 I/O 设备如下所示：文件、文件流、目录、物理磁盘、卷、控制台缓冲区、磁带驱动器、通信资源、mailslot 和管道。 该函数返回一个句柄，该句柄可用
			% 于访问不同类型的 I/O 的文件或设备，具体取决于文件或设备以及指定的标志和属性。本函数所有名称值参数均为Flags类型旗帜参数，有些还可以用|运算符进行旗
			% 帜组合。详情参阅Flags代码文件。本函数基于 Win32 API CreateFileW 实现，详情参阅微软文档。
			%# 语法
			% ```
			% obj=MATLAB.IOFun.File(FileName,Name=Value);
			% ```
			%# 输入参数
			% FileName(1,1)string，要创建或打开的文件或设备的名称。 可以在此名称中使用正斜杠 (/) 或反斜杠 (\) 。
			% ## 名称值参数
			%  DesiredAccess(1,1)MATLAB.Flags=MATLAB.Flags.GENERIC_READ，请求对文件或设备的访问权限，可汇总为读取、写入或两者均不。最常用的值是
			%   GENERIC_READ、 GENERIC_WRITE或两者（GENERIC_READ + GENERIC_WRITE）。如果此参数为零（ZERO），则应用程序可以在不访问该文件或设备的情况下查询某
			%   些元数据，例如文件、目录或设备属性，即使拒绝了GENERIC_READ访问。不能请求与已打开句柄的打开请求中 ShareMode 参数指定的共享模式冲突的访问模式。
			%  ShareMode(1,1)MATLAB.Flags=MATLAB.Flags.FILE_SHARE_READ+MATLAB.Flags.FILE_SHARE_WRITE|MATLAB.Flags.FILE_SHARE_DELETE，文件或设备请求的共享模
			%   式，可以读取、写入、删除、所有这些或无。对属性或扩展属性的访问请求不受此标志的影响。如果此参数为零（ZERO）且创建文件成功，则文件或设备无法共享，
			%   并且无法在文件或设备的句柄关闭之前再次打开。无法请求与具有打开句柄的现有请求中指定的访问模式冲突的共享模式，创建文件将失败。若要启用进程在打开文
			%   件或设备时共享文件或设备，请使用一个或多个Flags值的兼容组合。
			%  CreationDisposition(1,1)MATLAB.Flags=MATLAB.Flags.OPEN_EXISTING，对存在或不存在的文件或设备执行的操作。对于文件以外的设备，此参数通常设置为
			%   OPEN_EXISTING。
			%  FlagsAndAttributes(1,1)MATLAB.Flags=MATLAB.Flags.FILE_ATTRIBUTE_NORMAL，文件或设备属性和标志， FILE_ATTRIBUTE_NORMAL 是文件最常见的默认值。此
			%   参数可以包含可用文件属性的任意组合，(FILE_ATTRIBUTE_*) 。 所有其他文件属性都替代 FILE_ATTRIBUTE_NORMAL。此参数还可以包含标志组合，
			%   (FILE_FLAG_) 来控制文件或设备缓存行为、访问模式和其他特殊用途标志。这些值与任何 FILE_ATTRIBUTE_ 值结合使用。注意当打开现有文件时，它通常将文件
			%   标志与现有文件的文件属性组合在一起，并忽略作为 FlagsAndAttributes 的一部分提供的任何文件属性。
			%See also <a href="matlab:edit MATLAB.Flags">MATLAB.Flags</a> <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/fileapi/nf-fileapi-createfilew">CreateFileW</a>
			arguments
				FileName
				options.DesiredAccess=MATLAB.Flags.GENERIC_READ
				options.ShareMode=MATLAB.Flags.FILE_SHARE_READ|MATLAB.Flags.FILE_SHARE_WRITE|MATLAB.Flags.FILE_SHARE_DELETE
				options.CreationDisposition=MATLAB.Flags.OPEN_EXISTING
				options.FlagsAndAttributes=MATLAB.Flags.FILE_ATTRIBUTE_NORMAL
			end
			obj.Handle=MATLAB.internal.WindowsAPI.File_Create.Call(FileName,uint32(options.DesiredAccess),uint32(options.ShareMode),uint32(options.CreationDisposition),uint32(options.FlagsAndAttributes));
		end
		function FileSize=GetSize(obj)
			%检索指定文件的大小。
			%必须使用 FILE_READ_ATTRIBUTES 访问权限或等效项创建句柄，或者调用方必须对包含文件的目录具有足够的权限。本函数基于 Win32 API GetFileSizeEx 实现，详
			% 情参阅微软文档。
			%# 返回值
			% FileSize(1,1)uint64，文件大小（以字节为单位）
			%See also <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/fileapi/nf-fileapi-getfilesizeex">GetFileSizeEx</a>
			FileSize=MATLAB.internal.WindowsAPI.File_GetSize.Call(obj.Handle);
		end
		function Data=Read(obj,varargin)
			%从指定的文件或输入/输出 (I/O) 设备读取数据。 如果设备支持，则读取发生在文件指针指定的位置。
			%# 语法
			% ```
			% Data=obj.Read(Number,Type);
			% ```
			%# 输入参数
			% Number(1,1)uint64=intmax('uint64')，要读入的元素个数。注意不是字节数，而是类型特定的元素个数，实际字节数还要乘上类型本身的大小。如果不指定此参
			%  数，将尽可能多地读入。
			% Type(1,1)MATLAB.DataTypes.ArrayType=MATLAB.DataTypes.ArrayType.UINT8，要读入的数据类型。不同的类型具有不同的单元素字节数。
			%# 返回值
			% Data(:,1)，从指针读入的POD类型数据。如果请求的字节数超出文件大小，将读入尽可能多的元素个数直到文件结束。
			Number=intmax('uint64');
			Type=MATLAB.DataTypes.ArrayType.UINT8;
			for V=1:numel(varargin)
				Arg=varargin{V};
				if isnumeric(Arg)&&~isa(Arg,'MATLAB.DataTypes.ArrayType')
					Number=Arg;
				else
					Type=MATLAB.DataTypes.ArrayType(Arg);
				end
			end
			Data=MATLAB.internal.WindowsAPI.File_Read.Call(obj.Handle,Number,int32(Type));
		end
		function SetEnd(obj)
			%将指定文件的物理文件大小设置为文件指针的当前位置。
			%物理文件大小也称为文件末尾。本函数可用于截断或扩展文件。本函数基于 Win32 API SetEndOfFile 实现，详情参阅微软文档。
			%See also <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/fileapi/nf-fileapi-setendoffile">SetEndOfFile</a>
			MATLAB.internal.WindowsAPI.File_SetEnd.Call(obj.Handle);
		end
		function NewFilePointer=SetPointer(obj,DistanceToMove,MoveMethod)
			%移动指定文件的文件指针。
			%本函数基于 Win32 API SetFilePointerEx 实现，详情参阅微软文档。
			%# 语法
			% ```
			% NewFilePointer=obj.SetPointer;
			% %获取当前文件指针位置
			%
			% NewFilePointer=obj.SetPointer(DistanceToMove);
			% %设置新的文件指针位置，以文件开头为原点
			%
			% NewFilePointer=obj.SetPointer(DistanceToMove,MoveMethod);
			% %将文件指针设定为相对于指定参照系的偏移
			% ```
			%# 输入参数
			% DistanceToMove(1,1)uint64，移动文件指针的字节数。 正值将文件中的指针向前移动，负值将文件指针向后移动。
			% MoveMethod(1,1)MATLAB.Flags，文件指针移动的起点。详见Flags代码文件。
			%# 返回值
			% NewFilePointer(1,1)uint64，新文件指针
			%See also <a href="matlab:edit MATLAB.Flags">MATLAB.Flags</a> <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/fileapi/nf-fileapi-setfilepointerex">SetFilePointerEx</a>
			switch nargin
				case 1
					DistanceToMove=0;
					MoveMethod=MATLAB.Flags.FILE_CURRENT;
				case 2
					MoveMethod=MATLAB.Flags.FILE_BEGIN;
			end
			NewFilePointer=MATLAB.internal.WindowsAPI.File_SetPointer.Call(obj.Handle,DistanceToMove,uint32(MoveMethod));
		end
		function Write(obj,varargin)
			%将数据写入指定的文件或输入/输出 (I/O) 设备。
			%此方法可以一次写出多个POD数组。此方法存在已知问题，暂不支持写出稀疏矩阵，将产生意外结果。将在以后版本中修复。
			%# 语法
			% ```
			% obj.Write(Data1,Data2,…);
			% ```
			%# 输入参数
			% Data1,Data2,…，要写出的POD数组，将在文件中连续紧密排列。
			MATLAB.internal.WindowsAPI.File_Write.Call(obj.Handle,varargin);
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.File_Close.Call(obj.Handle);
		end
	end
end
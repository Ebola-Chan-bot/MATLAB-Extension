classdef MemoryMapping<handle
	%使用 Win32 API 操作内存映射文件
	%相比于内置memmapfile，本类不必要映射一个磁盘上已存在的文件，并允许更灵活的指针操作。使用Create或Open方法获取对象，View方法获取映射指针，用指针操作读写数据。
	%See also MATLAB.General.SharedPtr
	properties(SetAccess=immutable,GetAccess=private)
		Handle
	end
	methods(Access=private)
		function obj = MemoryMapping(Handle)
			obj.Handle=Handle;
		end
	end
	methods(Static)
		function varargout=Create(options)
			%为指定文件创建或打开命名或未命名的文件映射对象。
			%创建文件映射对象后，文件的大小不得超过文件映射对象的大小;如果存在，则并非所有文件内容都可用于共享。如果应用程序为大于磁盘上实际命名文件的大小的文件映射对
			% 象指定了一个大小，并且如果页面保护允许写入访问，即 Protect 参数指定 PAGE_READWRITE 或 PAGE_EXECUTE_READWRITE，则磁盘上的文件将增加以匹配文件映射对象的
			% 指定大小。 如果扩展了文件，则文件旧端与文件新端之间的文件内容不保证为零：行为由文件系统定义。 如果磁盘上的文件无法增加，函数将失败。由操作系统分页文件支
			% 持的文件映射对象中页面的初始内容为0。返回的句柄对新的文件映射对象具有完全访问权限，可用于需要文件映射对象的句柄的任何函数。多个进程可以使用单个共享文件
			% 映射对象或创建由同一文件支持的单独文件映射对象来共享同一文件的视图。 单个文件映射对象可以通过在创建进程时继承句柄、复制句柄或按名称打开文件映射对象，由
			% 多个进程共享。创建文件映射对象实际上不会将视图映射到进程地址空间。View函数将文件的视图映射到进程地址空间。有一个重要例外，从由同一文件支持的任何文件映射
			% 对象派生的文件视图在特定时间是一致的或相同的。 对于进程内的视图和由不同进程映射的视图，可以保证一致性。异常与远程文件相关。 尽管本函数适用于远程文件，但
			% 它不会保持一致。 例如，如果两台计算机都将一个文件映射为可写文件，并且两台计算机都更改了同一页，则每台计算机只能看到自己对页面的写入。 在磁盘上更新数据
			% 时，不会合并数据。使用输入和输出 (I/O) 函数访问的映射文件和文件 (File类的Read和Write方法) 不一定是一致的。文件映射对象的映射视图维护对对象的内部引用，
			% 并且文件映射对象在释放对其的所有引用之前不会关闭。通过映射视图修改文件时，可能不会自动更新上次修改时间戳。 
			%本函数基于 Win32 API CreateFileMappingW 实现，详情参阅微软文档。
			%# 语法
			% ```
			% obj=MATLAB.IOFun.MemoryMapping.Create(Name=Value);
			% %创建或打开命名或未命名的文件映射对象
			%
			% [obj,Pointer]=MATLAB.IOFun.MemoryMapping.Create(Name=Value);
			% %额外返回指向映射起始位置的指针
			% ```
			%# 名称值参数
			% File(1,1)=intmax('uint64')，要从中创建文件映射对象的文件的句柄。必须使用与 Protect 参数指定的保护标志兼容的访问权限打开该文件。这不是必需的，但建议打开
			%  要映射的文件进行独占访问。如果不指定此参数或指定为intmax('uint64')，则调用过程还必须为 MaximumnSize 参数中的文件映射对象指定大小，或者指定FillData。在
			%  此方案中，将创建一个指定大小的文件映射对象，该对象由系统分页文件而不是文件系统中的文件提供支持。
			% Protect(1,1)MATLAB.Flags，指定文件映射对象的页面保护。对象的所有映射视图都必须与此保护兼容。默认值为PAGE_READONLY，但如果File和Name均未指定，或指定了
			%  FillData，默认值为PAGE_READWRITE。详情参阅Flags代码文件。
			% MaximumSize(1,1)uint64=0，文件映射对象的最大大小。如果此参数为0，则文件映射对象的最大大小等于 File 标识的文件的当前大小与FillData的总字节数的孰大值。尝
			%  试映射长度为0的文件将失败。应用程序应测试长度为0的文件，并拒绝这些文件。
			% Name(1,:)char=''，文件映射对象的名称。如果此参数与现有映射对象的名称匹配，函数将请求访问具有 Protect 指定的保护的对象。如果此参数为空值，则创建没有名称
			%  的文件映射对象。如果 Name 与现有事件、信号灯、mutex、可等待计时器或作业对象的名称匹配，则函数将失败，发生这种情况是因为这些对象共享相同的命名空间。该名
			%  称可以具有"Global\"或"Local\"前缀，以在全局或会话命名空间中显式创建对象。 名称的其余部分可以包含除反斜杠字符 (\) 以外的任何字符。 从会话零以外的会话创
			%  建全局命名空间中的文件映射对象需要 SeCreateGlobalPrivilege 特权。使用终端服务会话实现快速用户切换。第一个登录的用户使用会话0，下一个登录的用户使用会话
			%  1等。 内核对象名称必须遵循终端服务概述的准则，以便应用程序可以支持多个用户。
			% FillData cell={}，要填充的初始内容，用元胞数组串联填充多种不同类型的POD数组，它们将在内存中连续紧密排列。如果同时还设置了MaximumSize参数，则这些初始内
			%  容的总字节数不能超过MaximumSize。如果指定了File且文件当前长度小于FillData总字节数，文件将被自动扩展。
			%# 返回值
			% obj(1,1)MATLAB.IOFun.MemoryMapping，新创建的文件映射对象的句柄。如果该对象在函数调用之前存在，则函数将返回现有对象的句柄（其当前大小，而不是指定的大
			%  小）。如果创建了新的映射，其大小等于MaximumSize。如果未指定MaximumSize或指定为0，则文件映射对象的最大大小等于 File 标识的文件的当前大小与FillData的总
			%  字节数的孰大值。
			% Pointer(1,1)MATLAB.General.SharedPtr，指向映射起始位置的指针，直到映射结束的整个内存段都可以访问，访问权限与Protect一致。
			%See also <a href="matlab:edit MATLAB.Flags">MATLAB.Flags</a> <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/memoryapi/nf-memoryapi-createfilemappingw">CreateFileMappingW</a> 
			arguments
				options.File=intmax('uint64')
				options.Protect %这里即使限定uint32也不会对MATLAB.Flags进行转换，因此必须手动转换uint32
				options.MaximumSize=0
				options.Name=''
				options.FillData={}
			end
			if isa(options.File,'MATLAB.IOFun.File')
				File=options.File.Handle;
			else
				File=options.File;
			end
			if isfield(options,'Protect')
				Protect=options.Protect;
			elseif ~isempty(options.FillData)||options.File==intmax('uint64')&&options.Name==""
				Protect=MATLAB.Flags.PAGE_READWRITE;
			else
				Protect=MATLAB.Flags.PAGE_READONLY;
			end
			varargout=cell(1,nargout);
			[varargout{:}]=MATLAB.internal.WindowsAPI.MemoryMapping_Create.Call(File,uint32(Protect),options.MaximumSize,options.Name,options.FillData);
			varargout{1}=MATLAB.IOFun.MemoryMapping(varargout{1});
			if nargout>1
				varargout{2}=MATLAB.General.SharedPtr(varargout{2},@(Pointer)MATLAB.internal.WindowsAPI.MemoryMapping_Unview.Call(uint64(Pointer)));
			end
		end
		function varargout=Open(Name,DesiredAccess)
			%打开已存在的命名文件映射对象。
			%本函数基于 Win32 API OpenFileMappingW 实现，详情参阅微软文档。
			%# 语法
			% ```
			% import MATLAB.IOFun.MemoryMapping
			% obj=MemoryMapping.Open(Name);
			% %只读打开一个已命名的映射句柄
			%
			% obj=MemoryMapping.Open(Name,DesiredAccess);
			% %额外指定更多访问权限
			%
			% [obj,Pointer]=MemoryMapping.Open(___);
			% %与上述任意语法组合使用，额外返回指向映射起始位置的指针
			% ```
			%# 输入参数
			% Name(1,1)string，要打开的文件映射对象的名称。 如果按此名称打开文件映射对象的句柄，并且映射对象上的安全描述符与 DesiredAccess 参数不冲突，则打开操作会成
			%  功。 该名称可以具有"Global\"或"Local\"前缀，以在全局或会话命名空间中显式打开对象。 名称的其余部分可以包含除反斜杠字符 (\) 以外的任何字符。 快速用户切
			%  换是使用终端服务会话实现的。 第一个登录的用户使用会话 0、下一个登录的用户使用会话 1 等。 内核对象名称必须遵循终端服务概述的准则，以便应用程序能够支持多
			%  个用户。
			% DesiredAccess(1,1)MATLAB.Flags=MATLAB.Flags.FILE_MAP_READ，对文件映射对象的访问。 针对目标文件映射对象上的任何安全描述符检查此访问。 有关值的列表，请
			%  参阅Flags代码文件。
			%# 返回值
			% obj(1,1)MATLAB.IOFun.MemoryMapping，指定文件映射对象的打开句柄。
			% Pointer(1,1)MATLAB.General.SharedPtr，指向映射起始位置的指针，直到映射结束的整个内存段都可以访问，访问权限与DesiredAccess一致。
			%See also <a href="matlab:edit MATLAB.Flags">MATLAB.Flags</a> <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/memoryapi/nf-memoryapi-openfilemappingw">OpenFileMappingW</a> 
			arguments
				Name
				DesiredAccess=MATLAB.Flags.FILE_MAP_READ
			end
			varargout=cell(1,nargout);
			[varargout{:}]=MATLAB.internal.WindowsAPI.MemoryMapping_Open.Call(uint32(DesiredAccess),Name);
			varargout{1}=MATLAB.IOFun.MemoryMapping(varargout{1});
			if nargout>1
				varargout{2}=MATLAB.General.SharedPtr(varargout{2},@(Pointer)MATLAB.internal.WindowsAPI.MemoryMapping_Unview.Call(uint64(Pointer)));
			end
		end
	end
	methods
		function Pointer=View(obj,options)
			%将文件映射的视图映射到调用进程的地址空间。
			%本函数基于 Win32 API MapViewOfFile 实现，详情参阅微软文档。
			%# 语法
			% ```
			% Pointer=obj.View(Name=Value);
			% ```
			%# 名称值参数
			% DesiredAccess(1,1)MATLAB.Flags=MATLAB.Flags.FILE_MAP_READ，对文件映射对象的访问类型，用于确定页面的页面保护。详情参阅Flags代码文件。
			% FileOffset(1,1)uint64=0，要开始视图的文件偏移量。必须匹配系统的内存分配粒度。也就是说，偏移量必须是分配粒度的倍数。
			% NumberOfBytesToMap(1,1)uint64=0，要映射到视图的文件映射的字节数。所有字节必须位于Create方法指定的最大大小范围内。 如果此参数为0，则映射将从指定的偏移量
			%  扩展到文件映射的末尾。
			%# 返回值
			% Pointer(1,1)MATLAB.General.SharedPtr，指向映射起始位置的指针，直到映射结束的整个内存段都可以访问，访问权限与DesiredAccess一致。
			%See also <a href="matlab:edit MATLAB.Flags">MATLAB.Flags</a> MATLAB.General.SharedPtr <a href="https://learn.microsoft.com/zh-cn/windows/win32/api/memoryapi/nf-memoryapi-mapviewoffile">MapViewOfFile</a> 
			arguments
				obj
				options.DesiredAccess=MATLAB.Flags.FILE_MAP_READ
				options.FileOffset=0
				options.NumberOfBytesToMap=0
			end
			Pointer=MATLAB.General.SharedPtr(MATLAB.internal.WindowsAPI.MemoryMapping_View.Call(obj.Handle,uint32(options.DesiredAccess),options.FileOffset,options.NumberOfBytesToMap),@(Pointer)MATLAB.internal.WindowsAPI.MemoryMapping_Unview.Call(uint64(Pointer)));
		end
		function delete(obj)
			MATLAB.internal.WindowsAPI.MemoryMapping_Close.Call(obj.Handle);
		end
	end
end
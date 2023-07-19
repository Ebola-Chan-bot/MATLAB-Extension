classdef ProjectFileSystem
	%此类依赖Windows投影文件系统设计，请参阅https://learn.microsoft.com/zh-cn/windows/win32/projfs/projected-file-system
	properties(SetAccess=immutable)
		Pointer
	end
	methods
		function obj = ProjectFileSystem(VirtualizationRootPath,Notifications,Callbacks)
			%构造一个投影文件系统对象
			%构造对象，必须指定一个挂载根目录，以及一系列回调函数句柄。当Windows访问挂载目录下的文件系统对象时，将调用这些回调函数句柄来实现操作。
			%# 语法
			% ```
			% obj=MATLAB.IOFun.ProjectFileSystem(VirtualizationRootPath,Notifications,Name=Value);
			% ```
			%# 输入参数
			% VirtualizationRootPath(1,1)string，指定虚拟化根目录的完整路径
			% Notifications(1,1)MATLAB.Flags，应当接受的提醒，可用|组合旗帜，详见MATLAB.Flags的 IOFun.ProjectFileSystem Notifications 节。
			% ## 名称值参数
			%  DirectoryEnumeration(1,1)function_handle，用于枚举目录下的条目的回调函数。必须接受一个(1,:)char输入参数，标识要枚举的目录。如果指定目录不
			%   存在，应返回MATLAB.Lang.WindowsErrorCode.ERROR_FILE_NOT_FOUND；否则应返回一个table，每行代表路径下的一个对象，具有以下列：
			%   - FileName(:,1)string，必需，指向包含条目名称的字符串
			%   - IsDirectory(:,1)logical=false，可选，指定该项是否为目录。
			%   - FileSize(:,1)int64，可选，项的大小（以字节为单位）。
			%  GetPlaceholderInfo(1,1)function_handle，用于获取单个对象的信息。必须接受一个(1,:)char输入参数，标识提供者存储中请求信息的文件或目录的路径。
			%   如果指定对象不存在，应返回MATLAB.Lang.WindowsErrorCode.ERROR_FILE_NOT_FOUND；否则应返回(1,1)struct，可选具有以下列：
			%   - DestinationFileName(1,1)string，指定相对于虚拟化根目录的路径，指向要创建占位符的文件或目录。
			%   - IsDirectory(1,1)logical=false，可选，指定该项是否为目录。
			%   - FileSize(1,1)int64，可选，项的大小（以字节为单位）。
			%  GetFileData(1,1)function_handle，用于获取文件数据信息。必须依次接受以下参数：
			%   1. FilePathName(1,:)char，标识提供程序后盾存储中应为其返回数据的文件的路径。
			%   2. ByteOffset(1,1)uint64，请求的数据偏移量（以字节为单位）从文件开头。 提供程序必须返回从此偏移量开始的文件数据
			%   3. Length(1,1)uint32，请求的文件数据的字节数。 提供程序必须至少返回以byteOffset开头的文件数据字节数。
			%   必须依次返回以下值：
			%   1. Status(1,1)MATLAB.Lang.WindowsErrorCode，执行结果。如果成功，应返回S_OK；否则返回相应错误代码。
			%   2. Data，文件数据，必须是POD类型，包括数值、字符和逻辑，不允许结构体、类对象、元胞等复杂类型。
			arguments
				VirtualizationRootPath
				Notifications
				Callbacks.DirectoryEnumeration
				Callbacks.GetPlaceholderInfo
				Callbacks.GetFileData
				Callbacks.QueryFileName
				Callbacks.Notification
				Callbacks.CancelCommand
			end
			HasFields=ismember(["DirectoryEnumeration"],Callbacks);
			if HasFields(1)
				Callbacks.DirectoryEnumeration=@(FilePathName)DirectoryEnumeration(Callbacks.DirectoryEnumeration,FilePathName);
			end
			obj.Pointer=MATLAB.internal.WindowsAPI.PFS_Create.Call(VirtualizationRootPath,Notifications,Callbacks);
		end
	end
end
function Enumerations=DirectoryEnumeration(UserFunction,FilePathName)
Enumerations=UserFunction(FilePathName);
if istabular(Enumerations)
	HasColumns=ismember(["IsDirectory","FileSize"],Enumerations.Properties.VariableNames);
	Enumerations.FileName=string(Enumerations.FileName);
	if HasColumns(1)
		Enumerations.IsDirectory=logical(Enumerations.IsDirectory);
	end
	if HasColumns(2)
		Enumerations.FileSize=int64(Enumerations.FileSize);
	end
	Enumerations=table2struct(Enumerations,ToScalar=true);
end
end
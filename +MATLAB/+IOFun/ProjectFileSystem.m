classdef ProjectFileSystem
	properties(SetAccess=immutable)
		%用于跨进程共享对象
		GUID
	end
	methods
		function obj = ProjectFileSystem(VirtualizationRootPath,Callbacks)
			%构造一个投影文件系统对象
			%构造对象，必须指定一个挂载根目录，以及一系列回调函数句柄。当Windows访问挂载目录下的文件系统对象时，将调用这些回调函数句柄来实现操作。
			%# 语法
			% ```
			% obj=MATLAB.IOFun.ProjectFileSystem(VirtualizationRootPath,Name=Value);
			% ```
			%# 输入参数
			% VirtualizationRootPath(1,1)string，要将投影文件系统挂载到的根目录
			% ## 名称值参数
			%  StartDirectoryEnumeration(1,1)function_handle，必需
			arguments
				VirtualizationRootPath
				Callbacks.StartDirectoryEnumeration
				Callbacks.EndDirectoryEnumeration
				Callbacks.GetDirectoryEnumeration
				Callbacks.GetPlaceholderInfo
				Callbacks.GetFileData
				Callbacks.QueryFileName
				Callbacks.Notification
				Callbacks.CancelCommand
			end
			obj.GUID=MATLAB.internal.WindowsAPI.PrjStartVirtualizing.Call(VirtualizationRootPath,Callbacks);
		end
	end
end
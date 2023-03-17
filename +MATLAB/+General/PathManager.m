 classdef(Abstract,Sealed)PathManager
	%搜索路径管理系统
	%如果你是本机的唯一MATLAB用户，你应该不需要本类。本类面向的是多用户计算机的管理员，帮助管理员配置MATLAB路径，以便多个用户可以互不干扰地使用同一份MATLAB安装。本类
	% 依赖 .NET 7.0 桌面运行时，首次安装时可能会报错提示需要安装该运行时。本类是纯抽象静态类，不允许构造对象，请直接使用类内静态方法。
	%# 适用症状
	% MATLAB垃圾的多用户搜索路径管理机制已经被广大公用计算机管理员们诟病已久，并且至今没有表露出任何打算改进的意图，因此本工具箱前来解决此问题！如果你管理的公用计算机
	%  上安装了唯一一份MATLAB并且共享给多个用户使用，你可能会遇到以下症状：
	%  - 出现大量红字报错，包括搜索路径找不到、弹出一大堆错误提示对话框提示找不到函数等等。报错后MATLAB大量功能无法正常使用。这是因为路径定义函数pathdef.m为只读。
	%  - MATLAB能够正常使用，但是出现大量橙字警告，提示一大堆搜索路径找不到或无法打开。这是因为某用户设置了他的私有路径，其他用户无法访问。
	%# 病因和疗法
	% 根本原因是MATLAB的搜索路径管理系统设计之初根本没有考虑到多用户之间的共享、隔离功能。多用户之间常常需要共享某些内容，而隔离另一些内容。Windows操作系统对此已经做
	%  了非常好的明确规范，尽管很多应用开发者并不遵守：
	%  - %ProgramFiles%，存放x64应用的只读文件。这些文件应该仅在安装过程中可写，日常使用中应当保持只读。通常在这里存放应用的可执行文件、多媒体素材等日常使用过程中不需
	%   要修改的文件。
	%  - %ProgramFiles(x86)%，存放x86应用的只读文件。
	%  - %ProgramData%，存放一般用户只读、管理员可写的数据。这里通常存放的是一些全局配置文件，管理员有权修改它们，希望被一般用户共享，但不希望一般用户随意修改它们。
	%  - %PUBLIC%，存放所有用户可写的数据。
	%  - %APPDATA%，每个用户专有的应用数据。这些数据仅由每个用户自己可写（除了管理员可读写所有用户数据），对这些数据的修改不会影响其它用户。
	% 我们希望的搜索路径，应当由3部分组成：
	%  - 内置和工具箱函数路径，这些路径应当仅在安装时允许修改，因此应放在%ProgramFiles%目录下
	%  - 用户之间共享的第三方函数路径，这些路径应当只允许管理员修改，一般用户只能读取，因此应放在%ProgramData%目录下
	%  - 用户自己使用的代码路径，这些路径应当允许用户自己修改，但是不应影响到其他用户，因此应放在%APPDATA%下。但是因为MATLAB恰好支持更方便的%MATLABPATH%环境变量，所
	%   以使用该变量实现用户私有路径。
	% 而MATLAB是怎么做的呢？它彻底无视了上述规范，将上述三种路径通通存放在%ProgramFiles%的pathdef.m下。因为%ProgramFiles%被认为是只有在安装时才允许修改的，因此一般用
	%  户无法修改它，也就无法设置自己需要的路径。如果管理员修改了权限，允许一般用户修改它，那么任何一个用户的改动都会影响到其他用户，导致其他用户出现无法访问别人的私有
	%  目录的问题。
	% 为了纠正这个问题，本工具箱需要管理员权限，对内置savepath函数行为进行更改，避免修改全局的pathdef。优化后，一般用户对搜索路径的修改只会影响自己，对其他人无影响；
	%  而管理员则可以明确指定对全局路径的修改，让所有用户共享某些路径。
	methods(Static)
		function Setup
			%安装搜索路径管理系统。
			%需要提权。依赖 .Net 7.0 桌面运行时，若未安装，首次启动时可能出错，提示需要安装。安装操作将调用restoredefaultpath，将MATLAB搜索路径出厂化（已安装的附加功
			% 能不受影响），所有用户自定义搜索路径都会被删除。此操作将影响所有用户。
			%See also MATLAB.General.PathManager.Uninstall
			CurrentPaths=path;
			restoredefaultpath;
			MATLAB.internal.savepath;
			path(CurrentPaths);
			MATLAB.internal.ElevatedOperation.Install_Path_Manager.Call(uint8(numel(matlabroot)),matlabroot);
			clear savepath
		end
		function Uninstall
			%卸载搜索路径管理系统。
			%需要提权。卸载操作将删除之前设置的所有用户私有搜索路径（已安装的附加功能不受影响）。此操作将影响所有用户。
			%See also MATLAB.General.PathManager.Setup
			AllPaths=path;
			try
				SharedPaths=MATLAB.General.PathManager.SharedPaths;
			catch ME
				if ME.identifier=="MATLAB:fileread:cannotOpenFile"
					SharedPaths='';
				else
					ME.rethrow;
				end
			end
			MATLAB.internal.ElevatedOperation.Uninstall_Path_Manager.Call(uint8(numel(matlabroot)),matlabroot);
			clear savepath
			restoredefaultpath;
			path(path,SharedPaths);
			savepath;
			path(AllPaths);
		end
		function SP=SharedPaths(SP)
			%显示/设置共享搜索路径。
			%设置路径需要提权。共享搜索路径将在不同用户之间共享。无论用户设置了任何自定义搜索路径，都不会覆盖共享路径，而是在任何用户启动MATLAB时强制加载。此设置不会
			% 马上应用。只有设置之后启动的MATLAB会话才会应用这些搜索路径。请注意，Windows访问控制系统可能会阻止其他用户对某些路径的访问，请确认你设置的共享路径本身对
			% 其他用户开放访问。
			%# 语法：
			% ```
			% MATLAB.General.PathManager.SharedPaths(SP)
			% %设置共享搜索路径。
			%
			% SP=MATLAB.General.PathManager.SharedPaths
			% %返回当前共享搜索路径
			% ```
			%# 输入参数
			% SP string，要设置的新路径，旧路径会被它删除覆盖。输入可以是字符串数组或分号分隔路径的单个字符串。
			%# 返回值
			% SP(1,1)string，当前共享搜索路径，分号分隔
			%See also MATLAB.General.PathManager.AddSharedPaths
			persistent SharedPath
			if isempty(SharedPath)
				SharedPath=fullfile(getenv('ProgramData'),'MathWorks\PathManager\共享路径.txt');
			end
			if nargin
				SP=char(strip(join(SP,pathsep),pathsep));
				MATLAB.internal.ElevatedOperation.Set_shared_path.Call(uint8(numel(SP)),SP);
			else
				SP=fileread(SharedPath);
			end
		end
		function AddSharedPaths(SP)
			%添加共享搜索路径
			%需要提权。共享搜索路径将在不同用户之间共享。无论用户设置了任何自定义搜索路径，都不会覆盖共享路径，而是在任何用户启动MATLAB时强制加载。此设置不会
			% 马上应用。只有设置之后启动的MATLAB会话才会应用这些搜索路径。请注意，Windows访问控制系统可能会阻止其他用户对某些路径的访问，请确认你设置的共享路径本身对
			% 其他用户开放访问。
			%# 语法
			% ```
			% MATLAB.General.PathManager.AddSharedPaths(SP);
			% ```
			%# 输入参数
			% SP string，要添加的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。已存在的路径会自动排除，不会重复添加。
			%See also MATLAB.General.PathManager.SharedPaths
			SP=char(strip(join(SP,pathsep),pathsep));
			MATLAB.internal.ElevatedOperation.Add_shared_path.Call(uint8(numel(SP)),SP);
		end
		function RemoveSharedPaths(SP)
			%移除共享搜索路径
			%需要提权。此修改不会马上应用，只有在此之后启动的MATLAB会话才会应用这些修改。
			%# 语法
			% ```
			% MATLAB.General.PathManager.RemoveSharedPaths(SP);
			% ```
			%输入参数
			% SP string，要移除的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。移除原本就不存在的搜索路径也不会报错。
			%See also MATLAB.General.PathManager.SharedPaths
			SP=char(strip(join(SP,pathsep),pathsep));
			MATLAB.internal.ElevatedOperation.Remove_shared_path.Call(uint8(numel(SP)),SP);
		end
	end
end
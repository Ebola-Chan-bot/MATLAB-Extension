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
	%  - 用户自己使用的代码路径，这些路径应当允许用户自己修改，但是不应影响到其他用户，因此应放在%APPDATA%下。
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
			MATLAB.internal.WindowsAPI.Get_pathdef_permission.Call;
			%必须用私有函数，因为restoredefaultpath后找不到任何包路径
			MatlabSavepath;
			%必须先save再还原，否则会把工具箱路径也给写进pathdef
			path(CurrentPaths);
			MATLAB.internal.WindowsAPI.Install_path_manager.Call;
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
			MATLAB.internal.WindowsAPI.Uninstall_path_manager.Call;
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
				SharedPath=fullfile(getenv('ProgramData'),'MathWorks\埃博拉酱\共享路径.txt');
			end
			if nargin
				MATLAB.internal.WindowsAPI.Set_shared_path.Call(strip(join(SP,pathsep),pathsep));
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
			MATLAB.internal.WindowsAPI.Add_shared_path.Call(strip(join(SP,pathsep),pathsep))
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
			MATLAB.internal.WindowsAPI.Remove_shared_path.Call(strip(join(SP,pathsep),pathsep))
		end
	end
end
function notsaved = MatlabSavepath(outputfile)
%SAVEPATH Save the current MATLAB path in the pathdef.m file.
%   SAVEPATH saves the current MATLABPATH in the pathdef.m
%   which was read on startup.
%
%   SAVEPATH outputFile saves the current MATLABPATH in the
%   specified file.
%
%   SAVEPATH returns:
%     0 if the file was saved successfully
%     1 if the file could not be saved
%
%   See also PATHDEF, ADDPATH, RMPATH, USERPATH, PATH, PATHTOOL.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;

% Early return if we're not able to perform path operations.
if ~iCanModifyPath()
    notsaved = 1;
    return;
end

% Assume that things are going well until we learn otherwise.
result = 0;

% Unless the user specifies otherwise, we're going to overwrite the
% pathdef.m file that MATLAB currently sees.
if nargin == 0
    if Capability.isSupported(Capability.LocalClient)
        outputfile = which('pathdef.m');
    else
        % If platform is a "remote client", use the prefdir
        % as the default place to save pathdef.m
        outputfile = fullfile(prefdir, 'pathdef.m');
    end
else
    if ~ischar(outputfile) && ~(isstring(outputfile) && isscalar(outputfile))
        if nargout == 1
            notsaved = 1;
        end
        return;
    end
end

if isstring(outputfile)
    outputfile = char(outputfile);
end

% This is a token string that we will look for in the template file.
magic_string = 'PLEASE FILL IN ONE DIRECTORY PER LINE';

templatefile = fullfile(matlabroot, 'toolbox', 'local', 'template', 'pathdef.m');

% Try to read the template file.  If we can't, that's OK, we have a
% backup plan.
fid = fopen(templatefile, 'r');

if fid ~= -1
    template = fread(fid,'*char')';
    fclose(fid);
else
    template = ['function p = pathdef', 10, ...
                '%PATHDEF Search path defaults.', 10, ...
                '%   PATHDEF returns a string that can be used as input to MATLABPATH', 10, ...
                '%   in order to set the path.', 10, 10, ...
                '% DO NOT MODIFY THIS FILE. THE LIST OF ENTRIES IS AUTOGENERATED BY THE', 10, ...
                '% INSTALLER, SAVEPATH, OR OTHER TOOLS. EDITING THE FILE MAY CAUSE THE FILE', 10, ...
                '% TO BECOME UNREADABLE TO THE PATHTOOL AND THE INSTALLER.', 10, 10, ...
                'p = [...', 10, ...
                '%%% BEGIN ENTRIES %%%', 10, ...
                magic_string, 10, ...
                '%%% END ENTRIES %%%', 10, ...
                '     ...', 10, ...
                '];', 10, 10, ...
                'if matlab.internal.feature(''mpm'')', 10, ...
                '    filetimestamp = 0x0000000000000u64', 10, ...
                '    p = [userpath pathsep getenv(''MATLABPATH'') pathsep p pathsep ...', 10, ...
                '        matlab.internal.packages.getPathForPackagesInstalledAfter(filetimestamp)];', 10, ...
                'else', 10, ...
                '    p = [userpath pathsep getenv(''MATLABPATH'') pathsep p];', 10, ...
                'end', 10];
end

% Find the location of the "magic string" in the file.
magic_index = strfind(template, magic_string);

% Take everything that appears *before* the "magic string" line as
% "firstpart," and everything that appears after that line as
% "lastpart."
% We'll sandwich the path particulars between the two ends.
firstpart = template(1:magic_index-1);
lastpart = template(magic_index + 1:end);

lfs_in_firstpart = find(firstpart == 10, 1, 'last');
firstpart = firstpart(1:lfs_in_firstpart);

lfs_in_lastpart = find(lastpart == 10, 1, 'first');
lastpart = lastpart(lfs_in_lastpart+1:end);

% Generate timestamp for the newly created file and inject into lastpart.
file_timestamp = floor(posixtime(datetime('now','TimeZone','UTC')) * 10^6);
lastpart = regexprep(lastpart, '0x[0-9A-F]{13}u64' , ['0x' dec2hex(file_timestamp) 'u64']);

% Read the current path.
thepath = matlabpath;

% First, Break the path down into a cell array of strings, one for
% each entry in the path.  We leave the pathsep on the end of each
% string.  The path might not actually *end* with a pathsep, but if
% not, we add one for consistency's sake.
ps = pathsep;
if thepath(end) ~= ps
    thepath = [thepath ps];
end

% Get the exact form of the entries that we want to create in the
% new pathdef file based on the path.  all_path_lines will be a
% cell array of strings.
DelimitedByAndIncludingSep = ['(.[^' ps ']*' ps '?)'];
all_path_lines = regexp(thepath, DelimitedByAndIncludingSep, 'tokens');
all_path_lines = [all_path_lines{:}]';



% Exclude the value of userworkpath and any temporary editor folders
% from being saved because they are dynamic (per user/session) and
% automatically placed on the path by userpath.m on startup.
try
    % get the user work folder in case it has been removed from the path
    workpath = [ system_dependent('getuserworkfolder') ps ];

    % get the full userpath so it won't be inlined in the generated file
    excludedPaths = regexp([userpath() pathsep getenv('MATLABPATH') pathsep], DelimitedByAndIncludingSep, 'tokens');
    excludedPaths = [excludedPaths{:}]';
    excludedExternalPaths = matlab.internal.path.ExcludedPathStore.getCurrentExcludeList();
    if ~isempty(excludedExternalPaths)
        excludedPaths = [excludedPaths; cellstr(append(excludedExternalPaths, pathsep))'];
    end

    % exclude case-insensitively from path list that will be saved
    pathmatch = strcmpi(all_path_lines, workpath);

    % If the user work folder is not found, then the user deleted
    % it from the path.
    if ~any(pathmatch)
        userpath('clear')  %clear the userpath setting
    end

    % find the index for any folder under and excluded path
    for idx = 1 : numel( excludedPaths )
        pathmatch = pathmatch | strcmpi( all_path_lines, excludedPaths{idx});
    end

    all_path_lines(pathmatch) = [];

catch exception %#ok<NASGU>
end

all_path_lines = matlabrootify(all_path_lines);

% Start constructing the contents of the new file.  We start with
% the firstpart.
cont = firstpart;

% Append the paths separated by newline characters
cont = [cont all_path_lines{:}];

% Conclude with the lastpart.
cont = [cont lastpart];

% We have the completed new text of the file, so we try to write it out.
% Return immediately if a directory.
if isdir(outputfile)
    if nargout == 1
        notsaved = 1;
    else
        warning(message('MATLAB:SavePath:PathNotSaved', outputfile));
    end
    return;
end

% try to open the toolbox/local location
[ fid,  reset_permissions_to_read_only ] = iFopen( outputfile );

% if file was not opened and this is a PC, write out a temp file and try to
% move it later
if fid == -1 && ispc
    % try to open the file again in a location we should have write
    % permission/access to
    [ fid, tempfilename ] = iFopenTempLocation(  );
else
    tempfilename = '';
end
move_file = ~isempty(tempfilename);

if fid == -1
    result = 1;
    if nargout == 1
        notsaved = result;
    else
        warning(message('MATLAB:SavePath:PathNotSaved', outputfile));
    end

    if reset_permissions_to_read_only
        if ispc
            fileattrib(outputfile, '-w');
        else
            fileattrib(outputfile, '-w', 'u');
        end

    end
    return;
end

% Write it out.
count = fprintf(fid,'%s', cont);
if count < length(template)
    result = 1;
end
fclose(fid);

% Move file if necessary
if move_file && result == 0
    iSystemMovefile( tempfilename, outputfile );

    % check that the MOVE succeeded
    if isfile(tempfilename)
       result = 1;
    end
end

clear pathdef; %make sure that pathdef gets cleared.
if nargout == 1
    notsaved = result;
elseif result == 1
    warning(message('MATLAB:SavePath:PathNotSaved', outputfile));
end

if reset_permissions_to_read_only
    if ispc
        fileattrib(outputfile, '-w');
    else
        fileattrib(outputfile, '-w', 'u');
    end
end
end
%---------------------------------------------
function dirnames = matlabrootify(dirnamesIn)
% Given a cell array of path entries, this performs two functions:
% (1) If the path entry under consideration is a subdirectory of
% matlabroot, it encodes that information directly into the string.
% Therefore, even if the location of the MATLAB installation is changed,
% pathdef.m will still point to the appropriate location.
% (2) Performs additional formatting.

% If we're on PC, we want to do our comparisons in a case-insensitive
% fashion.  Since it also doesn't matter what case the entries are made in,
% we might as well lowercase everything now - no harm done.
if ispc
    mlroot = lower(matlabroot);
    dirnames = lower(dirnamesIn);
else
    mlroot = matlabroot;
    dirnames = dirnamesIn;
end

% Find indices to entries in the MATLAB root. One match must be at the
% start of the entry. Calculate indices to remaining entries, and preserve
% case-sensitivity
mlr_dirs = cellfun(@(x) ismember(1,x),strfind(dirnames,mlroot));
dirnames(~mlr_dirs) = dirnamesIn(~mlr_dirs);

% We'll need to wrap all the entries in strings, so do some quote escaping
dirnames = strrep(dirnames, '''', '''''');

% Replace MATLAB roots with "matlabroot" only at the start of the entry,
% and wrap entries in quotes. Be sure to escape backslash in mlroot since it
% is a metacharacter to regexprep.
dirnames(mlr_dirs) = regexprep(dirnames(mlr_dirs), ...
                            regexptranslate('escape', mlroot), ...
                            '     matlabroot,''','once');
dirnames(~mlr_dirs) = strcat('     ''',dirnames(~mlr_dirs));
dirnames = strcat(dirnames, ''', ...', {char(10)});
end
function [ fid, reset_permissions_to_read_only ] = iFopen( outputfile )
fid = fopen(outputfile, 'w');
reset_permissions_to_read_only = false;
if fid == -1
    % We failed to open the file for writing.  That might be
    % because we don't have write permission for that file.  Let's
    % try to make it read-write.
    if ispc
        success = fileattrib(outputfile, '+w');
    else
        success = fileattrib(outputfile, '+w', 'u');
    end
    if success
        % Last chance.  Can we write to it?  If we fail here, we have
        % no choice but to fail.
        reset_permissions_to_read_only = true;
        fid = fopen(outputfile, 'w');
    end
end
end
function [ fid, name ] = iFopenTempLocation
name = tempname;
fid = fopen( name, 'w' );
end
function result = iSystemMovefile( src, dest )
command = 'move /y';
% quote the file names in case they contain spaces
% use runAsAdmin flag so a UAC event is triggered
[ ~, result ] = system( [ command ' "' src '" "' dest '"' ], '-runAsAdmin' );
end
function tf = iCanModifyPath()
% Are we permitted to do path operations in this environment or not. This
% should be moved to internal Capabilities.
tf = ~parallel.internal.pool.isPoolThreadWorker();
end
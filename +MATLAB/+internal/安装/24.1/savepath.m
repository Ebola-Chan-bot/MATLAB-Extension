%埃博拉酱修复版
function status=savepath(~)
%2024a开始，TEMP、工具箱和打开的项目路径直接用`matlab.internal.path.ExcludedPathStore.getCurrentExcludeList`取得
persistent SessionExclude SharedPath UserPathFile SupportPackagesDirectory
if isempty(SessionExclude)
	SessionExclude=string(split(perl('getphlpaths.pl',matlabroot),pathsep));
	SharedPath=fullfile(getenv('ProgramData'),'MathWorks\埃博拉酱\共享路径.txt');
	UserPathFile=fullfile(getenv('LOCALAPPDATA'),'埃博拉酱');
	if ~isfolder(UserPathFile)
		mkdir(UserPathFile);
	end
	UserPathFile=fullfile(UserPathFile,'用户路径.txt');
	SupportPackagesDirectory=fullfile(getenv("ProgramData"),"MATLAB\SupportPackages");
end
PrivatePaths=split(path,pathsep);
Fid=fopen(UserPathFile,'wt');
%setdiff采用稳定顺序，因为有些工具箱（如Psychtoolbox）对路径顺序有严格要求
UserPaths=join(setdiff(PrivatePaths(~startsWith(PrivatePaths,SupportPackagesDirectory)),[SessionExclude;unique(matlab.internal.path.ExcludedPathStore.getCurrentExcludeList)';userpath;string(split(fileread(SharedPath),pathsep))],'stable'),pathsep);
if ~isequaln(UserPaths,missing)
	fwrite(Fid,UserPaths,'char');
end
fclose(Fid);
status=0;
end
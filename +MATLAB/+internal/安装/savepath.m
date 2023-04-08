function status=savepath(~)
persistent PS SessionExclude AddonDirectory SharedPath UserPathFile SupportPackagesDirectory
if isempty(PS)
	PS=pathsep;
	SessionExclude=string(split([perl('getphlpaths.pl',matlabroot) PS matlab.internal.language.ExcludedPathStore.getInstance.getExcludedPathEntry],PS));
	AddonDirectory=matlab.internal.addons.util.retrieveAddOnsInstallationFolder;
	SharedPath=fullfile(getenv('ProgramData'),'MathWorks\埃博拉酱\共享路径.txt');
	UserPathFile=fullfile(getenv('LOCALAPPDATA'),'埃博拉酱');
	if ~isfolder(UserPathFile)
		mkdir(UserPathFile);
	end
	UserPathFile=fullfile(UserPathFile,'用户路径.txt');
	SupportPackagesDirectory=fullfile(getenv("ProgramData"),"MATLAB\SupportPackages");
end
Project=matlab.project.rootProject;
if isempty(Project)
	ProjectPaths=strings(1,0);
else
	ProjectPaths=string(unique(ProjectGraphTraverse(Project,strings(1,0))));
end
PrivatePaths=split(path,PS);
Fid=fopen(UserPathFile,'wt');
%setdiff采用稳定顺序，因为有些工具箱（如Psychtoolbox）对路径顺序有严格要求
UserPaths=join(setdiff(PrivatePaths(~startsWith(PrivatePaths,[AddonDirectory,SupportPackagesDirectory])),[SessionExclude;ProjectPaths';userpath;string(split(fileread(SharedPath),PS))],'stable'),PS);
if ~isequaln(UserPaths,missing)
	fwrite(Fid,UserPaths,'char');
end
fclose(Fid);
status=0;
end
function [ProjectPaths,KnownProjects] = ProjectGraphTraverse(Project,KnownProjects)
KnownProjects=[KnownProjects Project.RootFolder];
NumReferences=numel(Project.ProjectReferences);
ProjectPaths=cell(1,NumReferences);
for P=1:NumReferences
	PP=Project.ProjectReferences(P).Project;
	if ~ismember(PP.RootFolder,KnownProjects)
		[ProjectPaths{P},KnownProjects]=ProjectGraphTraverse(PP,KnownProjects);
	end
end
ProjectPaths=[ProjectPaths{:} arrayfun(@(PP)PP.File,Project.ProjectPath)];
end
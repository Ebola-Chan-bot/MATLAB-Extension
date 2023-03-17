function status=savepath(~)
persistent PS SessionExclude AddonDirectory SharedPath
if isempty(PS)
	PS=pathsep;
	SessionExclude=string(split([perl('getphlpaths.pl',matlabroot) PS matlab.internal.language.ExcludedPathStore.getInstance.getExcludedPathEntry],PS));
	AddonDirectory=matlab.internal.addons.util.retrieveAddOnsInstallationFolder;
	SharedPath=fullfile(getenv('ProgramData'),'MathWorks\PathManager\共享路径.txt');
end
Project=matlab.project.rootProject;
if isempty(Project)
	ProjectPaths=strings(1,0);
else
	ProjectPaths=string(unique(ProjectGraphTraverse(Project,strings(1,0))));
end
PrivatePaths=split(path,PS);
System.Environment.SetEnvironmentVariable('MATLABPATH',join(setdiff(PrivatePaths(~startsWith(PrivatePaths,AddonDirectory)),[SessionExclude;ProjectPaths';userpath;string(split(fileread(SharedPath),';'))]),PS),System.EnvironmentVariableTarget.User);
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
function RcAddPath
path(path,fileread(fullfile(getenv('ProgramData'),'MathWorks\埃博拉酱\共享路径.txt')));
UserPathFile=fullfile(getenv('LOCALAPPDATA'),'埃博拉酱\用户路径.txt');
if isfile(UserPathFile)
	path(path,fileread(UserPathFile));
end
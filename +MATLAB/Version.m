function V = Version
V.Me='v10.3.0';
V.MATLAB='R2021a';
persistent NewVersion
if isempty(NewVersion)
	NewVersion=MATLAB.SupportPkg.CheckUpdateFromGithub('https://github.com/Silver-Fang/MATLAB-Extension/releases','埃博拉酱的MATLAB扩展',V.Me);
end
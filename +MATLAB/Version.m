function V = Version(AlwaysCheck)
arguments
	AlwaysCheck=false;
end
persistent pVersion
if isempty(pVersion)||AlwaysCheck
	V='20.2.4';
	if~isempty(metafunction('TextAnalytics.CheckUpdateFromGitHub'))
		TextAnalytics.CheckUpdateFromGitHub('https://github.com/Ebola-Chan-bot/MATLAB-Extension/releases','埃博拉酱的MATLAB扩展',['v',V]);
	end
	pVersion.Me=matlab.mpm.Version(V);
	pVersion.MATLAB='R2026a';
end
V=pVersion;
function V = Version
V.Me='v18.3.2';
V.MATLAB='R2023b';
persistent NewVersion
try
	if isempty(NewVersion)
		NewVersion=TextAnalytics.CheckUpdateFromGitHub('https://github.com/Silver-Fang/MATLAB-Extension/releases','埃博拉酱的MATLAB扩展',V.Me);
	end
catch ME
	if ME.identifier~="MATLAB:undefinedVarOrClass"
		ME.rethrow;
	end
end
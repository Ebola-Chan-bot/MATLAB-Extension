function V = Version
V.Me='v18.1.0';
V.MATLAB='R2024a';
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
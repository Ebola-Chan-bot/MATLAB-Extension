function V = Version
V.Me='v19.5.2';
V.MATLAB='R2024b';
persistent NewVersion
try
	if isempty(NewVersion)
		NewVersion=TextAnalytics.CheckUpdateFromGitHub('https://github.com/Ebola-Chan-bot/MATLAB-Extension/releases','埃博拉酱的MATLAB扩展',V.Me);
	end
catch ME
	if ME.identifier~="MATLAB:undefinedVarOrClass"
		ME.rethrow;
	end
end
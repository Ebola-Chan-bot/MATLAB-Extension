classdef(Abstract)Database
	properties(Constant)
		NullString=string(missing)
		ExtractPattern=asManyOfPattern(wildcardPattern(1,Inf,Except="."|"`"),1);
		DatabasePath=fullfile(fileparts(mfilename('fullpath')),'+Database');
	end
end
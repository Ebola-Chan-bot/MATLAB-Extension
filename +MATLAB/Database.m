classdef(Abstract)Database
	properties(Constant)
		NullString=string(missing)
		ExtractPattern=asManyOfPattern(wildcardPattern(1,Inf,Except="."|"`"),1);
	end
end
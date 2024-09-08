classdef(Abstract)DataTypes
	properties(Constant)
		TempFile=fullfile(tempdir,matlab.lang.internal.uuid+".mat")
	end
end
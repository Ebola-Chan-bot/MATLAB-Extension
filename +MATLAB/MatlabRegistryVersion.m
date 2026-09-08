%[text] 返回当前MATLAB在Windows注册表中显示的版本。例如，R2026b返回26.2。
function V = MatlabRegistryVersion
persistent MRV
if isempty(MRV)
	MRV=split(version,'.');
	MRV=join(MRV(1:2),'.');
	MRV=MRV{1};
end
V=MRV;
end

%[appendix]{"version":"1.0"}
%---

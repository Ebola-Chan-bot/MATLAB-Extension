function [StructPaths,Versions] = ExploreVersionStruct(Struct)
import MATLAB.DataTypes.ArrayBuilder
FieldNames=fieldnames(Struct);
if isfield(Struct,'Me')
	StructPaths="";
	Versions=Struct.Me;
else
	StructPaths=ArrayBuilder;
	Versions=ArrayBuilder;
	for a=1:numel(FieldNames)
		FN=FieldNames{a};
		[P,V]=ExploreVersionStruct(Struct.(FN));
		StructPaths.Append("."+string(FN)+P);
		Versions.Append(V);
	end
	StructPaths=StructPaths.Harvest;
	Versions=Versions.Harvest;
end
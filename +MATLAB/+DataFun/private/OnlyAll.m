function [Only,All] = OnlyAll(Groups1,CRT2,Unique2)
[Only,All]=deal(true);
for Index=1:max(Groups1)
	Target=unique(CRT2(Groups1==Index,:));
	Only=Only&&height(Target)==1;
	All=All&&isequal(Target,Unique2);
end
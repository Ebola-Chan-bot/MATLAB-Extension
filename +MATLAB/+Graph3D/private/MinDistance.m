function [M,I]=MinDistance(Colors,NumberOfVariables)
Colors=double(Colors);
NumberOfColors=width(Colors);
Color1Matrix=repmat(Colors,1,1,NumberOfColors);
Color2Matrix=repmat(permute(Colors,[1 3 2]),1,NumberOfColors,1);
Distance=squeeze(sum((Color1Matrix-Color2Matrix).^2,1));
Distance(logical(eye(NumberOfColors)))=Inf;
Distance(NumberOfVariables+1:end,NumberOfVariables+1:end)=Inf;
[M,I]=min(Distance,[],"all","linear");
M=gather(M);
I=gather(I);
end
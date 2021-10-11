function [Colors,Md] = ColorDistribute(NumberOfColorsToSuggest,ColorsToAvoid)
arguments
    NumberOfColorsToSuggest(1,1)uint8
end
arguments(Repeating)
    ColorsToAvoid(3,:)uint8
end
ColorsToAvoid=gpuArray([ColorsToAvoid{:}]);
SizeColor=width(ColorsToAvoid)+NumberOfColorsToSuggest;
DimensionSplit=ceil(double(SizeColor)^(1/3));
if ~isempty(ColorsToAvoid)
    Cta=floor(double(ColorsToAvoid)/256*DimensionSplit);
    AvoidIndices=(Cta(1,:)*DimensionSplit+Cta(2,:))*DimensionSplit+Cta(3,:);
else
    AvoidIndices=[];
end
PossibleIndices=setdiff(0:DimensionSplit^3-1,AvoidIndices);
StartPoints=PossibleIndices(randsample(length(PossibleIndices),NumberOfColorsToSuggest));
StartBs=mod(StartPoints,DimensionSplit);
StartPoints=(StartPoints-StartBs)/DimensionSplit;
StartGs=mod(StartPoints,DimensionSplit);
StartPoints=(StartPoints-StartGs)/DimensionSplit;
[Colors,Md]=TryCircle([[StartPoints;StartGs;StartBs]*255/(DimensionSplit-1) ColorsToAvoid],[SizeColor SizeColor],NumberOfColorsToSuggest);
Colors=gather(uint8(Colors(:,1:NumberOfColorsToSuggest)));
Md=sqrt(double(Md));
end
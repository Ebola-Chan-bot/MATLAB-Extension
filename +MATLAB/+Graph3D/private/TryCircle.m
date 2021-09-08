function [Colors,Md]=TryCircle(Colors,SizeColors,NumberOfColorsToSuggest)
Colors=int16(Colors);
[Md,MinInd]=MinDistance(Colors,NumberOfColorsToSuggest);
FirstTime=true;
while true
    [Index1,Index2]=ind2sub(SizeColors,MinInd);
    if Index1<=NumberOfColorsToSuggest
        [Colors,M,MinIndNew]=TryColor(Colors,Index1,Md,NumberOfColorsToSuggest,MinInd,FirstTime);
        FirstTime=false;
        if M>Md||M==Md&&MinIndNew~=MinInd
            Md=M;
            MinInd=MinIndNew;
            continue;
        end
    end
    if Index2<=NumberOfColorsToSuggest
        [Colors,M,MinIndNew]=TryColor(Colors,Index2,Md,NumberOfColorsToSuggest,MinInd,FirstTime);
        FirstTime=false;
        if M>Md||M==Md&&MinIndNew~=MinInd
            Md=M;
            MinInd=MinIndNew;
            continue;
        end
    end
    break;
end
end
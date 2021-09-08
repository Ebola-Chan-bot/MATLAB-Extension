function [Colors,Md,MinInd]=TryColor(Colors,Index,Md,NumberOfColorsToSuggest,MinInd,FirstTime)
persistent RGBs Untried
if isempty(RGBs)
    RGBs=gpuArray(int32(cat(4,repmat((0:255)',1,256,256),repmat(0:255,256,1,256),repmat(shiftdim(0:255,-1),256,256))));
end
if FirstTime
    Untried=true(256,256,256,"gpuArray");
end
Colors=int32(Colors);
PossibleDistances=sum((RGBs-permute(Colors(:,[1:Index-1 Index+1:end]),[3 4 5 1 2])).^2,4);
Candidates=find(all(PossibleDistances>Md,5)&Untried);
if isempty(Candidates)
    Candidates=find(all(PossibleDistances==Md,5)&Untried);
end
if ~isempty(Candidates)
    if numel(Candidates)>1
        NewColor=gather(randsample(Candidates,1));
    else
        NewColor=gather(Candidates);
    end
    [NewR,NewG,NewB]=ind2sub([256 256 256],NewColor);
    NewColor=squeeze(RGBs(NewR,NewG,NewB,:));
    Colors(:,Index)=NewColor;
    [M,MinInd]=MinDistance(Colors,NumberOfColorsToSuggest);
    if M>Md
        Untried=true(256,256,256);
        Untried(NewColor(1)+1,NewColor(2)+1,NewColor(3)+1)=false;
        Md=M;
    else
        Untried(NewColor(1)+1,NewColor(2)+1,NewColor(3)+1)=false;
    end
end
end
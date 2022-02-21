function Subs=Slice1D(NumDims,SliceDim,Slice)
persistent Colon
if isempty(Colon)
	Colon={':'};
end
Subs=Colon(ones(1,NumDims));
Subs{SliceDim}=Slice;
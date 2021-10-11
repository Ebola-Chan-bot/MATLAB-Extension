function varargout = DFSuperCat(varargout,CM,SplitDimensions)
import MATLAB.DataTypes.CatMode
switch CM
	case CatMode.Scalar
		varargout=cellfun(@cell2mat,varargout,"UniformOutput",false);
	case CatMode.Linear
		if isempty(SplitDimensions)
			%这里不能使用varargout=horzcat(varargout{:})，因为varargout元胞里有可能是空的
			varargout=cellfun(@(Out)vertcat(Out{:}),varargout,"UniformOutput",false);
		else
			varargout=cellfun(@(Out)cat(SplitDimensions,Out{:}),varargout,"UniformOutput",false);
		end
	case CatMode.CanCat
		varargout=cellfun(@MATLAB.DataTypes.Cell2Mat,varargout,"UniformOutput",false);
end
end
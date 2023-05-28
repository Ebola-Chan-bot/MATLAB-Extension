classdef NDTable<matlab.mixin.indexing.RedefinesParen&matlab.mixin.indexing.RedefinesBrace&matlab.mixin.indexing.RedefinesDot
	properties
		Data
		Dimensions(:,1)cell
		DimensionNames(1,:)string
	end
	methods(Access=protected)
		function [obj,indexOp]=IndexToAssign(obj,indexOp)
			indexOp=indexOp.Indices;
			for D=1:numel(indexOp)
				Index=indexOp{D};
				if ~(isreal(Index)||isequal(Index,":"))
					if numel(obj.Dimensions)<D
						obj.Dimensions{D}=unique(Index,'stable');
					else
						obj.Dimensions{D}=union(obj.Dimensions{D},Index,"stable");
					end
					%考虑到Index中可能有重复值，必须用ismember确认
					[~,Index]=ismember(Index,obj.Dimensions{D});
					indexOp{D}=Index;
				end
			end
		end
		function varargout=parenReference(obj,indexOp)
			Indices=indexOp(1).Indices;
			for I=1:numel(Indices)
				Index=Indices{I};
				if ~(isreal(Index)||isequal(Index,":"))
					[~,Index]=ismember(Index,obj.Dimensions{I});
					Indices{I}=Index;
				end
				if numel(obj.Dimensions)>=I
					obj.Dimensions{I}=obj.Dimensions{I}(Index);
				end
			end
			obj.Data=obj.Data(Indices{:});
			if isscalar(indexOp)
				varargout={obj};
			else
				[varargout{1:nargout}]=obj.(indexOp(2:end));
			end
		end
		function varargout=braceReference(obj,indexOp)
			Indices=indexOp(1).Indices;
			for I=1:numel(Indices)
				Index=Indices{I};
				if ~(isreal(Index)||isequal(Index,":"))
					[~,Index]=ismember(Index,obj.Dimensions{I});
					Indices{I}=Index;
				end
			end
			obj=obj.Data(Indices{:});
			if isscalar(indexOp)
				varargout={obj};
			else
				[varargout{1:nargout}]=obj.(indexOp(2:end));
			end
		end
		function varargout=dotReference(obj,indexOp)
			Names=indexOp(1).Name;
			Indices=repmat({':'},1,ndims(obj.Data));
			for I=1:numel(obj.Dimensions)
				[Exist,Index]=ismember(Names,obj.Dimensions{I});
				if any(Exist)
					Indices{I}=Index(Exist);
				end
			end
			obj=obj.Data(Indices{:});
			if isscalar(indexOp)
				varargout={obj};
			else
				[varargout{1:nargout}]=obj.(indexOp(2:end));
			end
		end
		%括号索引返回的还是NDTable，因此不允许级联赋值，没有意义
		function obj = parenAssign(obj,indexOp,varargin)
			[obj,Indices]=obj.IndexToAssign(indexOp);
			obj.Data(Indices{:})=varargin{1}.Data;
		end
		function obj = braceAssign(obj,indexOp,varargin)
			[obj,Indices]=obj.IndexToAssign(indexOp(1));
			if isscalar(indexOp)
				obj.Data(Indices{:})=varargin{1};
			else
				obj.Data(Indices{:}).(indexOp(2:end))=varargin{:};
			end
		end
		function obj=dotAssign(obj,indexOp,varargin)
			Names=indexOp(1).Name;
			Indices=repmat({':'},1,ndims(obj.Data));
			AnyExist=false(numel(Name),1);
			for I=1:numel(obj.Dimensions)
				[Exist,Index]=ismember(Names,obj.Dimensions{I});
				if any(Exist)
					Indices{I}=Index(Exist);
				end
				AnyExist=AnyExist|Exist;
			end
			Names=Names(~AnyExist);
			NumNewFields=numel(Names);
			if NumNewFields
				NewIndex=numel(obj.Dimensions{1});
				obj.Dimensions{1}=[reshape(obj.Dimensions{1},1,[]),reshape(Names,1,[])];
				NewIndex=NewIndex+1:NewIndex+NumNewFields;
				if isequal(Indices{1},':')
					Indices{1}=NewIndex;
				else
					Indices{1}=[reshape(Indices{1},1,[]),NewIndex];
				end
			end
			if isscalar(indexOp)
				obj.Data(Indices{:})=varargin{1};
			else
				obj.Data(Indices{:}).(indexOp(2:end))=varargin{:};
			end
		end
		function n=CommonListLength(obj,indexOp,Context)
			if isscalar(indexOp)
				n=1;
			else
				n=listLength(obj.(indexOp(1)),indexOp(2:end),Context);
			end
		end
		function n = parenListLength(obj,indexOp,Context)
			n=obj.CommonListLength(indexOp,Context);
		end
		function n = braceListLength(obj,indexOp,Context)
			n=obj.CommonListLength(indexOp,Context);
		end
		function n=dotListLength(obj,indexOp,Context)
			n=obj.CommonListLength(indexOp,Context);
		end
		function obj = parenDelete(obj,indexOp)
			if isscalar(indexOp)
				Indices=indexOp.Indices;
				for I=1:numel(Indices)
					Index=Indices{I};
					if ~isequal(Index,":")
						if ~isreal(Index)
							[~,Index]=ismember(Index,obj.Dimensions{I});
							Indices{I}=Index;
						end
						if numel(obj.Dimensions)>=I
							obj.Dimensions{I}(Index(Index<=numel(obj.Dimensions{I})))=[];
						end
						break;
					end
				end
				obj.Data(Indices{:})=[];
			else
				Indices=indexOp(1).Indices;
				for I=1:numel(Indices)
					Index=Indices{I};
					if ~(isreal(Index)||isequal(Index,":"))
						[~,Index]=ismember(Index,obj.Dimensions{I});
						Indices{I}=Index;
					end
				end
				obj.Data(Indices{:}).(indexOp(2:end))=[];
			end
		end
	end
	methods
		function obj=NDTable(Data,Dimensions,DimensionNames)
			arguments
				Data
				Dimensions=cell(0,1)
				DimensionNames=strings(0,1)
			end
			obj.Data=Data;
			obj.Dimensions=Dimensions;
			obj.DimensionNames=DimensionNames;
		end
		function varargout = size(obj,varargin)
			[varargout{1:nargout}]=size(obj.Data,varargin{:});
		end
		function out = cat(dim,varargin)
			Arg=varargin{1};
			CatDimensions=Arg.Dimensions;
			CatDimensionNames=Arg.DimensionNames;
			NumArgs=numel(varargin);
			[CatData,CatDim]=deal(cell(NumArgs,1));
			CatData{1}=Arg.Data;
			if numel(CatDimensions)>=dim
				CatDim{1}=reshape(CatDimensions{dim},1,[]);
			end
			for V=2:NumArgs
				Arg=varargin{V};
				CatDimensionNames(end+1:numel(Arg.DimensionNames))=Arg.DimensionNames(numel(CatDimensionNames)+1:end);
				CatDimensions(end+1:numel(Arg.Dimensions))=Arg.Dimensions(numel(CatDimensions)+1:end);
				if numel(Arg.Dimensions)>=dim
					CatDim{V}=reshape(Arg.Dimensions{dim},1,[]);
				end
				CatData{V}=Arg.Data;
			end
			CatDimensions{dim}=[CatDim{:}];
			out=MATLAB.DataTypes.NDTable(cat(dim,CatData{:}),CatDimensions,CatDimensionNames);
		end
	end
end
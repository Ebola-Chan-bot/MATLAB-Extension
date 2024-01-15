classdef NDTable<matlab.mixin.indexing.RedefinesParen&matlab.mixin.indexing.RedefinesBrace&matlab.mixin.indexing.RedefinesDot
	%N维表格，相当于支持字符串索引的N维数组
	%内置table本质上是个矩阵，提供了将行和列的名称作为索引来访问矩阵的方法，但它只有2维。NDTable提供通过行列名访问高维数组的方法，即多维表格。此外，它还支持常规的数组
	% 操作，包括 size cat permute reshape
	%构造方法的文档中描述了构造NDTable的方法。我们假设用文档中的示例代码，已构造了一个NDTable对象名为obj。
	%# 圆括号索引
	% ## 语法
	%  ```
	%  Slice=obj(Index1,Index2,…);
	%  %索引取值
	%
	%  obj(Index1,Index2,…)=Slice;
	%  %索引赋值
	%
	%  obj(:,:,…,TruncateIndex,:,:,…)=[];
	%  %索引截断
	%  ```
	% ## 示例
	%  ```
	%  Slice=obj(1:3,["E","G"],5,7:-1:1,1,:)
	%  %{
	%   Slice =
	%
	%     3×2×1×7 NDTable 数组 - 属性:
	%
	%                 Data: [3×2×1×7 double]
	%           Dimensions: [4×2 table]
	%  %}
	%  obj(2:4,["F","H"],6,7:-1:1,:,1)=Slice
	%  %{
	%   obj =
	%
	%     4×5×6×7 NDTable 数组 - 属性:
	%
	%                 Data: [4×5×6×7 double]
	%           Dimensions: [4×2 table]
	%  %}
	%  ObjToTruncate=obj;
	%  ObjToTruncate(:,"F",:,:)=[]
	%  %{
	%   ObjToTruncate =
	%
	%     4×4×6×7 NDTable 数组 - 属性:
	%
	%                 Data: [4×4×6×7 double]
	%           Dimensions: [4×2 table]
	%  %}
	%  ```
	% ## 输入参数
	%  Index1,Index2,…，各维索引，可以为数值索引，或在Dimensions属性中指定的对应维度使用字符串索引，也可以使用冒号。超出数组实际维度的部分可以使用1或冒号索引。但如果
	%   索引维数少于NDTable的实际维数，高维部分将被展开，其IndexNames将丢失。
	%  Slice NDTable，在赋值时使用的数据源。此NDTable将仅作为一般数组使用，它的Dimensions将被忽略，不会对结果数组的Dimensions进行修改。
	%  TruncateIndex，要截断的维度索引，可以为数值索引，或在Dimensions属性中指定的对应维度使用字符串索引。只能在一个维度使用具体索引值，其它维度必须使用冒号。
	% ## 返回值
	%  Slice NDTable，索引取值得到的切片结果。除了Data数组被切片外，包含字符串的Dimensions各维也将按照索引被切片。如果对某个维度使用了大于字符串个数的数值索引，Slice
	%   的Dimensions中的那个位置将用一个missing作为占位符。
	% ## 局限性
	%  如果使用名为i的工作区变量进行圆括号索引，将返回表中的原始值而不是NDTable。这是为了工作区中的变量编辑器优化。
	%# 花括号索引
	% ## 语法
	%  ```
	%  Slice=obj{Index1,Index2,…};
	%  %索引取值
	%
	%  obj{Index1,Index2,…}=Slice;
	%  %索引赋值
	%  ```
	% ## 示例
	%  ```
	%  Slice=obj{1:3,["E","G"],5,7:-1:1,1,:};
	%  class(Slice)
	%  %{
	%   ans =
	%
	%       'double'
	%  %}
	%  obj{2:4,["F","H"],6,7:-1:1,:,1}=Slice
	%  %{
	%   obj =
	%
	%     4×5×6×7 NDTable 数组 - 属性:
	%
	%                 Data: [4×5×6×7 double]
	%           Dimensions: [4×2 table]
	%  %}
	%  ```
	% ## 输入参数
	%  Index1,Index2,…，各维索引，和圆括号索引相同
	%  Slice，赋值时使用的数据源。不同于圆括号索引，此处应当使用原始数据类型数组，而不是NDTable。这些数据将被直接写入Data属性。
	% ## 返回值
	%  Slice，索引取值得到的切片结果。不同于圆括号索引，此处返回的时原始数据类型数组，而不是NDTable。
	%# 点索引
	% ## 语法
	%  ```
	%  Slice=obj.Name;
	%  obj.Name=Slice;
	%  %单个名称可直接作为字段名索引取值/赋值
	%
	%  Slice=obj.([Name1,Name2,…]);
	%  obj.([Name1,Name2,…])=Slice;
	%  %使用多个名称必须组合成字符串数组并用点括号索引语法
	%  ```
	% ## 示例
	%  ```
	%  Slice=obj.F;
	%  size(Slice)
	%  %{
	%   ans =
	%
	%        4     1     6     7
	%  %}
	%  obj.G=Slice
	%  %{
	%   obj =
	%
	%     4×5×6×7 NDTable 数组 - 属性:
	%
	%                 Data: [4×5×6×7 double]
	%           Dimensions: [4×2 table]
	%  %}
	%  Slice=obj.(["A","P"]);
	%  size(Slice)
	%  %{
	%   ans =
	%
	%        1     5     6
	%  %}
	%  obj.(["B","O"])=Slice;
	%  ```
	% ## 输入参数
	%  Name，单个字符串索引，但无需带双引号，可以直接像结构体一样引用字段。将在Dimensions中查找此名称，对找到该名称的维度进行切片，其它维度全部保留。
	%  Name1,Name2,…，多个字符串索引，必须带双引号并组合成字符串数组，并用点括号语法索引。将在Dimensions中查找这些名称，对找到任何名称的维度进行切片，其它维度全部保
	%   留。
	%  Slice，赋值时使用的数据源，尺寸必须和对应的索引取值操作得到的数组相同。
	% ## 返回值
	%  Slice，索引取值得到的切片结果，返回原始数据类型数组，而不是NDTable。
	%# 运算
	% NDTable支持一些简单的运算。
	% ## 二元运算
	%  目前支持的运算：plus(+) minus(-) times(.*) rdivide(./) gt(>) lt(<) ge(>=) le(<=) eq(==) ne(~=) and(&) or(|) xor
	%  维度规则：
	%  - 如果两个操作数只有一个是NDTable，则返回的NDTable具有与那个NDTable相同的Dimensions；但如果返回Data发生了单一维度自动隐式扩展，且那个维度的IndexNames只有1个，
	%   则此维度的IndexNames也将被自动扩展。
	%  - 如果两个操作数都是NDTable，则它们的Dimensions必须完全相同，返回值也将拥有相同的Dimensions。
	% ## 降维运算
	%  目前支持的运算：sum mean median min max std var any all
	%  维度规则：
	%  - 发生降维的维度，其IndexNames将被清空，但如果那个维度本身长度就是1则不受影响
	%  - 对于min和max，其第2个返回值也将是具有相同Dimensions的NDTable。
	%See also MATLAB.DataTypes.NDTable/NDTable
	properties

		%实际存储数据的高维数组，可以为任意类型
		Data

		%各维度的名称和维度内索引名称
		%每行一个维度，必需包含以下列：
		%- DimensionName(:,1)string，维度名称。此参数对索引操作无实际用途，主要供人类阅读。没有名称的维度一般设为missing。
		%- IndexNames(:,1)cell，维度内的各个位置索引名称，元胞内是(1,:)string，可以用名称索引到维度内的此位置。可以不指定或仅指定一部分，未指定的部分将只能用数值索引。
		% 可用missing填充表示不指定此位置的名称。
		Dimensions table
	end
	methods(Access=protected)
		function [obj,indexOp]=IndexToAssign(obj,indexOp)
			indexOp=indexOp.Indices;
			for D=1:numel(indexOp)
				Index=indexOp{D};
				if ~(isreal(Index)||isequal(Index,":"))
					obj.Dimensions.IndexNames{D}=string(obj.Dimensions.IndexNames{D});
					if height(obj.Dimensions)<D
						obj.Dimensions.IndexNames{D}=unique(Index,'stable');
					else
						obj.Dimensions.IndexNames{D}=union(obj.Dimensions.IndexNames{D},Index,'stable');
					end
					%考虑到Index中可能有重复值，必须用ismember确认
					[~,Index]=ismember(Index,obj.Dimensions.IndexNames{D});
					indexOp{D}=Index;
				end
			end
		end
		function n=CommonListLength(obj,indexOp,Context)
			if isscalar(indexOp)
				n=1;
			else
				n=listLength(obj.(indexOp(1)),indexOp(2:end),Context);
			end
		end
		function varargout=parenReference(obj,indexOp)
			if inputname(1)=="i"&&isscalar(indexOp)
				%变量编辑器专用
				varargout{1}=obj.Data.(indexOp);
				return;
			end
			Indices=indexOp(1).Indices;
			NumIndices=numel(Indices);
			if NumIndices<find(size(obj.Data)==1,1)-1
				%索引不足的情况不能报错也不能警告，因为表格展示时会用到这种索引
				obj.Dimensions(NumIndices+1:end,:)=[];
			end
			for I=1:NumIndices
				Index=Indices{I};
				if ~isequal(Index,':')
					if ~isreal(Index)
						IndexNames=Index;
						obj.Dimensions.IndexNames{I}=string(obj.Dimensions.IndexNames{I});
						[Exist,Index]=ismember(Index,obj.Dimensions.IndexNames{I});
						if all(Index)
							Indices{I}=Index;
						else
							MATLAB.Exceptions.Index_name_not_found.Throw(join(IndexNames(~Exist),' '));
						end
					end
					if height(obj.Dimensions)>=I&&~islogical(Index)
						ValidIndexLogical=Index<=numel(obj.Dimensions.IndexNames{I});
						if any(ValidIndexLogical)
							NewStrings=repmat(string(missing),1,find(ValidIndexLogical,1,'last'));
							NewStrings(ValidIndexLogical)=obj.Dimensions.IndexNames{I}(Index(ValidIndexLogical));
							obj.Dimensions.IndexNames{I}=NewStrings;
						else
							obj.Dimensions.IndexNames{I}=strings(1,0);
						end
					end
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
					obj.Dimensions.IndexNames{I}=string(obj.Dimensions.IndexNames{I});
					IndexNames=Index;
					[~,Index]=ismember(IndexNames,obj.Dimensions.IndexNames{I});
					IndexNames=IndexNames(~Index);
					if ~isempty(IndexNames)
						MATLAB.Exceptions.Index_name_not_found.Throw(join(IndexNames,' '));
					end
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
			NoSuchName=true;
			for I=1:height(obj.Dimensions)
				if ~isempty(obj.Dimensions.IndexNames{I})
					obj.Dimensions.IndexNames{I}=string(obj.Dimensions.IndexNames{I});
					[Exist,Index]=ismember(Names,obj.Dimensions.IndexNames{I});
					if any(Exist)
						NoSuchName=false;
						Indices{I}=Index(Exist);
					end
				end
			end
			if NoSuchName
				MATLAB.Exceptions.NDTable_does_not_contain_these_IndexNames.Throw(join(Names,' '));
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
			NewObj=varargin{1};
			obj.Data(Indices{:})=NewObj.Data;
			obj.Dimensions.DimensionName(1:height(NewObj.Dimensions))=NewObj.Dimensions.DimensionName;
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
			AnyExist=false(numel(Names),1);
			for I=1:height(obj.Dimensions)
				if ~isempty(obj.Dimensions.IndexNames{I})
					obj.Dimensions.IndexNames{I}=string(obj.Dimensions.IndexNames{I});
					[Exist,Index]=ismember(Names,obj.Dimensions.IndexNames{I});
					if any(Exist)
						Indices{I}=Index(Exist);
					end
					AnyExist=AnyExist|Exist;
				end
			end
			Names=Names(~AnyExist);
			NumNewFields=numel(Names);
			if NumNewFields
				NewIndex=numel(obj.Dimensions.IndexNames{1});
				obj.Dimensions.IndexNames{1}=[reshape(string(obj.Dimensions.IndexNames{1}),1,[]),reshape(Names,1,[])];
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
				Temp=obj.Data(Indices{:});
				Temp.(indexOp(2:end))=varargin{:};
				obj.Data(Indices{:})=Temp;
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
				NumIndices=numel(Indices);
				if NumIndices<find(size(obj.Data)==1,1)-1
					%索引不足的情况不能报错也不能警告，因为表格展示时会用到这种索引
					obj.Dimensions(NumIndices+1:end,:)=[];
				end
				for I=1:NumIndices
					Index=Indices{I};
					if ~isequal(Index,":")
						if ~isreal(Index)
							obj.Dimensions.IndexNames{I}=string(obj.Dimensions.IndexNames{I});
							[~,Index]=ismember(Index,obj.Dimensions.IndexNames{I});
							Indices{I}=Index;
						end
						if height(obj.Dimensions)>=I
							obj.Dimensions.IndexNames{I}(Index(Index<=numel(obj.Dimensions.IndexNames{I})))=[];
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
						[~,Index]=ismember(Index,obj.Dimensions.IndexNames{I});
						Indices{I}=Index;
					end
				end
				obj.Data(Indices{:}).(indexOp(2:end))=[];
			end
		end
	end
	methods(Static)
		function obj1=Operate(obj1,obj2,Operator)
			%执行自定义二元运算操作
			%# 语法
			% ```
			% import MATLAB.DataTypes.NDTable.Operate
			%
			% obj=Operate(obj1,Data2,Operator);
			% %将NDTable与数值数组执行运算。
			%
			% obj=Operate(Data1,obj2,Operator);
			% %将数值数组与NDTable执行运算
			%
			% obj=Operate(obj1,obj2,Operator);
			% %将两个NDTable执行运算。使用此语法时，两个NDTable必须具有完全相同的Dimensions
			% ```
			%# 输入参数
			% obj1 NDTable，第一个操作数
			% obj2 NDTable，第二个操作数
			% Data1，第一个操作数
			% Data2，第二个操作数
			% Operator function_handle，二元操作函数句柄。如 @plus(+) @minus(-) @times(.*) @rdivide(./) 等。
			%# 返回值
			% obj NDTable，具有与输入NDTable相同的Dimensions。但如果运算中发生了单一维度自动隐式扩展，且那个维度的IndexNames只有1个，则此维度的IndexNames也将被自动
			%  扩展。
			if isa(obj1,'MATLAB.DataTypes.NDTable')
				if isa(obj2,'MATLAB.DataTypes.NDTable')
					if isequaln(obj1.Dimensions,obj2.Dimensions)
						obj1.Data=Operator(obj1.Data,obj2.Data);
					else
						MATLAB.Exceptions.Cannot_operate_on_NDTables_with_different_Dimensions.Throw;
					end
				else
					obj1=RepeatDimension(obj1,Operator(obj1.Data,obj2));
				end
			else
				obj1=RepeatDimension(obj2,Operator(obj1,obj2.Data));
			end
		end
	end
	methods
		function obj=NDTable(Data,Dimensions)
			%从原始数据新建NDTable
			%# 语法
			% ```
			% obj=MATLAB.DataTypes.NDTable(Data);
			% %用指定的多维数组构造NDTable
			%
			% obj=MATLAB.DataTypes.NDTable(Data,Dimensions);
			% %额外指定各维度名称和可用的字符串索引
			% ```
			%# 示例
			% ```
			% Data=rand(4,5,6,7);
			% IndexNames={["A","B","C","D"];["E","F","G","H","I"];[];["M","N","O","P"]};
			% obj=MATLAB.DataTypes.NDTable(Data,table(IndexNames));
			% ```
			% 上述代码创建了一个4维表，其中1、2、4维允许用字符串索引，第3维未指定字符串索引因此只能用数值索引。第4维长度为7但仅指定了前4个字符串索引，要访问后面的位置
			%  仍只能用数值索引。可以看到，必须在Dimensions中指定允许的字符串索引才能在该维度使用字符串索引，但无论是否指定，或不完全指定，永远可以用数值索引。具体索
			%  引语法见NDTable类文档。
			%# 输入参数
			% Data，即本类的Data属性值，详见此属性文档
			% Dimensions，即本类的Dimensions属性值，详见此属性文档。如果缺少任何一个必需列，将会自动添加，不会出错。
			%See also MATLAB.DataTypes.NDTable MATLAB.DataTypes.NDTable.Data MATLAB.DataTypes.NDTable.Dimensions
			arguments
				Data
				Dimensions=table('Size',[0,2],'VariableTypes',["string","cell"],'VariableNames',["DimensionName","IndexNames"]);
			end
			obj.Data=Data;
			Dimensions.Properties.DimensionNames(1)="维度";
			ColumnLogical=~ismember(["DimensionName","IndexNames"],Dimensions.Properties.VariableNames);
			if ColumnLogical(1)
				Dimensions.DimensionName(:)=string(missing);
			end
			if ColumnLogical(2)
				Dimensions.IndexNames(:)={[]};
			end
			obj.Dimensions=Dimensions;
		end
		function varargout = size(obj,varargin)
			[varargout{1:nargout}]=size(obj.Data,varargin{:});
		end
		function out = cat(dim,varargin)
			Arg=varargin{1};
			CatDimensions=Arg.Dimensions;
			NumArgs=numel(varargin);
			[CatData,CatDim]=deal(cell(NumArgs,1));
			CatData{1}=Arg.Data;
			if height(CatDimensions)>=dim
				CatDim{1}=reshape(CatDimensions.IndexNames{dim},1,[]);
			end
			for V=2:NumArgs
				Arg=varargin{V};
				CatHeight=height(CatDimensions);
				ArgHeight=height(Arg.Dimensions);
				CatDimensions.DimensionName(end+1:ArgHeight)=Arg.Dimensions.DimensionName(CatHeight+1:end);
				CatDimensions.IndexNames(end+1:ArgHeight)=Arg.Dimensions.IndexNames(CatHeight+1:end);
				if ArgHeight>=dim
					CatDim{V}=reshape(string(Arg.Dimensions{dim}),1,[]);
					CatDim{V}(end+1:size(Arg.Data,dim))=missing;
				end
				CatData{V}=Arg.Data;
			end
			CatDimensions.IndexNames{dim}=[CatDim{:}];
			out=MATLAB.DataTypes.NDTable(cat(dim,CatData{:}),CatDimensions);
		end
		function obj=reshape(obj,varargin)
			%因此操作发生改变的维度，其索引名称变为空
			NewData=reshape(obj.Data,varargin{:});
			Dims=1:max(ndims(obj.Data),ndims(NewData));
			obj.Data=NewData;
			obj.Dimensions.IndexNames(size(NewData,Dims)~=size(obj.Data,Dims))={strings(1,0)};
		end
		function obj=permute(obj,DimensionOrder)
			%如果所有维度都具有维度名称，可以指定维度名称作为新的维度顺序
			if ~isreal(DimensionOrder)
				[~,DimensionOrder]=ismember(DimensionOrder,obj.Dimensions.DimensionName);
			end
			obj.Data=permute(obj.Data,DimensionOrder);
			NDims=numel(DimensionOrder);
			if height(obj.Dimensions)<NDims
				obj.Dimensions.DimensionName(end+1:NDims)=missing;
			end
			obj.Dimensions(1:NDims,:)=obj.Dimensions(DimensionOrder,:);
		end
		%% 二元运算
		function obj=plus(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@plus);
		end
		function obj=minus(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@minus);
		end
		function obj=times(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@times);
		end
		function obj=rdivide(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@rdivide);
		end
		function obj=gt(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@gt);
		end
		function obj=lt(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@lt);
		end
		function obj=ge(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@ge);
		end
		function obj=le(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@le);
		end
		function obj=eq(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@eq);
		end
		function obj=ne(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@ne);
		end
		function obj=and(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@and);
		end
		function obj=or(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@or);
		end
		function obj=xor(obj1,obj2)
			obj=MATLAB.DataTypes.NDTable.Operate(obj1,obj2,@xor);
		end
		%% 降维操作
		function varargout=ReduceDimension(obj,Reducer,varargin)
			%执行自定义降维运算
			%# 语法
			% ```
			% varargout=obj.ReduceDimension(Reducer,varargin);
			% ```
			%# 输入参数
			% Reducer function_handle，降维运算的函数句柄，如 @mean @std @min @max 等
			% varargin，需要交给Reducer的其它参数。注意Reducer不能获取NDTable的维度名称，所以只能用数字指定维度参数。
			%# 返回值
			% varargout NDTable，每个返回值都是降维后的NDTable，发生降维的维度的IndexNames变为空。
			%See also MATLAB.DataTypes.NDTable.Operate
			if nargout
				Sizes=size(obj.Data);
				[varargout{1:nargout}]=Reducer(obj.Data,varargin{:});
				obj.Dimensions.IndexNames(size(obj.Data,1:numel(Sizes))<Sizes)={strings(1,0)};
				varargout=cellfun(@(Data)MATLAB.DataTypes.NDTable(Data,obj.Dimensions),varargout,UniformOutput=false);
			end
		end
		function obj=sum(obj,varargin)
			obj=obj.ReduceDimension(@sum,varargin{:});
		end
		function obj=mean(obj,varargin)
			obj=obj.ReduceDimension(@mean,varargin{:});
		end
		function obj=median(obj,varargin)
			obj=obj.ReduceDimension(@median,varargin{:});
		end
		function obj=std(obj,varargin)
			obj=obj.ReduceDimension(@std,varargin{:});
		end
		function obj=var(obj,varargin)
			obj=obj.ReduceDimension(@var,varargin{:});
		end
		function [M,I]=max(obj,varargin)
			[M,I]=obj.ReduceDimension(@max,varargin{:});
		end
		function [M,I]=min(obj,varargin)
			[M,I]=obj.ReduceDimension(@min,varargin{:});
		end
		function obj=any(obj,varargin)
			obj=obj.ReduceDimension(@any,varargin{:});
		end
		function obj=all(obj,varargin)
			obj=obj.ReduceDimension(@all,varargin{:});
		end
	end
end
function obj=RepeatDimension(obj,NewData)
Dims=1:max(ndims(obj.Data),ndims(NewData));
NewSizes=size(NewData,Dims);
Dims=NewSizes>size(obj.Data,Dims)&cellfun(@isscalar,obj.Dimensions.IndexNames)';
obj.Data=NewData;
obj.Dimensions.IndexNames(Dims)=arrayfun(@(D,S)repmat(D{1},1,S),obj.Dimensions.IndexNames(Dims),NewSizes(Dims)',UniformOutput=false);
end
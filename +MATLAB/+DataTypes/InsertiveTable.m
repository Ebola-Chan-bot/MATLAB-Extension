classdef InsertiveTable < matlab.mixin.indexing.RedefinesParen & matlab.mixin.indexing.RedefinesBrace & matlab.mixin.indexing.RedefinesDot
	%支持高效插入的表
	%通过维护一个行数大于实际数据量的 RawTable，避免每次插入行时重新分配内存。
	%当索引赋值的目标行超过当前 RawTable 行容量时，自动扩容至所需行数的 2 倍。
	%此类支持table的大多数普通语法，只有部分低性能写法故意被阻止。可以调用table方法将此类对象转换为普通table。

	properties(Access=protected)
		%实际存储数据的表。行数可能大于 ValidRows（包含预留行）
		RawTable

		%有效行数。1:ValidRows 为有效数据，超出部分为预留的垃圾行
		ValidRows
	end

	methods
		function obj = InsertiveTable(RawTable)
			%构造一个空表，或者包装一个已有table
			arguments
				RawTable = table
			end
			obj.RawTable = RawTable;
			obj.ValidRows = height(RawTable);
		end

		function varargout = size(obj, varargin)
			%返回逻辑尺寸（行数返回 ValidRows，其余维度转发 RawTable）
			[varargout{1:nargout}] = size(obj.RawTable(1:obj.ValidRows, :), varargin{:});
		end

		function out = cat(dim, varargin)
			%串联多个 InsertiveTable 或 table
			if dim==1&&numel(varargin)==2
				MATLAB.Exception.Deliberately_not_supporting.Throw('InsertiveTable不支持vertcat方法拼入新行。请改用end+1:end+N索引方式。')
			end
			for i = 1:numel(varargin)
				Arg = varargin{i};
				if isa(Arg, 'MATLAB.DataTypes.InsertiveTable')
					varargin{i} = Arg.RawTable(1:Arg.ValidRows, :);
				end
			end
			out = MATLAB.DataTypes.InsertiveTable(cat(dim, varargin{:}));
		end

		function T=table(obj)
			%转换为普通table
			T=obj.RawTable(1:obj.ValidRows,:);
		end
	end

	methods (Access = protected)
		% ===== RedefinesParen =====

		function varargout = parenReference(obj, indexOp)
			[varargout{1:nargout}] = obj.RawTable.(indexOp);
		end

		function obj = parenAssign(obj, indexOp, varargin)
			if isscalar(indexOp)&&height(varargin{1})==1&&istabular(varargin{1})
				MATLAB.Exception.Deliberately_not_supporting.Throw('请勿向InsertiveTable插入单行表。改用花括号值列表。');
			end
			[obj, ~] = obj.ensureCapacity(indexOp(1).Indices);
			obj.RawTable.(indexOp) = varargin{:};
			obj = obj.updateValidRowsOnAssign(indexOp(1).Indices{1});
		end

		function obj = parenDelete(obj, indexOp)
			Indices = indexOp(1).Indices;
			RowIdx = Indices{1};
			if isequal(RowIdx, ':')
				DeletedCount = obj.ValidRows;
			elseif islogical(RowIdx)
				DeletedCount = sum(RowIdx);
			else
				DeletedCount = numel(RowIdx);
			end
			obj.RawTable(Indices{:}) = [];
			obj.ValidRows = obj.ValidRows - DeletedCount;
		end

		function n = parenListLength(obj, indexOp, Context)
			n = listLength(obj.RawTable, indexOp, Context);
		end

		% ===== RedefinesBrace =====

		function varargout = braceReference(obj, indexOp)
			[varargout{1:nargout}] = obj.RawTable.(indexOp);
		end

		function obj = braceAssign(obj, indexOp, varargin)
			[obj, ~] = obj.ensureCapacity(indexOp(1).Indices);
			obj.RawTable.(indexOp) = varargin{:};
			obj = obj.updateValidRowsOnAssign(indexOp(1).Indices{1});
		end

		function n = braceListLength(obj, indexOp, Context)
			n = listLength(obj.RawTable, indexOp, Context);
		end

		% ===== RedefinesDot =====

		function varargout = dotReference(obj, indexOp)
			[varargout{1:nargout}] = obj.RawTable.(indexOp);
		end

		function obj = dotAssign(obj, indexOp, varargin)
			obj.RawTable.(indexOp) = varargin{:};
		end

		function n = dotListLength(obj, indexOp, Context)
			n = listLength(obj.RawTable, indexOp, Context);
		end
	end

	methods (Access = private)
		function [obj, Indices] = ensureCapacity(obj, Indices)
			%确保 RawTable 行容量足够。若目标行索引超过当前行数，扩容至 2 倍
			RowIdx = Indices{1};
			if isequal(RowIdx, ':')
				return
			end
			if islogical(RowIdx)
				RequiredRows = find(RowIdx, 1, 'last');
				if isempty(RequiredRows)
					return
				end
			else
				RequiredRows = max(RowIdx);
			end
			CurrentCapacity = height(obj.RawTable);
			if RequiredRows > CurrentCapacity && CurrentCapacity
				obj.RawTable{RequiredRows * 2,1}=obj.RawTable{1,1};
			end
		end

		function obj = updateValidRowsOnAssign(obj, RowIdx)
			%赋值后更新 ValidRows
			if isequal(RowIdx, ':')
				obj.ValidRows = height(obj.RawTable);
			elseif islogical(RowIdx)
				LastTrue = find(RowIdx, 1, 'last');
				if ~isempty(LastTrue)
					obj.ValidRows = max(obj.ValidRows, LastTrue);
				end
			else
				obj.ValidRows = max(obj.ValidRows, max(RowIdx));
			end
		end

	end
end
classdef (Sealed) Missing < matlab.mixin.internal.MatrixDisplay & matlab.mixin.CustomCompactDisplayProvider
	%内置missing类型的升级版，支持整数类型
	%此类型可以转换为整数类型。对于无符号整数，将转换为最大值；对于有符号整数，将转换为最小值。
    methods (Hidden)
        function disp(m)
            disp(string(m)); % converts missing to the missing string, not to "<missing>"
        end
        function rep = compactRepresentationForColumn(obj,displayConfiguration,~)
            rep = fullDataRepresentation(obj,displayConfiguration);
        end
        function rep = compactRepresentationForSingleLine(obj,displayConfiguration,~)
            rep = fullDataRepresentation(obj,displayConfiguration);
        end
        
        function b = ismissing(m, indicators)
            if nargin > 1
                try
                    if isa(m, 'missing')
                        if ~isa(indicators, 'missing')
                            error(message('MATLAB:invalidConversion', 'missing', class(indicators)));
                        end
                    else
                        b = deferCall('ismissing', m, indicators);
                        return;
                    end
                catch ME
                    throwAsCaller(ME);
                end
            end
            b = true(size(m));
        end
        
        function d = double(m)
            d = nan(size(m));
        end
        
        function d = single(m)
            d = nan(size(m), 'single');
		end
        
		function d = int8(m)
            d = repmat(intmin('int8'),size(m));
		end
        
		function d = int16(m)
            d = repmat(intmin('int16'),size(m));
		end
        
		function d = int32(m)
            d = repmat(intmin('int32'),size(m));
		end
        
		function d = int64(m)
            d = repmat(intmin('int64'),size(m));
		end
        
		function d = uint8(m)
            d = repmat(intmax('uint8'),size(m));
		end
        
		function d = uint16(m)
            d = repmat(intmax('uint16'),size(m));
		end
        
		function d = uint32(m)
            d = repmat(intmax('uint32'),size(m));
		end
        
		function d = uint64(m)
            d = repmat(intmax('uint64'),size(m));
		end
        
        function s = string(m)
            s = string(nan(size(m)));
        end
        
        function s = struct(varargin)
            if nargin == 1
                error(message('MATLAB:invalidConversion', 'struct', 'missing'));
            else
                try
                    s = builtin('struct', varargin{:});
                catch e
                    throwAsCaller(e);
                end
            end
        end
        
        function o = horzcat(varargin)
            o = deferCall('horzcat', varargin{:});
        end
        
        function o = vertcat(varargin)
            o = deferCall('vertcat', varargin{:});
        end
        
        function o = cat(dim, varargin)
            if ismissing(dim)
                dim = nan;
            end
            varargin = convertCell(varargin);
            o = redispatch('cat', dim, varargin{:});
        end
        
        function b = isequal(varargin)
            b = false;
        end
        
        function b = isequaln(varargin)
            try
                b = deferCall('isequaln', varargin{:});
            catch
                b = false;
            end
        end
        
        function b = lt(left, right)
            b = compare(left,right,'lt');
        end
        
        function b = le(left, right)
            b = compare(left,right,'le');
        end
        
        function b = gt(left, right)
            b = compare(left,right,'gt');
        end
        
        function b = ge(left, right)
            b = compare(left,right,'ge');
        end
        
        function b = eq(left, right)
            b = falseExpand(left, right);
        end
        
        function b = ne(left, right)
            b = ~falseExpand(left, right);
        end
    end
    
    methods (Hidden, Access=protected)
        function displayImpl(m, ~, ~)
            disp(m);
            if isscalar(m) && (matlab.internal.display.formatSpacing == "loose")
                fprintf(newline);
            end
        end
    end
end

function arg = convertCell(arg)
    missings = false(size(arg));
    for i = 1:numel(arg)
        missings(i) = isa(arg{i},"missing");
    end
    % Convert all the missings in the input arg list to the class of the first
    % non-missing.
    found = find(~missings, 1);
    if ~isempty(found)
        for i = find(missings)
            arg{i} = matlab.internal.datatypes.missingLike(arg{i},arg{found});
        end
    end
end

function b = falseExpand(left, right)
    try
        convertCell({left, right});
        b = false(size(left)) | false(size(right));
    catch e
        e.throwAsCaller;
    end
end

function o = redispatch(fcn, varargin)
    try
        if isa(varargin{end}, 'missing')
            o = builtin(fcn, varargin{:});
        else
            o = feval(fcn, varargin{:});
        end
    catch e
        e.throwAsCaller;
    end
end

function o = deferCall(fcn, varargin)
    try
        varargin = convertCell(varargin);
        o = redispatch(fcn, varargin{:});
    catch e
        e.throwAsCaller;
    end
end

function b = compare(left, right, comparison)
    try
        if isa(left, "missing") && isa(right, "missing")
            b = falseExpand(left, right);
        else
            % Redispatch to the class so it can error if it does not support
            % relational operators.
            b = deferCall(comparison, left, right);
        end
    catch e
        e.throwAsCaller;
    end
end
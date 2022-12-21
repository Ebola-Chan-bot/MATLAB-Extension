classdef UniLink<handle
	properties
		Value
		Link
	end
	methods
		function obj = UniLink(Value,Link)
			obj.Value=Value;
			obj.Link=Link;
		end
	end
end
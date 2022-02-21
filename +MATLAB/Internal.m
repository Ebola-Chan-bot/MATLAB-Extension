classdef Internal
	%快速集合算法，所有函数都仅支持内置类型的行向量作为集合参数。
	%这些函数仅供内部使用，随时可能发生更改。
	methods(Static)
		function Diff=QuickSetDiff(SetA,SetB)
			Diff=SetA(~any(SetA==SetB',1));
		end
		function Inter=QuickIntersect(SetA,SetB)
			Inter=SetA(any(SetA==SetB',1));
		end
		function Set=QuickUnique(Set)
			Set=Set(~any(triu(Set==Set',1),1));
		end
		function Set=QuickUnion(SetA,SetB)
			Set=MATLAB.Internal.QuickUnique(SetA,SetB);
		end
		function Is=QuickIsMember(Element,Set)
			Is=any(Element==Set);
		end
	end
end
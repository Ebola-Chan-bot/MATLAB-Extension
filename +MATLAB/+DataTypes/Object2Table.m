%[text] 将对象数组转换为表，一个属性一列
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Table = MATLAB.DataTypes.Object2Table(Objects);
%[text] %将所有对象所有公开访问的非隐藏属性列在表中
%[text] 
%[text] Table = MATLAB.DataTypes.Object2Table(Objects,Name=Value);
%[text] %额外指定筛选条件，只列出满足条件的公开访问属性。条件可以选择多个。
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] EB=errorbar(1,2,3,4);
%[text] 
%[text] %列出对象的所有属性值
%[text] MATLAB.DataTypes.Object2Table(EB)
%[text] 
%[text] %列出对象所有属性的属性
%[text] MATLAB.DataTypes.Object2Table(metaclass(EB).PropertyList,Name_="DefaultValue")
%[text] ```
%[text] ## 输入参数
%[text] Objects，要列出属性的对象数组
%[text] ### 名称值参数
%[text] 名称值参数均为matlab.metadata.Property的属性，详见其文档。并非所有属性均可用于筛选，目前仅支持：
%[text] - Name string
%[text] - Dependent logical
%[text] - Hidden logical
%[text] - HasDefault logical \
%[text] 所有筛选条件均可以设置多个值，符合这些值中任何一个的属性都会被列出。不同条件之间则是逻辑与关系。此外，可以在参数名称后缀下划线，表示该条件应当取反，即排除（而不是包含）满足该条件的属性。
%[text] ## 返回值
%[text] Table table，列出所有对象的属性，一行一个对象，一列一个属性。如果所有属性值尺寸相同且第1维长度为1，列类型将与属性值相同；否则列类型是元胞。只能列出公开访问的属性。
%[text] **See also** [matlab.metadata.Property](<matlab:doc matlab.metadata.Property>) [properties](<matlab:doc properties>) [metaclass](<matlab:doc metaclass>) [struct2table](<matlab:doc struct2table>)
function Table = Object2Table(Objects,varargin)
if nargin>1
	Properties=metaclass(Objects).PropertyList;
	Properties=Properties(MATLAB.ElMat.IsEqualN({Properties.GetAccess},"public",-2));
	for V=1:2:numel(varargin)
		if isempty(Properties)
			break;
		end
		Name=varargin{V};
		Exclude=endsWith(Name,'_');%不需要考虑属性名称原本就有下划线后缀的情况，因为只允许matlab.metadata.Property的属性名称
		if Exclude
			Name=char(Name);
			Name(end)='';
		end
		if ischar(Properties(1).(Name))
			Values={Properties.(Name)};
		else
			Values=[Properties.(Name)];
		end
		Properties=Properties(xor(Exclude,ismember(Values,varargin{V+1})));
	end
	Properties={Properties.Name};
else
	Properties=properties(Objects).';
end
Table=table;
for P=string(Properties)
	Values={Objects.(P)}.';
	if all(cellfun(@height,Values)==1)
		try
			Values=vertcat(Values{:});
		catch ME
			if ~any(ME.identifier==["MATLAB:catenate:dimensionMismatch","MATLAB:catenate:implicitTypeConversionGivesDimensionMismatch"])
				ME.rethrow;
			end
		end
	end
	Table.(P)=Values;
end
end

%[appendix]{"version":"1.0"}
%---

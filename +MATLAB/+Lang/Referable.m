classdef Referable<handle
	%为值创建引用源，然后可以创建同步更改的引用
	%此容器包装一个输入值，然后可以创建引用。当更改容器内的值时，所有引用值也被同步修改。
	%# 示例
	% ```MATLAB
	% Source=MATLAB.Lang.Referable(1);
	% Reference=Source.CreateReference
	% Source.Value(2)=2;
	% Reference
	% ```
	% 运行上述代码将输出：
	% ```输出
	% Reference = 
	%
	%      1
	%
	%
	% Reference = 
	% 
	%      1     2
	% ```
	% 可见，随着Source值的更改，Reference的值也一并更改了。而且，Reference对外展现的类型和原始值相同，具有（几乎）完全相同的行为，可用于（几乎）完全相同的运算。例如：
	% ```MATLAB
	% ones(Reference)
	% ```
	% ```输出
	% ans =
	%
	%      1     1
	% ```
	% Reference的修改同样会回传给Source，如：
	% ```MATLAB
	% Source=MATLAB.Lang.Referable(table);
	% Reference=Source.CreateReference;
	% Reference.A=[1;1];
	% Source.Value
	% ```
	% ```
	% ans =
	% 
	%   2×1 table
	%
	%     A
	%     _
	%
	%     1
	%     1
	% ```
	% 上例创建了一个空表的引用，然后对引用进行添加列的操作，此修改同样被同步到Source.Value中。
	%引用运算产生的结果将不再和原始值绑定。如果引用不被索引地放在赋值等号左边被赋予引用以外的值，也将与原始值解绑。特别地，表格中无法直接插入引用值，因为它会对引用指向
	% 的值进行索引复制，而不是直接复制引用。要在表格中使用引用，可以在引用外套一层元胞数组或其它隔绝表格对引用直接索引的容器类型。
	%引用数组的串联、索引、变形等操作都将产生与原始值解绑的值，而不再是引用。
	%如果你发现某个函数行为不同，请反馈到GitHub。
	%关于序列化。引用可以保存到mat文件，也可以在并行池中跨进程传递。但这将导致引用与Referable解绑。
	properties(Access=protected)
		rValue
	end
	properties(Dependent)
		%容纳值。修改此值将导致所有此容器派生的引用值被修改。
		% 注意，不允许改变此值的类型，任何修改必须与构造Referable对象时使用的值类型保持一致。
		Value
	end
	methods
		function Value=get.Value(obj)
			Value=obj.rValue;
		end
		function set.Value(obj,Value)
			if isa(Value,class(obj.rValue))
				obj.rValue=Value;
			else
				MATLAB.Exceptions.Cannot_change_type_of_Referable_value.Throw;
			end
		end
		function obj = Referable(Value)
			%构造Referable对象
			%# 语法
			% ```
			% obj=MATLAB.Lang.Referable(Value);
			% ```
			%# 输入参数
			% Value，任意类型值。注意，此处指定的值类型将决定以后修改时的类型。
			obj.rValue=Value;
		end
		function Reference=CreateReference(obj,UpdateClass)
			%创建一个引用
			%此方法返回Referable容纳值的引用。引用与容纳值具有相同的运算行为和方法，并与容纳值保持绑定关系。对容纳值的修改也将同步到引用上；对引用的修改也将同步回容纳
			% 值。注意，将引用变量整个赋以其它值不是"对引用的修改"，这种行为将导致绑定解除。引用参与运算后的运算结果通常也不与容纳值绑定。
			%引用具有与容纳值相同的表观类型，但它实际上是从一个引用类型模板在运行时创建的动态类型。对不同类型的容纳值，都会在运行时创建不同的动态引用类型。对相同类型的
			% 容纳值，则共用同一个缓存的动态类型。这个缓存持久存在于磁盘上，不会随着计算机重启而消灭，下次启动MATLAB会话时仍可以使用同样的缓存。
			%# 语法
			% ```
			% Reference=obj.CreateReference;
			% %为Referable的容纳值创建一个引用。如果以前创建过相同类型的引用，将使用缓存的动态类型。
			%
			% Reference=obj.CreateReference(UpdateClass);
			% %额外指定是否需要更新动态类型。如果容纳值的类型是用户定义的，当用户修改类定义后，缓存的动态类型不会自动更新，需要在这里强制更新动态类型。
			% ```
			%# 输入参数
			% UpdateClass(1,1)logical=false。如果设为true，将为容纳值的类型重新生成一个动态类型，而不使用已有的缓存。如果容纳值的类型定义发生了修改，特别是新方法定
			%  义、旧方法删除时，应当手动更新动态类型。动态类型更新后，所有之前已创建的引用也会随之更新到新的动态类型。
			arguments
				obj
				UpdateClass=false
			end
			persistent CommonMethods TemplateCode SMTemplate UserDirectory
			if isempty(CommonMethods)||UpdateClass
				CommonMethods=methods('MATLAB.internal.ReferenceBase');
				CommonMethods(contains(CommonMethods,'ReferenceBase'))=[];
				TemplateCode=splitlines(fileread(which('MATLAB.internal.ReferenceTemplate')));
				SMStartLine=find(contains(TemplateCode,'SpecialMethod('),1);
				SMEndLine=find(contains(TemplateCode(SMStartLine+1:end),'end'),1)+SMStartLine;
				SMTemplate=join(TemplateCode(SMStartLine:SMEndLine),newline);
				TemplateCode=[join(TemplateCode(1:SMStartLine-1),newline);join(TemplateCode(SMEndLine+1:end),newline)];
				UserDirectory=fullfile(userpath,'+MATLAB\+internal');
			end
			ClassName=class(obj.rValue);
			ReferenceClass="Reference_"+replace(ClassName,'.','_');
			warning off MATLAB:MKDIR:DirectoryExists
			mkdir(UserDirectory);
			CodePath=fullfile(UserDirectory,ReferenceClass+".m");
			if ~isfile(CodePath)||UpdateClass
				%使用metaclass可以发现隐藏方法，而methods不能
				ClassMethods=metaclass(obj.rValue).MethodList;
				[MethodNames,Access,Static]=deal(cell(numel(ClassMethods),1));
				[MethodNames{:}]=ClassMethods.Name;
				[Access{:}]=ClassMethods.Access;
				[Static{:}]=ClassMethods.Static;
				%Access和public不能用字符串等号比较，因为Access可能会有元类型值，不一定是字符向量
				MethodNames(MATLAB.ElMat.IsEqualN(Access,"public")|vertcat(Static{:}))=[];
				Fid=fopen(CodePath,'w','n','UTF-8');
				fwrite(Fid,string(join([replace(TemplateCode(1),"ReferenceTemplate",ReferenceClass);strrep(SMTemplate,'SpecialMethod',setdiff(MethodNames,CommonMethods));TemplateCode(2)],newline)),'char');
				fclose(Fid);
				rehash;
			end
			Reference=feval("MATLAB.internal."+ReferenceClass,obj);
		end
		function UT=underlyingType(obj)
			UT=class(obj.Value);
		end
	end
end
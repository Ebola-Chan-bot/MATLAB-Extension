埃博拉酱的MATLAB扩展工具包，提供一系列MATLAB内置函数所欠缺，但却常用的增强功能。

[![View 埃博拉酱的 MATLAB 扩展 Extension on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ww2.mathworks.cn/matlabcentral/fileexchange/96344-matlab-extension)
# 目录
本包中所有函数均在MATLAB命名空间下，使用前需import。使用命名空间是一个好习惯，可以有效防止命名冲突，避免编码时不必要的代码提示干扰。
- [+MATLAB](#MATLAB)
	- [+Containers](#Containers)
	- [+DataFun](#DataFun)
	- [+DataTypes](#DataTypes)
	- [+ElMat](#ElMat)
	- [+General](#General)
	- [+IO](#IO)
	- [+IOFun](#IOFun)
	- [+Lang](#Lang)
	- [+Ops](#Ops)
	- [+SpecFun](#SpecFun)
	- [+SupportPkg](#SupportPkg) 一键获取MATLAB硬件支持包
	- [+UITools](#UITools)

每个代码文件内部都有详细文档，可以用doc命令查看，此处仅列出函数签名、类公开接口和功能简介。
# +MATLAB
类
```MATLAB
classdef IEnumerableException
	%可枚举异常，提供一种方便的异常接口类
	methods
		function Throw(obj,Message,options)
			%抛出异常，可选指定更多详细信息
		end
	end
end
classdef MException<MException
	%内置MException的扩展，支持更灵活的构造和额外的Detail属性
	properties
		%异常的其它详细信息
		Detail
	end
	methods
		function obj=MException(options)
			%使用全员可选的名称值参数构造对象
		end
	end
end
```
函数
```MATLAB
%计算两个N维空间向量的夹角弧度
function A=AngleND(varargin)
%绘制多条误差阴影线图
function Patches=MultiShadowedLines(Y,ShadowHeights,FaceAlpha,options)
%设置当前图窗的纵横比
function Fig=FigureAspectRatio(HorizontalProportion,VerticalProportion,Scale,options)
%列出指定工程所添加的搜索路径
function ProjectPaths = ListAllProjectPaths(Project)
```
## +Containers
```MATLAB
classdef IndexMap<handle
	% IndexMap是一种自动分配键的映射
	methods
		function C=Count(obj)
			% 返回对象中的键-值对组的数量
		end
		function Values=Items(obj,Keys,varargin)
			% 获取或设置与指定的键关联的值。
		end
		function Keys=Add(obj,varargin)
			% 将指定的值添加到IndexMap中，返回自动分配的新键。
		end
		function Keys=Allocate(obj,Number)
			% 预分配指定数目的新键，暂不赋值
		end
		function Clear(obj)
			% 将所有键和值从IndexMap中移除。
		end
		function IK=IsKey(obj,Keys)
			% 确定 IndexMap 对象是否包含键
		end
		function K=Keys(obj)
			% 返回一个向量，其中包含 IndexMap 对象中的所有键。
		end
		function Remove(obj,Keys)
			% 从 IndexMap 对象中删除键-值对组
		end
	end
end
classdef(Abstract)IQueue<handle
	% 表示对象的先进先出集合。
	events
		%有元素被添加到队列中时引发此事件
		DataEnqueued
	end
	methods(Abstract)
		% 移除并返回位于 IQueue 开始处的对象。
		Elements=Dequeue(obj,Number)
		% 将对象添加到 IQueue 的结尾处。
		Enqueue(obj,varargin)
	end
	%某些方法的默认实现。子类可以重写成性能更高的实现。
	methods
		function C=Count(obj)
			% 获取 Queue 中包含的元素数。
		end
		function Clear(obj)
			% 从 IQueue 中移除所有对象。
		end
		function C=Contains(obj,varargin)
			% 确定某些元素是否在 IQueue 中。
		end
		function P=Peek(obj)
			% 返回位于 IQueue 开始处的对象但不将其移除。
		end
		function Array=ToArray(obj)
			% 将 IQueue 元素复制到新数组。
		end
		function E=IsEmpty(obj)
			% 检查队列是否为空
		end
	end
end
classdef Queue<matlab.mixin.Copyable&MATLAB.Containers.IQueue
	%MALTAB.Containers.IQueue的简单基本实现
	methods
		function obj=Queue(varargin)
			% 初始化 Queue 类的新实例。
		end
	end
end
```
## +DataFun
```MATLAB
%内置findgroups的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [G,ID] = FindGroupsN(A,Dimension)
%返回数组的最大值以及所在的坐标。
function [Value,varargout] = MaxSubs(Data,Dimensions)
%一次性高效算出数据沿维度的平均值和标准误
function [Mean,SEM]=MeanSem(Data,Dimensions)
%返回数组的最小值以及所在的坐标。
function [Value,varargout] = MinSubs(Data,Dimensions)
%数组元素沿指定维度的缩放范围
function Array = Rescale(Array,LowerBound,UpperBound,Dimensions)
```
## +DataTypes
类
```MATLAB
classdef ArrayBuilder<handle
	%数组累加器
	properties(SetAccess=immutable)
		%累加维度
		BuildDimension
	end
	methods
		function obj = ArrayBuilder(BuildDimension)
			%构造ArrayBuilder对象
		end
		function Append(obj,New)
			%向数组末尾累加新值
		end
		function Array=Harvest(obj)
			%收获累加完毕的MATLAB数组。收获后可以释放本对象，也可以继续累加。
		end
		function Clear(obj)
			%清空ArrayBuilder对象
		end
	end
end
classdef CatMode
	%此类用于MATLAB.DataTypes.ArrayFun的参数枚举
	enumeration
		%Function的返回值为标量
		Scalar
		%SplitDimensions为标量，且Function的返回值为类型、PackDimensions维度上尺寸均相同的数组
		Linear
		%Function的返回值为数值、逻辑、字符或字段相同的结构体数组，且尺寸完全相同
		EsNlcs
		%Function的返回值为数组，允许尺寸不同，但最终可以拼接成一整个大数组
		CanCat
		%不符合上述任何条件，或返回值为函数句柄
		DontCat
	end
end
```
函数
```MATLAB
%内置arrayfun的升级版，支持指定维度、单一维度隐式扩展和返回数组自动拼接
function varargout=ArrayFun(Function,Arguments,options)
%cell2mat的升级版，强力拼接任意数据类型
function Cells = Cell2Mat(Cells)
%取对一个文件夹下所有满足给定文件名模式的文件的绝对路径，对它们执行函数
function varargout = FolderFun(Function,Directory,options)
%将多个结构体标量按字段合并，重复的字段将取第一个值
function Merged = MergeStructs(varargin)
%重复多次调用函数，为每个重复参数生成一个返回值
function varargout = RepeatingFun(Function,Arguments)
%对多张表格实施类似于 SQL SELECT 的查询操作
function Result = Select(From,Fields,Where)
%内置typecast的升级版，支持多维数组，需指定转换维度
function Y = TypeCast(X,Type,Dimension)
```
## +ElMat
```MATLAB
%内置flip函数的升级版，支持同时翻转多个维度
function A = Flip(A,Dimensions)
%内置isequaln的升级版，支持任意数组类型，并可以指定比较维度，返回逻辑数组
function Equal = IsEqualN(A,B,Dimensions)
%支持任意维度数组的linspace
function Sequence = LinSpace(Start,End,Number,Dimension)
%根据维度顺序和尺寸，生成自定义的下标转线性索引数组
function ActualIndexArrayByArbitrarySubs = OrderedDimensionSize2IndexArray(DimensionSize,DSOrderArbitrary,options)
%根据维度顺序和尺寸，生成自定义的线性索引转下标向量
function varargout = OrderedDimensionSize2SubsVectors(DimensionSize,DSOrderArbitrary,options)
%内置cat函数的魔改版，可以给不兼容数组自动补全空值
function Array = PadCat(Dimension,Padder,varargin)
%内置rot90函数的升级版，支持指定任意两个维度组成的旋转平面
function A = Rot90(A,varargin)
%内置transpose函数的升级版，支持转置任意两个维度
function A = Transpose(A,DimPair)
```
## +General
```MATLAB
%列出所有MATLAB官方API的搜索路径
function Paths = BuiltinPaths
%内置cd函数的升级版，支持打开目录选择对话框要求用户手动选择当前目录
function OldDirectory = CD(NewDirectory)
%调用 Win32 ShellAPI 执行可撤销的批量文件复制
function AnyOperationCanceled = CopyFile(Source,Destination)
%调用 Win32 ShellAPI 执行可撤销的批量文件、目录删除
function AnyOperationCanceled=Delete(Paths)
%内置load函数的魔改版，取消适用场合限制，支持直接输出变量
function varargout = Load(Path,VariableName)
%调用 Win32 ShellAPI 执行可撤销的批量文件移动
function AnyOperationCanceled = MoveFile(Source,Destination)
%内置save函数的魔改版，采用名称值参数保存变量，可以在parfor循环中使用。
function Save(MatPath,Variable)
%在工作区或复合变量中搜索变量名、结构体字段、表格列或对象属性
function Paths = SearchNames(Names,Parent)
%确认Java路径已添加到静态路径列表
function Exist=StaticJavaPath(Path,Reset)
```
## +IO
```MATLAB
classdef ZipFileReader<handle
	%ZIP文件批量读入器，直接从ZIP档案中读入，不会向磁盘写出解压文件
	properties(SetAccess=immutable)
		%创建该对象的ZipReader
		ZipReader
	end
	methods
		function [Data,BytesRead]=Read(objs,NumBytes)
			%从文件读入指定数目的字节
		end
	end
end
classdef ZipReader<handle
	%ZIP档案读入器。不同于内置unzip，本类支持直接读入ZIP档案中的文件字节（解压后的），而不需要将其解压到文件。
    methods
        function obj = ZipReader(ZipPath)
			%构造ZipReader对象，从指定路径打开一个ZIP档案
		end
		function Locates=NameLocate(obj,Names)
			%查找指定文件名在档案中的索引
		end
		function FileReader=FOpen(obj,NameOrIndex)
			%打开ZIP档案中的文件以供读入
		end
		function Sizes=GetSize(obj,NameOrIndex)
			%获取档案中指定文件的压缩前大小
		end
		function Names=GetName(obj,Indices)
			%根据索引取得文件名
		end
		function NumEntries=GetNumEntries(obj)
			%获取档案中的文件数目
		end
    end
end
```
## +IOFun
```MATLAB
%将一列分隔符字符串的前几个字段读出为表格或时间表
function Table = DelimitedStrings2Table(Strings,FieldNames,Delimiter,options)
%批量重命名.mat文件中的变量
function MatVariableRename(OldNames,NewNames,MatPaths)
%将org.w3c.dom.Document导出为XML文本
function XmlString = XmlDom2String(XmlDom)
%将XML字符串解析为org.w3c.dom.Document类型
function XmlDom = XmlString2Dom(XmlString)
```
## +Lang
```MATLAB
%根据验证函数将输入的Varargin分发到输出变量
function varargout = DistributeVararginByValidation(Varargin,ValidationFun,DefaultFun)
%获取函数的第N个输出
function varargout = GetNthOutputs(Function,OutputIndices)
%内置input函数的增强版，取消适用场合限制
function X = Input(varargin)
```
## +Ops
```MATLAB
%内置ismember的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [Is,Location] = IsMemberN(Member,Set,Dimension)
%内置setdiff的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [Diff,IA] = SetDiffN(SetA,SetB,Dimension)
%内置union的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据，还能同时合并多个集合
function USet = UnionN(Dimension,varargin)
%内置unique的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [C,ia,ic] = UniqueN(A,Dimension)
```
## +SpecFun
```MATLAB
%穷举一定长度的所有可能的逻辑向量
function Exhaustion = LogicalExhaustion(Length)
%列出集合的所有子集
function SS = Subsets(Set)
```
## +SupportPkg
```MATLAB
%示例脚本
Demo
%安装下载好的支持包
function InstallSupportPackages(ArchivesDirectory,options)
%下载支持包下载器。
function SupportPackageDownloader(CacheDirectory,options)
```
## +UITools
```MATLAB
%可以设置初始目录，以及保存上次所在目录的文件打开对话框
function FilePaths = OpenFileDialog(options)
%可以设置初始目录，以及保存上次所在目录的文件保存对话框
function FilePath = SaveFileDialog(options)
```

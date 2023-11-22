埃博拉酱的MATLAB扩展工具箱，提供一系列MATLAB内置函数所欠缺，但却常用的增强功能。还替官方修复了许多内置函数的bug。

[![View 埃博拉酱的 MATLAB 扩展 Extension on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ww2.mathworks.cn/matlabcentral/fileexchange/96344-matlab-extension)
# 目录
本包中所有函数均在MATLAB命名空间下，使用前需import。
- [+MATLAB](#matlab)
	- [+Containers](#containers) 实现多种STL容器
	- [+DataFun](#datafun) 数值统计操作
	- [+DataTypes](#datatypes) 元胞、表格、结构等特殊容器类型的复杂操作
	- [+ElFun](#elfun) 数值变换
	- [+ElMat](#elmat) 数组形状变换
	- [+General](#general) 变量、路径、工作区操作
	- [+Graphics](#graphics) 图窗和绘图操作
	- [+ImageSci](#imagesci) 读入图像
	- [+IO](#io) 文件和ZIP档案操作
	- [+IOFun](#iofun) 文件、网络、内存读写相关
	- [+Lang](#lang) 函数使用、定义、异常工具、语言功能
	- [+Ops](#ops) 逻辑和集合操作
	- [+Project](#project) 工程相关
	- [+RandFun](#randfun) 随机概率分布洗牌
	- [+SpecFun](#specfun) 穷举、椭圆周长
	- [+SupportPkg](#supportpkg) 一键获取MATLAB硬件支持包
	- [+UITools](#uitools) 文件打开和保存对话框
	- 还有一些尚未归类的工具函数直接放在MATLAB包下

每个代码文件内部都有详细文档，可以用doc命令查看，此处仅列出函数签名和类功能简介。
# +MATLAB
函数
```MATLAB
%在系统浏览器中打开附加功能资源管理器
function BrowseAddonsExplorer
%绘制跟随曲线方向的箭头
function Arrows = LineFollowingArrow(XYCoordinates,options)
%暂停执行MATLAB，不可中止
function Pause(varargin)
%将任意维度的RGB图像转换为灰度图
function Image = Rgb2Gray(Image,Dimension)
%将数值转换为具有指定有效位数的定点计数法字符串
function Fixedpoints = SignificantFixedpoint(Numbers,Significance)
%在不破坏图连通性的前提下尝试移除节点（Try to remove the node without breaking graph connectivity）
function Graph = TtrtnWbgc(Graph,ToRemove)
```
## +Containers
```MATLAB
classdef IndexMap
	% IndexMap是一种自动分配键的映射
end
classdef(Abstract)IQueue
	% 表示对象的先进先出集合。
end
classdef Queue
	%MALTAB.Containers.IQueue的简单基本实现
end
classdef Stack
	%STL风格的先进后出栈实现，但不要求栈中对象具有相同的数据类型
end
classdef StlQueue
	%STL风格的先进先出队列实现，但不要求队列中对象具有相同的数据类型
end
classdef Vector
	%STL风格的向量实现
end
```
## +DataFun
```MATLAB
%内置findgroups的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [G,ID] = FindGroupsN(Collection,Dimension)
%返回数组的最大值以及所在的坐标。
function [Value,varargout] = MaxSubs(Data,Dimensions,K)
%一次性高效算出数据沿维度的平均值和标准误
function [Mean,SEM]=MeanSem(Data,Dimensions)
%返回数组的最小值以及所在的坐标。
function [Value,varargout] = MinSubs(Data,Dimensions,K)
%数组元素沿指定维度的缩放范围
function Array = Rescale(Array,LowerBound,UpperBound,Dimensions)
%在任意维度上计算互相关
function [C,Lag] = XCorr(X,Y,Dimensions)
```
## +DataTypes
类
```MATLAB
classdef ArrayBuilder
	%数组累加器
end
classdef ArrayType
	%枚举MATLAB所有基本数据类型
end
classdef CatMode
	%此类用于MATLAB.DataTypes.ArrayFun的参数枚举
end
classdef EventLogger
	%事件记录器，类似于秒表
end
classdef NDTable
	%N维表格，相当于支持字符串索引的N维数组
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
%检查表中所有全等的列，将它们合并成一列
function Table = MergeCongruentColumns(Table)
%将多个结构体标量按字段合并，重复的字段将取第一个值
function Merged = MergeStructs(varargin)
%按照键列合并表
function Merged = MergeTables(KeyColumns,varargin)
%重复多次调用函数，为每个重复参数生成一个返回值
function varargout = RepeatingFun(Function,Arguments)
%对内联表查询进行图论优化
function [OptimizedTables,TableGraph] = OptimizeQueryGraph(Tables,ColumnsOfInterest,Flags)
%对多张表格实施类似于 SQL SELECT 的查询操作
function ResultTable = Select(varargin)
%内置typecast的升级版，支持多维数组，需指定转换维度
function Y = TypeCast(X,Type,Dimension)
```
## +ElFun
```MATLAB
%计算两个N维空间向量的夹角弧度
function A=AngleND(varargin)
%将有限的整数资源按照权重尽可能公平分配
function Allocation = IntegerAllocate(Resources,Weights)
```
## +ElMat
```MATLAB
%内置cat函数的魔改版，可以给不兼容数组自动剪除尾数
function Array = CutCat(Dimension,varargin)
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
function Array = PadCat(Dimension,Arrays,options)
%内置rot90函数的升级版，支持指定任意两个维度组成的旋转平面
function A = Rot90(A,varargin)
%内置transpose函数的升级版，支持转置任意两个维度
function A = Transpose(A,DimPair)
%通过重复维度来统一数组的尺寸
function varargout = UniformSize(varargin)
```
## +General
函数
```MATLAB
%列出所有MATLAB官方API的搜索路径
function Paths = BuiltinPaths
%内置cd函数的升级版，支持打开目录选择对话框要求用户手动选择当前目录
function OldDirectory = CD(NewDirectory)
%内置javaaddpath的升级版，自动添加目录下的所有jar
function JavaAddPath(Paths)
%内置load函数的魔改版，取消适用场合限制，支持直接输出变量
function varargout = Load(Path,VariableName)
%重启MATLAB
function Restart
%内置save函数的魔改版，采用名称值参数保存变量，可以在parfor循环中使用。
function Save(MatPath,Variable)
%在工作区或复合变量中搜索变量名、结构体字段、表格列或对象属性
function Paths = SearchNames(Names,Parent)
%确认Java路径已添加到静态路径列表
function Exist=StaticJavaPath(Path,Reset)
%解决内置which找不到包内类下成员方法的问题
function Path = Which(varargin)
```
类
```MATLAB
classdef PathManager<handle
	%搜索路径管理系统
end
classdef Pointer<uint64
	%分配和读写C++内存指针
end
classdef SharedPtr<handle
	%将引用计数智能指针回绕在动态分配的对象周围。
end
```
## +Graphics
函数
```MATLAB
%设置当前图窗的纵横比
function Fig=FigureAspectRatio(HorizontalProportion,VerticalProportion,varargin)
%绘制多条误差阴影线图
function Patches=MultiShadowedLines(Y,ShadowHeights,FaceAlpha,options)
%列出内置作图函数允许使用的Marker字符
function VMC = ValidMarkerChars(Index)
```
类
```MATLAB
classdef Window<handle
	%创建一个全透明Windows窗口，可以在其上显示图像
end
```
## ImageSci
```MATLAB
%内置imread的升级版，额外支持WebP格式图像
function varargout = ImRead(varargin)
```
## +IO
函数
```MATLAB
%调用 Win32 ShellAPI 执行可撤销的批量文件复制
function AnyOperationCanceled = CopyFile(Source,Destination)
%调用 Win32 ShellAPI 执行可撤销的批量文件、目录删除
function AnyOperationCanceled=Delete(Paths,Flags)
%创建 Windows lnk 快捷方式
function LnkShortcut(varargin)
%调用 Win32 ShellAPI 执行可撤销的批量文件移动
function AnyOperationCanceled = MoveFile(Source,Destination)
```
类
```MATLAB
classdef ZipFileReader
	%ZIP文件批量读入器，直接从ZIP档案中读入，不会向磁盘写出解压文件
end
classdef ZipReader
	%ZIP档案读入器。不同于内置unzip，本类支持直接读入ZIP档案中的文件字节（解压后的），而不需要将其解压到文件。
end
```
## +IOFun
函数
```MATLAB
%将一列分隔符字符串的前几个字段读出为表格或时间表
function Table = DelimitedStrings2Table(Strings,FieldNames,Delimiter,options)
%批量重命名.mat文件中的变量
function MatVariableRename(OldNames,NewNames,MatPaths)
%发送喵提醒
function SendMeowAlert(MeowCode)
%将org.w3c.dom.Document导出为XML文本
function XmlString = XmlDom2String(XmlDom)
%将XML字符串解析为org.w3c.dom.Document类型
function XmlDom = XmlString2Dom(XmlString)
```
类
```MATLAB
classdef File<handle
	%使用 Win32 API 的文件读写操作，比MATLAB内置文件操作更灵活丰富
end
classdef MemoryMapping<handle
	%使用 Win32 API 操作内存映射文件
end
```
## +Lang
函数
```MATLAB
%为MATLAB安装补丁，修复已知bug
function BugList = BuiltinBugFix(Command,RestartDisposition)
%收集无法返回的过程值
function Value = Capture(Value,Receiver,Property)
%使得当前MATLAB进程崩溃
function Crash
%根据验证函数将输入的Varargin分发到输出变量
function varargout = DistributeVararginByValidation(Varargin,ValidationFun,DefaultFun)
%获取函数的第N个输出
function varargout = GetNthOutputs(Function,OutputIndices)
%内置input函数的增强版，取消适用场合限制
function X = Input(varargin)
```
类
```MATLAB
classdef IEnumerableException
	%可枚举异常，提供一种方便的异常接口类
end
classdef MException
	%内置MException的扩展，支持更灵活的构造和额外的Detail属性
end
classdef Optional
	%一个值的句柄容器，可选为空。
end
classdef Owner
	%为句柄对象指定一个所有者，托管其生命周期
end
classdef Referable
	%为值创建引用源，然后可以创建同步更改的引用
end
```
## +Ops
```MATLAB
%内置ismember的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [IsIn,Location] = IsMemberN(Target,Source,Dimension)
%维度化的逻辑赋值
function Array = LogicalAssign(Array,Logical,Value)
%内置setdiff的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [Diff,IA] = SetDiffN(SetA,SetB,Dimension)
%内置union的升级版，支持任意数组类型，并可以指定拆分维度，missing类值视为相等的有效数据，还能同时合并多个集合
function USet = UnionN(Dimension,varargin)
%内置unique的升级版，支持任意数组和表格类型，并可以指定拆分维度，missing类值视为相等的有效数据
function [Set,InputIndex,UniqueIndex] = UniqueN(Set,varargin)
```
## Project
```MATLAB
%为Windows添加.prj文件扩展名关联
function AssociatePrjExtension
%列出指定工程所添加的搜索路径
function ProjectPaths = ListAllProjectPaths(Project)
```
## +RandFun
```MATLAB
%生成任意概率分布密度的随机数
function varargout = RandAnyDist(PDF,Size,Range)
%生成单位球面上均匀分布的随机点
function [X,Y,Z] = RandOnSphere(varargin)
%洗牌算法，支持设定最大连续重复数
function [Array,CountCache] = Shuffle(Array,options)
```
## +SpecFun
```MATLAB
%计算椭圆周长
function P = EllipticPerimeter(a,b)
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

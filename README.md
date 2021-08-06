埃博拉酱的MATLAB数据操纵工具包，提供一系列MATLAB内置函数所欠缺，但却常用的增强功能

本项目的发布版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)规范。开发者认为这是一个优秀的规范，并向每一位开发者推荐遵守此规范。
# 目录
本包中所有函数均在命名空间下，使用前需import。使用命名空间是一个好习惯，可以有效防止命名冲突，避免编码时不必要的代码提示干扰。
- [+MATLAB](#MATLAB)
	- [+Addons](#Addons) 本包用于开发人员管理发布包，以及用户查询包依赖项。
		- [GetRequirements](#GetRequirements) 获取包中包含的依赖项列表
		- [PublishRequirements](#PublishRequirements) 在包目录下生成一个依赖项.mat文件
	- [+DataFun](#DataFun)
		- [MaxSubs](#MaxSubs) 返回数组的最大值以及所在的坐标。
	- [+DataTypes](#DataTypes)
		- [@ArrayBuilder](#ArrayBuilder) 数组累加器类
		- [RepeatingFun](#RepeatingFun) 重复多次调用函数，为每个重复参数生成一个返回值
     - [+ElMat](#ElMat)
          - [OrderedDimensionSize2IndexArray](#OrderedDimensionSize2IndexArray) 根据维度顺序和尺寸，生成自定义的下标转线性索引数组
          - [OrderedDimensionSize2SubsVectors](#OrderedDimensionSize2SubsVectors) 根据维度顺序和尺寸，生成自定义的线性索引转下标向量
     - [+General](#General)
          - [StaticJavaPath](#StaticJavaPath) 确认Java路径已添加到静态路径列表
     - [+ImageSci](#ImageSci)
          - [@OmeTiff](#OmeTiff) 支持XYCTZ五维索引的OME标准Tiff增强库
          - [SetLastDirectory](#SetLastDirectory) 跳转到最后一个IFD，并且返回该IFD的序号。
	- [+IOFun](#IOFun)
		- [MatVariableRename](#MatVariableRename) 批量重命名.mat文件中的变量
          - [XmlDom2String](#XmlDom2String) 将org.w3c.dom.Document导出为XML字符串
          - [XmlString2Dom](#XmlString2Dom) 将XML字符串解析为org.w3c.dom.Document类型
	- [+UITools](#UITools)
		- [OpenFileDialog](#OpenFileDialog) 可以设置初始目录，以及保存上次所在目录的文件打开对话框
- [+MatlabShared](#MatlabShared)
	- [+SupportPkg](#SupportPkg) 一键获取MATLAB硬件支持包
		- [ClearCache](#ClearCache) 清除缓存的下载器文件
		- [InstallSupportPackages](#InstallSupportPackages) 安装下载好的支持包
		- [SupportPackageDownloader](#SupportPackageDownloader) 下载支持包下载器
# +MATLAB
## +Addons
本包用于开发人员管理发布包，以及用户查询包依赖项。
### 依赖版本结构体
要使用本包中的依赖版本管理工具，你的包目录下必须有一个Version函数，返回依赖版本结构体。

依赖版本结构体包含一个Me字段，存储本包的版本号。其它字段则为所有依赖包的包名。如果依赖包名有点号分割，则表示为点索引的次级结构体。例如你开发的包A.B版本1.0.0，依赖包C.D版本1.1.0、包C.E-2.2.0和包F-1.3.0，则你应当撰写一个A.B.Version函数，返回含有如下字段的结构体：
- Me(1,1)string="1.0.0"，本包的版本号
- C(1,1)struct，依赖包C.D和C.E共用的顶级限定名，为一个结构体，包含如下字段：
	- D(1,1)struct，至少包含一个字段Me(1,1)string="1.1.0"，为包C.D的版本号。也可以继续包含C.D自身的其它依赖项。可以在包C.D中也包含一个同构的Version函数，实现递归调用。
	- E(1,1)struct，类似于C.D依赖项，C.E也有一个Me字段为版本号"2.2.0"
- F(1,1)struct，至少包含一个字段Me(1,1)string="1.3.0"

A.B.Version函数代码示例：
```MATLAB
function V=Version
V.Me="1.0.0";
%假定这些依赖包也都包含Version函数，则可以进行递归调用
V.C.D=C.D.Version;
V.C.E=C.E.Version;
V.F=F.Version;
%假设还依赖一个包G不包含Version函数，则必须手动输入
V.G.Me="1.3.0";
```
### GetRequirements
获取包中包含的依赖项列表

如果包目录下有一个依赖项.mat文件，本函数将载入那个文件并将其中的RequirementTable返回。该文件记录了包发布时所有依赖项的版本信息。可由[PublishRequirements](#PublishRequirements)生成。

输入参数：PackageName(1,1)string，要查看依赖信息的包名，默认本包（EbolaChan.MatlabExtension）

返回值：RequirementTable(:,2)table，第1列Package，第2列Version，列出该包发布时所有依赖项和版本
### PublishRequirements
在包目录下生成一个依赖项.mat文件

本函数用于包开发人员。当包下含有返回[依赖版本结构体](#依赖版本结构体)的Version函数时，可以用本函数在同目录下生成一个"依赖项.mat"，保存版本依赖结构体的所有一级依赖项的当前版本。这样当你的包发布给用户后，用户可以用[GetRequirements](#GetRequirements)得到你的包发布时所有依赖项的版本，然后逐一下载安装所有的依赖项。

输入参数：PackageName(1,1)string，你的包名，需要在该包下包含Version函数，返回版本依赖结构体

返回值：RequirementTable(:,2)table，第1列Package，第2列Version，列出该包发布时所有依赖项和版本
## +DataFun
### MaxSubs
返回数组的最大值以及所在的坐标。

MATLAB自带的max函数只能返回多维数组最大值的线性索引。本函数一口气返回最大值以及多维坐标，方便易用
```MATLAB
%对于有多个最大值的数组，返回线性索引最小的那个位置的坐标：
[M,S1,S2]=MATLAB.DataFun.MaxSubs([9 9 1;1 4 4;9 8 9])
%{
M =

     9


S1 =

     1


S2 =

     1
%}
%还可以指定运算维度。如将一个3维数组的后两维求最大值和下标，则返回的最大值和下标都是沿第1维的向量，且只返回最大值在后两维的下标
[M,S2,S3]=MATLAB.DataFun.MaxSubs(rand(3,3,3),[2 3]);
```

**位置参数**

Data，必需，要寻找最大值的多维数组

Dimensions(1,:)uint8，可选，要取最大值的维度。返回值在这些维度上长度将为1，在其它维度上排列最大值。默认所有维度都参与运算，即返回单一标量作为整个数组的最大值。**请按从小到大顺序排列这些维度**，本函数不会检查。不按顺序排列的维度值将产生意外结果。

**返回值**

Value(1,1)，最大值

[S1,S2, …, Sn]，最大值所在的位置中，线性索引最小的那个位置的坐标。每个返回值依次代表各维度的坐标。只包含Dimensions维度的坐标。
## +DataTypes
### @ArrayBuilder
数组累加器类

将数据向内存中积累时，经常遇到需要不断累加数组的问题，MATLAB会提示预分配内存。但如果读取之前无法得知将会有多少项，预分配就会变成一个十分麻烦的动态任务。本类建立一个增长维度，在此维度上可以不断累加一个内置的数组。用户只需不断Append即可，无需考虑内存分配的问题，本类会自动进行优化的内存管理。
```MATLAB
%构造一个沿第1维度累加的数组
Ab=MATLAB.DataTypes.ArrayBuilder(1);
%重复累加
for a=1:3
  Ab.Append(randi([0 9],randi([0 3]),3));
end
Ab.Harvest
%继续累加
for a=1:3
  Ab.Append(randi([0 9],randi([0 3]),3));
end
Ab.Harvest
%{
ans =

     8     3     4
     8     2     9
     0     8     1
     1     1     8
     5     8     3
     1     6     5


ans =

     8     3     4
     8     2     9
     0     8     1
     1     1     8
     5     8     3
     1     6     5
     0     2     1
     //数据随机生成，每次运行可能不同
%}
```

构造参数：BuildDimension(1,1)uint8=1，累加维度。数组的这个维度将不断累加增长，其它维度将由第一次Append决定，以后不再改变。

**只读属性**

BuildDimension(1,1)uint8，累加维度

**成员方法**

`Append`

向数组累加新内容

输入参数：New，要累加的内容。第一次可以累加任意内容，以后累加内容可以和第一次在累加维度上尺寸不一致，其它维度必须尺寸一致。

`Harvest`

收获累加完毕的MATLAB数组。收获后可以释放本对象，也可以继续累加。

返回值：Array，累加完毕的MATLAB数组。

`Clear`

清空储藏，从零开始重新累加，而不必新建对象重新分配内存，具有较高的性能。
### RepeatingFun
重复多次调用函数，为每个重复参数生成一个返回值
```MATLAB
[One,Two,Three]=MATLAB.DataTypes.RepeatingFun(@zeros,1,2,3)
%{
One =

     0


Two =

     0     0
     0     0


Three =

     0     0     0
     0     0     0
     0     0     0
%}
```
**输入参数**

Function(1,1)function_handle，必需，要调用的函数句柄

Arguments，重复，每次调用的输入参数

**返回值**

varargout，每个重复输入的参数按顺序生成的返回值
## +ElMat
### OrderedDimensionSize2IndexArray
根据实际维度顺序和尺寸，生成自定义的下标转线性索引数组

一个数组的维度顺序可以用permute轻易调整。但当这个数组以非标准格式线性排列存储于巨大文件中时，你可能无法将这个文件整个读入内存再操作，而是只能将你的标准下标转换为线性索引，然后访问文件的特定部分。

本函数生成一个数组。你可以用标准下标顺序访问这个数组的元素得到文件的线性索引，并且可以适应不同的维度顺序。

本函数生成的线性索引数组实际上类似于[OrderedDimensionSize2SubsVectors](#OrderedDimensionSize2SubsVectors)的反向操作符，即将下表转换为线性索引。但本函数不是它的反函数，因为参数列表完全相同，而且同样支持自定义维度顺序。

现假设有一个数据集存储了五维图像数据，分别为宽度（X轴）、高度（Y轴）、多通道（C轴）、多深度（Z轴）、多时间点（T轴）。像素值在文件中是线性排列的，但文件头中定义了各轴的排列顺序和各轴尺寸：
```MATLAB
%% 示例1
Fid=fopen('示例数据.bin','r');
%读入维度顺序。这个维度顺序由XYCZT五个字符的排列来描述。例如YXTZC,YTZXC,都是可能的维度顺序。维度顺序的表示法是Little-endian的，即较低的维度在前，较高维度在后。
ActualOrder=fread(Fid,5,'char=>char')
%读入各维尺寸
DimensionSize=fread(Fid,5,'uint8=>uint8');
%文件中的维度顺序是运行时才知道的，编码时无从得知。为了方便后续处理，我们需要将维度顺序化归一致。这里使用YXCTZ作为标准维度顺序。
IndexArray=MATLAB.ElMat.OrderedDimensionSize2IndexArray(DimensionSize,false,ArbitraryOrder='YXCTZ',ActualOrder=ActualOrder);
%读入数据主体：
Data=fread(Fid,Inf,'uint8=>uint8');
%假设现在我们要取Y=1,X=2,C=3,T=4,Z=5处的数据，则可以：
Data(IndexArray(1,2,3,4,5))
%IndexArray将你的下标转换为文件数据的线性索引。这种转换仅仅是一个数组索引操作，具有较高的性能。
%本例中IndexArray和Data占据相同的内存，这是因为Data的维度顺序是完全未知的。实际上对于图像数据，前两维往往都是YX。在这个知识的帮助下，我们可以缩减IndexArray的尺寸：
Data=reshape(Data,DimensionSize(1),DimensionSize(2),[]);
IndexArray=MATLAB.ElMat.OrderedDimensionSize2IndexArray(DimensionSize(3:5),false,ArbitraryOrder='CTZ',ActualOrder=ActualOrder(3:5));
%已知前两维是YX，那么只有后三维未知，需要进行索引转换。于是假设现在我们要取C=3,T=2,Z=1处的图像帧：
imshow(Data(:,:,IndexArray(3,2,1)));
fclose(Fid);
%% 示例2
% 另一种情况是，虽然维度顺序是未知的，但各维尺寸对应的维度是已知的，而并非对应着文件中未知的维度顺序。
function GetData(Data,ActualOrder,SizeC,SizeT,SizeZ,C,T,Z)
arguments
	Data(:,:,:)uint8
	ActualOrder(1,3)char
	SizeC(1,1)uint8
	SizeT(1,1)uint8
	SizeZ(1,1)uint8
	C(1,1)uint8
	T(1,1)uint8
	Z(1,1)uint8
end
%本例中数据集实际维度顺序仍然未知，由用户输入决定；但是用户并未给出对应实际维度顺序的各维尺寸，而是作为具有实际意义的变量输入，即各维尺寸对应的维度是已知的：你只能按照一个任意的顺序将这些尺寸进行排列。
IndexArray=MATLAB.ElMat.OrderedDimensionSize2IndexArray([SizeC,SizeT,SizeZ],true,ArbitraryOrder='CTZ',ActualOrder=ActualDimensionOrder);
%注意到第2个参数使用了true，表示各维尺寸是按照编码时任意指定的顺序，而非ActualOrder排列的。这样得到的IndexArray仍然能按照上例相同的方法使用：
imshow(Data(:,:,IndexArray(C,T,Z)));
end
```
上述示例中，生成的索引数组只被使用了少数次数，相比于计算该数组的开销来说，性能上是不划算的，不如直接简单用ismember重排下标，再用sub2ind转线性索引。但如果索引取值操作需要被大量重复使用，提前计算出一个索引数组性能较高，相当于两次索引解决问题，远快于每次调用这些具有复杂逻辑的函数。

**位置参数**

DimensionSize(1,:)uint32，必需，各维度尺寸

DSOrderArbitrary(1,1)logical=true，可选，DimonsionSize的排列顺序是否是任意指定的。若true，表示DimensionSize的维度顺序以ArbitraryOrder为准；否则以ActualOrder为准。

**名称值参数**

以下两个参数若仅指定其一，则必须为数值向量；否则可以为任意类型：

ActualOrder(1,:)=1:numel(DimensionSize)，源数组实际的维度顺序。数组元素是任意的，只要每个元素在ArbitraryOrder中也都有出现即可。

ArbitraryOrder(1,:)=1:numel(DimensionSize)，希望得到的索引矩阵的维度顺序。数组元素是任意的，只要每个元素在ActualOrder中也都有出现即可。

**返回值**

ActualIndexArrayByWantSubs uint32，线性索引数组。用下标定位该数组中的某些元素后，这些元素就对应着源数组在该下标处的线性索引。
### OrderedDimensionSize2SubsVectors
根据维度顺序和尺寸，生成自定义的线性索引转下标向量

一个数组的维度顺序可以用permute轻易调整。但当这个数组以非标准格式线性排列存储于巨大文件中时，你可能无法将这个文件整个读入内存再操作，而是只能将线性索引转换为有意义的下标，然后再做下标特定的操作。

本函数为每个下标维度生成一个向量。例如生成X Y Z三个维度向量，则X向量在位置I处的值表示线性索引I对应的X下标。这类似于ind2sub，但ind2sub不能假定线性索引是完全按顺序排列的，所以要付出一些性能代价，此外也不支持维度重排。

本函数生成的下标向量实际上类似于OrderedDimensionSize2IndexArray的反向操作符，即将线性索引转换为下标。但本函数不是它的反函数，因为参数列表完全相同，而且同样支持自定义维度顺序。示例在[那个函数的文档](#OrderedDimensionSize2IndexArray)中。

**位置参数**

DimensionSize(1,:)uint32，必需，各维度尺寸

DSOrderArbitrary(1,1)logical=true，可选，DimonsionSize的排列顺序是否是任意指定的。若true，表示DimensionSize的维度顺序以ArbitraryOrder为准；否则以ActualOrder为准。

**名称值参数**

以下两个参数若仅指定其一，则必须为数值向量；否则可以为任意类型：

ActualOrder(1,:)=1:numel(DimensionSize)，源数组实际的维度顺序。数组元素是任意的，只要每个元素在ArbitraryOrder中也都有出现即可。

ArbitraryOrder(1,:)=1:numel(DimensionSize)，希望得到的索引矩阵的维度顺序。数组元素是任意的，只要每个元素在ActualOrder中也都有出现即可。

**返回值**

\[S1,S2,S3, …\]\(1,:\)uint32，下标向量。例如Sk向量在位置I处的值，表示线性索引I对应的第k维下标。
## +General
### StaticJavaPath
确认Java路径已添加到静态路径列表

内置javaaddpath只能将Java路径添加到动态列表，因此每次运行程序都要重新添加。本函数能够遍历静态Java路径列表，检查是否存在指定的Java路径；若不存在，则添加之。

注意，静态添加的Java路径必须重启MATLAB以后才能生效

输入参数：Path(1,1)string，要确认的Java路径

返回值：Exist(1,1)logical，Java路径是否在调用本函数之前就已存在于静态列表中。注意，存在于静态列表中并不意味着MATLAB已经加载了它。例如运行本函数两次，第2次必定返回true，但新添加的路径仍然必须重启MATLAB才能生效。
## +ImageSci
### @OmeTiff
支持XYCTZ五维索引的OME标准Tiff增强库，继承于Tiff基类。请先参阅Tiff基类的文档`doc Tiff`。此处只列出本类新增的方法以及重写的方法。

五个维度的实际意义是：X，图像宽度；Y，图像高度；C，颜色通道；T，采样时点；Z，图像纵深

**依赖属性**

依赖属性的读写都不是简单的单变量读写，而是实际上调用了具有一定开销的函数，所以请尽量缓存依赖属性的值，避免频繁访问。

SizeX(1,1)uint16，图像宽度

SizeY(1,1)uint16，图像高度

SizeC(1,1)uint16，颜色通道数

SizeT(1,1)uint16，采样时点数

SizeZ(1,1)uint16，图像纵深

DimensionOrder(1,3)char，IFD排列的维度顺序。IFD是严格线性排列的。要实现高维操作，就必须规定一个维度顺序。XY轴是单个IFD内部固定的，不能修改；可变的只有CTZ三个维度的顺序。默认C最低，Z最高。修改该属性将改变成员方法`Read5D`和`Write5D`对图像序列的reshape/permute方式，对已经存在的IFD序列没有影响。

PixelType(1,:)char，像素值的数据类型，默认'uint16'

**构造函数**

构造函数的参数列表和基类Tiff完全相同，请参考基类Tiff的构造函数文档。但需注意，如果要读取现有文件，只能读取OmeTiff文件，不能读取一般的Tiff文件。但反过来，基类Tiff可以正确识别OmeTiff，仅仅是丢失高维度信息而已。对于一般Tiff，可以通过本类下的`Transcode`静态方法转换为OmeTiff。

**成员方法**

`close`

此方法重写基类，但参数列表完全相同，功能也基本一样，请参阅`doc Tiff.close`。如果您修改了OmeTiff文件，请务必使用此函数正确关闭，否则可能导致文件损坏。

`GetDefaultTagStruct`

获取默认的标签结构体，用于在写入每个IFD时传递给`setTag`方法。详见`doc Tiff.setTag`和`doc Tiff.write`

建议使用成员方法`Write5D`取代基类的`write`方法，可以无需指定标签结构体。

返回值：TagStruct(1,1)struct，默认的标签结构体，包含图像高宽、像素类型等基类Tiff所需要的信息。

`Read5D`

从OmeTiff中读出五维图像数据
```MATLAB
Reader=MATLAB.ImageSci.OmeTiff('示例OmeTiff.tif');
%一次性读完所有图像数据，返回五维数组
Reader.Read5D;
%可以指定读取范围：
Reader.Read5D(X=1:3,C=[5 1],T=2)
%上述代码读取通道[5 1]在时间点2处的所有Z层数据，并裁剪X轴只剩1:3，返回尺寸为(:,3,2,1,:)的五维数组
```
此函数将改变当前IFD。如果您依赖当前IFD工作，请在调用之前用一个变量保存当前IFD，调用后再设回去。

*必需参数*

obj(1,1)MATLAB.ImageSci.OmeTiff，类对象

*名称值参数*

Y(1,:)uint16，Y轴截取范围。若不指定，则不作裁剪全部读取。

X(1,:)uint16，X轴截取范围。若不指定，则不作裁剪全部读取。

C(1,:)uint16，C轴截取范围。若不指定，则不作裁剪全部读取。

T(1,:)uint16，T轴截取范围。若不指定，则不作裁剪全部读取。

Z(1,:)uint16，Z轴截取范围。若不指定，则不作裁剪全部读取。

*返回值*

Image(:,:,:,:,:)，图像数据。无论文件的维度顺序为何，Image的维度顺序总是YXCTZ。无论文件的数据类型是几位，Image总是会将其cast为PixelType的设定值。

`SetLastDirectory`

跳转到最后一个IFD，并且返回该IFD的序号。

这里的最后一个IFD是在文件中实际存在的IFD，而不是简单计算SizeC\*SizeT\*SizeZ。

标准Tiff库不提供直接跳转最后一个IFD的方法。这是Tiff文件格式设计之初就固有的缺陷：IFD之间类似于链表的关系，无法从文件头中读到文件尾的位置信息，因此只能逐个遍历。但如果在MATLAB端循环调用nextDirectory并检查lastDirectory，开销较大。比较优化的做法是使用setDirectory，在库内部完成遍历过程，因此需要对IFD数目进行高效的“猜测”。本函数采用精心设计的log2跳转算法寻找最后一个IFD，比循环调用nextDirectory直到lastDirectory为true的方法性能更高。

输入参数：obj(1,1)MATLAB.ImageSci.OmeTiff，类对象

返回值：LastDirectory(1,1)double，最后一个IFD的序号

`setTag`

此方法重写基类，但参数列表完全相同，功能也基本一样，请参阅`doc Tiff.setTag`。唯一需要注意的是，第1个IFD的ImageDescription标签被用于存储重要的元数据信息，请勿手动修改，除非您知道自己在做什么。

`Write5D`

向OmeTiff中写入五维图像数据
```MATLAB
Writer=MATLAB.ImageSci.OmeTiff('示例OmeTiff.tif','w8');
%先设置必要的基本参数
Writer.DimensionOrder='CTZ';
Writer.PixelType='uint16';
Writer.SizeX=5;
Writer.SizeY=5;
Writer.SizeC=5;
Writer.SizeT=5;
%最高维度是Z，支持自动扩展，因此这里可以设为0
Writer.SizeZ=0;
Image=randi(65535,[5 5 5 5 5],'uint16');
%一次性写入所有图像数据
Writer.Write5D(Image);
%可以指定写入范围：
Writer.Write5D(Image,Z=6:10,Y=5:-1:1);
%上述代码将沿Y轴翻转的图像写入第6:10Z层
%下面展示一些错误用法。这些错误用法不一定会中断代码执行，但可能造成文件损坏。
Writer.Write5D(Image,C=4:8);
%上述代码错误，因为C不是最高维度，无法自动扩展，因此指定的C轴范围不能超过SizeC属性设定的上限。如您需要扩展C轴，必须新建一个空白文件，将C轴设为最高维度。
Writer.Write5D(Image(:,:,1:3,:,:),C=1:3,Z=11:15);
%上述代码错误，因为当前Z轴长度为10，指定了11:15，虽然支持自动扩展，但自动扩展要求其它维度必须完全覆盖（可以调整顺序）。此处C轴只截取了1:3，没有完全覆盖，因此是错误用法。
Writer.Write5D(Image(1:3,:,:,:,:),X=1:3);
%上述代码错误，因为指定了X轴范围1:3，而X轴是第2维；Image的维度顺序总是YXCTZ，因此Y轴尺寸1:3。指定的范围和Image尺寸不一致。
%完成写入后务必正确关闭，否则可能损坏文件。
Writer.close;
```
此函数将改变当前IFD。如果您依赖当前IFD工作，请在调用之前用一个变量保存当前IFD，调用后再设回去。

请注意，Tiff文件基础格式要求图像帧之间必须严格紧凑地线性排列；OME规范则要求所有图像帧必须具有相同的高宽。因此您不能在过于靠后的位置写入，以至于和已有数据之间出现空隙；全新增添的图像帧数据必须完整覆盖要求的高宽尺寸方块，不能有像素遗漏不写入，否则将损坏文件。除了最高维度以外，其它维度也不支持扩展。扩展其它维度必须新建OmeTiff文件，并在写入任何数据之前指定好所有非可扩展维度的尺寸。

*位置参数*

obj(1,1)MATLAB.ImageSci.OmeTiff，必需，类对象

Image(:,:,:,:,:)，必需，要写入的图像数据。维度顺序总是YXCTZ，无论文件中定义的顺序为何。数组尺寸必须与名称值参数设置的范围匹配。数据类型必须与PixelType属性和文件中实际数据类型匹配。出于性能考虑，本函数不会对这些要求进行任何检查。错误的参数可能造成程序执行中断或文件损坏。

TagStruct(1,1)struct=obj.GetDefaultTagStruct，可选，Tiff标签结构体，包含Tiff库要求的基本标签参数。一般无需设置本参数，保持默认即可。

*名称值参数*

名称值参数指定数据写入位置。写入位置不能超过非可扩展维度的尺寸范围。默认全部按照Image的尺寸写在每个维度的较低端。原有数据将被覆盖。最高维度可自动扩展，因此可以给最高维度指定大于上限的位置（但最低位置和上限之间不能留空）。当发生扩展时，所有非扩展维度必须全部覆盖写入完整的数据，即数据尺寸恰好等于那个维度的长度，否则可能会损坏文件。

Y(1,:)uint16=1:size(Image,1)，Y轴写入位置。此向量长度必须等于Image第1维长度，即numel(X)==size(Image,1)。

X(1,:)uint16=1:size(Image,2)，X轴写入位置。此向量长度必须等于Image第2维长度，即numel(Y)==size(Image,2)。

C(1,:)uint16=1:size(Image,3)，C轴写入位置。此向量长度必须等于Image第3维长度，即numel(C)==size(Image,3)。

T(1,:)uint16=1:size(Image,4)，T轴写入位置。此向量长度必须等于Image第4维长度，即numel(T)==size(Image,4)。

Z(1,:)uint16=1:size(Image,5)，Z轴写入位置。此向量长度必须等于Image第5维长度，即numel(Z)==size(Image,5)。

**静态方法**

`Concatenate`

沿指定维度串联多个OmeTiff文件
```MATLAB
%以下写法均合法，且含义相同：
MATLAB.ImageSci.OmeTiff.Concatenate('Output.tif','Z','File1.tif','File2.tif','File3.tif');
MATLAB.ImageSci.OmeTiff.Concatenate('Output.tif',5,["File1.tif","File2.tif","File3.tif"]);
MATLAB.ImageSci.OmeTiff.Concatenate('Output.tif','Z',{'File1.tif','File2.tif','File3.tif'});
```
本函数将指定的多个OmeTiff文件沿指定维度串联起来。这些OmeTiff文件必须在串联维度以外的维度具有完全相同的尺寸和相同的像素类型。生成的新文件将输出到指定位置。新文件的维度顺序由第1个输入文件决定

*输入参数*

OutputFile(1,1)string，必需，输出文件的路径

Dimension(1,1)，必需，串联维度，可以是维度编号（按照YXCTZ的顺序），也可以是维度字符（YXCTZ中的一个）

InputFile，依次输入所有要串联的文件路径，或者把它们组合成数组。第1个文件将决定输出文件的维度顺序。

`Transcode`

将一般Tiff文件转码为OmeTiff，或者强制修改原OmeTiff的维度信息

OmeTiff是一种特殊的Tiff格式。使用Tiff基类库可以读写OmeTiff，但是会丢失维度信息；然而OmeTiff类不能用于读写一般Tiff，因为文件中缺少必要的维度信息。因此需要使用本函数先将一般Tiff转码为OmeTiff，并补充必要的维度信息。
```MATLAB
%将一般Tiff文件Tiff.tif原地转码为OmeTiff。源文件的维度顺序是TZC，输出时使用默认的维度顺序CTZ。SizeC和SizeZ已知，SizeT自动计算
Transcode('TZC','Tiff.tif',SizeC=2,SizeZ=5);
%打开文件选择对话框让用户手动选择要转码的文件
Transcode('TZC',SizeC=2,SizeZ=5);
%转码到一个新文件OmeTiff.tif。源文件维度顺序是CTZ，但希望新文件采用TZC的维度顺序；SizeC和SizeT已知，SizeZ自动计算
TransCode('CTZ',To='OmeTiff.tif',ToDimension='TZC',SizeC=2,SizeT=100);
```
上述示例代码并不要求Tiff.tif只能是一般Tiff而不能是OmeTiff。因此本函数亦可用于将OmeTiff进行reshape、permute等操作。

为了提高性能，请考虑如下优化建议：

1. 原地转码，即From和To相同
2. 不改变维度顺序，即FromDimensionOrder和ToDimensionOrder相同
3. 如果您无需遍历文件就能得知IFD数目，请完全指定SizeC SizeT SizeZ三个参数，避免自动计算时程序不得不遍历整个文件

如果这三条建议都能做到，那么程序将只会直接修改ImageDescription，具有最高的性能。

*位置参数*

FromDimensionOrder(1,3)char，必需，源文件的维度顺序，如'CTZ', 'TZC'等

From(1,1)string，可选，源文件的路径。默认打开文件选择对话框要求用户手动选择。

*名称值参数*

ToDimensionOrder(1,3)char='CTZ'，转码后的维度顺序。如果和FromDimension相同，将省去图像序列重排的步骤，提高性能。

To(1,1)string=From，目标文件的路径。如果和From相同，将直接覆盖原文件。如果DimensionOrder也相同，将只修改ImageDescription。

SizeC(1,1)uint16，颜色通道数。

SizeT(1,1)uint16，采样时点数。

SizeZ(1,1)uint16，图像纵深。

SizeC SizeT SizeZ，至少指定其中两个，第三个可以自动计算得出，但这需要遍历整个文件得到IFD总数，性能较低。因此如您有更高性能的信息来源可以直接得到IFD总数，请自行计算出这三个维度并提供给本函数，以便提高性能。
### SetLastDirectory
跳转到最后一个IFD，并且返回该IFD的序号。

标准Tiff库不提供直接跳转最后一个IFD的方法。这是Tiff文件格式设计之初就固有的缺陷：IFD之间类似于链表的关系，无法从文件头中读到文件尾的位置信息，因此只能逐个遍历。但如果在MATLAB端循环调用nextDirectory并检查lastDirectory，开销较大。比较优化的做法是使用setDirectory，在库内部完成遍历过程，因此需要对IFD数目进行高效的“猜测”。本函数采用精心设计的log2跳转算法寻找最后一个IFD，比循环调用nextDirectory直到lastDirectory为true的方法性能更高。

输入参数：TiffClient(1,1)Tiff

返回值：LastDirectory(1,1)double，最后一个IFD的序号
## +IOFun
### MatVariableRename
批量重命名.mat文件中的变量
```MATLAB
%使用文件选择对话框选择所有要重命名变量的.mat文件，将其中所有具有OldNamesRow字符串行向量中任一字符串名称的变量，重命名为NewNamesRow字符串行向量中对应位置的字符串
MATLAB.IOFun.MatVariableRename(OldNamesRow,NewNamesRow);
```

**位置参数**

OldNames(1,:)string，必需，要修改的变量名。如果.mat文件中不含某个变量名，将不会出错，而会忽略。

NewNames(1,:)string，必需，要改为的变量名。不能少于OldNames，不能有重复的名称。

MatPaths(1,:)string，可选，要重命名的.mat文件路径。默认打开文件选择对话框要求用户手动选择。
### XmlDom2String
将org.w3c.dom.Document导出为XML字符串

MATLAB自带xmlwrite函数只能将XML写出到文件，而不能生成内存中的XML文本，本函数弥补了这项功能缺陷。要求的输入org.w3c.dom.Document是一个Java对象，可以轻松实现对XML的增删改查，详见[Java文档](https://docs.oracle.com/javase/8/docs/api/org/w3c/dom/Document.html)。

本函数是[XmlString2Dom](#XmlString2Dom)的反函数。

输入参数：XmlDom(1,1)org.w3c.dom.Document，XML文档对象模型

返回值：XmlString(1,1)string，XML文本
### XmlString2Dom
将XML字符串解析为org.w3c.dom.Document类型

MATLAB自带xmlread函数只能读取XML文件，而不能解析内存中的字符串，本函数弥补了这项功能缺陷。返回的org.w3c.dom.Document是一个Java对象，可以轻松实现对XML的增删改查，详见[Java文档](https://docs.oracle.com/javase/8/docs/api/org/w3c/dom/Document.html)。

本函数是[XmlDom2String](#XmlDom2String)的反函数。

输入参数：XmlString(1,1)string，XML文本

返回值：XmlDom(1,1)org.w3c.dom.Document，XML解析结果
## +UITools
### OpenFileDialog
可以设置初始目录，以及保存上次所在目录的文件打开对话框

MATLAB自带的uigetfile只能将初始目录设为当前目录，且下次打开时不能自动恢复到上次打开的目录，十分不便。本函数调用System.Windows.Forms.OpenFileDialog解决了这一问题。一个常见用法，就是将需要输入文件路径的函数的默认值设为该函数的返回值：
```MATLAB
function [Filename,fps,Name,nrd_c,raw_data,raw_tag] = MTRM_Rdc3(TagThreshold,options)
arguments
	TagThreshold(1,1)uint16=550
	options.MTPaths(:,1)string=MATLAB.UITools.OpenFileDialog(Filter="MetaTags文件|*.MetaTags.mat",Title="选择MetaTags文件",Multiselect=true)
	options.RMPaths(:,1)string=MATLAB.UITools.OpenFileDialog(Filter="Measurements文件|*.Measurements.mat",Title="选择Measurements文件",Multiselect=true)
end
%函数体……
```

**名称-值对组参数**

*Filter*

(1,1)string，文件名筛选器。

对于每个筛选选项，筛选器字符串都包含筛选器的说明，后跟竖线和筛选器模式。 不同筛选选项的字符串用竖线分隔。

下面是筛选器字符串的示例：
```
Text files (*.txt)|*.txt|All files (*.*)|*.*
```
可以通过用分号分隔文件类型将多个筛选模式添加到筛选器，例如：
```
Image Files(*.BMP;*.JPG;*.GIF)|*.BMP;*.JPG;*.GIF|All files (*.*)|*.*
```

*InitialDirectory*

(1,1)string，文件对话框中显示的初始目录

*Multiselect*

(1,1)logical。如果对话框允许同时选定多个文件，则为 true；反之，则为 false。 默认值为 false。

*Title*

(1,1)string，文件对话框标题。该字符串放置在对话框的标题栏中。 如果标题为空字符串，则系统将使用默认标题，即 "另存为" 或 "打开"。

**返回值**

FilePaths(1,:)string，包含对话框中所有选定文件的绝对路径。如果未选择任何文件，则返回一个1×0字符串数组。
# +MatlabShared
## +SupportPkg
一键获取MATLAB硬件支持包。最简单的使用方法：`edit MATLAB.SupportPkg.Demo`，按照提示一节一节运行，即可完成安装。

如需在不联网的其它计算机上安装，请先在联网计算机上运行[SupportPackageDownloader](#SupportPackageDownloader)，将下载的支持包安装文件复制到目标计算机上，然后在目标计算机上运行[InstallSupportPackages](#InstallSupportPackages)。

以下是各函数详细说明。
### ClearCache
清除缓存的下载器文件

执行本函数将清除[SupportPackageDownloader](#SupportPackageDownloader)下载的下载器文件，释放空间。

输入参数：CacheDirectory(1,1)string，默认为本函数所在目录下的Cache子目录
### InstallSupportPackages
安装下载好的支持包

下载器执行过程中会要求用户选择支持包的下载路径。将这个路径提供给本函数，即可执行安装。如果不提供路径，则会弹出一个选择文件夹窗口，要求用户选择下载路径。

**输入参数**

ArchivesDirectory(1,1)string，可选位置参数，支持包安装文件所在路径。如果不提供该参数，将弹出选择文件夹窗口要求用户手动选择。

MatlabRoot(1,1)string=matlabroot，名称-值对组参数，MATLAB安装目录。
### SupportPackageDownloader
下载支持包下载器。

MATLAB支持包需要先下载一个独立下载器才能下载。本函数根据平台和版本下载对应的下载器并可选执行下载。
```MATLAB
%为本机下载，无需指定任何参数
MatlabShared.SupportPkg.SupportPackageDownloader;
%为不同系统架构、不同MATLAB发行版本下载，需要指定目标架构、发行版本等。例如为Linux上的R2020b下载：
MatlabShared.SupportPkg.SupportPackageDownloader(false,"D:\SupportPackageDownloader","glnxa64",VersionRelease="2021b");
```
**可选位置参数**

RunAfterDownload(1,1)logical=true，下载后是否立即执行下载器

CacheDirectory(1,1)string，下载位置。默认在本函数目录的Cache子目录下。

ComputerArch(1,1)string{mustBeMember(ComputerArch,["win64" "glnxa64" "maci64"])}=computer("arch")，目标操作系统架构

**名称-值对组参数**

VersionRelease(1,1)string=version('-release')，目标MATLAB发行版本
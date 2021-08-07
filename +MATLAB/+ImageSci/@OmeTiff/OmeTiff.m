classdef OmeTiff<Tiff
	% 支持XYCTZ五维索引的OME标准Tiff增强库，继承于Tiff基类。请先参阅Tiff基类的文档。
	% 五个维度的实际意义是：X，图像宽度；Y，图像高度；C，颜色通道；T，采样时点；Z，图像纵深
	properties(Access=private)
		Image(1,1)
		Pixels(1,1)
		UUID(1,:)char
		IFDProjection(:,:,:)double
		IPNeedUpdate(1,1)logical=true
		DimensionNeedUpdate(1,1)logical=false
		Name(1,1)string
		TDTemplate(1,1)
	end
	properties(SetAccess=private)
		% 存储图像元数据的org.w3c.dom.Document对象。
		% 除非您需要访问未列在依赖属性中的特殊元数据，否则应当直接访问依赖属性而不是访问它。
		% 另一个应用场景是，您可能需要将该图像的元数据完整拷贝到新文件中。此时您可以将该属性作为新文件构造函数的ImageDescription参数输入。
		ImageDescription(1,1)
	end
	properties(Dependent)
		%图像宽度
		SizeX(1,1)uint16
		%图像高度
		SizeY(1,1)uint16
		%图像颜色通道数
		SizeC(1,1)uint16
		%图像采样时点数
		SizeT(1,1)uint16
		%图像深度
		SizeZ(1,1)uint16
		% IFD排列的维度顺序
		% IFD是严格线性排列的。要实现高维操作，就必须规定一个维度顺序。XY轴是单个IFD内部固定的，不能修改；可变的只有CTZ三个维度的顺序。默认C最低，Z最高。修改该属性将改变Read5D和Write5D对图像序列的reshape/permute方式，对已经存在的IFD序列没有影响。
		DimensionOrder(1,3)char
		%像素值的数据类型，默认'uint16'
		PixelType(1,:)char
	end
	methods(Access=private)
		function ResetID(obj)
			obj.ImageDescription=MATLAB.IOFun.XmlString2Dom(obj.getTag('ImageDescription'));
			OME=obj.ImageDescription.getElementsByTagName('OME').item(0);
			obj.UUID=OME.getAttribute('UUID');
			obj.Image=OME.getElementsByTagName('Image').item(0);
			obj.Pixels=obj.Image.getElementsByTagName('Pixels').item(0);
			obj.IPNeedUpdate=true;
		end
	end
	methods
		function obj = OmeTiff(FilePath,Mode,options)
			% 构造函数，不完全兼容基类
			%% 可选位置参数
			% FilePath(1,1)string，文件路径。默认打开文件选择对话框要求用户手动选择。请注意，如果要读取现有文件，只能读取OmeTiff文件，不能读取一般的Tiff文件。但反过来，基类Tiff可以正确识别OmeTiff，仅仅是丢失高维度信息而已。对于一般Tiff，可以通过本类下的Transcode静态方法转换为OmeTiff。
			% Mode(1,1)string="r"，打开模式。"r"：只读；"w"：写入不大于4㎇的数据；"w8"：写入大于4㎇的数据；"r+"：读写现有数据。注意，基类Tiff还支持"a"选项，但OmeTiff不支持，因为OmeTiff格式要求在文件头包含文件尾信息，因此不可能在不修改文件头的情况下追加数据。
			%% 名称值参数
			% Mode(1,1)string，同可选位置参数Mode。当您不想指定FilePath但需要指定Mode时，可以使用此名称值参数。如果同时指定位置参数和名称值参数的Mode，将以名称值参数为准。
			% ImageDescription，OmeXml元数据。可以指定为org.w3c.dom.Document对象，也可以是XML文本。仅当Mode指定为"w"或"w8"时才有效。该元数据将被直接写入文件。通常用于将其它文件中的元数据拷贝到新文件。文件名信息将会自动更正。
			arguments
				FilePath(1,1)string=MATLAB.UITools.OpenFileDialog(Filter='OmeTiff文件|*.tif',Title='选择要打开的OmeTiff')
				Mode(1,1)string="r"
				options.Mode(1,1)string
				options.ImageDescription
			end
			if isfield(options,'Mode')
				Mode=options.Mode;
			end
			[~,Filename,Extension]=fileparts(FilePath);
			obj@Tiff(FilePath,Mode);
			obj.Name=Filename+Extension;
			if ismember(Mode,["w" "w8"])
				if isfield(options,'ImageDescription')
					if isa(options.ImageDescription,'org.w3c.dom.Document')
						obj.ImageDescription=options.ImageDescription;
					else
						obj.ImageDescription=MATLAB.IOFun.XmlString2Dom(options.ImageDescription);
					end
				else
					obj.ImageDescription=xmlread(fullfile(fileparts(mfilename("fullpath")),'初始ID.xml'));
				end
				OME=obj.ImageDescription.getElementsByTagName('OME').item(0);
				obj.UUID=['urn:uuid:' char(java.util.UUID.randomUUID)];
				OME.setAttribute('UUID',obj.UUID);
				obj.Image=OME.getElementsByTagName('Image').item(0);
				obj.Image.setAttribute('Name',obj.Name);
				obj.Pixels=obj.Image.getElementsByTagName('Pixels').item(0);
				UUIDs=obj.Pixels.getElementsByTagName('UUID');
				for a=0:UUIDs.getLength-1
					Node=UUIDs.item(a);
					Node.setAttribute('FileName',obj.Name);
					Node.setTextContent(obj.UUID);
				end
			else
				obj.ResetID;
				Sample=obj.read;
				if obj.Pixels.getAttribute('SizeX').isEmpty
					obj.SizeX=size(Sample,2);
				end
				if obj.Pixels.getAttribute('SizeY').isEmpty
					obj.SizeY=size(Sample,1);
				end
			end
			TD=obj.ImageDescription.createElement('TiffData');
			TD.setAttribute('PlaneCount','1');
			U=obj.ImageDescription.createElement('UUID');
			U.setAttribute('FileName',obj.Name);
			U.setTextContent(obj.UUID);
			TD.appendChild(U);
			obj.TDTemplate=TD;
		end
		function setTag(obj,varargin)
			% 此方法已被重写，参数列表和基类Tiff完全相同。
			% 请注意，第1个IFD的ImageDescription标签被用于存储重要的元数据信息，请勿手动修改，除非您知道自己在做什么。
			obj.setTag@Tiff(varargin{:});
			if obj.currentDirectory==1
				TagID=varargin{1};
				if isstruct(TagID)&&isfield(TagID,'ImageDescription')||isnumeric(TagID)&&TagID==Tiff.TagID.ImageDescription||strcmp(TagID,'ImageDescription')
					obj.ResetID;
				end
			end
		end
		function SizeX=get.SizeX(obj)
			SizeX=str2double(obj.Pixels.getAttribute('SizeX'));
		end
		function SizeY=get.SizeY(obj)
			SizeY=str2double(obj.Pixels.getAttribute('SizeY'));
		end
		function SizeC=get.SizeC(obj)
			SizeC=str2double(obj.Pixels.getAttribute('SizeC'));
		end
		function SizeT=get.SizeT(obj)
			SizeT=str2double(obj.Pixels.getAttribute('SizeT'));
		end
		function SizeZ=get.SizeZ(obj)
			SizeZ=str2double(obj.Pixels.getAttribute('SizeZ'));
		end
		function DimensionOrder=get.DimensionOrder(obj)
			DimensionOrder=char(obj.Pixels.getAttribute('DimensionOrder'));
			DimensionOrder=DimensionOrder(3:5);
		end
		function Type=get.PixelType(obj)
			Type=char(obj.Pixels.getAttribute('Type'));
		end
		function set.SizeX(obj,SizeX)
			obj.Pixels.setAttribute('SizeX',string(SizeX));
		end
		function set.SizeY(obj,SizeY)
			obj.Pixels.setAttribute('SizeY',string(SizeY));
		end
		function set.SizeC(obj,SizeC)
			obj.Pixels.setAttribute('SizeC',string(SizeC));
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.SizeT(obj,SizeT)
			obj.Pixels.setAttribute('SizeT',string(SizeT));
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.SizeZ(obj,SizeZ)
			obj.Pixels.setAttribute('SizeZ',string(SizeZ));
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.DimensionOrder(obj,DimensionOrder)
			obj.Pixels.setAttribute('DimensionOrder',['XY' DimensionOrder]);
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.PixelType(obj,Type)
			obj.Pixels.setAttribute('Type',Type);
		end
		function TagStruct=GetDefaultTagStruct(obj)
			% 获取默认的标签结构体，用于在写入每个IFD时传递给setTag方法。
			% 建议使用Write5D取代基类的write方法，可以无需指定标签结构体。
			persistent TSTemplate
			if isempty(TSTemplate)
				TSTemplate=struct("Photometric",Tiff.Photometric.MinIsBlack,"Compression",Tiff.Compression.None,"PlanarConfiguration",Tiff.PlanarConfiguration.Chunky,'BitsPerSample',str2double(extract(obj.PixelType,digitsPattern)),"SamplesPerPixel",1);
			end
			TagStruct=TSTemplate;
			TagStruct.ImageWidth=obj.SizeX;
			TagStruct.ImageLength=obj.SizeY;
		end
	end
	methods(Static)
		Concatenate(OutputFile,Dimension,varargin)
		Transcode(From,FromDimensionOrder,options)
		Rename(From,To)
	end
end
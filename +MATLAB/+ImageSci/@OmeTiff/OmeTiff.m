classdef OmeTiff<Tiff
    % 支持XYCTZ五维索引的OME标准Tiff增强库，继承于Tiff基类。请先参阅Tiff基类的文档。
	% 五个维度的实际意义是：X，图像宽度；Y，图像高度；C，颜色通道；T，采样时点；Z，图像纵深
	properties(Access=private)
		ImageDescriptionDom(1,1)
		Image(1,1)
		Pixels(1,1)
		UUID(1,:)char
		IFDProjection(:,:,:)uint16
		IPNeedUpdate(1,1)logical=true
		DimensionNeedUpdate(1,1)logical=false
		Name(1,1)string
		TDTemplate(1,1)
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
			obj.ImageDescriptionDom=MATLAB.IOFun.XmlString2Dom(obj.getTag('ImageDescription'));
			obj.UUID=obj.OME.getAttribute('UUID');
			obj.Image=obj.OME.getElementsByTagName('Image').item(0);
			obj.Pixels=obj.Image.getElementsByTagName('Pixels').item(0);
			obj.IPNeedUpdate=true;
		end
	end
	methods
		function obj = OmeTiff(varargin)
			%构造函数的参数列表和基类Tiff完全相同，请参考基类Tiff的构造函数文档。
			[~,Filename,Extension]=fileparts(varargin{1});
			FileExist=exist(Filename,'file');
			obj@Tiff(varargin{:});
			obj.Name=Filename+Extension;
			if FileExist
				obj.ResetID;
			else
				obj.ImageDescriptionDom=MATLAB.IOFun.XmlString2Dom(fileread(fullfile(fileparts(mfilename("fullpath")),'初始ID.xml')));
				OME=obj.ImageDescriptionDom.getElementsByTagName('OME').item(0);
				obj.UUID=['urn:uuid:' char(java.util.UUID.randomUUID)];
				OME.setAttribute('UUID',obj.UUID);
				Image=OME.getElementsByTagName('Image').item(0);
				obj.Image=Image;
				Image.setAttribute('Name',obj.Name);
				obj.Pixels=Image.getElementsByTagName('Pixels').item(0);
			end
			TD=obj.ImageDescriptionDom.createElement('TiffData');
			TD.setAttribute('PlaneCount',1);
			U=obj.ImageDescriptionDom.createElement('UUID');
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
			DimensionOrder=obj.Pixels.getAttribute('DimensionOrder');
			DimensionOrder=DimensionOrder(3:5);
		end
		function Type=get.PixelType(obj)
			Type=obj.Pixels.getAttribute('Type');
		end
		function set.SizeX(obj,SizeX)
			obj.Pixels.setAttribute('SizeX',SizeX);
		end
		function set.SizeY(obj,SizeY)
			obj.Pixels.setAttribute('SizeY',SizeY);
		end
		function set.SizeC(obj,SizeC)
			obj.Pixels.setAttribute('SizeC',SizeC);
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.SizeT(obj,SizeT)
			obj.Pixels.setAttribute('SizeT',SizeT);
			obj.IPNeedUpdate=true;
			obj.DimensionNeedUpdate=true;
		end
		function set.SizeZ(obj,SizeZ)
			obj.Pixels.setAttribute('SizeZ',SizeZ);
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
		Concatenate(OutputFile,Dimension,InputFile)
		Transcode(From,FromDimensionOrder,options)
	end
end
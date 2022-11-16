classdef NDComplex
	%N维复数
	%本类暂时作为预发布测试版，请勿在生产环境中使用
	properties
		%第1维是2^n元数，后面是数组维度
		Data
	end
	methods(Static,Access=private)
		function Data=ToNAry(Data)
			if isa(Data,'MATLAB.ElFun.NDComplex')
				Data=Data.Data;
			else
				Data=shiftdim(Data,-1);
				if ~isreal(Data)
					Data=[real(Data);imag(Data)];
				end
			end
		end
		function varargout=NAryNormalize(varargin)
			varargin=cellfun(@MATLAB.ElFun.ToNAry,varargin,UniformOutput=false);
			NumElements=max(cellfun(@height,varargin));
			varargout=varargin;
			for V=1:nargout
				varargout{V}(end+1:NumElements,:)=0;
			end
		end
	end
	methods(Access=private)
		function obj = NDComplex(Data)
			obj.Data=Data;
		end
	end
	methods(Static)
		function obj=Parse(Data)
			obj=MATLAB.ElFun.NDComplex(MATLAB.ElFun.NDComplex.ToNAry(Data));
		end
	end
	methods
		function S=size(obj)
			S=size(obj.Data);
			S(1)=[];
		end
		function obj=times(Left,Right)
			import MATLAB.ElFun.NDComplex
			[Left,Right]=NDComplex.NAryNormalize(Left,Right);
			Sizes=size(Left);
			NumElements=Sizes(1);
			Sizes(1)=[];
			LeftIndex=0:NumElements-1;
			RightIndex=bitxor(LeftIndex(:),LeftIndex);
			obj=NDComplex(pagemtimes(reshape((-1).^sum(cumsum(dec2bin(LeftIndex)=='1',2,'reverse').*dec2bin(bitand(LeftIndex,RightIndex))=='1',2).*Right(RightIndex(:),:),[NumElements,NumElements,Sizes]),reshape(Left,NumElements,1,Sizes)));
		end
		function obj=abs(obj)
			obj=shiftdim(vecnorm(obj.Data,2,1));
		end
		function obj=conj(obj)
			obj.Data(2:end,:)=-obj.Data(2:end,:);
		end
		function obj=rdivide(Left,Right)
			if isreal(Right)
				obj=MATLAB.ElFun.NDComplex(Left.Data./Right);
			else
				obj=Left.*conj(Right)./abs(Right);
			end
		end
		function obj=plus(Left,Right)
			[Left,Right]=MATLAB.ElFun.NDComplex.NAryNormalize(Left,Right);
			obj=MATLAB.ElFun.NDComplex(Left+Right);
		end
		function obj=minus(Left,Right)
			[Left,Right]=MATLAB.ElFun.NDComplex.NAryNormalize(Left,Right);
			obj=MATLAB.ElFun.NDComplex(Left-Right);
		end
		function R=real(obj)
			Subs=repmat({':'},1,obj.ndims);
			R=shiftdim(obj.Data(1,Subs{:}));
		end
		function N=ndims(obj)
			N=ndims(obj.Data)-1;
		end
		function I=imag(obj)
			Subs=repmat({':'},1,obj.ndims);
			I=obj.Data(2:end,Subs{:});
		end
		function C=complex(obj)
			Subs=repmat({':'},1,obj.ndims);
			Real=shiftdim(obj.Data(1,Subs{:}));
			Imag=shiftdim(obj.Data(2,Subs{:}));
			C=complex(Real,Imag);
		end
	end
end
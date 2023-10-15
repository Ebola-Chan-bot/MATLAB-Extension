classdef ReferenceBase
	properties(Access=protected)
		Referable
	end
	methods(Static,Access=protected)
		function Args=ArgsDeref(Args)
			for A=1:numel(Args)
				if isa(Args{A},'MATLAB.internal.ReferenceBase')
					Args{A}=Args{A}.Referable.Value;
				end
			end
		end
	end
	methods
		function obj = ReferenceBase(Referable)
			obj.Referable=Referable;
		end
		function display(obj)
			InputName=inputname(1);
			eval(sprintf('%s=obj.Referable.Value;display(%s);',InputName,InputName));
		end
		function Index=end(obj,IndexDimension,NumIndices)
			Index=repmat("1",1,NumIndices);
			Optional=MATLAB.Lang.Optional;
			Index(IndexDimension)="MATLAB.Lang.Capture(end,Optional)";
			eval(sprintf('obj.Referable.Value(%s);',join(Index,',')));
			Index=Optional.Value;
		end
		function varargout=isa(obj,Type,varargin)
			if Type=="MATLAB.internal.ReferenceBase"
				varargout={true};
			else
				varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
				[varargout{1:nargout}]=isa(obj.Referable.Value,Type,varargin{:});
			end
		end
		function obj=subsasgn(obj,varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			obj.Referable.Value=subsasgn(obj.Referable.Value,varargin{:});
		end
		function varargout=colstyle(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=colstyle(varargin{:});
		end
		function varargout=class(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=class(varargin{:});
		end
		function varargout=ischar(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ischar(varargin{:});
		end
		function varargout=isempty(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=isempty(varargin{:});
		end
		function varargout=metaclass(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=metaclass(varargin{:});
		end
		function varargout=methods(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=methods(varargin{:});
		end
		function varargout=methodsview(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=methodsview(varargin{:});
		end
		function varargout=numArgumentsFromSubscript(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=numArgumentsFromSubscript(varargin{:});
		end
		function varargout=properties(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=properties(varargin{:});
		end
		function varargout=size(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=size(varargin{:});
		end
		function varargout=subsref(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=subsref(varargin{:});
		end
		function varargout=superclasses(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=superclasses(varargin{:});
		end
		function varargout=underlyingType(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=underlyingType(varargin{:});
		end
		function varargout=Inf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=Inf(varargin{:});
		end
		function varargout=NaN(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=NaN(varargin{:});
		end
		function varargout=angle(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=angle(varargin{:});
		end
		function varargout=applylut(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=applylut(varargin{:});
		end
		function varargout=arrayfun(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=arrayfun(varargin{:});
		end
		function varargout=assert(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=assert(varargin{:});
		end
		function varargout=bandwidth(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bandwidth(varargin{:});
		end
		function varargout=beta(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=beta(varargin{:});
		end
		function varargout=betaln(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=betaln(varargin{:});
		end
		function varargout=bicg(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bicg(varargin{:});
		end
		function varargout=bicgstab(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bicgstab(varargin{:});
		end
		function varargout=bicgstabl(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bicgstabl(varargin{:});
		end
		function varargout=binocdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=binocdf(varargin{:});
		end
		function varargout=binopdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=binopdf(varargin{:});
		end
		function varargout=bwdist(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bwdist(varargin{:});
		end
		function varargout=bwlabel(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bwlabel(varargin{:});
		end
		function varargout=bwlookup(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bwlookup(varargin{:});
		end
		function varargout=bwmorph(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=bwmorph(varargin{:});
		end
		function varargout=cast(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cast(varargin{:});
		end
		function varargout=cat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cat(varargin{:});
		end
		function varargout=cdf2rdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cdf2rdf(varargin{:});
		end
		function varargout=cgs(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cgs(varargin{:});
		end
		function varargout=cond(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cond(varargin{:});
		end
		function varargout=condest(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=condest(varargin{:});
		end
		function varargout=conv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=conv(varargin{:});
		end
		function varargout=convn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=convn(varargin{:});
		end
		function varargout=corr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=corr(varargin{:});
		end
		function varargout=corr2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=corr2(varargin{:});
		end
		function varargout=corrcoef(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=corrcoef(varargin{:});
		end
		function varargout=cot(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cot(varargin{:});
		end
		function varargout=cotd(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cotd(varargin{:});
		end
		function varargout=coth(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=coth(varargin{:});
		end
		function varargout=cov(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cov(varargin{:});
		end
		function varargout=csc(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=csc(varargin{:});
		end
		function varargout=cscd(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cscd(varargin{:});
		end
		function varargout=csch(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=csch(varargin{:});
		end
		function varargout=deconv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=deconv(varargin{:});
		end
		function varargout=deg2rad(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=deg2rad(varargin{:});
		end
		function varargout=del2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=del2(varargin{:});
		end
		function varargout=detectFASTFeatures(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=detectFASTFeatures(varargin{:});
		end
		function varargout=detectHarrisFeatures(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=detectHarrisFeatures(varargin{:});
		end
		function varargout=detrend(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=detrend(varargin{:});
		end
		function varargout=discretize(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=discretize(varargin{:});
		end
		function varargout=disp(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=disp(varargin{:});
		end
		function varargout=disparityBM(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=disparityBM(varargin{:});
		end
		function varargout=disparitySGM(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=disparitySGM(varargin{:});
		end
		function varargout=dot(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=dot(varargin{:});
		end
		function varargout=edge(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=edge(varargin{:});
		end
		function varargout=existsOnGPU(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=existsOnGPU(varargin{:});
		end
		function varargout=expint(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=expint(varargin{:});
		end
		function varargout=expm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=expm(varargin{:});
		end
		function varargout=eye(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=eye(varargin{:});
		end
		function varargout=factorial(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=factorial(varargin{:});
		end
		function varargout=false(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=false(varargin{:});
		end
		function varargout=fft2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fft2(varargin{:});
		end
		function varargout=fillmissing(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fillmissing(varargin{:});
		end
		function varargout=filter2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=filter2(varargin{:});
		end
		function varargout=fitcecoc(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitcecoc(varargin{:});
		end
		function varargout=fitcensemble(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitcensemble(varargin{:});
		end
		function varargout=fitcknn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitcknn(varargin{:});
		end
		function varargout=fitcsvm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitcsvm(varargin{:});
		end
		function varargout=fitctree(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitctree(varargin{:});
		end
		function varargout=fitdist(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitdist(varargin{:});
		end
		function varargout=fitensemble(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitensemble(varargin{:});
		end
		function varargout=fitglm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitglm(varargin{:});
		end
		function varargout=fitlm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitlm(varargin{:});
		end
		function varargout=fitrensemble(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitrensemble(varargin{:});
		end
		function varargout=fitrsvm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitrsvm(varargin{:});
		end
		function varargout=fitrtree(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fitrtree(varargin{:});
		end
		function varargout=flipdim(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=flipdim(varargin{:});
		end
		function varargout=fliplr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fliplr(varargin{:});
		end
		function varargout=flipud(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=flipud(varargin{:});
		end
		function varargout=fpdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fpdf(varargin{:});
		end
		function varargout=fprintf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=fprintf(varargin{:});
		end
		function varargout=freqspace(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=freqspace(varargin{:});
		end
		function varargout=gampdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gampdf(varargin{:});
		end
		function varargout=gather(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gather(varargin{:});
		end
		function varargout=gevcdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gevcdf(varargin{:});
		end
		function varargout=gevinv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gevinv(varargin{:});
		end
		function varargout=gevpdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gevpdf(varargin{:});
		end
		function varargout=gevstat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gevstat(varargin{:});
		end
		function varargout=glmfit(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=glmfit(varargin{:});
		end
		function varargout=gmres(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gmres(varargin{:});
		end
		function varargout=gpcdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gpcdf(varargin{:});
		end
		function varargout=gpinv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gpinv(varargin{:});
		end
		function varargout=gppdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gppdf(varargin{:});
		end
		function varargout=gpstat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gpstat(varargin{:});
		end
		function varargout=gpuArray(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gpuArray(varargin{:});
		end
		function varargout=gradient(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gradient(varargin{:});
		end
		function varargout=gray2ind(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=gray2ind(varargin{:});
		end
		function varargout=griddedInterpolant(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=griddedInterpolant(varargin{:});
		end
		function varargout=head(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=head(varargin{:});
		end
		function varargout=height(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=height(varargin{:});
		end
		function varargout=histc(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=histc(varargin{:});
		end
		function varargout=histcounts(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=histcounts(varargin{:});
		end
		function varargout=histeq(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=histeq(varargin{:});
		end
		function varargout=horzcat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=horzcat(varargin{:});
		end
		function varargout=hygecdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=hygecdf(varargin{:});
		end
		function varargout=hygepdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=hygepdf(varargin{:});
		end
		function varargout=idivide(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=idivide(varargin{:});
		end
		function varargout=ifft2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ifft2(varargin{:});
		end
		function varargout=im2double(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=im2double(varargin{:});
		end
		function varargout=im2int16(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=im2int16(varargin{:});
		end
		function varargout=im2single(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=im2single(varargin{:});
		end
		function varargout=im2uint16(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=im2uint16(varargin{:});
		end
		function varargout=im2uint8(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=im2uint8(varargin{:});
		end
		function varargout=imabsdiff(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imabsdiff(varargin{:});
		end
		function varargout=imadjust(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imadjust(varargin{:});
		end
		function varargout=imadjustn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imadjustn(varargin{:});
		end
		function varargout=imbothat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imbothat(varargin{:});
		end
		function varargout=imclose(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imclose(varargin{:});
		end
		function varargout=imcomplement(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imcomplement(varargin{:});
		end
		function varargout=imcrop(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imcrop(varargin{:});
		end
		function varargout=imdilate(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imdilate(varargin{:});
		end
		function varargout=imerode(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imerode(varargin{:});
		end
		function varargout=imfill(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imfill(varargin{:});
		end
		function varargout=imfilter(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imfilter(varargin{:});
		end
		function varargout=imgaussfilt(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imgaussfilt(varargin{:});
		end
		function varargout=imgaussfilt3(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imgaussfilt3(varargin{:});
		end
		function varargout=imgradient(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imgradient(varargin{:});
		end
		function varargout=imgradientxy(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imgradientxy(varargin{:});
		end
		function varargout=imhist(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imhist(varargin{:});
		end
		function varargout=imlincomb(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imlincomb(varargin{:});
		end
		function varargout=imnoise(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imnoise(varargin{:});
		end
		function varargout=imopen(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imopen(varargin{:});
		end
		function varargout=imreconstruct(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imreconstruct(varargin{:});
		end
		function varargout=imregdemons(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imregdemons(varargin{:});
		end
		function varargout=imregionalmax(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imregionalmax(varargin{:});
		end
		function varargout=imregionalmin(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imregionalmin(varargin{:});
		end
		function varargout=imresize(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imresize(varargin{:});
		end
		function varargout=imrotate(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imrotate(varargin{:});
		end
		function varargout=imrotate_old(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imrotate_old(varargin{:});
		end
		function varargout=imtophat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imtophat(varargin{:});
		end
		function varargout=imwarp(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imwarp(varargin{:});
		end
		function varargout=imwrite(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=imwrite(varargin{:});
		end
		function varargout=ind2rgb(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ind2rgb(varargin{:});
		end
		function varargout=ind2sub(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ind2sub(varargin{:});
		end
		function varargout=inpolygon(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=inpolygon(varargin{:});
		end
		function varargout=int2str(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=int2str(varargin{:});
		end
		function varargout=integral(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=integral(varargin{:});
		end
		function varargout=interp1(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=interp1(varargin{:});
		end
		function varargout=interp2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=interp2(varargin{:});
		end
		function varargout=interp3(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=interp3(varargin{:});
		end
		function varargout=interpn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=interpn(varargin{:});
		end
		function varargout=intersect(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=intersect(varargin{:});
		end
		function varargout=ipermute(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ipermute(varargin{:});
		end
		function varargout=iradon(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=iradon(varargin{:});
		end
		function varargout=isUnderlyingType(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=isUnderlyingType(varargin{:});
		end
		function varargout=isbanded(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=isbanded(varargin{:});
		end
		function varargout=isgpuarray(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=isgpuarray(varargin{:});
		end
		function varargout=ishermitian(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ishermitian(varargin{:});
		end
		function varargout=islocalmax(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=islocalmax(varargin{:});
		end
		function varargout=islocalmin(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=islocalmin(varargin{:});
		end
		function varargout=ismember(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ismember(varargin{:});
		end
		function varargout=ismembertol(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ismembertol(varargin{:});
		end
		function varargout=ismissing(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ismissing(varargin{:});
		end
		function varargout=isoutlier(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=isoutlier(varargin{:});
		end
		function varargout=issymmetric(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=issymmetric(varargin{:});
		end
		function varargout=kmeans(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=kmeans(varargin{:});
		end
		function varargout=knnsearch(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=knnsearch(varargin{:});
		end
		function varargout=legendre(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=legendre(varargin{:});
		end
		function varargout=linspace(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=linspace(varargin{:});
		end
		function varargout=logspace(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=logspace(varargin{:});
		end
		function varargout=lscov(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=lscov(varargin{:});
		end
		function varargout=lsqr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=lsqr(varargin{:});
		end
		function varargout=mat2gray(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mat2gray(varargin{:});
		end
		function varargout=mat2str(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mat2str(varargin{:});
		end
		function varargout=mean(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mean(varargin{:});
		end
		function varargout=medfilt2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=medfilt2(varargin{:});
		end
		function varargout=meshgrid(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=meshgrid(varargin{:});
		end
		function varargout=minres(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=minres(varargin{:});
		end
		function varargout=mode(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mode(varargin{:});
		end
		function varargout=movmad(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movmad(varargin{:});
		end
		function varargout=movmax(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movmax(varargin{:});
		end
		function varargout=movmean(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movmean(varargin{:});
		end
		function varargout=movmedian(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movmedian(varargin{:});
		end
		function varargout=movmin(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movmin(varargin{:});
		end
		function varargout=movprod(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movprod(varargin{:});
		end
		function varargout=movstd(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movstd(varargin{:});
		end
		function varargout=movsum(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movsum(varargin{:});
		end
		function varargout=movvar(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=movvar(varargin{:});
		end
		function varargout=mpower(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mpower(varargin{:});
		end
		function varargout=mustBeFinite(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBeFinite(varargin{:});
		end
		function varargout=mustBeInteger(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBeInteger(varargin{:});
		end
		function varargout=mustBeNonNan(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBeNonNan(varargin{:});
		end
		function varargout=mustBeNonnegative(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBeNonnegative(varargin{:});
		end
		function varargout=mustBeNonzero(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBeNonzero(varargin{:});
		end
		function varargout=mustBePositive(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=mustBePositive(varargin{:});
		end
		function varargout=nbincdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nbincdf(varargin{:});
		end
		function varargout=nbininv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nbininv(varargin{:});
		end
		function varargout=nbinpdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nbinpdf(varargin{:});
		end
		function varargout=nbinstat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nbinstat(varargin{:});
		end
		function varargout=ndgrid(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ndgrid(varargin{:});
		end
		function varargout=nextpow2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nextpow2(varargin{:});
		end
		function varargout=normest(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=normest(varargin{:});
		end
		function varargout=normxcorr2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=normxcorr2(varargin{:});
		end
		function varargout=nthroot(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=nthroot(varargin{:});
		end
		function varargout=null(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=null(varargin{:});
		end
		function varargout=num2str(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=num2str(varargin{:});
		end
		function varargout=ones(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ones(varargin{:});
		end
		function varargout=padarray(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=padarray(varargin{:});
		end
		function varargout=pagectranspose(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagectranspose(varargin{:});
		end
		function varargout=pagefun(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagefun(varargin{:});
		end
		function varargout=pageinv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pageinv(varargin{:});
		end
		function varargout=pagemldivide(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagemldivide(varargin{:});
		end
		function varargout=pagemrdivide(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagemrdivide(varargin{:});
		end
		function varargout=pagemtimes(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagemtimes(varargin{:});
		end
		function varargout=pagesvd(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagesvd(varargin{:});
		end
		function varargout=pagetranspose(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pagetranspose(varargin{:});
		end
		function varargout=pca(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pca(varargin{:});
		end
		function varargout=pcg(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pcg(varargin{:});
		end
		function varargout=pdist(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pdist(varargin{:});
		end
		function varargout=pdist2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pdist2(varargin{:});
		end
		function varargout=pinv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pinv(varargin{:});
		end
		function varargout=planerot(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=planerot(varargin{:});
		end
		function varargout=poly(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=poly(varargin{:});
		end
		function varargout=polyder(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=polyder(varargin{:});
		end
		function varargout=polyfit(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=polyfit(varargin{:});
		end
		function varargout=polyval(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=polyval(varargin{:});
		end
		function varargout=polyvalm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=polyvalm(varargin{:});
		end
		function varargout=qmr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=qmr(varargin{:});
		end
		function varargout=rad2deg(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rad2deg(varargin{:});
		end
		function varargout=radon(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=radon(varargin{:});
		end
		function varargout=rand(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rand(varargin{:});
		end
		function varargout=randg(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=randg(varargin{:});
		end
		function varargout=randi(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=randi(varargin{:});
		end
		function varargout=randn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=randn(varargin{:});
		end
		function varargout=randperm(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=randperm(varargin{:});
		end
		function varargout=randsample(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=randsample(varargin{:});
		end
		function varargout=reallog(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=reallog(varargin{:});
		end
		function varargout=realpow(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=realpow(varargin{:});
		end
		function varargout=realsqrt(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=realsqrt(varargin{:});
		end
		function varargout=regionprops(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=regionprops(varargin{:});
		end
		function varargout=regress(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=regress(varargin{:});
		end
		function varargout=rgb2gray(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rgb2gray(varargin{:});
		end
		function varargout=rgb2hsv(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rgb2hsv(varargin{:});
		end
		function varargout=rgb2ycbcr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rgb2ycbcr(varargin{:});
		end
		function varargout=rgbwide2ycbcr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rgbwide2ycbcr(varargin{:});
		end
		function varargout=rmmissing(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rmmissing(varargin{:});
		end
		function varargout=rmoutliers(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rmoutliers(varargin{:});
		end
		function varargout=roots(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=roots(varargin{:});
		end
		function varargout=rot90(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=rot90(varargin{:});
		end
		function varargout=sec(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sec(varargin{:});
		end
		function varargout=secd(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=secd(varargin{:});
		end
		function varargout=sech(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sech(varargin{:});
		end
		function varargout=selectStrongestBbox(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=selectStrongestBbox(varargin{:});
		end
		function varargout=selectStrongestBboxMulticlass(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=selectStrongestBboxMulticlass(varargin{:});
		end
		function varargout=setdiff(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=setdiff(varargin{:});
		end
		function varargout=setxor(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=setxor(varargin{:});
		end
		function varargout=shiftdim(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=shiftdim(varargin{:});
		end
		function varargout=sortrows(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sortrows(varargin{:});
		end
		function varargout=spdiags(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spdiags(varargin{:});
		end
		function varargout=speye(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=speye(varargin{:});
		end
		function varargout=spfun(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spfun(varargin{:});
		end
		function varargout=spline(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spline(varargin{:});
		end
		function varargout=spmdReduce(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spmdReduce(varargin{:});
		end
		function varargout=spmdSend(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spmdSend(varargin{:});
		end
		function varargout=spones(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=spones(varargin{:});
		end
		function varargout=sprand(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sprand(varargin{:});
		end
		function varargout=sprandn(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sprandn(varargin{:});
		end
		function varargout=sprandsym(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sprandsym(varargin{:});
		end
		function varargout=sprintf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sprintf(varargin{:});
		end
		function varargout=std2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=std2(varargin{:});
		end
		function varargout=stdfilt(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=stdfilt(varargin{:});
		end
		function varargout=stretchlim(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=stretchlim(varargin{:});
		end
		function varargout=sub2ind(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=sub2ind(varargin{:});
		end
		function varargout=subsindex(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=subsindex(varargin{:});
		end
		function varargout=svds(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=svds(varargin{:});
		end
		function varargout=swapbytes(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=swapbytes(varargin{:});
		end
		function varargout=symmlq(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=symmlq(varargin{:});
		end
		function varargout=tail(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=tail(varargin{:});
		end
		function varargout=tcdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=tcdf(varargin{:});
		end
		function varargout=tensorprod(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=tensorprod(varargin{:});
		end
		function varargout=tfqmr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=tfqmr(varargin{:});
		end
		function varargout=topkrows(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=topkrows(varargin{:});
		end
		function varargout=trace(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=trace(varargin{:});
		end
		function varargout=trapz(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=trapz(varargin{:});
		end
		function varargout=true(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=true(varargin{:});
		end
		function varargout=typecast(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=typecast(varargin{:});
		end
		function varargout=unifcdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=unifcdf(varargin{:});
		end
		function varargout=unifpdf(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=unifpdf(varargin{:});
		end
		function varargout=union(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=union(varargin{:});
		end
		function varargout=unique(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=unique(varargin{:});
		end
		function varargout=uniquetol(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=uniquetol(varargin{:});
		end
		function varargout=unwrap(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=unwrap(varargin{:});
		end
		function varargout=validateattributes(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=validateattributes(varargin{:});
		end
		function varargout=var(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=var(varargin{:});
		end
		function varargout=vertcat(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=vertcat(varargin{:});
		end
		function varargout=width(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=width(varargin{:});
		end
		function varargout=wiener2(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=wiener2(varargin{:});
		end
		function varargout=writematrix(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=writematrix(varargin{:});
		end
		function varargout=xcorr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=xcorr(varargin{:});
		end
		function varargout=ycbcr2rgb(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ycbcr2rgb(varargin{:});
		end
		function varargout=ycbcr2rgbwide(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=ycbcr2rgbwide(varargin{:});
		end
		function varargout=zeros(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=zeros(varargin{:});
		end
		function varargout=append(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=append(varargin{:});
		end
		function varargout=cellstr(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=cellstr(varargin{:});
		end
		function varargout=char(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=char(varargin{:});
		end
		function varargout=compose(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=compose(varargin{:});
		end
		function varargout=contains(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=contains(varargin{:});
		end
		function varargout=count(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=count(varargin{:});
		end
		function varargout=endsWith(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=endsWith(varargin{:});
		end
		function varargout=erase(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=erase(varargin{:});
		end
		function varargout=eraseBetween(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=eraseBetween(varargin{:});
		end
		function varargout=extract(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=extract(varargin{:});
		end
		function varargout=extractAfter(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=extractAfter(varargin{:});
		end
		function varargout=extractBefore(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=extractBefore(varargin{:});
		end
		function varargout=extractBetween(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=extractBetween(varargin{:});
		end
		function varargout=insertAfter(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=insertAfter(varargin{:});
		end
		function varargout=insertBefore(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=insertBefore(varargin{:});
		end
		function varargout=join(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=join(varargin{:});
		end
		function varargout=lower(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=lower(varargin{:});
		end
		function varargout=matches(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=matches(varargin{:});
		end
		function varargout=pad(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=pad(varargin{:});
		end
		function varargout=replace(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=replace(varargin{:});
		end
		function varargout=replaceBetween(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=replaceBetween(varargin{:});
		end
		function varargout=reverse(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=reverse(varargin{:});
		end
		function varargout=split(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=split(varargin{:});
		end
		function varargout=splitlines(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=splitlines(varargin{:});
		end
		function varargout=startsWith(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=startsWith(varargin{:});
		end
		function varargout=strip(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=strip(varargin{:});
		end
		function varargout=strlength(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=strlength(varargin{:});
		end
		function varargout=upper(varargin)
			varargin=MATLAB.internal.ReferenceBase.ArgsDeref(varargin);
			[varargout{1:nargout}]=upper(varargin{:});
		end
	end
end
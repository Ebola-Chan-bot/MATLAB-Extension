%[text] 为条形图、误差条或线图之间添加统计显著性标识
%[text] 此函数会自动优化线条和文本的位置。但是这种优化位置可能会因其它图形对象布局的更改而被破坏。如果遇到这种情况，可以使用PLineRetune重新优化位置。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [Lines,Texts]=MATLAB.Graphics.PLine(Descriptors);
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] load('+MATLAB\+Graphics\PLine.mat');
%[text] figure;
%[text] Bars=bar(ActiveLightRising{["MOp2/3","MOp5"],["NaiveLight","Transfer"],"Mean"});
%[text] colororder([1,0,1;0,0.5,0]);
%[text] MATLAB.Graphics.FigureAspectRatio(8,5,1/3);
%[text] Ax=gca;
%[text] Ax.Units='points';
%[text] hold on;
%[text] EBs=errorbar(vertcat(Bars.XEndPoints).',ActiveLightRising{["MOp2/3","MOp5"],["NaiveLight","Transfer"],"Mean"},[],ActiveLightRising{["MOp2/3","MOp5"],["NaiveLight","Transfer"],"Sem"},CapSize=Ax.Position(3)*Bars(1).GroupWidth*Bars(1).BarWidth/(numel(Bars)*diff(xlim)*2),Color='k',LineStyle='none');
%[text] xticks(1:2);
%[text] xticklabels(["Layer 2/3","Layer 5"]);
%[text] box off;
%[text] MATLAB.Graphics.PLine(table(EBs(1),EBs(end),1,2,"n.s.",'VariableNames',["ObjectA","ObjectB","IndexA","IndexB","Text"]));
%[text] xlabel(Layout,'Time from 💡(:)💧(|)');
%[text] ylim([0,diff(ylim)]);
%[text] ylabel('Rising time');
%[text] legend(Bars,["Naive","Transfer"],Location=MATLAB.Graphics.OptimizedLegendLocation(Bars));
%[text] ```
%[text] ![](text:image:59f8)
%[text] ## 输入参数
%[text] Descriptors tabular，一行一个标识，包含以下列：
%[text] - ObjectA(:,1)matlab.graphics.chart.primitive.Bar|matlab.graphics.chart.primitive.ErrorBar|matlab.graphics.primitive.Line|matlab.graphics.chart.primitive.Scatter，必需，参与显著性比较的其中一个图形对象。所有图形对象必须隶属于同一个坐标区，且坐标区的YAxis标尺数据类型必须支持算术运算（如数值类型、duration等）。
%[text] - IndexA(:,1)，可选，指示要取ObjectA中的第几个点。一个图形对象中可能有多个点，用此参数指示要取哪个参与比较。如果不指定此列或指定为0，将自动赋予默认值。
%[text] - ObjectB(:,1)，可选，参与显著性比较的另一个图形对象，必须与ObjectA是同一类型，且在同一个坐标区。如果不指定此列或指定为matlab.graphics.GraphicsPlaceholder，默认与ObjectA相同。
%[text] - IndexB(:,1)，可选，指示要取ObjectB中的第几个点。一个图形对象中可能有多个点，用此参数指示要取哪个参与比较。如果不指定此列或指定为0，将自动赋予默认值。
%[text] - Text(:,1)string，必需，要标识的文本
%[text] - ExtraOffset(:,1)，可选，手动指定额外的偏移量，单位是坐标值 \
%[text] 根据图形对象类型不同，对IndexA和IndexB赋予默认值的规则如下：
%[text] ### matlab.graphics.chart.primitive.Bar|matlab.graphics.chart.primitive.ErrorBar
%[text] 如果ObjectA和ObjectB相同：如果IndexA和IndexB均未指定，取第一和最后一点；否则报错。
%[text] 如果ObjectA和ObjectB不同：如果IndexA和IndexB指定其一，则另一个默认与指定值相同；否则报错。
%[text] ### matlab.graphics.primitive.Line
%[text] 如果ObjectA和ObjectB相同：如果IndexA和IndexB均未指定，取第一和最后一点；否则报错。
%[text] 如果ObjectA和ObjectB不同：
%[text] - 如果IndexA和IndexB均未指定，且YData是可求差的类型，则取两条线对应位置YData差异最大的点；否则报错。
%[text] - 如果IndexA和IndexB指定其一，则另一个默认与指定值相同 \
%[text] ### matlab.graphics.chart.primitive.Scatter
%[text] 如果ObjectA和ObjectB相同：如果IndexA和IndexB均未指定，XData只有2种不同的值，且YData是可以比较大小的类型，则取两种不同XData确定的子点集内，各自YData最大的点；否则报错。
%[text] 如果ObjectA和ObjectB不同：如果IndexA和IndexB指定其一，则另一个默认与指定值相同；否则报错。
%[text] ## 返回值
%[text] Lines(:,1)matlab.graphics.primitive.Line，返回标识线以便后期手动修改属性
%[text] Texts(:,1)matlab.graphics.primitive.Text，返回标识文本以便后期手动修改属性
%[text] **See also** [matlab.graphics.chart.primitive.Bar](<matlab:doc matlab.graphics.chart.primitive.Bar>) [matlab.graphics.chart.primitive.ErrorBar](<matlab:doc matlab.graphics.chart.primitive.ErrorBar>) [matlab.graphics.primitive.Line](<matlab:doc matlab.graphics.primitive.Line>) [matlab.graphics.chart.primitive.Scatter](<matlab:doc matlab.graphics.chart.primitive.Scatter>) [matlab.graphics.primitive.Text](<matlab:doc matlab.graphics.primitive.Text>) [MATLAB.Graphics.PLineRetune](<matlab:doc MATLAB.Graphics.PLineRetune>)
function [Lines,Texts]=PLine(Descriptors)
HasColumns=ismember(["ObjectB", "IndexA", "IndexB"], Descriptors.Properties.VariableNames);
if HasColumns(1)
	Logical=arrayfun(@(x)isa(x, 'matlab.graphics.GraphicsPlaceholder'), Descriptors.ObjectB);
	Descriptors.ObjectB(Logical)=Descriptors.ObjectA(Logical);
else
	Descriptors.ObjectB=Descriptors.ObjectA;
end
if ~HasColumns(2)
	Descriptors.IndexA(:)=0;
end
if ~HasColumns(3)
	Descriptors.IndexB(:)=0;
end
NumPLines=height(Descriptors);
[Lines,Texts]=deal(gobjects(NumPLines,1));
for D=1:NumPLines
	ObjectA=Descriptors.ObjectA(D);
	ObjectB=Descriptors.ObjectB(D);
	IndexA=Descriptors.IndexA(D);
	IndexB=Descriptors.IndexB(D);
	VerticalPLine=false;
	if ObjectA==ObjectB
		if isa(ObjectA,'matlab.graphics.chart.primitive.Bar')
			XData=ObjectA.XEndPoints;
			YData=ObjectA.YEndPoints;
		else
			XData=ObjectA.XData;
			YData=ObjectA.YData;
		end
		if IndexA==0
			if IndexB==0
				if isa(ObjectA,'matlab.graphics.chart.primitive.Scatter')
					[Group,XData]=findgroups(XData);
					if numel(XData)==2
						[MinKey,MaxKey]=bounds(YData);
						KeyPoints=[MinKey,MaxKey];
						[~,Index]=min(abs(KeyPoints));
						if KeyPoints(Index)<0
							MinMaxFun=@min;
						else
							MinMaxFun=@max;
						end
						YData=splitapply(MinMaxFun, YData, Group);
						Index=[];
					else
						MATLAB.Exception.Invalid_Descriptor.Throw({'无法确认单一Scatter集内的关键点';Descriptors(D,:)});
					end
				else
					Index=[1,numel(XData)];
				end
			else
				MATLAB.Exception.Invalid_Descriptor.Throw({'不允许为相同对象指定单一索引';Descriptors(D,:)});
			end
		else
			if IndexB==0
				MATLAB.Exception.Invalid_Descriptor.Throw({'不允许为相同对象指定单一索引';Descriptors(D,:)});
			else
				Index=[IndexA, IndexB];
			end
		end
		if ~isempty(Index)
			XData=XData(Index);
			YData=YData(Index);
		end
		if isa(ObjectA,'matlab.graphics.chart.primitive.ErrorBar')

			%无论有没有空，YPNData必须是(2,2)矩阵，且数据类型未必是数值，所以需要如下精心设计：
			if isempty(ObjectA.YNegativeDelta)
				YPNData(2,:)=ObjectA.YPositiveDelta(Index);
			else
				YPNData(2,:)=-ObjectA.YNegativeDelta(Index);
				YPNData=flipud(YPNData);
			end
			if~isempty(ObjectA.YPositiveDelta)
				YPNData(2,:)=ObjectA.YPositiveDelta(Index);
			end

			YData=YData+YPNData([2,4]-(YData<0));
		end
	else
		if isa(ObjectA,'matlab.graphics.chart.primitive.Bar')
			XData={ObjectA.XEndPoints, ObjectB.XEndPoints};
			YData={ObjectA.YEndPoints, ObjectB.YEndPoints};
		else
			XData={ObjectA.XData, ObjectB.XData};
			YData={ObjectA.YData, ObjectB.YData};
		end
		%误差棒区可能会重叠，所以不能给YData加上误差范围

		VerticalPLine=isa(ObjectA, 'matlab.graphics.primitive.Line');
		if IndexA==0
			if IndexB==0
				if VerticalPLine
					Length=min(cellfun(@numel,YData));
					[~,IndexA]=max(abs(YData{1}(1:Length)-YData{2}(1:Length)));
					IndexB=IndexA;
				else
					MATLAB.Exception.Invalid_Descriptor.Throw({'不同的非Line对象至少需要指定一个索引';Descriptors(D,:)});
				end
			else
				IndexA=IndexB;
			end
		else
			if IndexB==0
				IndexB=IndexA;
			end
		end
		XData=[XData{1}(IndexA), XData{2}(IndexB)];
		YData=[YData{1}(IndexA), YData{2}(IndexB)];
		if isa(ObjectA,'matlab.graphics.chart.primitive.ErrorBar')
			if XData(1)==XData(2)
				if YData(1)==YData(2)
					MATLAB.Exception.Invalid_Descriptor.Throw({'重合的点';Descriptors(D,:)});
				else
					YData=AddErrorBar(YData, ObjectA, ObjectB, IndexA, IndexB);
					VerticalPLine=true;
				end
			else
				if ObjectA.LineStyle=="none"
					if ~isempty(ObjectA.YNegativeDelta)
						YPNData(1,1)=-ObjectA.YNegativeDelta(IndexA);
					end
					if ~isempty(ObjectB.YNegativeDelta)
						YPNData(1,2)=-ObjectB.YNegativeDelta(IndexB);
					end
					if ~isempty(ObjectA.YPositiveDelta)
						YPNData(2,1)=ObjectA.YPositiveDelta(IndexA);
					end
					if ~isempty(ObjectB.YPositiveDelta)
						YPNData(2,2)=ObjectB.YPositiveDelta(IndexB);
					end
					YData=YData+YPNData([2,4]-(YData<0));
				else
					YData=AddErrorBar(YData, ObjectA, ObjectB, IndexA, IndexB);
					VerticalPLine=true;
				end
			end
		end
	end
	Ax=ObjectA.Parent;
	XRuler=Ax.XAxis;
	if VerticalPLine
		YData=YData/2+sum(YData)/4;
		hold(Ax,'on');
		Lines(D)=plot(Ax,XData,YData,'k');
		T=text(Ax,mean(XData),mean(YData),Descriptors.Text(D),HorizontalAlignment='left',VerticalAlignment='middle');
		if XData(1)~=XData(2)
			TextY(2)=T.Extent(2);
			TextY(1)=TextY(2)+T.Extent(4);
			T.Position(1)=ruler2num(max((num2ruler(TextY,Ax.YAxis)-YData(1))/(YData(2)-YData(1))*(XData(2)-XData(1))+XData(1)),XRuler);
		end
		Texts(D)=T;
	else
		Descriptors.XData(D,:)=XData;
		Descriptors.YData(D,:)=YData;
	end
end
if ~VerticalPLine
	XData=ruler2num(Descriptors.XData,XRuler);
	[Lower,Higher]=bounds(permute(XData,[3,4,1,2]),4);
	Logical=isbetween(XData,Lower,Higher);
	PNType=sum(Descriptors.YData<0,2);
	for D=1:NumPLines
		switch PNType(D)
			case 0
				MMFun=@max;
			case 1
				if min(ruler2num(Descriptors.YData(D,:),Descriptors.ObjectA(D).Parent.YAxis),[],2,ComparisonMethod='abs')<0
					MMFun=@min;
				else
					MMFun=@max;
				end
			case 2
				MMFun=@min;
		end
		Descriptors.FinalYData(D)=MMFun(Descriptors.YData(Logical(:,:,D)));
	end
	FinalYData=ylim;
	FinalYData=Descriptors.FinalYData+(FinalYData(2)-FinalYData(1))/10.*sign(Descriptors.FinalYData);
	hold(Ax,'on');
	Lines=plot(Ax,Descriptors.XData.',[FinalYData,FinalYData].','k');
	Logical=Descriptors.FinalYData<0;
	Texts(Logical)=text(Ax,mean(XData(Logical,:),2),FinalYData(Logical),Descriptors.Text(Logical),HorizontalAlignment='center',VerticalAlignment='bottom',AffectAutoLimits=true);
	Logical=~Logical;
	Texts(Logical)=text(Ax,mean(XData(Logical,:),2),FinalYData(Logical),Descriptors.Text(Logical),HorizontalAlignment='center',VerticalAlignment='top',AffectAutoLimits=true);
	Logical=Logical*2-1;
	Error=Inf;
	while true
		YLimA=ylim;
		for D=1:NumPLines
			Texts(D).Position(2)=ruler2num(Lines(D).YData(1),Lines(D).Parent.YAxis)+Texts(D).Extent(4)*Logical(D);
		end
		YLimB=ylim;
		NewError=max(abs(YLimA-YLimB));
		if NewError<Error
			Error=NewError;
		else
			break;
		end
	end
	MATLAB.Graphics.PLineRetune(Lines,Texts);
end
end
function YData=AddErrorBar(YData, ObjectA, ObjectB, IndexA, IndexB)
if YData(1)<YData(2)
	CandidateYData=YData;
	if ~isempty(ObjectA.YPositiveDelta)
		CandidateYData(1)=YData(1)+ObjectA.YPositiveDelta(IndexA);
	end
	if ~isempty(ObjectB.YNegativeDelta)
		CandidateYData(2)=YData(2)-ObjectB.YNegativeDelta(IndexB);
	end
	if CandidateYData(1)<CandidateYData(2)
		YData=CandidateYData;
	end
else
	CandidateYData=YData;
	if ~isempty(ObjectA.YNegativeDelta)
		CandidateYData(1)=YData(1)-ObjectA.YNegativeDelta(IndexA);
	end
	if ~isempty(ObjectB.YPositiveDelta)
		CandidateYData(2)=YData(2)+ObjectB.YPositiveDelta(IndexB);
	end
	if CandidateYData(1)>CandidateYData(2)
		YData=CandidateYData;
	end
end
end

%[appendix]{"version":"1.0"}
%---
%[text:image:59f8]
%   data: {"align":"baseline","height":344,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAiYAAAFYCAIAAADobKA9AAAACXBIWXMAABcSAAAXEgFnn9JSAAAAB3RJTUUH6QcYARUvR7Ty8AAAACR0RVh0U29mdHdhcmUATUFUTEFCLCBUaGUgTWF0aFdvcmtzLCBJbmMuPFjdGAAAACJ0RVh0Q3JlYXRpb24gVGltZQAyNC1KdWwtMjAyNSAwOToyMTo0NxH1macAACAASURBVHic7d15QFNXvgfwE40EJIiQoWIEpFHApTbQgIk2hVGwbkMf+KAIdbSKQqsiY22LOFZblyJtqS+CCyhYl0elVmRK7XOr2oqaiMvQqgyiEZFFQUA0GIKRvD\/ue5kUkCWEGxK+n7\/CzcnNLzbw7T3n3HMYGo2GAAAA9Lx+xi4AAAD6CkQOAADQBJEDAAA0QeQAAABNEDkAAEATM4+crKwsHo8nFouLi4u1B2tra4ODg7OysoxYGABAH8Q0dgGGJ5VKIyIiqMfR0dFyudy49QAAAMUMr3JEIpFcLr9+\/XpgYKCxawEAgH8zw8h5kdb9aUqlMjY2Fj1sAAD06EORU1NTQwh57bXXdA+6ubklJyfrjvQAAEAPMcPISUxM5PF4Y8eOzc3NTU1N5fF4PB5PKpVeuXKFEMLhcLQtraysIiMjBQJBdna28eoFAOgrzDBy4uLi5HL5sWPHuFwuNX1ALpfz+fzz58+LRCJ7e3vdxlZWVuHh4bm5ubjQAQDoaWYYOZQrV65UVFRof1QqlaWlpX5+fq1b8vl8gUBAXQMBAEDPMcNJ0oQQpVJ5\/vx5QsiTJ0927949e\/bsmzdvVldX6\/aqaVlZWUkkEtprBADoc8wzcsrKyi5fvkwIyczMJIQMHDiwpKREIBA4OTkZuzQAgL7LPCMnOzvbzc3Nzc1t1KhRrq6uycnJu3fvdnNza7MxNUk6LCyM3hoBAPocMxzLqa2tlUqlf\/3rXwcNGkQICQsLCwwMfNFQjVQqjY+Pp7dAAIA+ygyvck6cOOHi4uLp6fmPf\/yDOhIXF6fbwN7e\/vDhw4SQ4uLiDz\/8MDo6Gpc4AAA0MMOrnOrq6qVLl1pZWbXfrLi4eP78+YGBgS0CCQAAeogZXuUsXbqUEKJUKttpQy39mZCQgOsbAADamGHktK+2tjYyMrK6uvrYsWMvmlAAAAA9oQ9FDnVlw+Vy25m9BgAAPcf8I0epVK5cuTI3Nxd75wAAGBdDo9EYuwYAAOgTzHDGGiFEJpPJZDJjVwEAAH9gnh1rUqmUECIUCo1dCAAA\/Jt5XuUAAEAvhMgBAACaIHIAAIAmiBwAAKAJIgcAAGiCyAEAAJogcgAAgCaIHAAAoAkiBwAAaILIAQAAmiByAACAJogcAACgCSIHAABogsgBAACaIHIAAIAmiBwAAKAJIgcAAGiCyAEAAJogcgAAgCaIHICOSaVSHo8nlUrz8\/PDw8Pd3d35fP7KlSvLy8vbeVV1dXVSUpKPjw+Px+Pz+UuXLr127ZpGo6GtbIDehmnsAgBMxokTJ3744QcvL6\/o6OiLFy9+9913d+7cSUlJcXBwaN24qqpq2bJlhYWF\/v7+zs7ODx8+\/PHHH8+ePZuamioSiegvHqA3QOQAdNb333+\/detWsVhMCFGr1V9\/\/fWOHTsuXrw4c+bM1o3PnTt35cqVHTt2TJ48mToSHh7+t7\/97dKlS+PHj+\/XDx0M0BeZ0vdepVJ9\/\/33M2bMoLopli1bVlpaauyioA+ZPn36+PHjqcdMJtPX15cQolAo2mzc1NSkVqsrKyubm5upI6+88srJkyeXLl2KvIE+y2S++kql8u9\/\/\/vf\/\/53oVC4a9eujz\/++Pfff4+IiLh27ZqxS4O+wsnJycLCopONvb29X3755U8++cTPz2\/t2rVnz559UTgB9B0mEzk3btw4duzYunXr1qxZM3ny5HfeeWf\/\/v22trZ79+5VqVTGrg76hDbHbF5kxIgRu3fvnjlzZlVV1b59++bNm\/faa68tXry4\/RkHAObNZMZy7ty5M3To0Ndee43BYFBHuFzu66+\/np+f39DQwGKxjFseQGsuLi7JyclNTU3Xr1+\/cOFCbm7u0aNHFQqFRCKxs7MzdnUARmAyVzkhISHHjx93c3PTHnn27Nnjx4+NWBLAi6hUqs8\/\/zwsLKyystLCwsLLy2vx4sU5OTkhISFyufzhw4fGLhDAOEwmclq7c+dOXl6et7f3oEGDjF0LwB+wWCwnJ6f8\/PxTp05ppw80NjY+evSIw+HY2NgYtzwAYzHVyKmqqlq7di2LxQoNDWUyTaZ7EMwYdbtobGysUqkkhEyfPl0kEn3yySfh4eFJSUnr1q2bNWvWmTNn5syZM2TIEEJIcXGxWCwODg6ura01du0ANDHJP9Z1dXXr168vLCzcunWru7t7m21kMllERAT1WCgUxsbG0lggAHFwcNi6dWtGRkZOTs7WrVsHDBjg7+\/\/+eef+\/j4aMcjAfoahsktv1FeXh4fH19QULBlyxZfX982f3slEolMJhMKhdojiBwAAKMzsaucwsLC2NjY58+ff\/PNN15eXu20xJUNAEBvY0pjOTdv3ly6dKm1tfXOnTvbzxsAAOiFTOYqp6qqas2aNfb29l9\/\/bWzs7OxywEAgC4zjcjRaDSHDh26ePHiG2+88f333+s+ZWtr+\/bbb7PZbGPVBgAAnWQakfP06dMbN24QQs6ePXv27Fndp\/h8flBQkJHqMppJkyYZuwQAE3b69Gljl9BHmd6Mtc6QSCTErGep\/fLLL8YuAcCE+fn5GbuEPso0rnKgBfzCAIApMqUZawAAYNIQOQAAQBNEDgAA0ASRAwAANEHkAAAATRA5AABAE0QOAADQBJEDAAA0QeQAAABNEDkAAEATRA4AANAEkQMAADRB5AAAAE0QOQAAQBNEDgAA0ASRAwAANEHkAAAATRA5AABAE0QOAADQBJEDAAA0QeT0OpMmTWIYwqRJk4z9UQAA\/oBp7AKgpdOnT7ff4LPPPiOErF27lpZyAAAMBlc5AABAE0QOAADQBJEDAAA0QeQAAABNEDkAAEATRA4AANAEkQMAADRB5AAAAE0QOQAAQBNEDgAA0ASRAwAANEHkAAAATRA5YBhYABsAOoTIAcM4ffq0piN\/\/vOfz5w5036bDhfSBgDThcgBAACaIHIAAIAmiBwAAKAJIgcAAGiCyAEAAJogcgAAgCaIHABoA260gp7ANHYBANAbdXiD1GeffXbmzBncRwVdgqscAACgCSIHAMwH+gN7ud4SOXl5ebNnz66trW2nTXFxsVgs5v1RYmIibUUCQC\/XyYWXPv30Uyy8ZBTGH8vRaDQ\/\/\/xzfHy8k5NT+y0fPHhQX18\/Z84cOzs77cHRo0f3cIEAAGAYRo6csrKy7du3Hzx4UK1Wdxg5ZWVlQ4YMWbRokbOzMz3lAQCAARkzcmpra2NiYgoKCoKDg5ubm0tKStpprNFo5HI5l8u1tbWlq0AAADAkA4zlaDSax48f19XVPX\/+\/NmzZ1167ahRozIzM7\/88ktHR8f2Wz59+rSyspLL5VpaWnajWAAAMJpuRY5SqczIyBCLxZ6engsWLLh\/\/\/7KlSvXrVtXV1fXmZfb29snJCSIRKJ+\/Tou4+nTp6WlpYMHD05PT\/fx8fHw8Fi8ePGNGze6Uz8AANBJ\/8hRKBSrV6\/esGFDv379OBwOIaSpqenBgwfffPPN+++\/X1VVZbgiCSGkrq7u4cOHGRkZt2\/fTkxMXLNmTWFhYXh4eF5enmHfCAAAeoj+YznZ2dm5ubkJCQmhoaFffvmlVCq1tbVNT0\/PysrasGFDTk5OVFSUAQttaGhQq9UbN24MCQlhMBiEEH9\/\/5iYmG3bto0dO1Z3DpuWTCbTPhYKhQYsRj+69XTzPEKh0FBn6w3\/MgDQR+gZOQ0NDfn5+UFBQUFBQbrdYiwWKyws7Nq1a5cuXYqIiGCz2Qaqk3h5ebX4I+vo6Dh9+vTNmzeXlJS0jhyJRKJtLxQKjf6HVSaThYeHixpF3T+VZaNl0T+LilKLun8qqaX022+\/Nfo\/DgD0EXpGjkqlKisrE4lELBarxVMsFovD4RQXFzc1NXW7vD9oaGiwsrLSTThra+uGhgaVStW6cWxsbGxsrGEL6L7Mykxjl\/AHEUMjjF0CAPQheo7lMBgMJpP5\/PlzjUbT4imNRvP8+XMmk0l1fxlKUlLSm2++eevWLd03qqqq4nK51EgSAAD0cnpGjo2NzZgxY86cOXP37t0WTxUXF\/\/8889jxoyxsbHpdnn\/5u3tXV1dfeTIEbVarX2jnJyciRMnuri4GPCNAACgh+jZscZkMoOCgnJycpYvX75ixYrGxkZCSH19\/cWLFxMTE2tra4OCgpjMbt1nWltbGxkZSQhJT0+3t7cXiUQLFizYvn17eXn5jBkz7ty5s3\/\/\/gEDBixcuLB15x4YkEwmk0gkBjlVQUGBRCJJTU01yNkyM3tXLyUAdEj\/VPD09NywYcPq1avnzp1LHfH39yeEDBgwICEhwdPT0zAF\/j8Wi7V8+fKRI0dmZGRkZ2dzOJygoKCoqCgHBwfDvhG0IJVKz5SceeT5yADnmk2OkqMGOA8hjkc7uHcYAHoh\/SOHwWAEBgaKRKIff\/zx+PHjjY2NlpaWb7zxxltvvdXhammtxcXFtThib29\/+PBh3SMsFiskJCQkJETvmkE\/jY6NyiFKY1cBACavu2usOTg4zJ8\/f\/78+QapBgAAzFi3Iqe5ufn+\/fslJSXNzc0tnmKxWK+++ipGWQAAQEv\/yLl3715cXJxUKm3zWT6fn56ejsgBAAAtPSNHrVbv3btXKpWKxWIvL6\/WDWxtbS0sLLpXGwAAmBU9I+fx48eXLl0KCQlZv349LmUAAKAzurX6AIfDQd4AAEAn6b\/6gKenZ01NTZvrmwEAALSmZ+QwmcyIiIjff\/\/9wIEDSiXu2AAAgI7pP2Nt+PDh0dHR8fHxn332WetnqRlr9vb23agNAADMiv6Rk5OTs3LlSu0imwAAAO3TM3IUCsXRo0fHjh371Vdf8Xg8w+5TAAAAZknPyGlqaqqurhaJRCNGjDBsQQAAYK70nD5gYWHh4ODQ5hZtAAAAbdLzKofNZgcFBSUlJYWEhLi7uxu2JgDoOYba\/UgmkxlwL6UOt42XyWTh4eEGea\/GxsaioqI9e\/YY5Gxyudwg5+kj9Iyc5uZmHx+fKVOmhIaGBgcHi0QiNput2wDLegL0ThKJJPZRB3\/fO2MqmTrVcippY75ql0kGS0QikVAobL9Zo2Nj5dRKA7yf4by852Vjl2Bi9IycR48eRUVFFRQUEEL27t27d+\/eFg2wrCdArxVbZ4DIMSCZpczYJQBN9Iwca2vrVatWtbP0AIvFsra21rcqAAAwQ3pGDovF8vHxMWwpAABg3vScsQYAANBVXbjKqa2tjYyMJISkp6cTQiIjI6mxnDZhwRsAAGihC5HDYDCcnJyoB4QQ6vGLODk5YUkCAADQ1YXIsbOzS05O1v6o+xgAAKBDeo7lqFSq\/Pz8oqKiNp+9evXqnj17FApFNwoDAABzo2fkNDQ0fP755zk5OW0+e\/z48ZycnKampm4UBgAA5qYLHWsqlerw4cOVlZWEEKVSWVFRcfHixc2bN7du9uOPP\/J4PCZT\/50RAADA\/HQhFVgslqura0JCwpMnT6gj1dXVV69ebeOkTGZsbKyNjY1hagQAALPQtQuR8ePHnzlzRqPR1NfXL1u2zNvbOyYmpnUzCwuLFkuuAQAAdC1y+vXrZ2dnRwixsLAIDg7mcrm48wYAADpJ\/80LFixYYNhSAADAvGHBGwAAoAkiBwAAaILIAQAAmiByAACAJogcAACgCSIHAABoouckaWrvnHb2yyGEcDicoKCgqKgoBwcH\/d4FAADMiZ6RY2FhERgYOGjQoLNnz3I4HIFA4OHhUVRUdPny5ZqaGg6H4+Tk9PDhw\/T09N9\/\/33Lli0vvfSSYesGAACTo\/+toF5eXmlpaR9\/\/PH8+fNZLBZ1XKVSZWVl7dmzJzExceTIkcePH4+Li8vJyYmKijJczQAAYJL0HMtpamrKysry9PScM2eONm8IISwWKywsTCAQZGRkqNXqSZMmTZ069dKlS9g7BwAA9IwchUJRVFT08ssvt16+k8VicTicoqIihUJBPa6ursbeOQAAoGfkMBgMJpP59OlTtVrd4im1Wv306VMmk8lgMLpdHgAAmA89I8fGxsbT0zMnJ0cqlbZ4SiqV5uTkeHp62tjYKBSKO3fu8Hg8a2vrbpcKAACmTc\/pA0wmMzQ09NSpU5GRkYGBgQEBAWw2W6FQnDx5Mjc318nJKTQ0tLm5WSKRnDp1avXq1brjPQAA0Dfpv1e0u7v79u3bP\/300+zs7OzsbO1xHx+f9evXu7u7P378uKioaNasWbNmzTJEqQAAYNr0jxxCiLu7+\/79+8vLy69fv15cXOzq6urp6Tls2LB+\/foRQths9vbt29GlBgAAlG5FDiGkX79+zs7Ozs7O06ZNa\/0U8gYAALS6FTlqtVoul1dVVbV+isVivfrqqxjCAQAALf0jp6qq6sMPP8zLy2vzWT6fn56e3kORo1Ao1q5dO378+LCwsJ44PwAA9AQ9I0ej0WRlZeXl5YnF4tDQUDs7uxYNWCxWD\/Wq1dXVbdiw4fDhw+PHj++J8wMAQA\/RM3KePHmSn58fEBCQlJRkY2Nj2JpeRKVS\/fLLLwkJCXfv3qXnHQEAwID0vBVUrVY\/efJkxIgRtOUNISQnJ+e9995TKBSxsbFDhw6l7X0BAMAg9IwcKysrFxeXNhe86TkDBgz44IMPjh07NmPGDKymAwBgcvSPnKlTp545c+b27duGLagds2bNWrp0qb29PW3vCAAABqTnWE5zc7OPj09ISMicOXP+8z\/\/c\/z48RYWFroNMEkaAABa0DNyHj16FBUVRW1EnZaWlpaW1qJBj06SBgAAU6Rn5FhbW69atUqlUr2oQc9Nku4kiUQikUioxyKRKDMz04jFAAAA0TtyWCyWj4+PYUsxrNjY2NjYWGNXAQAA\/6bn9AEAAICu6sJVTm1tbWRkJCEkPT2dEBIZGUmN5bSJGsvB7DIAANDqQuQwGAwnJyfqASGEevwiTk5OuHUGAAB0dSFy7OzskpOTtT\/qPgYAAOhQd\/fLMQo3N7cXrWANAAC9VremD5SWlv7www9NTU2EkKqqqoULF\/J4vNdff\/3IkSMajcZAFQIAgJnQP3KuXbsWGhr6448\/NjU1qdXqnTt3njp1atiwYU1NTatWrZLJZAasEgAAzID+K0n\/4x\/\/GDBgQGRk5MCBA6urq8+dOzd58uQjR47k5ua6u7v\/z\/\/8D50rfgIAQO+nZ+Q8ffq0qKjI399fIBD069evsLDwX\/\/6l6en56BBgxwdHb29vW\/cuPHkyRPD1goAACatW\/vlDBw4kMlkEkJu3LhBCPH09NRtgOEcAADQpeeMNSaTaWNj8\/z5c41G09DQ8Ntvv\/F4vOHDhxNCVCpVTU2Ng4NDi7WlAQCgj9PzKmfgwIEeHh4\/\/\/zzb7\/9JpVKL1y44O3tPWTIELVa\/dNPPx07dmzcuHHGXdYTAAB6G\/2vckJDQ0+dOhUcHEwIsbGxCQoKUqlUS5cuPXv2rJeX16xZs7D6AAAA6NL\/VlB3d\/d9+\/YdOXJEpVK9+eab7u7uKpXKyclpyZIlc+fOdXBwMGCVAABgBrq1+gCXy120aJH2RxaLtXHjxm6XBAAA5qkLkdPc3FxfX08IsbW1JYTU19e3MyeNwWDY2tr264fNEQAA4P90IXIePXqEzQsAAEBvXYgcCwuLwMBA6gEhJDAw0NfX90WNbW1tMUkaAAB0dSFy2Gz2ggULtD\/qPgYAAOhQj4y1qFSqnJycurq6njg5AACYqC7PWGtubi4oKDh37tyzZ89efvnlKVOmtLjl8+bNm5988klTU1M73W4AANAHdS1yFArFhg0bvvvuO+2RkSNHpqSkuLu7E0JUKtWePXuSkpKePXsWEBAwYMAAAxcLAACmrGsda9nZ2d99993w4cOTkpJ2794dHh5eUlKydetWpVJZXV0dExOzadMmQsgHH3ywefNmGxubnqkZAABMUheuclQqVUFBwejRo9PS0oYNG0YI8fX1dXd3T0lJkUqlO3fulEqlPj4+q1evHjduXI8VDAAApqoLVzkNDQ1yufz111\/ncrnUEQaDMXHiRGrRgUuXLkVHR2dkZCBvAACgTV2ePtC\/f3\/d9To5HI6Dg8P169fXr18fGhqK5QYAAOBFDJMQQUFBQUFByBsAAGiHYUKCw+GwWCyDnAoAAMwVrksAAIAmiBwAAKBJl6cPXLx4cfPmzdoflUplRUVFi4OEEFtb27fffpvNZhugRgAAMAtdjpyrV69evXq1xcHq6uoWB\/l8flBQULdKAwAA89KFyLG2tl61apVKpepMYxaL1WLtNQAA6OO6EDksFsvHx6fnSgEAAPOG6QMAAEATRA4AANAEkQMAADRB5AAAAE0QOQAAQBNEDgAA0ASRAwAANEHkAAAATRA5AABAE0QOAADQBJEDAAA0QeQAAABNEDkAAEATRA4AANAEkQMAADRB5AAAAE0QOQAAQBNEDgAA0ASRAwAANDFy5NTV1SUlJfH5fHd397lz5xYUFGg0mhc1Li4uFovFvD9KTEyks2AAANAb04jvrVAoNmzY8Ouvv8bGxnK53IMHD86dO3fr1q1isbjN9g8ePKivr58zZ46dnZ324OjRo+mqFwAAusWYkXP69Onjx4+npKT4+fkRQsRicXx8fFpa2tixY3VDRausrGzIkCGLFi1ydnamvVgAAOguo3WsKZXKkydPTpgwQSAQUEfYbHZwcPDVq1dLSkpat9doNHK5nMvl2tra0looAAAYiNEiR6FQlJSUjBgxgs1maw86OTkNGjTo5s2brds\/ffq0srKSy+VaWlrSWCYAABiM0SLn0aNHNTU1w4cP1z3IYDAYDEZZWVnr9k+fPi0tLR08eHB6erqPj4+Hh8fixYtv3LhBV70AANBdRp6xxmAwdH\/kcDgODg5qtbp1y7q6uocPH2ZkZNy+fTsxMXHNmjWFhYXh4eF5eXl0FQsAAN1izOkDXdLQ0KBWqzdu3BgSEkIFlb+\/f0xMzLZt29qcbiCTySIiIqjHQqEwNjaW7ooBAOCPelfk1NTUVFdXM5ltVOXl5SWTyXSPODo6Tp8+ffPmzSUlJW3OcEPMAAD0KkaLnMGDB3M4nBaT0zQajUajcXJyavMlDQ0NVlZW\/fr9uzPQ2tq6oaFBpVK1biwUCoVCoUFLBgCAbjHaWA6bzXZ1db19+7ZCodAeLCsre\/z4sbu7e+v2SUlJb7755q1bt7RHNBpNVVUVl8vlcDh0VAwAAN1jtKscKyurgICA1atX\/\/Of\/6SWG1AoFIcPH\/by8nJ1dW3d3tvbOzU19ciRIzwej+p5Ky4uzsnJmThxoouLS3cqkclkUqm0O2foPImdhJ436jyJRNL+5aBMJrO8b2lH2ui6NJZGx0ZjlwAA+jDmWI5YLPbx8Vm+fPm8efNGjhx58ODBS5cubd26lRqYqa2tjYyMJISkp6fb29uLRKIFCxZs3769vLx8xowZd+7c2b9\/\/4ABAxYuXMhisbpThlQqlclkNPTC9cKxJSHp+FP3ti5KmUx29P5RY1cBAPowZuTY2dl9+eWXGRkZO3fuVCqVAoFg165d3t7ebTZmsVjLly8fOXJkRkZGdnY2h8MJCgqKiopycHDofiWY0mZCJBLJ0V8QOQAmycgz1uzs7FasWLFixYrWT9nb2x8+fFj3CIvFCgkJCQkJoas6AAAwJOyXAwAANEHkAAAATXrXraC9hEwmCw8PN3YV+ouNjcXQFAD0QoictokaRZmVmcauQh8RQyOMXQIAQNvQsdYnJCYm8ni81rcfJSYmBgcH19bWtv9yqVQqFouLi4t7rEAA6BMQOX1IYmJih+nSJpFIlJeX5+bmZvCSAKBPQeT0IQUFBTt37jR2FQDQdyFy+go+n5+SkpKamtrO6j7FxcVisZj3\/7Kysqjj2o41qVTaooOOeom2ZVZWlvbliYmJPfqJAMDkIHL6EJFIFB0d\/aLuteLi4vnz53\/11VdyuVwul2dmZsbHx7fIJ3d3dz6f\/8svv2iPXLlyxcHBYcqUKYSQxMTE5OTkY8eOyeXyS5cuSaVSpA4A6ELk9C2LFi0ihLTZvZadnS0QCPh8PvUjn88PDAzUTRdCiL29\/ezZs6VSKRVaSqXy\/PnzIpHI3t6+uLg4Nzc3JiaGGvKxt7ePi4tr\/6IKAPoaRE7f0k4SxMXFSSQSKysrqvds7Nixubm5rc\/w2muvVVdX37x5kxBSVlZ2+fJlPz8\/QsiVK1eoZ7UtqUuiu3fv9uDnAQCTgsjpc17UvaYdyImIiEhISLh+\/XpgYGDrlzs5OQkEAurqh+pV0+5vVFFRMXXqVO1Yjre3d0FBAQ2fCABMBW4F7YsWLVoklUp1u9eUSmVKSopAIDhx4oSVlRV1pM3XWllZTZw48cCBA+Xl5dpeNeopPp9P7TRBw0cAAFOEq5y+SNu9lpqaSh1RKpWlpaVcLpfKG\/L\/nWZtvpyaLHD8+PHS0tJZs2ZRB3U73CjUZRPGcgBAC5HTR1Hda9ofraysXFxcdOcFpKSkVFRUtPlaase89evXu7i4ODk5UQfd3NwCAwM\/\/PBDapEC7WWTdj4CAAA61vouqnuNemxlZbVp06aVK1dqt8jLzMzkcrnaEGrBz88vNTV14sSJ2qsiQkhcXJyrq+vUqVOpH6Ojo+Pi4nr4QwCAKUHktE1qKTXR9TGlltLW20u3+ae\/xSZ4VlZWEolEIpFoj4hEIu2DvLw83deKRCK5XN76nGFhYWFhYXoXDwDmDZHTBqFQ+O233xq7Cj3FklihsGXkAAD0BoictuGvNgCAwWH6AAAA0ASRAwAANEHHWttkMpmxS+gWdAwCQC+EyGmDTCYLDw9vdGw0diH6sLxvGRuLGQQA0BshctrW6NhYObXS2FXoY+ixoS2OZGVlxcfHt9mYtiVqpFJpREQEISQwMHDTpk26d\/MAQN+ByDF\/uvfKZGVlHThwgOaV0JRK5bfffos7QwEA0wegx1ELuLm6uhq7EAAwMkROX1dbWxscHLx7925q5wJqH88X7UhNNc7KykpMTKSeGq\/vFgAAEDlJREFUCg4O1q6I0+JV1Go6UqmU2sUgPj5ee5A6D9WM2uKaOoNUKg0ODk5JSdE9AwCYDUQOEEJIenr67t275XJ5XFxchztSx8fH+\/n5UbtNE0I+++wzpVJJvSomJkb7KmqJT5FIdOnSJT6fn5CQIJfLRSJRcXHxW2+9RS2ZI5fLY2Ji5s+fr02dgoKC4uLi69evU42N888BAD0DkQOEEBIYGEhtIE06sSN1dHQ0FQbUvtSlpaVKpbKmpobo7ApKLcumPaeu7OxsBwcHaktsQshbb70lEAhSUlK0O\/SEh4djfgGAWULkACGE6A60dLgjdZujMu7u7g4ODlOnTqW65l6ktrZWKpXqbuxG7flG5RYhhMvlcjicbn8gAOiNEDnQUid3pNaqrq6uqamh1qWOjo5OTU2lRmLayR5tG8qL5nADgJnBJGn4g87vSN2muLg4aia09magNidGJyQkYI8DgD4IVznwB13akbodb731VmBgYEVFRYvEonYUPX\/+vO7xxMTE2NjYLmUbAJgiRA78QZd2pNZFDfxoJ7ZRQdVi21DKrFmzLl++vGXLFu0LU1NTMWUAoC9Axxr8QVd3pNYSiUSZmZnUqjaUF\/Weubm5\/fDDD5GRkTwejxDC5XKPHTvW5tw2ADAziJy+pfVG0S22oybt7khNCGnRWPeEL9qduvVbtD6iPUOLHa8BwJwgctpmed\/y5T0vG7sKAACzgshpg1AobPP\/1gEAoDswfQAAAGiCyAEAAJogcgAAgCYYyyGEEJlMpjtBC3ozmUxm7BIAQE+IHELPCvkymUwqlcY+iqXhvTpPMlgSG9tBSTKZ7EzJmUbHRnpK6oxeVQwAdB4ihwiFQqFQ2NPv8n+RU9e7IkdmKROJRO1\/fIlEcrTxaB2\/jraqAMBcYSwHAABogsgBAACaIHIAAIAmphQ5Go0mLy8vLCyMx+P5+Phs3769oaHB2EUBAEBnmVLknDt3bsmSJba2trt27Zo3b15GRsaaNWsUCoWx6wIAgE4xmRlrdXV127Zt8\/X1TUhIYLPZkydPHjdu3LJly\/z9\/WfMmGHs6gAAoGMmc5VTVFR06dKl4OBgNptNHREIBEKh8Ndff21qajJubeYEd8VCb4DvobkymcgpKSl56aWXnJ2dtUesra1dXV2LiorQt2ZA2m09AYwI30NzZTKRc\/fuXQ6HM3jwYO0RBoPRv3\/\/2tra+vp6IxYGAACdZDKRQwjp169f\/\/79dY+4uro+f\/5crVYbqyQAAOg8k5k+0FW9sy9YYtf7SpJIdBe8oRbN1P2nk8lklvct7YidEYprVy\/872sqTPF7SAixvG9pV4DvYcc6XMXKiEw7ckpKSvr3789ktvwU9KzU2VUdLqBJPyFp+b1s\/U2lZw26LvMzdgEmy0S\/h6RXVo7vYVeZTOQMHz48Nze3pqbG3t6eOqLRaJ4\/f25vb29ra9uicS\/9KwkA0LeZzFiOq6trVVXVvXv3tEcaGhpKSko8PDy006YBAKA3M5nI8fDw8Pb2PnLkiHZK9OXLl2Uyma+vr4WFhXFrAwCAzjCZjjU7O7u\/\/vWvf\/vb3x49ehQaGnrr1q09e\/YEBAT4+voauzQAAOgUhkajMXYNnaXRaM6dO5ecnJyfn8\/hcN55550FCxYMGjTI2HUBAECnmFLkAACASTOZsRwAADB1iBwAAKAJIqe3S0xMFIvFxcXFxi6kbaWlpcuWLePz+Tweb8aMGd9\/\/71KpdJtoFar165d+8UXX1BduDdu3IiKinJ3d+fz+StXriwvLzdS4WAASqUyNjY2ODi4trbW2LW0gSqP90e9tto+wmRmrEEvJJVKo6OjeTxefHz8Sy+99NNPP61aterWrVvLly9nsVhUm0ePHt24cWPFihUMBoNqP2rUKIlEolKp0tLS5s6dm5aWNmLECON+EDBLCoWipKTE399\/zJgx2oO2tra4rcKIEDmgJ5VKlZ2d7e7unpyc7OjoSAiZNGnSuHHjvvrqqylTpggEAqrZvXv31Gr18OHDFQrFN9984+7uLpFIqPZjx46dP3\/+oUOHPvroIwaDYcwPA+aorq7u4cOHUVFRM2fONHYt8H\/QsQZ6evz48YMHD7y9van8IIQwGIwJEyYMGjTo1q1b2mZXr1718PDgcDi1tbWPHz\/+y1\/+om3v5OQkEAjKy8sbGxuN8AHA3FVVVT1+\/JjL5Rq7EPg3RI7JKy0tXbVq1RtvvMHj8Tw8PObOnZuXl6fRaDQazRdffOHv719SUqJtrFarN27cGBERUVdXRwhRKpUZGRn+\/v48Hs\/Hx2f79u0NDQ1US6lUKhaL8\/LyFi5c6O7uvnz58sePH+u+r4ODw549e+Li4nQPNjQ06DZTKpUFBQVeXl4WFhYuLi6ZmZnz5s3TbXzv3j0rK6sWe1KAOXnR9\/Phw4ezZs36+OOPdQf\/7t+\/\/x\/\/8R\/JycnUyF95efnKlSupkcLAwMDTp083NzdTLTv8fhJCysrKhgwZ8qc\/\/Ym2DwsdQuSYttu3b8+fP7+wsHDJkiV79+79+OOP7927t2TJkt9++43BYPj7+1dVVf3+++\/a9g8fPrx48eKECRMGDx6sUChWr169adMmLy+vXbt2zZs3LyMjY82aNdolherr6z\/55JNRo0Zt2bJl0qRJNjY27RejVqtPnDgxcODAV199Vft2paWlY8eObdFSo9GUl5dv3rz59u3bQUFB6Fs3V+18PzkczqRJky5fvlxZWaltX1RUVFJSMnHiRAaDcfPmzblz5\/7888+LFi3atWuXh4fH4sWLDx06pL2VsP3vp0ajkcvlDg4O+fn5gYGBVGjl5uZiey3jwliOabtw4QKLxdq8ebOrqyshRCwWe3p6vvvuu\/\/617\/4fL6bm5uXl9fJkycDAgKsrKwIITdu3KioqJg0aRKDwTh9+vThw4cTEhLefvttBoMxefJkT0\/PJUuW8Pn8uXPnEkIaGhqmT58eExOjnQvQDo1Gc\/jw4V27dr3\/\/vtubm7UweLiYhsbGxcXF92WdXV1UVFRly9fZrFYn3\/++fjx4w3+zwK9RPvfT7FYnJaWJpPJqGfVavWpU6eEQqGHh4dKpdq1a5dKpdq\/f7+HhwchxNfXd9iwYV999dUrr7wyevRo0tH38+nTp5WVlTKZrLGxMTIy0tLS8uDBg7Gxsbdu3YqJiWm94wnQA1c5pm3OnDk\/\/fQT9RtLGTRokHY3h0GDBgUEBFy+fLmsrIwQ0tTUdPz4cYFA4OrqqlKpzpw5M2rUKF9fX+3QvUAg+POf\/5yXl6e90BEIBJ3MmxMnTmzYsCEwMHDRokXU77NGo7l06dIrr7zS4n8\/BwwYsHTp0m3btk2bNm3VqlXJycn4H09z1f73083N7fXXXz9\/\/rxSqSSEVFZWnjt3TiwWs9nsiooKmUzm7++vnc3IZDL\/8pe\/DBgw4MKFC9qztfP9bGpqevr0aXBw8L59+4KCgqZNm5aamvree+9lZGQUFBT00OeFDiHqzYFCobh9+3ZlZeWVK1fy8vIqKiq0T02YMCEtLe3ChQtubm4VFRX5+flRUVFsNruurq60tNTW1rawsPD27dva9s3NzQ8ePKD+BBBChg0b1uG7Nzc3Hzp0aPXq1TNnzly7dq12L4knT55cu3bt3XffbTEbjc1m+\/n5EUICAgKGDh26a9cusVisneEG5udF3082mz1p0qSvv\/66pKRk9OjR\/\/znPxsbGydMmEAIefjwYWVlJYvFkkql2vM8efKExWLdv39f27fWzvfTzs4uPT1d9wiTyZwxY8bBgwcvXLiA75uxIHJM2\/379zds2PDTTz8RQmxsbDw9PYVCYXV1tbaBi4vLxIkTz58\/P2vWLGpQh9q8TqPRqNVqagOIFufkcrmPHj2iHnfY\/6BSqbZv375t27Z33313+fLlVPcdpbS09MmTJ9pOttaYTOaUKVP27dt369Yt\/AkwSx1+P4VCIZvNzs\/P5\/F4Z8+enThxItUN+\/z5c7VavWvXrl27drU454MHD7RTHNv\/fjY1NRFCdEcKWSwWi8XSzpEB+iFyTJhKpUpOTi4sLDxw4ICnpyf1q1VcXHzixAltGxaL5efn9+mnnxYWFp48edLHx4eaM2ptbc3j8ZycnDZt2mRtbd365DU1NR0WoFart23btn379o8++mj+\/Pktfv+vX7\/u4uKinS909erVZcuWrVy5UvcmCbVarVKpMH3ALHXm+8nlcn18fPLy8saNG3f+\/Pn4+Hiqo2zIkCHOzs7vv\/\/+7Nmz9Xv3\/Pz8d955Z926dbpnePz4cX19vW5HH9AMYzkmrKGh4caNG2PGjBk7diz1+9zc3Hzx4sWKigrd\/5EUCARcLjc7O7uwsHD69OlUSxaLxefzf\/3116tXr2pbVlVVzZ49OyYmpvV809ao+QJpaWmrV69unTdNTU1Xr17l8\/na656hQ4fa29sfPXpUO1CkUCgOHDhgZ2c3atSobv9jQK\/Tme+nhYXF9OnTCwoKfvjhBw6Ho73YdXBwGD16dE5OTlVVlfaEeXl5Pj4+e\/fu7cy7Ozs7tziDQqHIzMx86aWXsEu9EeEqxwTU19fv27fPzs5O96Czs\/PMmTO9vb337Nljb2\/v5+fX0NCQk5Nz8eJFJpOp23Xwpz\/9afz48enp6ePGjaMm\/1BmzZpVUFAQGRk5f\/78CRMmVFZWZmVlyeXypUuXdmYXort37+7cuZPNZt+9ezc5OVn3KbFY7OTkVFRUFBYWpj3o6Og4b968+Pj4+vr6iIiIZ8+eHTx4UCqVbty4EZFj0ioqKnbs2KHbp0oIGT16dEBAQGe+nx4eHo6Ojnv27ImMjNReE7PZ7A8++OD9998PCwtbuHChk5PTlStXMjMzR4wYMW3atM5U5ejoGBMTs2LFiujo6Hnz5vXv3\/\/gwYMymSwhIWH48OEG\/PjQJYgcE9DQ0LB\/\/\/4WBwMDA2fOnBkTE2Ntbf3f\/\/3f+\/btGzZs2Ntvv71u3bovvvjizp07CoWCGslnMpnTpk07cOBAQEDAkCFDtGdgs9nr1q0bM2bMoUOH0tLSbGxs3njjjfXr17e+jaZNZWVl1CoDu3fvbvEUl8t9\/vw5k8l0dnbWPR4cHDxixIikpKRly5YxGAyxWHzw4MFXX30Vq92YtOrq6tYjLtHR0dOmTevM93PIkCEBAQFyuXzatGm618ru7u67d+\/esWPHf\/3Xf9XU1AwbNmz27Nlz5851cHDoZGH+\/v579+7dsmULdcOyWCz+7rvv8H0zLmzR1idcvnz5vffe27FjB0bpobfRaDQpKSkXLlzYunVri0t5MD8YyzF\/arX6yJEjAoFAt1cNoJeoqKg4evTotGnTkDd9ATrWzFl5eXl2dvbNmzdPnjy5detW7R0zAL1BXl6eTCbLy8sjhPj7+xu7HKADrnLM2cCBA8+dO\/frr79+9NFHvr6+xi4H4A+srKzS0tIaGxs\/\/fTTztx0DGYAYzkAAEATXOUAAABNEDkAAEATRA4AANAEkQMAADRB5AAAAE0QOQAAQBNEDgAA0ASRAwAANEHkAAAATRA5AABAk\/8FM1mUus+rpV0AAAAASUVORK5CYII=","width":550}
%---

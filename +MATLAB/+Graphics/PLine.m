%[text] 为条形图、误差条或线图之间添加统计显著性标识
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [Lines,Texts]=MATLAB.Graphics.PLine(Descriptors);
%[text] ```
%[text] ## 输入参数
%[text] Descriptors tabular，一行一个标识，包含以下列：
%[text] - ObjectA(:,1)matlab.graphics.primitive.Line|matlab.graphics.chart.primitive.Bar|matlab.graphics.chart.primitive.ErrorBar，必需，参与显著性比较的其中一个图形对象
%[text] - IndexA(:,1)，可选，指示要取ObjectA中的第几个点。一个图形对象中可能有多个点，用此参数指示要取哪个参与比较。如果不指定此列或指定为0，将自动赋予默认值。
%[text] - ObjectB(:,1)，可选，参与显著性比较的另一个图形对象，必须与ObjectA是同一类型。如果不指定此列或指定为matlab.graphics.GraphicsPlaceholder，默认与ObjectA相同。
%[text] - IndexB(:,1)，可选，指示要取ObjectB中的第几个点。一个图形对象中可能有多个点，用此参数指示要取哪个参与比较。如果不指定此列或指定为0，将自动赋予默认值。
%[text] - Text(:,1)string，必需，要标识的文本 \
%[text] #### 对IndexA和IndexB赋予默认值的规则
%[text] 如果ObjectA和ObjectB相同：
%[text] - 如果IndexA和IndexB均未指定，取第一和最后一点
%[text] - 如果IndexA和IndexB指定其一，报错 \
%[text] 如果ObjectA和ObjectB不同：
%[text] - 如果IndexA和IndexB均未指定：如果ObjectA是matlab.graphics.primitive.Line，取两条线对应位置YData差异最大的点；否则报错。
%[text] - 如果IndexA和IndexB指定其一，则另一个默认与指定值相同 \
%[text] ## 返回值
%[text] Lines(:,1)matlab.graphics.primitive.Line，标识线
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
				Index=[1,numel(XData)];
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
		XData=XData(Index);
		YData=YData(Index);
		if isa(ObjectA,'matlab.graphics.chart.primitive.ErrorBar')
			if ~isempty(ObjectA.YNegativeDelta)
				YPNData(1,:)=-ObjectA.YNegativeDelta(Index);
			end
			if ~isempty(ObjectA.YPositiveDelta)
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
	if VerticalPLine
		YData=YData/2+sum(YData)/4;
		Lines(D)=plot(Ax,XData,YData,'k');
		hold on;
		T=text(Ax,mean(XData),mean(YData),Descriptors.Text(D),HorizontalAlignment='left',VerticalAlignment='middle');
		if XData(1)~=XData(2)
			TextY(2)=T.Extent(2);
			TextY(1)=TextY(2)+T.Extent(4);
			T.Position(1)=ruler2num(max((num2ruler(TextY,Ax.YAxis)-YData(1))/(YData(2)-YData(1))*(XData(2)-XData(1))+XData(1)),Ax.XAxis);
		end
		Texts(D)=T;
	else
		[~,Index]=min(abs(YData));%不用ComparisonMethod，因为不支持duration
		if YData(Index)<0
			YData=min(YData);
		else
			YData=max(YData);
		end
		YData=YData*1.1;
		Lines(D)=plot(Ax,XData,[YData,YData],'k');
		hold on;
		XData=mean(XData);
		if YData<0
			T=text(Ax,XData,YData,Descriptors.Text(D),HorizontalAlignment='center',VerticalAlignment='bottom',AffectAutoLimits=true);
			while true
				YLim=ylim;
				YLim=YLim(2)-YLim(1);
				Extent=num2ruler(T.Extent([2,4]),Ax.YAxis);
				if Extent(1)+Extent(2)<=YData||Extent(2)>=YLim
					break;
				end
				T.Position(2)=ruler2num(YData-Extent(4)*1.1,Ax.YAxis);
			end
		else
			T=text(Ax,XData,YData,Descriptors.Text(D),HorizontalAlignment='center',VerticalAlignment='top',AffectAutoLimits=true);
			while true
				YLim=ylim;
				YLim=YLim(2)-YLim(1);
				Extent=num2ruler(T.Extent([2,4]),Ax.YAxis);
				if Extent(1)>=YData||Extent(2)>=YLim
					break;
				end
				T.Position(2)=ruler2num(YData+Extent(2)*1.1,Ax.YAxis);
			end
		end
		Texts(D)=T;
	end
end
if ~VerticalPLine
	Ax=gca;
	AllExtent=vertcat(Texts.Extent);
	RedundantDistances=AllExtent(:,4)/2;
	NegativeLogical=AllExtent(:,2)<0;
	AllXData=num2ruler(AllExtent(:,[1,3]),Ax.XAxis);
	AllXData(:,2)=AllXData(:,1)+AllXData(:,2);
	[MinX,MaxX]=bounds([vertcat(Lines.XData),AllXData],2);
	AllXData=[MinX,MaxX];
	while true
		AllYData=[AllExtent(:,2),AllExtent(:,4)+AllExtent(:,2)];
		RangeTable=sortrows(table(AllYData(:),repelem([true;false],NumPLines,1),'VariableNames',["Position","IsBottom"]),"Position");
		NumLayers=0;
		ExtentSum=0;
		for P=1:height(RangeTable)
			if RangeTable.IsBottom(P)
				if ~NumLayers
					RangeStart=RangeTable.Position(P);
				end
				NumLayers=NumLayers+1;
			else
				NumLayers=NumLayers-1;
				if ~NumLayers
					ExtentSum=ExtentSum+RangeTable.Position(P)-RangeStart;
				end
			end
		end
		YLim=ylim;
		YLim=YLim(2)-YLim(1);
		if num2ruler(ExtentSum*3/2,Ax.YAxis)>YLim
			break;
		end
		NoChange=true;
		for D1=1:NumPLines-1
			XData1=AllXData(D1,:).';
			YData1=AllYData(D1,:).';
			Negative=NegativeLogical(D1);
			for D2=D1+1:NumPLines
				if any(XData1>=AllXData(D2,:),'all')&&any(XData1<=AllXData(D2,:),'all')&&any(YData1>AllYData(D2,:),'all')&&any(YData1<AllYData(D2,:),'all')
					NoChange=false;
					if Negative
						AllYData(D2,2)=AllYData(D1,1)-RedundantDistances(D1);
						AllYData(D2,1)=AllYData(D2,2)-AllExtent(D2,4);
					else
						AllYData(D2,1)=AllYData(D1,2)+RedundantDistances(D1);
						AllYData(D2,2)=AllYData(D2,1)+AllExtent(D2,4);
					end
				end
			end
		end
		if NoChange
			break;
		end
		for D=1:NumPLines
			if NegativeLogical(D)
				Lines(D).YData(:)=num2ruler(AllYData(D,2),Lines(D).Parent.YAxis);
				Texts(D).Position(2)=AllYData(D,1);
			else
				Lines(D).YData(:)=num2ruler(AllYData(D,1),Lines(D).Parent.YAxis);
				Texts(D).Position(2)=AllYData(D,2);
			end
		end
		AllExtent=vertcat(Texts.Extent);
	end
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

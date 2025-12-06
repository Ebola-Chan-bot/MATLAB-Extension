%[text] 对PLine进行重新微调
%[text] 此函数配合PLine使用。PLine精心调整过的线条和文本位置，可能会因其它图形布局的改变（或您的手动更改）而变得不再适用。使用此函数以重新自动调优位置。
%[text] 目前仅支持水平P值线。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.Graphics.PLineRetune(Lines,Texts);
%[text] ```
%[text] ## 输入参数
%[text] Lines(:,1)matlab.graphics.primitive.Line，PLine返回的标识线对象
%[text] Texts(:,1)matlab.graphics.primitive.Text，PLine返回的标识文本对象
%[text] **See also** [MATLAB.Graphics.PLine](<matlab:doc MATLAB.Graphics.PLine>)
function PLineRetune(Lines,Texts)
NumPLines=numel(Lines);
AllExtent=vertcat(Texts.Extent);
Negative=AllExtent(:,2)<0;
Positive=~Negative;
AllXData=AllExtent(:,[1,3]);
AllXData(:,2)=AllXData(:,1)+AllXData(:,2);

%有两个Y轴时，图形对象所在的Y轴可能不是当前Y轴，需要特殊方法确保获取图形对象所在的Y轴
YAxis=MATLAB.Graphics.GetYAxis(Lines(1));

[MinX,MaxX]=bounds([vertcat(ruler2num(vertcat(Lines.XData),Lines(1).Parent.XAxis)),AllXData],2);%Lines.XData不一定是数值类型，因此必须转换成数值
AllXData=[MinX,MaxX];
while true
	%坐标尺度变换时，文本框可能低于基线，需要强制调整上去
	Baseline=vertcat(Lines.YData);
	Baseline(:,2)=[];
	OldExtent=AllExtent(:,2);
	AllExtent(Negative,2)=min(AllExtent(Negative,2),Baseline(Negative)-AllExtent(Negative,4));
	AllExtent(Positive,2)=max(AllExtent(Positive,2),Baseline(Positive));
	NoChange=isequal(OldExtent,AllExtent(:,2));
	AllYData=[AllExtent(:,2),AllExtent(:,4)+AllExtent(:,2)];

	%排除PLine太多，坐标区装不下的情形
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
	if num2ruler(ExtentSum*3/2,YAxis)>YLim
		MATLAB.Exception.Ax_cannot_fit_so_many_PLines.Warn;
		return;
	end

	%按照现有的尺度排开PLine分层
	RedundantDistance=ruler2num(YLim/10,YAxis);
	LineTextDistance=RedundantDistance/10;
	for D1=1:NumPLines-1
		XData1=AllXData(D1,:).';
		YData1=AllYData(D1,:).';
		for D2=D1+1:NumPLines
			if any(XData1>=AllXData(D2,:),'all')&&any(XData1<=AllXData(D2,:),'all')&&any(YData1>AllYData(D2,:),'all')&&any(YData1<AllYData(D2,:),'all')
				NoChange=false;
				if Negative(D1)
					AllYData(D2,2)=AllYData(D1,1)-RedundantDistance;
					AllYData(D2,1)=AllYData(D2,2)-AllExtent(D2,4);
				else
					AllYData(D2,1)=AllYData(D1,2)+RedundantDistance;
					AllYData(D2,2)=AllYData(D2,1)+AllExtent(D2,4);
				end
			end
		end
	end
	if NoChange
		break;
	end

	%将新的分层规划应用到图形对象。这一步可能会自动改变坐标尺度。
	for D=1:NumPLines
		if Negative(D)
			Lines(D).YData(:)=num2ruler(AllYData(D,2),YAxis);
			Texts(D).Position(2)=AllYData(D,2)-Texts(D).Extent(4)-LineTextDistance;
		else
			Lines(D).YData(:)=num2ruler(AllYData(D,1),YAxis);
			Texts(D).Position(2)=AllYData(D,1)+Texts(D).Extent(4)+LineTextDistance;
		end
	end	
	AllExtent=vertcat(Texts.Extent);
end
end

%[appendix]{"version":"1.0"}
%---

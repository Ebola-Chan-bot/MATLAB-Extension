%[text] 对PLine进行重新微调
%[text] 此函数配合PLine使用。PLine精心调整过的线条和文本位置，可能会因其它图形布局的改变（或您的手动更改）而变得不再适用。使用此函数以重新自动调优位置。
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
Logical=AllExtent(:,2)<0;
AllXData=AllExtent(:,[1,3]);
AllXData(:,2)=AllXData(:,1)+AllXData(:,2);
[MinX,MaxX]=bounds([vertcat(ruler2num(vertcat(Lines.XData),XRuler)),AllXData],2);%Lines.XData不一定是数值类型，因此必须转换成数值
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
	RedundantDistances=ruler2num(YLim/10,Ax.YAxis);
	NoChange=true;
	for D1=1:NumPLines-1
		XData1=AllXData(D1,:).';
		YData1=AllYData(D1,:).';
		Negative=Logical(D1);
		for D2=D1+1:NumPLines
			if any(XData1>=AllXData(D2,:),'all')&&any(XData1<=AllXData(D2,:),'all')&&any(YData1>AllYData(D2,:),'all')&&any(YData1<AllYData(D2,:),'all')
				NoChange=false;
				if Negative
					AllYData(D2,2)=AllYData(D1,1)-RedundantDistances;
					AllYData(D2,1)=AllYData(D2,2)-AllExtent(D2,4);
				else
					AllYData(D2,1)=AllYData(D1,2)+RedundantDistances;
					AllYData(D2,2)=AllYData(D2,1)+AllExtent(D2,4);
				end
			end
		end
	end
	if NoChange
		break;
	end
	for D=1:NumPLines
		if Logical(D)
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

%[appendix]{"version":"1.0"}
%---

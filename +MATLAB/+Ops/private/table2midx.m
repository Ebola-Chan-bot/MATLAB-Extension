function [Matrix1,Matrix2] = table2midx(Table1,Table2)
[NumRows,NumColumns]=size(Table1);
Matrix1=zeros(NumRows,NumColumns);
Pairwise=nargin>1;
RowNames=Table1.Properties.RowNames;
HasRowNames=~isempty(RowNames);
if HasRowNames
	Table1.Properties.RowNames={};
	if Pairwise
		RowNames=[RowNames;Table2.Properties.RowNames];
		Table2.Properties.RowNames={};
	end
end
if Pairwise
	Table1=[Table1;Table2];
end
for C=1:NumColumns
	Matrix1(:,C)=MATLAB.DataFun.FindGroupsN(Table1{:,C},1);
end
if HasRowNames
	Matrix1(:,end+1)=findgroups(RowNames);
end
if istimetable(Table1)
	Matrix1(:,end+1)=MATLAB.DataFun.FindGroupsN(Table1.Time,1);
end
if Pairwise
	Matrix2=Matrix1(NumRows+1:end,:);
	Matrix1(NumRows+1:end,:)=[];
end
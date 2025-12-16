%[text] 在不破坏图连通性的前提下尝试移除节点（Try to remove the node without breaking graph connectivity）
%[text] 本函数尝试尽可能从图中移除节点，但不破坏其连通性。如果移除一个节点会导致原本连通的子图被破坏，那个节点就不会被移除。
%[text] 本函数功能类似于寻找图的一个 Steiner Tree 子图，是NP困难问题，因此只能求出一个可行解，不保证最优。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Graph=MATLAB.TtrtnWbgc(Graph,ToRemove);
%[text] ```
%[text] ## 输入参数
%[text] Graph(1,1)graph，要尝试移除的图
%[text] ToRemove(1,:)，尝试移除的节点。如果是逻辑值，向量长度必须等于图中节点个数，指示每个节点是否可以尝试移除；否则必须是数值，指示要尝试移除的节点索引
%[text] ## 返回值
%[text] Graph(1,1)graph，移除后的结果图
%[text] **See also** [rmnode](<matlab:doc rmnode>)
function Graph = TtrtnWbgc(Graph,ToRemove)
%命名空间：GraphFun
if ~islogical(ToRemove)
	Logical=false(height(Graph.Nodes),1);
	Logical(ToRemove)=true;
	ToRemove=Logical;
end
Connectivity=max(Graph.conncomp);
AnyRemoved=true;
while AnyRemoved
	AnyRemoved=false;
	for N=height(Graph.Nodes):-1:1
		if ToRemove(N)
			TryGraph=Graph.rmnode(N);
			TryConnect=max(TryGraph.conncomp);
			if TryConnect<=Connectivity
				Graph=TryGraph;
				Connectivity=TryConnect;
				ToRemove(N)=[];
				AnyRemoved=true;
			end
		end
	end
end

%[appendix]{"version":"1.0"}
%---

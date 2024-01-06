%埃博拉酱修复版
function xmlString = getDocumentationXML(topic)
%getDocumentationXML Extracts the documentation content from the live code file to be displayed in doc.
%   getDocumentationXML(topic) topic is the file path of the live code file.

%   Copyright 2017-2020 The MathWorks, Inc.
topicParts = strsplit(topic, '/');
filePath = Which(topicParts{1});

if isempty(filePath) ...
		|| ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(filePath)
	xmlString = "";
	return;
end

xmlString = string(matlab.internal.livecode.FileModel.getDocumentationXml(filePath));
end
function Path = Which(varargin)
Path=which(varargin{:});
if isempty(Path)
	Item=string(split(varargin{1},'.'));
	if numel(Item)>=2
		Path=which(join(Item(1:end-1),'.'));
		if ~isempty(Path)
			Directory=fileparts(Path);
			Files=strtrim(string(ls(fullfile(Directory,Item(end)+".*"))));
			if ~isempty(Files)
				[~,~,Extensions]=fileparts(Files);
				[Exist,Index]=ismember([".mexw64",".mlx",".p",".m"],Extensions);
				Path=fullfile(Directory,Files(Index(find(Exist,1))));
			end
		end
	end
end
end
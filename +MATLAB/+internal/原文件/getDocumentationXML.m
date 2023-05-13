function xmlString = getDocumentationXML(topic)
    %getDocumentationXML Extracts the documentation content from the live code file to be displayed in doc.
    %   getDocumentationXML(topic) topic is the file path of the live code file.

    %   Copyright 2017-2020 The MathWorks, Inc.
    topicParts = strsplit(topic, '/');
    topic = topicParts{1};
    filePath = which(topic);

    if isempty(filePath) ...
            || ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(filePath)
        xmlString = "";
        return;
    end
    
    xmlString = string(matlab.internal.livecode.FileModel.getDocumentationXml(filePath));
end

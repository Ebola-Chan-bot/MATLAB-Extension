function doc(varargin)
wsVariables = evalin('caller', 'matlab.internal.language.introspective.getWorkspaceVars');
topics = matlab.internal.doc.reference.ReferenceTopicInput.parseTopicInputs(varargin, wsVariables);
% Resolve any remaining variables. This has to be done in doc.m rather
% than a helper function because it uses inputname.
for i = 1:length(topics)
	if topics(i).VariableIndex
		topics(i).VariableName = inputname(topics(i).VariableIndex);
	end
end

[docPage, displayText, primitive] = getReferencePage(topics);
launcher = [];
if isempty(docPage)
	if ~isempty(displayText)
		launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForHtmlText(displayText);
	elseif primitive
		% topics will always be a scalar in this case.
		varChar = char(topics.VariableName);
		topicChar = char(topics.Topic);
		disp(matlab.internal.help.getInstanceIsa(varChar, topicChar));
		return;
	else
		docPage = matlab.internal.doc.url.MwDocPage;
		docPage.RelativePath = "nofunc.html";
	end
end

if ~isempty(docPage)
	launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
end

if ~isempty(launcher)
	launcher.openDocPage;
end
end

function [docPage, displayText, primitive] = getReferencePage(topics, allowSearch)
arguments
	topics matlab.internal.doc.reference.ReferenceTopicInput
	allowSearch (1,1) logical = true
end

displayText = string.empty;
primitive = false;

if isempty(topics)
	docPage = matlab.internal.doc.url.MwDocPage;
	return;
end

topic = join([topics.Topic]);
isVariable = isscalar(topics) && topics.IsVariable;

[docPage, refTopics, primitive] = findReferencePage(topic, isVariable);
if primitive || ~isempty(docPage)
	return;
end

% Check if we can display help of some kind.
displayText = checkForLiveCodeDoc(topic, refTopics);
if ~isempty(displayText)
	return;
end

hasHelp = matlab.internal.help.helpwin.isHelpAvailable(topic, 'doc');
if hasHelp || ~allowSearch
	docPage = matlab.internal.doc.url.HelpwinPage(topic, 'doc');
elseif allowSearch
	docPage = matlab.internal.doc.url.DocSearchPage(topic);
end
end

function [docPage, refTopics, primitive] = findReferencePage(topic, isVariable)
docPage = matlab.internal.doc.url.DocPage.empty;
refTopics = matlab.internal.doc.reference.ReferenceTopic.empty;
primitive = false;

[operator,topic] = matlab.internal.language.introspective.isOperator(topic);
if ~operator
	if endsWith(topic, "/")
		topic = extractBefore(topic, strlength(topic));
	end

	docPage = checkForProductOrToolbox(topic);
	if ~isempty(docPage)
		return;
	end

	refTopicBuilder = matlab.internal.doc.reference.ReferenceTopicBuilder(topic, isVariable);
	refTopics = refTopicBuilder.buildRefTopics;

	if ~isempty(refTopics) && refTopics(1).IsPrimitive
		primitive = true;
		return;
	end
else
	[~,topicName] = fileparts(topic);
	if topicName == ""
		topicName = topic;
	end
	refTopics = matlab.internal.doc.reference.ReferenceTopic(topicName);
end

for refTopic = refTopics
	refItems = refTopic.getReferenceData;
	if ~isempty(refItems)
		refItem = refItems(1);
		docPage = getReferenceItemDocPage(refItems(1));
		docPage.Origin = matlab.internal.doc.url.DocPageOrigin("ReferenceItem", topic);

		if checkForOverload(topic)
			overloadString = topic + " " + isMethodOrProperty(refItem);
			overloadParam = matlab.net.QueryParameter('overload',overloadString);
			docPage.Query = [docPage.Query overloadParam];
		end
		return;
	end
end

% If we don't find a reference page for an operator, use the
% operators and special characters page.
if operator
	topicMap = matlab.internal.doc.csh.DocPageTopicMap("matlab");
	docPage = topicMap.mapTopic("MATLAB_OPS");
end
end

function docPage = checkForProductOrToolbox(topic)
prod = matlab.internal.doc.product.getDocProductInfo(topic);
if ~isempty(prod)
	docPage = matlab.internal.doc.url.MwDocPage;
	docPage.Product = prod;
	return;
end

prod = matlab.internal.doc.project.getDocPageCustomToolbox(topic);
if ~isempty(prod)
	docPage = matlab.internal.doc.url.CustomDocPage;
	docPage.Product = prod;
	docPage.RelativePath = prod.LandingPage;
else
	docPage = matlab.internal.doc.url.DocPage.empty;
end
end

function classEntity = isMethodOrProperty(refItem)
import matlab.internal.reference.property.RefEntityType;
entityType = refItem.RefEntities(1).RefEntityType;
classEntity = entityType == RefEntityType.Property || entityType == RefEntityType.Method;
end

function isOverloaded = checkForOverload(topic)
% Check if a broad query for the topic matches more than one item.
overloadTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
isOverloaded = length(overloadTopic.getReferenceData) > 1;
end

function docPage = getReferenceItemDocPage(refItem)
docPage = matlab.internal.doc.url.MwDocPage;
docPage.Product = refItem.HelpLocation;
docPage.RelativePath = refItem.Href;
end

function displayText = checkForLiveCodeDoc(topic, refTopics)
allTopics = [topic [refTopics.EntityName]];

displayText = string.empty;
for topic = allTopics
	if isLiveCodeAndHasDocumentation(topic)
		% Set the return value to the MLX doc string. The calling code
		% will need to differentiate between the output types.
		displayText = getMlxDoc(topic);
		return;
	end
end
end
function b = isLiveCodeAndHasDocumentation(topic)
docXML = getDocumentationXML(topic);
b = ~isempty(char(docXML));
end
function xmlString = getDocumentationXML(topic)
topicParts = strsplit(topic, '/');
topic = topicParts{1};
filePath = MATLAB.General.Which(topic);

if isempty(filePath) ...
		|| ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(filePath)
	xmlString = "";
	return;
end
xmlString = string(matlab.internal.livecode.FileModel.getDocumentationXml(filePath));
end
function html = getMlxDoc(topic, varargin)
    includeHeader = getInputArgs(varargin{:});

    xmlString = getDocumentationXML(topic);
    if xmlString ~= ""
        % Read the xml string directly into an XML model object
        dom = getDocXml(xmlString, includeHeader);
        xsltfile = fullfile(matlabroot,'toolbox\matlab\helptools\+matlab\+internal\+doc\+livecode\private\mlxdoc.xsl');
        
        transformer = matlab.io.xml.transform.Transformer;
        transformer.OutputEncoding = "UTF-8";
        sourceDoc = matlab.io.xml.transform.SourceDocument(dom);
        
        result = matlab.io.xml.transform.ResultString;
        transform(transformer, sourceDoc, xsltfile, result);
        html = char(result.String);
    else
        html = '';
    end
end

function include_header = getInputArgs(varargin)
    include_header = 1;
    for i = 1:numel(varargin)
        argName = varargin{i};
        if strcmp(argName, '-noheader')
            include_header = 0;
        end
    end
end

function dom = getDocXml(xmlString, includeHeader)
    dom = parseString(matlab.io.xml.dom.Parser, xmlString);

    % Add some information about global file locations to the dom.
    includesDir = matlab.internal.doc.url.MwDocPage;
    includesDir.DocLocation = "INSTALLED";
    includesDir.RelativePath = "includes";
    appendDomElement(dom, 'includes', char(includesDir));
    
    if includeHeader
        searchPage = matlab.internal.doc.url.DocSearchPage;
        searchPage.DocLocation = "INSTALLED";
        searchUrl = searchPage.getUrl;
        searchUrl.Query = [];
        appendDomElement(dom, 'searchpage', char(searchUrl));
        landingPage = matlab.internal.doc.url.MwDocPage;
        landingPage.DocLocation = "INSTALLED";
        appendDomElement(dom, 'landingpage', char(landingPage));
    end
end

function appendDomElement(dom, eltName, eltValue)
    newElt = dom.createElement(eltName);
    newText = dom.createTextNode(eltValue);
    newElt.appendChild(newText);
    dom.getDocumentElement.appendChild(newElt);
end
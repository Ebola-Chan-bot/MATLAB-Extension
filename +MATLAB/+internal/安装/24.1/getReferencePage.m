%埃博拉酱修复版
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

    [docPage, refTopics, primitive] = findReferencePage(topic, isscalar(topics) && topics.IsVariable);

    % Check if we can display help of some kind.
    displayText = checkForLiveCodeDoc(topic, refTopics);
    if ~isempty(displayText)
		docPage=[];
        return;
    end
    if primitive || ~isempty(docPage)
        return;
    end

    if matlab.internal.help.helpwin.isHelpAvailable(topic, 'doc') || ~allowSearch
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

        topicName = topic;
        refTopicBuilder = matlab.internal.doc.reference.ReferenceTopicBuilder(topicName, isVariable);
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

    best = matlab.internal.language.introspective.getBestReferenceItem(refTopics, topicName);
    if best
        refItem = best.item;
        docPage = getReferenceItemDocPage(refItem);
        docPage.Origin = matlab.internal.doc.url.DocPageOrigin("ReferenceItem", topic);

        if checkForOverload(topic)
            overloadString = topic + " " + isMethodOrProperty(refItem);
            overloadParam = matlab.net.QueryParameter('overload',overloadString);
            docPage.Query = [docPage.Query overloadParam];
        end
        return;
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
        if matlab.internal.doc.isLiveCodeAndHasDocumentation(topic)
            % Set the return value to the MLX doc string. The calling code
            % will need to differentiate between the output types.
            displayText = matlab.internal.doc.livecode.getMlxDoc(topic);
            return;
        end
    end
end

%   Copyright 2021-2022 The MathWorks, Inc.

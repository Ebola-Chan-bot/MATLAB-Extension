classdef CshDocPageHandler < matlab.internal.doc.ui.DocPageHandler
	properties
		Size (1,2) double = [400 400];
		Location (1,2) double = [100 100];
		Title (1,1) string = "";
	end

	properties (Dependent)
		Position (1,4) double;
	end

	methods (Access = protected)
		function success = openBrowserForDocPage(obj, url)
			url.Query = [url.Query matlab.net.QueryParameter('browser','F1help') matlab.net.QueryParameter('linkclickhandle','csh')];

			if matlab.internal.doc.services.isOnline
				releaseVersion = strcat("R", version('-release'));
				docLanguage = matlab.internal.doc.i18n.getDocLanguage;

				url.Query = [url.Query ...
					matlab.net.QueryParameter('docrelease',releaseVersion) ...
					matlab.net.QueryParameter('doclanguage',docLanguage)];

				if ~matlab.internal.web.isMatlabOnlineEnv
					url.Query = [url.Query ...
						matlab.net.QueryParameter('docviewer','helpbrowser')];
				end

				loginUrl = getLoginUrl;
				if ~isempty(loginUrl)
					url.Query = [url.Query matlab.net.QueryParameter('loginurl',loginUrl)];
				end
			end

			win = openCshWebWindow(obj, url.string);
			success = ~isempty(win);
		end
	end

	methods
		function position = get.Position(obj)
			% position [left bottom width height]

			if isnumeric(obj.Size) && min(obj.Size) > 0
				size = obj.Size;
			else
				size = [400 400];
			end

			if isnumeric(obj.Location) && min(obj.Location) >= 0
				location = obj.Location;
			else
				location = [100 100];
			end

			% Set the position bottom based on the screen size, the csh
			% window size and the location.
			scrsz = getScreenSize;
			if (scrsz(4)-size(2)-location(2)) > -1
				bottom = (scrsz(4)-size(2)-location(2));
			elseif (scrsz(4)-location(2)) > -1
				bottom = (scrsz(4)-location(2));
			else
				bottom = (location(2)+size(2));
			end

			position = [location(1) bottom size(1) size(2)];
		end
	end

	methods (Access = private)
		function cefWindow = openCshWebWindow(obj, help_path)
			cefWindow = getCshWindow(help_path);
			cefWindow.Position = obj.Position;
			if ~isempty(obj.Title)
				cefWindow.Title = char(obj.Title);
			end
			show(cefWindow);
			bringToFront(cefWindow);
		end
	end

	methods (Static, Access = private)

	end
end

function loginUrl = getLoginUrl
try
	loginUrl = matlab.internal.doc.getConnectorUrlForLogin;
catch
	loginUrl = '';
end
end

function help_url = getHelpPanelUrl(helpPath)
connector.ensureServiceOn;
connector.newNonce;
if getenv('MW_CSH_DEBUG')
	helpPanelPath = 'ui/help/helpbrowser/index-debug.html';
else
	helpPanelPath = 'ui/help/helpbrowser/index.html';
end
uri = matlab.net.URI(connector.getUrl(helpPanelPath));
uri.Query = matlab.net.QueryParameter('loadurl',helpPath);
help_url = string(uri);
end

function screen_size = getScreenSize
% Ensure that we get the screen size in pixels.
originalUnits = get(groot, 'Units');
if ~matches(originalUnits, 'pixels')
	cleanObj = onCleanup(@()set(groot, 'Units', originalUnits));
	set(groot, 'Units', 'pixels');
end
screen_size = get(0,'ScreenSize');
end

function window = getCshWindow(url)
arguments
	url string {mustBeScalarOrEmpty} = string.empty;
end
%埃博拉酱修复开始
window = matlab.internal.webwindow("about:blank");
persistent subscriber
if isempty(subscriber)
	msgService = message.internal.MessageService("helpservices");
	subscriber = msgService.subscribe("/help/cshwindow", @handleMessage);
end
window.URL = getHelpPanelUrl(url);
end

function cshWindow = findCshWindow(cshWinID)
cshWindow = matlab.internal.webwindow.empty;
cefManager = matlab.internal.webwindowmanager.instance();
for cefWindow = cefManager.findAllWebwindows
	if cshWinID == cefWindow.WinID && cefWindow.isWindowValid
		cshWindow = cefWindow;
		return;
	end
end
end
%埃博拉酱修复结束
function handleMessage(msg)
if isstruct(msg) && isfield(msg, "channel") && isfield(msg, "data") && isstruct(msg.data)
	channel = msg.channel;
	data = msg.data;

	switch channel
		case {"openhelpbrowser","externalclick"}
			if isfield(data, "url")
				web(data.url);
			end
		case "consoleeval"
			if all(isfield(data, ["cmdprefix","evalstring"]))
				executeInCommandWindow(join(string({data.cmdprefix, data.evalstring})));
			end
		case "evalselection"
			if isfield(data, "evalselection")
				executeInCommandWindow(data.evalselection);
			end
	end
end
end

function executeInCommandWindow(cmd)
internal.matlab.desktop.commandwindow.executeCommandForUser(cmd);
end

% Copyright 2021-2025 The MathWorks, Inc.
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
			% Perform setup required before launching a help UI.
			matlab.internal.doc.ui.setupForHelpUI;
			url.Query = [url.Query matlab.net.QueryParameter('browser','F1help') matlab.net.QueryParameter('linkclickhandle','csh')];

			if matlab.internal.doc.services.isOnline
				matlab.internal.doc.java.initializeLoginServices;

				if matlab.internal.web.isMatlabOnlineEnv
					docviewerValue = 'ml_online';
				else
					docviewerValue = 'helpbrowser';
				end
				releaseVersion = strcat("R", version('-release'));
				docLanguage = matlab.internal.doc.ui.CshDocPageHandler.getDocCenterLanguage;

				url.Query = [url.Query ...
					matlab.net.QueryParameter('docviewer',docviewerValue) ...
					matlab.net.QueryParameter('docrelease',releaseVersion) ...
					matlab.net.QueryParameter('doclanguage',docLanguage)];

				loginUrl = matlab.internal.doc.ui.CshDocPageHandler.getLoginUrl;
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
			scrsz = matlab.internal.doc.ui.CshDocPageHandler.getScreenSize;
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
			% Add winId so we can reuse the window.

			cefWindow = matlab.internal.webwindow(matlab.internal.doc.ui.CshDocPageHandler.getUrl(help_path, 'winid', 'cshww'), matlab.internal.getDebugPort());
			cefWindow.Position = obj.Position;
			cefWindow.show;

			if ~isempty(obj.Title)
				cefWindow.Title = char(obj.Title);
			end
			cefWindow.bringToFront;
		end
	end

	methods (Static, Access = private)
		function docCenterLanguage = getDocCenterLanguage
			docCenterLanguage = matlab.internal.doc.i18n.getDocLanguage;
		end

		function loginUrl = getLoginUrl
			try
				loginUrl = matlab.internal.doc.getConnectorUrlForLogin;
			catch
				loginUrl = '';
			end
		end

		function cef_window = findCshWindow(winIdName, winIdValue)
			% Find a CEF window with URL containg winid=cshww
			cef_window = [];
			windowId = [winIdName '=' winIdValue];
			windows = matlab.internal.webwindowmanager.instance();
			result = windows.findAllWebwindows;
			for i = 1:numel(result)
				if contains(result(i).URL, windowId)
					cef_window  = result(i);
					break;
				end
			end
		end

		function help_url = getUrl(helpPath, winIdName, winIdValue)
			connector.ensureServiceOn;
			connector.newNonce;
			if getenv('MW_CSH_DEBUG')
				helpPanelPath = 'ui/help/helpbrowser/index-debug.html';
			else
				helpPanelPath = 'ui/help/helpbrowser/index.html';
			end
			uri = matlab.net.URI(connector.getUrl(helpPanelPath));
			uri.Query = [matlab.net.QueryParameter('loadurl',helpPath) matlab.net.QueryParameter('helppanelid',winIdValue) matlab.net.QueryParameter(winIdName,winIdValue)];
			help_url = char(uri.string);
		end

		function screen_size = getScreenSize
			% Ensure that we get the screen size in pixels.
			originalUnits = get(groot, 'Units');
			if ~matches(originalUnits, 'pixels')
				set(groot, 'Units', 'pixels');
				% Restore original units.
				cleanObj = onCleanup(@()set(groot, 'Units', originalUnits));
			end
			screen_size = get(0,'ScreenSize');
		end
	end
end

% Copyright 2021-2022 The MathWorks, Inc.
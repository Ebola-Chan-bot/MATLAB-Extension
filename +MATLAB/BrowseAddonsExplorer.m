%[text] 在系统浏览器中打开附加功能资源管理器
%[text] 附加功能资源管理器本质上是一个网页，可以使用系统浏览器访问。不同于 File Exchange，你可以直接在网页上操作工具箱的安装。相比于MATLAB内置的网页浏览器，使用系统浏览器可以提供更加丰富的网页处理功能。
%[text] 当然，此网页并非脱机，同样依赖MathWorks服务器。当服务器或网络连接异常时，将无法打开。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] MATLAB.BrowseAddonsExplorer;
%[text] %打开附加功能资源管理器的主页
%[text] 
%[text] MATLAB.BrowseAddonsExplorer(Identifier);
%[text] %根据标识符打开特定附加功能的页面
%[text] ```
%[text] ## 输入参数
%[text] Identifier，特定附加功能的标识符。使用matlab.addons.installedAddons可以列出所有已安装附加功能的标识符。
%[text] **See also** [matlab.addons.installedAddons](<matlab:doc matlab.addons.installedAddons>)
function BrowseAddonsExplorer(Identifier)
matlab.internal.addons.Explorer.getInstance;
clientType = com.mathworks.addons.ClientType.EXPLORER;
addOnsCommunicator = com.mathworks.addons.AddonsCommunicator(clientType.getServerToClientChannel, clientType.getClientToServerChannel);
addOnsCommunicator.startMessageService;
com.mathworks.addons_common.notificationframework.UINotifierRegistry.register(clientType.getUINotifier(addOnsCommunicator));
% GETEXPLORERURL Returns the URL to be loaded to open Add-on Explorer

% Copyright: 2019-2022 The MathWorks, Inc.
EXPLORER_LAUNCHER_URL_OFFESET = "toolbox/matlab/addons/AddOnExplorerLauncher.html";

if ~isExplorerSupported()
	baseUrl = connector.getUrl(EXPLORER_LAUNCHER_URL_OFFESET);
	explorerUrlGenerator = matlab.internal.addons.AddOnWindowUrl(baseUrl);
	explorerUrlGenerator.addQueryParameter("showDefaultUnsupportedMsg", true);
	urlToBeLoaded = explorerUrlGenerator.generate.EncodedURI;
else

	platformInfo = matlab.internal.addons.util.explorer.getPlatformInfo();
	locale = strrep(get(0, 'Language'), "_", "-");
	mlRelease = ['R' version('-release')];
	docLanguageLocaleEnum = matlab.internal.doc.services.getDocLanguageLocale;
	docLanguage = docLanguageLocaleEnum.settingLocaleString;
	viewer = matlab.internal.addons.Configuration.viewer;
	connectorUrls = jsonencode(getConnectorUrls());

	baseUrl = strcat(string(matlab.internal.addons.util.explorer.baseUrl.get),"/","loading");
	urlGenerator = matlab.internal.addons.AddOnWindowUrl(baseUrl);
	navigateTo=struct(entryPoint="AddOns");
	if nargin
		navigateTo.identifier=Identifier;
	end
	explorerUrl = urlGenerator.addQueryParameter("navigateTo", jsonencode(navigateTo))...
		.addQueryParameter("platform", platformInfo)...
		.addQueryParameter("language", locale)...
		.addQueryParameter("release", mlRelease)...
		.addQueryParameter("docLanguage", docLanguage)...
		.addQueryParameter("viewer", viewer)...
		.addQueryParameter("connectorUrls", connectorUrls)...
		.addQueryParameter("entitlementId", getEntitlementId())...
		.addQueryParameter("licenseMode", getLicenseMode())...
		.addQueryParameter("ddux", jsonencode(getDduxKeys()))...
		.addQueryParameter("theme", getCurrentTheme())...
		.generate;
	explorerLauncherUrlGenerator = matlab.internal.addons.AddOnWindowUrl(string(connector.getUrl(EXPLORER_LAUNCHER_URL_OFFESET)));
	explorerLauncherUrl = explorerLauncherUrlGenerator.addQueryParameter("explorerUrl", explorerUrl.EncodedURI).generate;

	urlToBeLoaded = explorerLauncherUrl.EncodedURI;
end
web(urlToBeLoaded,'-browser');

	function connectorUrls = getConnectorUrls()
		connectorUrls = struct;
		connectorUrls.matlab = getConnectorUrlForMatlab();
		connectorUrls.login = getConnectorUrlForLogin();
	end

	function url = getConnectorUrlForMatlab()
		urlGenerator = matlab.internal.addons.AddOnWindowUrl(connector.getUrl("toolbox/matlab/addons/GalleryMatlabCommunicator.html"));
		url = urlGenerator.addQueryParameter("useRegFwk", useRegFwk()).generate.EncodedURI;
	end

	function url = getConnectorUrlForLogin()
		loginUrl = matlab.internal.login.getLoginFrameUrl( ...
			"channel", "__mlfpmc__", ...
			"external", true);
		url = connector.getUrl(loginUrl);
	end

	function entitlementId = getEntitlementId()
		licenseMode = matlab.internal.licensing.getLicMode;
		entitlementId = licenseMode.entitlement_id;
	end

	function dduxKeys = getDduxKeys()
		dduxKeys = struct;
		dduxKeys.installationId = string(dduxinternal.getInstallationId);
		dduxKeys.machineHash = string(dduxinternal.getMachineHash);
		dduxKeys.sessionKey = string(dduxinternal.getSessionKey);
	end

	function licenseMode = getLicenseMode()
		if matlab.internal.licensing.canAddonsAllowTrialsForLicense
			licenseMode = "FlexLicense";
		else
			licenseMode = "WebLicense";
		end
	end

	function value = useRegFwk(~)
		% ToDo: If condition can be eliminated when Java cache is deleted.
		if feature('webui')
			value = true;
			return;
		end

		settingsAPI = settings;
		managerSettings = settingsAPI.matlab.addons.manager;
		value = false;
		if managerSettings.hasSetting('UseRegFwk')
			value = managerSettings.UseRegFwk.PersonalValue;
		end
	end

end
%%
function isSupported = isExplorerSupported()
% ISEXPLORERSUPPORTED Private function to determine if Add-On Explorer is supported
% in the current instance of MATLAB.
% Can be configured to return the required value by setting the value of Setting
% matlab.addons.explorer.isExplorerSupported.ActiveValue
% Example:
% s = settings; s.matlab.addons.explorer.addSetting("isExplorerSupported");
% s.matlab.addons.explorer.isExplorerSupported.PersonalValue = false

% Copyright: 2020 The MathWorks, Inc.
s = settings;

if (s.matlab.addons.explorer.hasSetting("isExplorerSupported"))
	isSupported = s.matlab.addons.explorer.isExplorerSupported.ActiveValue;
else
	% Call API provided by MATLAB Online team
	isSupported = true;
end

end
function themeValue = getCurrentTheme(~)
% getCurrentTheme: Get current theme setting

% Copyright: 2022 The MathWorks, Inc.
themeValue = 'Light';

settingsAPI = settings;
themeSettings = settingsAPI.matlab.appearance;
if themeSettings.hasSetting('MATLABTheme')
	themeValue = themeSettings.MATLABTheme.ActiveValue;
end
end

%[appendix]{"version":"1.0"}
%---

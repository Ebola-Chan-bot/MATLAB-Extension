classdef ToolboxConfigurationReader < matlab.internal.addons.metadata.AddonMetadataReader
    
    properties
        key
        configuration
    end
    
    methods(Access = private)
        %helper file for now--this is needed for external paths when
        %returning matlabPaths
        function path = formatSlahesForOPCPackage(obj, path)
            if ispc
                %mostly for external files
                path = strrep(path, ':', '__');
                path = strrep(path, 's\\', '');
                
                %change slashes for OPC
                path = strrep(path,'\','/');
            end
        end
        
        function output = getParamAsChar(obj, key)
            output = obj.configuration.getParamAsString(key);
            if (~isempty(output))
                output = output.toCharArray';
            else
                output = '';
            end
        end
        
        function output = getParamAsString(obj, key)
            output = obj.configuration.getParamAsString(key);
            if (~isempty(output))
                output = string(output.toCharArray');
            end
        end
        
        function file = getSingleFile(obj, filesetKey)
            fileset = obj.configuration.getFileSet(filesetKey);
            fileArray = obj.getFileArray(fileset);
            if(~isempty(fileArray))
                file = fileArray{1};
            else
                file = '';
            end
        end
        
        function indices = expressionCompare(obj, strings, expression)
            indices = ~cellfun('isempty',regexpi(strings,expression,'match','once'));
        end
        
        function indices = findMFilesWithPCodedFile(obj, fileList)
            indices = zeros(size(fileList));
            %have a list of indices of m files
            mIndices = find(obj.expressionCompare(fileList, '.*\.m$'));
            
            %for each m file, see if pfile exists in list
            for i=1:numel(mIndices)
                mIndex = mIndices(i);
                mfile = fileList{mIndex};
                [filepath, name, ~] = fileparts(mfile);
                pfile = fullfile(filepath,strcat(name,'.p'));
                hasPFile = exist(pfile, 'file');
                
                if hasPFile
                    indices(mIndex) = true;
                end
            end
            
        end
        
        function fileArray = getExternalFiles(obj)
            fileset = obj.configuration.getFileSet('fileset.depfun.included');
            fileArray = obj.getFileArray(fileset);
        end
        
        function index = hasPathAtIndex(obj, pathEntry, pathList)
            index = find(strcmp(pathList, pathEntry));
            if isempty(index)
                index = [];
            end
        end
        
        %remove trailing /'s as MATLAB path cleans them out
        function formattedExclusions = formatExclusionList(obj, key)
            excludes = obj.configuration.getParamAsStringList(key);
            formattedExclusions = strings(size(excludes),1);
            rootFolder = obj.getRoot();
            
            for i = 1:size(excludes)
                relativeExclusion = string(excludes.get(i-1));
                fullExclusion = char(fullfile(rootFolder, relativeExclusion));
                if ~exist(fullExclusion) %#ok<EXIST> %could be jar files or dirs
                   fullExclusion = relativeExclusion; 
                end
                if (strcmp(fullExclusion(end),filesep))
                    fullExclusion = extractBetween(fullExclusion, 1, size(fullExclusion,2)-1);
                end
                formattedExclusions(i) = fullExclusion;
            end
        end
        
        function formattedPaths = getFormattedPaths(obj, pathCell, excludesFormatted)
            formattedPaths = obj.getFormattedPathsWithExternalFiles(pathCell, excludesFormatted, []);
        end
        
        function formattedPaths = getFormattedPathsWithExternalFiles(obj, pathCell, excludesFormatted, externalFilePaths)
            
            indices = contains(pathCell,obj.getRoot());
            pathCell = pathCell(indices);
            
            %externalFilePaths are made up locations that will exist on
            %install
            pathCell = [pathCell, externalFilePaths];
            
            if (~isempty(pathCell))
                indicesToExclude = cellfun(@(x) obj.hasPathAtIndex(x,pathCell) , excludesFormatted, 'UniformOutput', 0);
                indicesToExclude = indicesToExclude(~cellfun('isempty',indicesToExclude));
                indices = [indicesToExclude{:}];
                
                logicalIndex(1:size(pathCell,2)) = true;
                if (~isempty(indices))
                    logicalIndex(indices) = false;
                    pathCell = pathCell(logicalIndex);
                end
            end
            
            %clean root out of the paths
            rootFolder = obj.getRoot();
            formattedPaths = cellfun(@(x) erase(x, lineBoundary + rootFolder), pathCell, 'UniformOutput', 0 );
        end
        
        function externalFilePaths = getPathsForRequiredExternalFiles(obj, externalFiles)
            externalFilePaths = cell(1,0);
            for i=1:size(externalFiles, 2)
                originalFilePath = externalFiles{i};
                
                %the external file's parent folder will need to be put on the path
                [parent,~,~] = fileparts(originalFilePath);
                parentFolderToAddToPath = obj.formatSlahesForOPCPackage(parent);
                if(~startsWith(parentFolderToAddToPath,'/'))
                    parentFolderToAddToPath = strcat('/', parentFolderToAddToPath);
                end
                if ~any(strcmp(externalFilePaths,parentFolderToAddToPath))
                    externalFilePaths{end + 1} = parentFolderToAddToPath;
                end
            end
        end
        
        function dom = getDomObjectForXmlText(obj, xmlText)
            fileName = tempname;% fullfile(tempname,'examples.txt');
            fileID = fopen(fileName,'w');
            fprintf(fileID, '%s', string(xmlText));
            fclose(fileID);
            dom = xmlread(fileName);
            delete(fileName);
        end
        
        function fileArray = getFileArray(obj, fileset)
            files = fileset.getFiles();
            fileArray = cell(1,0);
            it = files.iterator;
            i = 1;
            while (it.hasNext())
                file = it.next();
                fileArray{end + 1} = char(file.getAbsolutePath());
                i = i+1;
            end
        end
        
        function formattedPath = formatHelpPath(obj, key)
            formattedPath = obj.getParamAsChar(key);
            rootFolder = obj.getRoot();
            formattedPath = erase(formattedPath, lineBoundary + strcat(rootFolder,filesep));
        end
    end
    
    
    methods(Static)
        function fileFromURL = getFileFromURL(url)
            %download the value from the URL, use websave
            fileProtocol = 'file://';
            
            %clean slashes for windows
            if(ispc)
                url = strrep(url,'\','/');
            end
            
            if(startsWith(url, fileProtocol))
                %if it is a double slash, check if not using hostname
                fileFromURL = erase(url, fileProtocol);
                if (exist(fileFromURL, 'file') && ~startsWith(fileFromURL, '/'))
                    %add one more slash to standardize case for VFIO
                    url = strrep(url, fileProtocol, strcat(fileProtocol,'/'));
                end
                
                %if file protocol use this
                remoteToLocal = matlab.io.internal.vfs.stream.RemoteToLocal(url);
                remoteFile = remoteToLocal.RemoteFileName;
                %we need to copy it ourselves, because the local file
                %is deleted when we exit this scope
                fileFromURL = tempname;
                copyfile(remoteFile, fileFromURL);
            else
                filename = tempname;
                try
					try
						fileFromURL = websave(filename,url);
					catch ME
						if ME.identifier=="MATLAB:webservices:Timeout"
							fileFromURL = websave(filename,replace(url,'www.mathworks.com','ww2.mathworks.cn'));
						else
							ME.rethrow;
						end
					end
				catch ME
                    if (ME.identifier == "MATLAB:webservices:ExpectedProtocol")
                          error(message('MATLAB:toolbox_packaging:packaging:WrongProtocol', url));
                    else
                        throw(ME);
                    end
                    
                end
            end
        end
    end
    
   
    methods
        function obj = ToolboxConfigurationReader(projectFile)
            obj = obj@matlab.internal.addons.metadata.AddonMetadataReader(projectFile);
            import com.mathworks.project.impl.model.Configuration;
            import com.mathworks.toolbox_packaging.services.ToolboxPackagingService;
            service = ToolboxPackagingService;
            try
                obj.key = service.openProject(projectFile);
                obj.configuration = service.getConfiguration(obj.key);
                service.closeProject(obj.key);
            catch e
                error(message('MATLAB:toolbox_packaging:packaging:InvalidToolboxProjectFile',projectFile));
            end
        end
        
        %basic info
        function name = getName(obj)
            name = obj.getParamAsChar("param.appname");
        end
        
        function version = getVersion(obj)
            version = obj.getParamAsChar("param.version");
        end
        
        function guid = getGuid(obj)
            guid = obj.getParamAsChar("param.guid");
        end
        
        function authorStruct = getAuthor(obj)
            authorStruct.name = obj.getParamAsChar("param.authnamewatermark");
            authorStruct.contact = obj.getParamAsChar("param.email");
            authorStruct.organization = obj.getParamAsChar("param.company");
        end
        
        function summary = getSummary(obj)
            summary = obj.getParamAsChar("param.summary");
        end
        
        function description = getDescription(obj)
            description = obj.getParamAsChar("param.description");
        end
        
        function createdInRelease = getCreatedInRelease(obj)
            %should be the release of the running session
            createdInRelease = "";
        end
        
        %may not need this
        function screenshot = getScreenshot(obj)
            screenshot = [];
            fid = fopen(obj.getScreenshotPath(),'rb');
            bytes = fread(fid);
            fclose(fid);
            if ~isempty(bytes)
                screenshot = matlab.net.base64encode(bytes);
            end
        end
        
        function licenseStruct = getLicense(obj)
            %license does not exist for a prj file
            licenseStruct = [];
        end
        
        function examples = getExamples(obj)
            xml = obj.configuration.getParamAsString('param.examples');
            examples = [];
            if ~isempty(xml)
                
                %this is just how it is right now (demos xml is not right)
                aes = com.mathworks.mladdonpackaging.AddonExamples;
                aes.populateFromXMLString(xml);
                modifiedXML = aes.createXMLString();
                doc = obj.getDomObjectForXmlText(modifiedXML);
                
                categories = doc.getElementsByTagName('exampleCategory');
                
                for categoryCnt = 1:categories.getLength()
                    currentCategory = categories.item(categoryCnt-1);
                    if(~isempty(currentCategory))
                        examples(categoryCnt).name = char(currentCategory.getAttribute("name"));
                        categoryExamples = currentCategory.getElementsByTagName("example");
                        for exampleCnt = 1: categoryExamples.getLength()
                            currentExample = categoryExamples.item(exampleCnt-1);
                            examples(categoryCnt).examples(exampleCnt).name = char(currentExample.getAttribute("name"));
                            examples(categoryCnt).examples(exampleCnt).type = char(currentExample.getAttribute("type"));
                            fileNodes = currentExample.getElementsByTagName("file");
                            imageCount = 1;
                            for fileCnt = 1: fileNodes.getLength()
                                currentFile = fileNodes.item(fileCnt-1);
                                type = char(currentFile.getAttribute("type"));
                                value = char(currentFile.getTextContent);
                                switch type
                                    case "source"
                                        examples(categoryCnt).examples(exampleCnt).source = value;
                                    case "thumbnail"
                                        examples(categoryCnt).examples(exampleCnt).thumbnail = value;
                                    case "main"
                                        examples(categoryCnt).examples(exampleCnt).main = value;
                                    case "image"
                                        examples(categoryCnt).examples(exampleCnt).images{imageCount} = value;
                                        imageCount = imageCount +1;
                                    otherwise
                                        %do nothing
                                end
                            end
                        end
                    end
                end
            end
        end
        
        %system requirements
        function platforms = getPlatformCompatibility(obj)
            platforms.win = obj.getParamAsChar('param.compatiblity.windows');
            platforms.linux = obj.getParamAsChar('param.compatiblity.linux');
            platforms.mac = obj.getParamAsChar('param.compatiblity.macos');
            platforms.MATLABOnline = obj.getParamAsChar('param.compatiblity.matlabonline');
        end
        
        %empty struct means any release
        function releaseCompatibilityStruct = getReleaseCompatibility(obj)
            releaseCompatibilityStruct.start = obj.getParamAsChar('param.release.start');
            releaseCompatibilityStruct.end = obj.getParamAsChar('param.release.end');
        end
        
        %external requirements
        %using char to match existing
        function requiredProducts = getRequiredProducts(obj)
            names = obj.configuration.getParamAsStringList('param.products.name');
            ids = obj.configuration.getParamAsStringList('param.products.id');
            versions = obj.configuration.getParamAsStringList('param.products.version');
            requiredProducts=[];
            for i = 1:size(names)
                c = i-1;
                requiredProducts(i).name = char(names.get(c));
                requiredProducts(i).version = char(versions.get(c));
                requiredProducts(i).identifier = char(ids.get(c));
            end
        end
        
        function requiredSupportPackages = getRequiredSupportPackages(obj)
            requiredSupportPackages = [];%obj.getSystemRequirements().supportPackageDependency;
        end
        
        function requiredAddons = getRequiredAddons(obj)
            xml = char(obj.configuration.getParamAsString('param.required.addons'));
            requiredAddons = [];
            
            if ~isempty(xml) && size(xml,1)~=0
                %escape the forward slashes
                xml = strrep(xml, '\','\\');
                doc = obj.getDomObjectForXmlText(xml);
                requiredAddOnsNodes = doc.getElementsByTagName('requiredAddOn');
                addonIndex = 1;
                for addonCnt = 1: requiredAddOnsNodes.getLength()
                    currentAddon = requiredAddOnsNodes.item(addonCnt-1);
                    include =strcmp(currentAddon.getAttribute("include"), "true");
                    if include
                        requiredAddons(addonIndex).name = char(currentAddon.getTextContent);
                        requiredAddons(addonIndex).identifier = char(currentAddon.getAttribute("id"));
                        requiredAddons(addonIndex).earliestVersion = char(currentAddon.getAttribute("earliest"));
                        requiredAddons(addonIndex).latestVersion = char(currentAddon.getAttribute("latest"));
                        requiredAddons(addonIndex).downloadURL = char(currentAddon.getAttribute("downloadURL"));
                        
                        %checksum must be created at package time, it will not
                        %come from prj
                        [checksum, checksumVersion] = obj.getChecksumForAddon(requiredAddons(addonIndex));
                        requiredAddons(addonIndex).checksum = checksum;
                        requiredAddons(addonIndex).checksumVersion = checksumVersion;
                        addonIndex = addonIndex + 1;
                    end
                end
            end
        end
        
        function [checksum, checksumVersion] = getChecksumForAddon(obj, addon)
            checksumVersion = '';
            if ~isempty(addon.downloadURL)
                url = addon.downloadURL;
            else
                [~, url, checksumVersion] = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getAddOnDownloadURL(addon.name, addon.identifier, addon.earliestVersion, addon.latestVersion);
            end
            
            outfilename = matlab.internal.addons.metadata.ToolboxConfigurationReader.getFileFromURL(url);
            %get checksum
            checksum = mlAddonComputeHash(outfilename);
            
            %delete the copied file
            delete(outfilename);
        end
        
        
        function requiredAdditionalSoftware = getRequiredAdditionalSoftware(obj)
            %no-up as we don't have a builtin for this
            names = obj.configuration.getParamAsStringList('param.additional.sw.names');
            licenses = obj.configuration.getParamAsStringList('param.additional.sw.licenses');
            winURL = obj.configuration.getParamAsStringList('param.additional.sw.win.url');
            macURL = obj.configuration.getParamAsStringList('param.additional.sw.mac.url');
            linuxURL = obj.configuration.getParamAsStringList('param.additional.sw.linux.url');
            
            requiredAdditionalSoftware = [];
            for i = 1:size(names)
                c = i-1;
                requiredAdditionalSoftware(i).name = char(names.get(c));
                requiredAdditionalSoftware(i).license = char(licenses.get(c));
                requiredAdditionalSoftware(i).winURL = char(winURL.get(c));
                requiredAdditionalSoftware(i).macURL = char(macURL.get(c));
                requiredAdditionalSoftware(i).linuxURL = char(linuxURL.get(c));
            end
        end
        
        %contents
        function includedApps = getIncludedApps(obj)
            apps = obj.configuration.getParamAsFileList('param.apps');
            %[~,rootFolderName,~] = fileparts(obj.getRoot);
            
            includedApps = [];
            for i = 1:apps.size()
                file = apps.get(i-1);
                location = char(file.getPath());
                try
                    info = mlappinfo(location);
                    
                    relativePath = strrep(location, obj.getRoot, '');
                    relativePath = strrep(relativePath,'\','/');
                    
                    includedApps(i).name = info.name;
                    includedApps(i).guid = info.GUID;
                    includedApps(i).relativePath = relativePath;
                    includedApps(i).installByDefault = 'true';
                catch e
                    %ignore this app
                end
            end
        end
        
        function revisionHistory = getRevisionHistory(obj)
            revisionHistory = [];
        end
        
        
        function fileList = getFileList(obj)
            fileList = [];
            rootFolder = obj.getRoot();
            if(~isempty(rootFolder) && exist(rootFolder,'dir'))
                filesUnderRoot = dir(strcat(rootFolder,'/**/*'));
                allFiles = arrayfun(@(x) fullfile(x.folder,x.name),filesUnderRoot,'UniformOutput',0);
                fileIndices = arrayfun(@(x) isfile(x), allFiles);
                fileList = allFiles(fileIndices);
                
                %file list should include the external file pulled in too
                externalFiles = obj.getExternalFiles();
                fileList = [fileList ; externalFiles'];
                
                %apply exclusions and filters
                filterText = obj.getParamAsString('param.exclude.filters');
                %construct a list of strings from the name
                filesJavaArray = javaArray('java.lang.String',size(fileList,1));
                for i=1:size(fileList,1)
                    relativeUnixStylePath = strrep(erase(fileList{i}, lineBoundary + strcat(rootFolder,filesep)), filesep, '/');
                    filesJavaArray(i) = java.lang.String(relativeUnixStylePath);
                end
                indices = com.mathworks.toolbox_packaging.plugin.FilterRule.getIndicesOfMatch(filterText, filesJavaArray);
                
                %exclude all mltbx
                installMapPath = obj.getInstallMapPath();
                excludePcodedMfile = logical(obj.configuration.getParamAsBoolean('param.exclude.pcodedmfiles'));
                idx = obj.expressionCompare(fileList, '.*\.mltbx$');
                idx = idx | obj.expressionCompare(fileList, '.*\.prj$');
                idx = idx | obj.expressionCompare(fileList, regexptranslate('escape',installMapPath));
                
                iterator = indices.iterator();
                while (iterator.hasNext())
                    %add one for 1 based index
                    idx(iterator.next + 1) = true;
                end
                
                if excludePcodedMfile
                    idx = idx | obj.findMFilesWithPCodedFile(fileList);
                end
                
                fileList(idx) = [];
            end
        end
        
        %configuration TODO
        function javaClassPaths = getJavaClassPaths(obj)
            excludesFormatted = obj.formatExclusionList('param.javaclasspath.excludes');
            
            %we have to locate all the jar files in the toolbox
            jars = dir(strcat(obj.getRoot(),'*/**/*.jar'));
            jarPaths = arrayfun(@(x) fullfile(x.folder,x.name),jars,'UniformOutput',0)';
            javaClassPaths = obj.getFormattedPaths(jarPaths, excludesFormatted);
        end
        
        function matlabPaths = getMATLABPaths(obj)
            excludesFormatted = obj.formatExclusionList('param.matlabpath.excludes');
            
            pathCell = regexp(path, pathsep, 'split');
            %if matlab path not already in here, add it
            if ~any(cellfun(@(x) strcmp(x,obj.getRoot), pathCell))
                pathCell = [pathCell, obj.getRoot];
            end
            externalFiles = obj.getExternalFiles();
            uniqueExternalFilePaths = obj.getPathsForRequiredExternalFiles(externalFiles);
            
            matlabPaths  = obj.getFormattedPathsWithExternalFiles(pathCell, excludesFormatted, uniqueExternalFilePaths);
            
            %change any empty to a single slash
            matlabPaths(strcmp('',matlabPaths)) = {filesep};
        end
        
        function mainFile = getRoot(obj)
            mainFile = obj.getSingleFile("fileset.rootdir");
        end
        
        function docPath = getDocumentationPath(obj)
            docPath = obj.formatHelpPath("param.docs");
        end
        
        function installMapPath = getInstallMapPath(obj)
            installMapPath = obj.formatHelpPath('param.installation.map');
        end
        
        function gsgPath = getGettingStartedGuide(obj)
            gsgPath = obj.formatHelpPath('param.getting.started.guide');
        end
        
        %------------------methods for .prj and Java config only-----------------
        %present in a configuration but not generally in add-on readers
        function projectPath = getProjectPath(obj)
            projectPath = obj.getPath();
        end
        
        function doPublish = doPublishExamplesOnPackage(obj)
            doPublish = logical(obj.configuration.getParamAsBoolean('param.exported.on.package'));
        end
        
        function exclude = excludePcodedMFiles(obj)
            exclude = logical(obj.configuration.getParamAsBoolean('param.exclude.pcodedmfiles'));
        end
        
        function screenshotPath = getScreenshotPath(obj)
            screenshotFile = obj.configuration.getParamAsFile('param.screenshot');
            if(~isempty(screenshotFile))
                screenshotPath = char(screenshotFile.getAbsolutePath());
            else
                screenshotPath = '';
            end
        end
        
        function folderList = getFolderList(obj)
            rootFolder = obj.getRoot();
            folderList = dir(fullfile(rootFolder, '**/*.*'));  %get list of files and folders in any subfolder
            folderList = folderList([folderList.isdir]);
            folderList = arrayfun(@(x) erase(fullfile(x.folder,x.name), [strcat(filesep,"..") + lineBoundary ,strcat(filesep,".") + lineBoundary ]),folderList,'UniformOutput',0);
            folderList = unique(folderList);
            
            %construct a list of strings from the name
            filterText = obj.getParamAsString('param.exclude.filters');
            folderJavaArray = javaArray('java.lang.String',size(folderList,1));
            for i=1:size(folderList,1)
                relativeUnixStylePath = strrep(erase(folderList{i}, lineBoundary + strcat(rootFolder,filesep)), filesep, '/');
                folderJavaArray(i) = java.lang.String(relativeUnixStylePath);
            end
            indices = com.mathworks.toolbox_packaging.plugin.FilterRule.getIndicesOfMatch(filterText, folderJavaArray);
            
            iterator = indices.iterator();
            idx = false(1, size(folderList,1));
            while (iterator.hasNext())
                %add one for 1 based index
                idx(iterator.next + 1) = true;
            end
            folderList(idx) = [];
            %we'll remove the root, as this list meant to be folders added
            %under the opc root
            rootIndex = strcmp(folderList, rootFolder);
            folderList = folderList(~rootIndex);
        end
    end
end
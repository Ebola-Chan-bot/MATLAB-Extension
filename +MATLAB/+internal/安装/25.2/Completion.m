classdef Completion < handle
	% The Completion of a set of functions is a set consisting of the original
	% functions and all the resources that the original set requires in order to
	% run.
	%
	% A Completion consists of:
	%
	%    * A root set, which consists of the original functions.
	%
	%    * A list of parts, which consists of the original functions and the
	%      functions and files the root set requires.
	%
	%    * A Schema, the set of rules that governs the generation of the parts
	%      list from the root set.
	%
	%    * A dependency graph, which describes the function call and file
	%      usage dependencies between the files in the part list.
	%
	%    * A target environment, which identifies the resources and licenses
	%      the Completion may presume to be available.

	% Copyright 2012-2024 The MathWorks, Inc.

	properties (SetAccess = protected)
		Schema
		Platforms
		Target = matlab.depfun.internal.Target.MATLAB;
	end

	properties (SetAccess=private,GetAccess=public)
		LicensedToolboxFilesInRuntimeCalledByUser
	end

	properties (Access=private)
		% Don't initialize any of these properties here, or the value will
		% stick across multiple instances. This is really only an issue for
		% handle objects, but still, good practice to avoid it.

		% The call (or use) tree of dependencies.
		DependencyGraph

		% Excluded files
		ExclusionList

		% Files expected in the target environment.
		ExpectedList

		% Initial inputs -- roots of the call tree (which is really a
		% forest, if you want to be technical about it).
		RootSet

		% Inspectors extract symbols from files and assign classifications
		% to symbols.
		Inspectors

		% A list of symbols that need analysis. Consider symbols equal if
		% their 'WhichResults' fields match.
		ScanList

		% A list of symbols that need deferred analysis.
		DeferredScanList

		% Maximum depth of the dependency forest -- currently, the only
		% useful values are 1 (immediate dependencies only) and inf (all
		% possible dependencies). So why not a boolean? Judgement call.
		CompletionLevel

		% Map file names to vertex IDs for fast lookup.
		File2Vertex

		% Names and root directories of installed toolboxes
		CachedTbxData

		% Slice classes, or not
		sliceClass

		% The name of the symbol class
		symCls

		% Cache of file system data -- WHICH and EXIST
		FsCache

		% Cache the list of files which has been analyzed
		isAnalyzed

		% use database for MATLAB files?
		% true, read dependencies for MATLAB files from existing database
		% false, compute dependencies for MATLAB files without using
		% existing database
		useDB

		% use the exclusion list from database?
		useExclusionListFromDB

		% list of MATLAB files
		matlabFiles

		% Construct from requirementsConstants in Completion constructor.
		dfdb_path
		% DependencyDepot
		DepDepot

		% navigator of the PCM database
		pcm_navigator

		% The map of built-in symbols and owning components (1-to-1)
		builtinSymbolToComponent

		% The map of symbols files built-inList
		builtinList

		% The map of source entries and owning components
		sourceToComponent

		% The map of given files and required components (1-to-many)
		fileToComponents

		% The map of given files and required packages (1-to-many)
		fileToPackages

		% List of undeployable matlab modules
		undeployableMatlabModules

		% A dictionary of license-protected shared directories
		protectedDirs

		% problematic files
		problematicFiles

		% true or false, indicates whether this is a special run for libMATLAB dependency analysis
		isLibMATLABDeps

		% Store PathUtility object for re-use
		PathUtility

		% True if use MATLAB Tasks for parallel cache prepopulation
		USE_TASKS

		% Threaded worker pool to parallely preload caches
		ThreadedPool

		% Clean up function for pool
		PoolCleanup

		% True if is creating dependency database
		inDBCreationMode

		% Threashold value of number of files to use MATLAB Tasks
		% Files under this number will be processed sequencially
		% TODO: Investigate the optimized value for the threashold
		TASK_THREASHOLD = 100

		% mode(autodetect, none, list) for support package inclusion
		supportPackageMode = matlab.depfun.internal.SPMode.NONE
		% list of support packages to include
		supportPackageList = {}

		EnvironmentVariableCleanup
	end

	properties(Constant)
		PlatformExt = initPlatformExt();
	end

	methods (Static)
		function obj = loadobj(S)
			if isstruct(S)
				obj = matlab.depfun.internal.Completion();

				obj.Schema = S.Schema;
				obj.Platforms = S.Platforms;
				obj.Target = S.Target;
				obj.DependencyGraph = S.DependencyGraph;
				obj.ExclusionList = S.ExclusionList;
				obj.ExpectedList = S.ExpectedList;
				obj.RootSet = S.RootSet;

				obj.ScanList = S.ScanList;
				obj.DeferredScanList = S.DeferredScanList;
				obj.CompletionLevel = S.CompletionLevel;
				obj.File2Vertex = S.File2Vertex;
				obj.CachedTbxData = S.CachedTbxData;
				obj.sliceClass = S.sliceClass;
				obj.FsCache = S.FsCache;
				obj.isAnalyzed = S.isAnalyzed;
				obj.useDB = S.useDB;
				obj.matlabFiles = S.matlabFiles;
				obj.dfdb_path = S.dfdb_path;
				obj.symCls = S.symCls;
				obj.PathUtility = S.PathUtility;
				obj.USE_TASKS = S.USE_TASKS;

				obj.builtinSymbolToComponent = S.builtinSymbolToComponent;
				obj.sourceToComponent = S.sourceToComponent;
				obj.fileToComponents = S.fileToComponents;
				obj.fileToPackages = S.fileToPackages;
				obj.problematicFiles = S.problematicFiles;

				% since the MatlabInspector constructor requires those function
				% handles, which relies on the current completion object.
				buildInspector(obj);
			end
		end
	end

	methods (Access = private)

		function principals = builtinPrincipals(obj)
			% Get built-ins from Inspectors
			principals = {};
			inspectorName = keys(obj.Inspectors);
			proxy = matlab.depfun.internal.flatten(values(obj.Inspectors(inspectorName{1}).BuiltinListMap));
			for i = 2:numel(inspectorName)
				% proxy is a cell array of MatlabSymbol
				proxy = [proxy  ...
					matlab.depfun.internal.flatten(values(obj.Inspectors(inspectorName{i}).BuiltinListMap))]; %#ok
			end
			if ~isempty(proxy)
				proxy = [proxy{:}];
				[~,uniq] = unique({proxy.WhichResult});
				proxy = proxy(uniq);
			end

			% Keep only those that are proxies
			keep = arrayfun(@(s)isProxy(s),proxy);
			proxy = proxy(keep);

			% For each, retrieve principals, building up an array of
			% MatlabSymbol objects.
			for j = 1:numel(proxy)
				principals = [ principals proxy(j).principals() ]; %#ok
			end
			if ~isempty(principals)
				principals = unique({principals.WhichResult});
			else
				principals = {};  % Don't return empty MatlabSymbol
			end
		end

		function recordFile2VertexID(obj, file, vid)
			% recordFile2Vertex Remember a file to vertex id mapping.
			if isKey(obj.File2Vertex, file)
				error(message(...
					'MATLAB:depfun:req:InternalDupFileVertex', file));
			else
				obj.File2Vertex(file) = vid;
			end
		end

		function vid = findVertexID(obj, sym)
			% findVertexID Lookup a vertex in the file name -> vertex map
			vid = [];
			file = sym.WhichResult;

			if isKey(obj.File2Vertex, file)
				vid = obj.File2Vertex(file);
			end
		end

		function removeSymbol(obj, sym)
			for k=1:numel(sym)
				vid = findVertexID(obj, sym(k));
				removeVertex(obj.DependencyGraph, vid);
			end
			if ~isempty(sym)
				remove(obj.File2Vertex, {sym.WhichResult});
			end
		end

		function computeDependencies(obj)
			% Compute dependencies if there's anything on the scan list.
			% If the dependency graph is non-empty, it must be left over from
			% a previous computation, so create a new one for this new completion.

			if ~isempty(obj.ScanList)
				% Create new graph if we don't have one, or the one we
				% have is non-empty.
				if isempty(obj.DependencyGraph)
					% Make a new graph object, directed, of course.
					obj.DependencyGraph = ...
						matlab.internal.container.graph.Graph(...
						'Directed', true);

					% Also reset the platform list
					obj.Platforms = matlab.depfun.internal.StringSet;

				end

				while ~isempty(obj.ScanList)
					findDependentFiles(obj);
					sym = knownSymbols(obj);

					% Do not apply additional set rules to extrinsic files.
					if ~isempty(sym)
						extrinsic = [sym.Type] == ...
							matlab.depfun.internal.MatlabType.Extrinsic;
						sym = sym(~extrinsic);
					end

					files = {};
					if ~isempty(sym)
						files = { sym.WhichResult };
					end

					% Apply the set rules
					[addedFiles, keep, ~] = ...
						ruleActions(obj, 'COMPLETION', files);

					% Files removed from the Completion set must be removed
					% from the graph. And all their dependencies too.
					removeSymbol(obj, sym(~keep));

					while ~isempty(addedFiles)
						% Files added to the Completion must be added to the
						% scan list for regular processing. Of course, as the
						% ScanList holds symbols, the files must be made into
						% symbols.
						[files, ignoreFileList] = obj.findAllFiles(addedFiles);
						[sym, uType] = resolveRootSet(obj, files, ignoreFileList);

						% Add the discoverable (apparently real) files of
						% unclaimed type (those for which there are no
						% inspectors) to the list of new symbols.
						[resolved, ~] = resolveUnknownType(obj, uType);

						sym = [sym resolved]; %#ok
						addedFiles = {};

						% TODO? Error if there are unknown unknowns? Which
						% there are if ~isempty(u).

						% Add the new symbols to the scan list.
						for k=1:numel(sym)
							obj.ScanList.enqueue(sym(k));
							if strcmp(sym(k).Ext,'.p')
								pSym = CopyMatlabSymbol(sym(k));
								if findCorrespondentMCode(pSym,'.m')
									addedFiles = [addedFiles pSym.WhichResult]; %#ok
								end
							end
						end

					end
				end
			end
		end

		function [compList, directDeps] = requiredComponents(obj, files)
			% Return a list of required components for given files
			import matlab.depfun.internal.requirementsConstants
			directDeps = cell(1,0);
			compList = cell(1,0); % For UNION
			if ~isempty(files)
				% This section uses the Component-Source data as a compensation
				% for the component boundary violations for 16a.
				owningComp = findComponentBasedOnScmData(obj, files);
				if ~isempty(owningComp)
					compList = union(compList, owningComp);
				end

				if obj.useDB % DFDB
					% WHICH errors if input contains 'built-in ('.
					isWhichResult = true;
					userfiles = obj.PickOutUserFiles(files, isWhichResult);
				else
					userfiles = files;
				end

				% Find component dependencies of each newly analyzed
				% user file.
				if ~isempty(userfiles)
					if obj.Target == matlab.depfun.internal.Target.MCR
						keep = isKey(obj.fileToComponents, userfiles);
						depComp = values(obj.fileToComponents, userfiles(keep));
						depComp = [depComp{:}];
						if ~isempty(depComp)
							compList = union(compList, depComp);
						end
					end

					% Get components required by built-ins directly called
					% in user code.
					builtins = retrieveBuiltinList(obj);
					depComp = obj.pcm_navigator.componentRequiredForBuiltin(builtins)';
					if ~isempty(depComp)
						compList = union(compList, depComp);
					end
				end
				directDeps = compList;

				% G2211025
				% In the scenario, what is being compiled is for MCR target,
				% and functionality solely supported by Simulink Compiler
				% has been detected:
				%
				% If product Simulink Compiler is not installed,
				%     let user know about the product.
				% If product Simulink Compiler is installed and
				%     if its license exists (unnecessarily checkout-able,
				%         e.g. expired license, insufficient floating license),
				%         make sure that at least one model file is detected.
				%         (MCC will attemp to checkout the license later. If that fails,
				%          a standard license checkout error will be issued.)
				%    if its license does not exist or is disabled,
				%         do nothing here. (Extremely rare, if not intentionally disabled.)
				if obj.Target == matlab.depfun.internal.Target.MCR ...
						&& all(ismember({'simulink_simulationinput' 'sl_proxy_interface'}, compList))
					if ~requirementsConstants.isSimulinkCompilerInstalled
						warning(message('Compiler:compiler:COM_WARN_SIMULINK_COMPILER_NOT_INSTALLED'));
					elseif requirementsConstants.isSimulinkCompilerAccessible
						% Simulink Compiler is installed and licensed.

						% Check if SLCompilerRuntimeModelSupport is
						% enabled. This allows the deployed application to
						% choose a model at runtime when the application
						% runs so a model is not required during build
						modelRuntimeSupport = matlab.internal.feature('SLCompilerRuntimeModelSupport');

						if ~any(endsWith(files, requirementsConstants.simulinkModelExt)) && modelRuntimeSupport == 0
							% Issue error if no model file is detected,
							% when Simulink.SimulationInput is detected.
							error(message('Compiler:compiler:COM_ERR_SIMULINK_MODEL_FILE_NOT_FOUND'));
						end
					end
				end

				% Find component dependencies of each pre-analyzed
				% file, including the add-in files, but not the user files.
				% g1810048 need to use obj.matlabFiles here because the
				% list in "files" has been filtered to only existing files
				% obj.DepDepot.requiredComponents needs the m-files in the
				% list even if only the p-file is on disk
				if obj.Target == matlab.depfun.internal.Target.MCR
					mlfiles = setdiff(union(obj.matlabFiles, files), userfiles);
					mlfiles = obj.filterFilesWithLicenseTest(mlfiles);
					if ~isempty(mlfiles)
						% If the user files already depend on all MCR products,
						% unnecessary to query the database for
						% pre-analyzed files for performance.
						precomputedDepComp = obj.DepDepot.requiredComponents(mlfiles)';
						if ~isempty(precomputedDepComp)
							compList = union(compList, precomputedDepComp);
						end
					end
				end
			end
		end

		function pid = productsShippingComponent(obj, components)
			% Return a list of ID of products which ship the given components
			if obj.Target == matlab.depfun.internal.Target.MCR
				test_license = true;
			else
				test_license = false;
			end

			pinfo = obj.pcm_navigator.productShippingComponentWithLicenseTest(components, obj.Target, test_license);
			pid = cell(size(pinfo));
			for k = 1:numel(pinfo)
				if ~isempty(pinfo{k})
					pid{k} = [pinfo{k}.extPID];
				end
			end
		end

		function products = getProductInfo(obj, product_ids, direct_prod_deps)
			% Input:
			%   product_ids - A cell array, whose length is the same as
			%                 the number of required components.
			%                 Each element is a cell array of
			%                 external ids of products required by the
			%                 correspondent component.
			% Output:
			%   products - A struct array that contains a list of unique
			%              required products. Each element has four fileds:
			%              Name - External name of the required product;
			%              Version - version of the required product;
			%              ProductNumber - External product identifier;
			%              Certain - A bool value that indicates the listed
			%                        product is certainly or may be required,
			%                        because more than one products may ship
			%                        the same required component.

			products = struct.empty;

			import matlab.depfun.internal.requirementsConstants

			if obj.Target == matlab.depfun.internal.Target.MCR
				product_ids{end+1} = ...
					requirementsConstants.required_min_product_mcr;
			else
				product_ids{end+1} = ...
					requirementsConstants.required_min_product_other;
			end

			% How many products may ship each required component?
			count_list = cellfun(@(l)numel(l), product_ids);

			% A list of unique products, which are certainly required.
			certain_idx = (count_list == 1);
			unique_list = unique([product_ids{certain_idx}]);
			certain_count = length(unique_list);

			% Found more than one products may ship the same
			% required component. Uncertain which one is really
			% required at this point, so hold the decision
			% to the end.
			pending_idx = (count_list > 1);
			pending_list = product_ids(pending_idx);
			if ~isempty(pending_list)
				for i = 1:numel(pending_list)
					certainIdx = ismember(pending_list{i}, unique_list);
					if ~any(certainIdx)
						% If the pending component has not been shipped
						% by any product. It is uncertain which one is
						% truely required or optimal.
						% Honestly list uncertion options and
						% leave the decision to the customer.
						% For MCR target, just use the lowest numbered runtime product.
						% This can be optimized more in future.
						if obj.Target == matlab.depfun.internal.Target.MCR
							pending_list{i} = min(pending_list{i});
						end

						for j = 1:numel(pending_list{i})
							unique_list(end+1) = pending_list{i}(j); %#ok
						end
					end
				end
			end


			if obj.Target == matlab.depfun.internal.Target.MCR

				% Workaround until a database for base runtime is created.
				if ismember(requirementsConstants.mcr_core_pid, unique_list) ...
						&& ~ismember(requirementsConstants.mcr_graphics_pid, unique_list)
					unique_list(end+1) = requirementsConstants.mcr_graphics_pid;
				end
				if ismember(requirementsConstants.mcr_graphics_pid, unique_list) ...
						&& ~ismember(requirementsConstants.mcr_non_graphics_pid, unique_list)
					unique_list(end+1) = requirementsConstants.mcr_non_graphics_pid;
				end

				% For MCR target, add mcr_jmi to initialize JVM in the deployed
				% mode.
				if ~ismember(requirementsConstants.mcr_graphics_pid, unique_list) ...
						&& ~ismember(requirementsConstants.mcr_jmi_pid, unique_list) ...
						&& ~isempty(intersect(requirementsConstants.mcrProductsNeedJVM, unique_list))
					unique_list(end+1) = requirementsConstants.mcr_jmi_pid;
				end

			end

			for k = 1:numel(unique_list)
				pinfo = obj.pcm_navigator.productInfo(unique_list(k));
				if isempty(pinfo)
					error(message('MATLAB:pcm_db:pcm:UnknownProductID', unique_list(k)));
				end
				products(k).Name = pinfo.extPName;
				products(k).Version = pinfo.version;
				products(k).ProductNumber = pinfo.extPID;

				if obj.Target == matlab.depfun.internal.Target.MCR
					products(k).Certain = ismember(pinfo.extPID, ...
						direct_prod_deps) || pinfo.extPID ~= requirementsConstants.mcr_gpu_pid;
				else
					if k <= certain_count
						products(k).Certain = true;
					else
						products(k).Certain = false;
					end
				end
			end
		end

		function products = requiredProducts(obj, files)
			% requiredProducts What products do these files require?
			% The result is a struct array.
			% Each element contains three fields: Name, Version and
			% ProductNumber, Certain.
			import matlab.depfun.internal.requirementsConstants

			directCalledProdIDs = [];
			product_external_ids = {};
			if ~isempty(files)
				[reqComp, directComps] = obj.requiredComponents(files);

				% A handful of shared directories are protected by license.
				% If user code directly uses functions in those protected
				% dirs, products specified in the lmgr file are required.
				pid_for_lic_protected_shared_dirs = {};
				if isConfigured(obj.protectedDirs)
					lic_protected_shared_dirs = keys(obj.protectedDirs);
					for k = 1:numel(lic_protected_shared_dirs)
						if any(startsWith(files, lic_protected_shared_dirs(k)))
							info = obj.protectedDirs(lic_protected_shared_dirs(k));
							pid_for_lic_protected_shared_dirs{end+1} = info.pid; %#ok
							reqComp(strcmp(reqComp, info.component)) = [];
						end
					end
				end

				% Capture the products potentially directly called by the
				% user
				if ~isempty(directComps)
					directCalledProdIDs = obj.productsShippingComponent(directComps);
					directCalledProdIDs = unique([directCalledProdIDs{:}]);
					directCalledProdIDs = union(directCalledProdIDs,...
						[pid_for_lic_protected_shared_dirs{:}]);
				end

				% Get all products called by the user using transitive
				% closure of toolbox calls.
				if ~isempty(reqComp)
					product_external_ids = ...
						obj.productsShippingComponent(reqComp);
				end

				if ~isempty(pid_for_lic_protected_shared_dirs)
					product_external_ids = [pid_for_lic_protected_shared_dirs ...
						reshape(product_external_ids,1,[])];
				end

				% Work-around for user authored .jar and .class files
				% which are included with -a.
				% MEX files also require mcr_core. (G1318387)
				% Their presence indicates that mcr_core is required.
				if obj.Target == matlab.depfun.internal.Target.MCR ...
						&& any(~cellfun('isempty',regexp(files,'.+\.(jar|class|mex\w+)$')))
					product_external_ids{end+1} = requirementsConstants.mcr_core_pid;
					directCalledProdIDs(end+1) = requirementsConstants.mcr_core_pid;
				end
			end
			products = obj.getProductInfo(product_external_ids, directCalledProdIDs);

			% Raccel built target is only compatible with the current platform.
			if obj.Target == matlab.depfun.internal.Target.MCR ...
					&& ismember(double(requirementsConstants.mcr_raccel_pid), [products.ProductNumber]) ...
					&& any(endsWith(files, requirementsConstants.simulinkModelExt, 'IgnoreCase', true))
				obj.Platforms = matlab.depfun.internal.StringSet(requirementsConstants.arch);
			end
		end

		function symbols = knownSymbols(obj, filter)
			% knownPaths Return all the symbols with paths that match a filter
			if nargin == 1
				filter = '';
			end
			% Retrieve the data objects stored in the graph's vertices.
			symbols = [];
			if obj.DependencyGraph.VertexCount > 0
				symbolList = partProperty(obj.DependencyGraph, 'Data', 'Vertex');
				symbols = [ symbolList.symbol ];

				% Apply the filter, if any, to the paths.
				if ~isempty(filter) && ~isempty(symbols)
					match = regexp({symbols.WhichResults}, ...
						filter, 'once');
					% Keep the symbols with matching paths
					keepIdx = ~cellfun('isempty', match);
					symbols = symbols(keepIdx);
				end
			end
		end

		function traceList = buildTraceList(obj, canonicalPath)
			import matlab.depfun.internal.*

			% Don't canonicalize file paths by default.
			if nargin == 1
				canonicalPath = false;
			end
			traceList = struct([]);

			% Don't do any work if there's nothing to do
			if isempty(obj.DependencyGraph) || ...
					obj.DependencyGraph.VertexCount == 0, return; end

			% An array of the 'Data' objects at every vertex. They'd better
			% be homogenous. Extract the 'symbol' field from the vertex
			% data.
			symbolList = partProperty(obj.DependencyGraph, 'Data', 'Vertex');
			symbolList = [symbolList.symbol];

			% G2015313 Only return top level Simulink model files to MCC.
			if obj.Target == matlab.depfun.internal.Target.MCR ...
					&& requirementsConstants.isSimulinkCompilerAccessible ...
					&& obj.DependencyGraph.EdgeCount > 0
				slmodel_vid = find([symbolList.Type] == MatlabType.SimulinkModel);
				if ~isempty(slmodel_vid)
					% The vertex ID in the graph, written in C++, start
					% from 0. Need to add one here, because MATLAB index
					% starts from 1.
					edges = obj.DependencyGraph.EdgeVectors + 1;
					remove_idx = [];
					for v = slmodel_vid
						client_vid = edges(edges(:,2) == v, 1);
						% Yourself are not your client.
						self_idx = client_vid == v;
						client_vid(self_idx) = [];
						% Circular dependency between Simulink models is
						% explicitly disallowed in the documentation.
						% If all clients of this Simulink model are
						% Simulink models, this one is not top-level.
						if ~isempty(client_vid) && all(ismember(client_vid, slmodel_vid))
							remove_idx = [remove_idx; v]; %#ok
						end
					end
					symbolList(remove_idx) = [];
				end
			end

			% Use while-loop because for k=1:length(symbolList) doesn't
			% re-evaluate length(symbolList) at the beginning of the loop.
			k = 1;
			while k <= length(symbolList)
				% Don't return any dot-qualified symbols, because they
				% might originate from the same file as a non-dot-qualified
				% symbol. The bare form is the canonical form.

				% Note: since any symbol might be a proxy and even
				% MathWorks symbols might have extension directories
				% outside of MathWorks directories, expand every
				% symbol to its (potential) list of principals.

				symbol = symbolList(k);
				pList = principals(symbol);

				if ~isempty(pList)

					% Exclude principals according to the per-target
					% rules. For example, a user class with the same
					% name as a MathWorks class may list MathWorks
					% files as principals. But MathWorks files are
					% supposed to be excluded by certain targets
					% (MATLAB, for example).

					filePath = {pList.WhichResult};
					[exclude, expect] = notShipping(obj,filePath,'COMPLETION');
					keep = ~(exclude | expect);
					pList = pList(keep);

					% Add the principals to the end of the symboList
					% that we're currently looping through. I know,
					% modifying the list you're iterating over is "bad
					% form", but here I am telling you about it -- don't
					% ignore me -- and it is so very convenient.
					if ~isempty(pList)
						symbolList = [symbolList pList]; %#ok
					end
				end

				if matlab.depfun.internal.cacheExist(symbol.WhichResult,'file')
					[exclude, expect] = notShipping(obj,{symbol.WhichResult},'COMPLETION');
					keep = ~(exclude | expect);
					if keep
						traceList(end+1).name = symbol.Symbol; %#ok
						traceList(end).type = char(symbol.Type);
						traceList(end).path = symbol.WhichResult;
						traceList(end).language = 'MATLAB';
					end
				end

				k = k + 1;
			end

			user_alias_files = findUserAliasFiles(traceList);
			for k = 1:length(user_alias_files)
				traceList(end+1).name = 'alias.json';%#ok
				traceList(end).type = char(matlab.depfun.internal.MatlabType.Data);
				traceList(end).path = user_alias_files{k};
				traceList(end).language = 'MATLAB';
			end

			if canonicalPath % Only by request
				for k=1:length(traceList)
					traceList(k).path = strrep(traceList(k).path,'\','/');
				end
			end

			% Never return duplicates.
			if ~isempty(traceList)
				[~,i,~] = unique({traceList.path});
				traceList = traceList(i);
			end

		end

		function known = isInDependencyGraph(obj, d)
			% isInDependencyGraph Determine if the rootSet depends on symbol d.
			% Search the dependency graph for a vertex with the same symbol data.
			% This needs to be very fast since it forms part of the core dynamic
			% discovery algorithm. findIf requires a callback to MATLAB from
			% C++. This may or may not be fast enough.

			% @todo: Possible performance enhancements:
			% * Augment the Completion object with a file name -> vertex ID map,
			%   for hyperspeed lookup. (At the expense of effectively duplicating
			%   much of the graph data.)

			% Find all the parts with a symbol data matching d.
			vid = findVertexID(obj, d);
			known = ~isempty(vid);
		end

		function id = findOrCreateVertex(obj, symbol, create)
			% Find the first vertex with symbol data matching
			% the referant's symbol
			id = findVertexID(obj, symbol);
			if isempty(id) && create
				referant.symbol = symbol;
				id = addVertex(obj.DependencyGraph, referant);
				recordFile2VertexID(obj, symbol.WhichResult, id);
			end
		end

		function recordExclusion(obj, file, reason)
			obj.ExclusionList(end+1).file = file;
			obj.ExclusionList(end).why = reason;
		end

		function recordExpected(obj, file, reason)
			canonicalized = strrep(file, '/', ...
				matlab.depfun.internal.requirementsConstants.FileSep);
			if isempty(obj.ExpectedList)
				rq.file = canonicalized;
				rq.why = reason;
				obj.ExpectedList = rq;
			elseif ~ismember(canonicalized, {obj.ExpectedList.file})
				rq.file = canonicalized;
				rq.why = reason;
				obj.ExpectedList(end+1) = rq;
			end
		end

		function recordPlatformExt(obj, ext)
			% MATLAB extensions are case sensitive.
			% Platform independent file extensions are not keys
			% in obj.PlatformExt.

			% TODO: Refine test for .dll and .so to check for platform
			% specific directory name in path string?
			% TODO: Another suggestion: .dll and .so only imply current
			% platform?

			if isKey(obj.PlatformExt, ext)
				p = obj.PlatformExt(ext);
				add(obj.Platforms, p{:});
			end
		end

		function recordPlatform(obj, service)
			% recordPlatform
			e = service.Ext;
			recordPlatformExt(obj, e);
		end

		function recordClassDependency(obj, client, symbol)
			% recordClassDependency Record dependencies on class files.
			% TODO: Eliminate? Anything special to do here? Most responsibilities
			% moved to ClassSymbol.

			% Make client depend on symbol's proxy.
			recordDependency(obj, client, symbol);

		end

		function enqueueUnanalyzedSymbol(obj, sym)
			if ~obj.useDB ...
					|| ~isempty(obj.PickOutUserFiles(sym.WhichResult,true))
				%  Enqueue the symbol to the scan list only if the file
				% exists and has not been analyzed.
				if matlab.depfun.internal.cacheExist(sym.WhichResult,'file') ...
						&& ~isKey(obj.isAnalyzed, sym.WhichResult)
					obj.ScanList.enqueue(sym);
				end
			end
		end

		function addClassToScanList(obj, proxy)
			% Add the given class (proxy and principals) to the scan list.

			pList = principals(proxy);
			arrayfun(@(s)enqueueUnanalyzedSymbol(obj, s), pList);

			% Add the proxy -- proxy symbol does not appear
			% in its list of principals.
			enqueueUnanalyzedSymbol(obj, proxy);
		end

		function symList = recordDependency(obj, client, service)
			% recordDependency Client depends on service. Write it down.
			import matlab.depfun.internal.MatlabType;
			import matlab.depfun.internal.MatlabSymbol;

			symList = [];

			% ----------------------------
			% Deal with the client symbol
			% ----------------------------

			% Retrieve the proxy symbol for the client. This allows us to
			% capture the dependencies of a principal but represent the
			% principal by the proxy in the dependency graph.
			client = proxy(client);

			% Since the initial RootSet may be different from the
			% initial ScanList, some symbols in that ScanList may
			% not be in the RootSet. They have not yet
			% been inserted into the DependencyGraph before
			% reaching this point. Thus, we need to check the
			% existence of the client too.
			if ~obj.isInDependencyGraph(client)
				source = findOrCreateVertex(obj, client, true);
			else
				source = findOrCreateVertex(obj, client, false);
			end

			% -----------------------------
			% Deal with the service symbol
			% -----------------------------

			if ~isa(service,obj.symCls)
				error(message('MATLAB:depfun:req:InvalidInputType',...
					3,class(service), obj.symCls));
			end

			if isExcluded(obj, service.WhichResult)
				return;
			end

			% Never record a dependency on a principal. You'll likely get it
			% wrong; all the principals required by the input file set
			% should be pulled in by dependencies on their proxies.
			%
			% However, we must record dependencies on static methods of a
			% class, as programs can use static methods without ever
			% creating class instances -- and if no instances are created,
			% no proxy will ever be added to the dependency set.
			if isPrincipal(service) && ~isProxy(service) && ...
					~isStaticMethod(service)
				return;
			end

			% Check if a file isExpected after isPrincipal so that
			% principals don't show up in the expected file list.
			if isExpected(obj, service.WhichResult) && ...
					~isAllowed(obj, 'COMPLETION', service.WhichResult)
				return;
			end

			% Retrieve the proxy symbol for the service. The client
			% already exists in the graph.
			%
			% Proxies protect the graph from having too many redundant
			% edges.
			service = proxy(service);

			% Last chance check for exclusion and requirement
			if ~isExcluded(obj, service.WhichResult) && ...
					(~isExpected(obj, service.WhichResult) || ...
					isAllowed(obj, 'COMPLETION', service.WhichResult))

				% G934738: if the dependent file is a P-file, add it
				% to the completion but don't add it to the ScanList
				if strcmp(service.Ext,'.p')
					tmpPSym = CopyMatlabSymbol(service);
					if ~obj.isInDependencyGraph(tmpPSym)
						target = findOrCreateVertex(obj, tmpPSym, true);
						addEdge(obj.DependencyGraph, source, target);
						matlab.depfun.internal.cacheEdge(source, ...
							target, true);
					else
						target = findOrCreateVertex(obj, tmpPSym, false);
						if ~matlab.depfun.internal.cacheEdge(source, ...
								target, false)
							addEdge(obj.DependencyGraph, source, target);
							matlab.depfun.internal.cacheEdge(source, ...
								target, true);
						end
					end

					% add the correspondent MATLAB file to the completion
					% and ScanList.
					findCorrespondentMCode(service,'.m');
				end

				% Only enqueue services that we haven't analyzed already
				% G1235327
				% The existence of a node in the graph used to be necessary and
				% sufficient to say the file represented by the node has
				% been analyzed. However, this is no longer sufficient,
				% because analyzed class methods can be represented by the
				% same proxy node in the graph, and the proxy itself may
				% have not been analyzed.
				enqueueService = ~isKey(obj.isAnalyzed, service.WhichResult) ...
					&& (obj.CompletionLevel > 0);

				% G886754: if the dependent file is a MEX-file, also add its
				% MATLAB file to the completion but don't add it to the ScanList
				DoesShadowedMFileExist = false;
				if strcmp(service.Ext(2:end), mexext)
					Mfile = strrep(service.WhichResult, service.Ext, '.m');
					if matlab.depfun.internal.cacheExist(Mfile,'file')
						tmpMSym = CopyMatlabSymbol(service);
						tmpMSym.WhichResult = Mfile;
						tmpMSym.Ext = '.m';
						DoesShadowedMFileExist = true;
					end
				end

				% Must analyze the class schema file of UDD classes
				% (that's how we find their parent classes).
				if service.Type == MatlabType.UDDClass
					clsSchema = getUDDClassSchema(service.WhichResult);
					if ~isempty(clsSchema)
						obj.ScanList.enqueue(MatlabSymbol(...
							MatlabSymbol.basename(clsSchema), ...
							MatlabType.UDDMethod, clsSchema));
					end
				end

				% If the service is a UDD package function or a UDD class, look
				% for a package schema file. The service depends on the package
				% schema file if there is one. Recursively record this dependency.
				if (service.Type == MatlabType.UDDPackageFunction && ...
						strcmp(service.Symbol,'schema') == false) || ...
						service.Type == MatlabType.UDDClass

					% The format of the WhichResult differs, so we must use
					% different methods (these techniques don't rise to the
					% level of "algorithm") to find the class directory; also,
					% we can't rely on the class being registered yet.
					clsDir = MatlabSymbol.classDir(service.Symbol);
					if isempty(clsDir)
						clsDir = service.WhichResult;
					end
					if service.Type == MatlabType.UDDPackageFunction
						pkgSchema = getUDDPackageFunctionSchema(clsDir);
					else
						pkgSchema = getUDDPackageSchema(clsDir);
					end
					% If we found one, remember it. If the service is a p-file,
					% copy it before recording a dependency on it, since
					% findCorrespondentMcode will morph it into an MATLAB file --
					% and since MatlabSymbols are handle objects, we'll end up
					% with two files of the same name at different vertices in
					% the graph. And that's a fatal error.
					if ~isempty(pkgSchema)
						pkgSchemaClient = service;
						if strcmp(service.Ext, '.p')
							pkgSchemaClient = CopyMatlabSymbol(service);
						end
						cellfun( ...
							@(ps)recordDependency(obj, pkgSchemaClient, ...
							MatlabSymbol(MatlabSymbol.basename(ps), ...
							MatlabType.UDDPackageFunction, ps)), ...
							pkgSchema, 'UniformOutput', false);
					end
				end

				if ~obj.isInDependencyGraph(service)
					target = findOrCreateVertex(obj, service, true);
					addEdge(obj.DependencyGraph, source, target);
					matlab.depfun.internal.cacheEdge(source, target, true);

					% Remember any platform dependencies created by
					% this file.
					recordPlatform(obj, service);

					% Return array of newly added symbols
					symList = [ symList service ];

					% G886754: if the dependent file is an MEX-file, also add its
					% MATLAB file to the completion but don't add them to the
					% ScanList
					if DoesShadowedMFileExist
						target = findOrCreateVertex(obj, tmpMSym, true);
						addEdge(obj.DependencyGraph, source, target);
						matlab.depfun.internal.cacheEdge(source, target, true);
					end
				else
					target = findOrCreateVertex(obj, service, false);
					if ~matlab.depfun.internal.cacheEdge(source, target, false)
						addEdge(obj.DependencyGraph, source, target);
						matlab.depfun.internal.cacheEdge(source, target, true);
					end

					if DoesShadowedMFileExist
						target = findOrCreateVertex(obj, tmpMSym, false);
						if ~matlab.depfun.internal.cacheEdge(source, target, false)
							addEdge(obj.DependencyGraph, source, target);
							matlab.depfun.internal.cacheEdge(source, target, true);
						end
					end
				end

				% If the dependency is permitted, and we're computing
				% a full completion, add the required file to the
				% list of files that require further analysis. Also
				% enqueue any principals that service may represent.
				if enqueueService
					if isClass(service)
						addClassToScanList(obj, service);
					else
						if ~obj.useDB ...
								|| ~isempty(obj.PickOutUserFiles(service.WhichResult,true))
							obj.ScanList.enqueue(service);
						end
					end
				end
			end
		end

		function recordComponentDependency(obj, client, serviceList)
			% This function records the client's component dependencies.
			% serviceList is a struct that consists of two fields, 'builtin'
			% and 'file', which are cell arrays storing built-in and non-built-in
			% symbols used by the client, respectively.

			compList = cell(1,0);
			if ~isempty(serviceList.builtin)
				keep = isKey(obj.builtinSymbolToComponent, serviceList.builtin);
				if any(keep)
					component = convertStringsToChars(...
						obj.builtinSymbolToComponent(...
						convertCharsToStrings(serviceList.builtin(keep))));
					compList = union(compList, component);
				end
			end

			if ~isempty(serviceList.file)
				remove = obj.isExcluded(serviceList.file);
				fileList = serviceList.file(~remove);

				% This section uses the Component-Source data as a compensation
				% for the component boundary violations for 16a.
				if ~isempty(fileList)
					component = findComponentBasedOnScmData(obj, fileList);
					if ~isempty(component)
						compList = union(compList, component);
					end
				end
			end

			if ~isempty(serviceList.component)
				compList = union(compList, serviceList.component);
			end

			% Remember what components are required for each file.
			if ~isempty(compList)
				obj.fileToComponents(client.WhichResult) = compList;
			end
		end

		function recordPackageDependency(obj, client, pkgList)
			obj.fileToPackages(client.WhichResult) = pkgList;
		end

		function compList = findComponentBasedOnScmData(obj, files)
			import matlab.depfun.internal.requirementsConstants;

			compList = cell(1,0);

			keep = strncmpi(files, requirementsConstants.MatlabRoot, ...
				length(requirementsConstants.MatlabRoot));
			items = files(keep);
			% Remove matlab root
			len = length(requirementsConstants.MatlabRoot)+1;
			items = cellfun(@(p)p(len:end), items, 'UniformOutput', false);

			while ~isempty(items) && ~all(cellfun('isempty', items))
				found = isKey(obj.sourceToComponent, items);
				if any(found)
					component = obj.sourceToComponent(convertCharsToStrings(items(found)));
					compList = convertStringsToChars(union(compList, component));
				end
				items = items(~found);
				% Trim off the last part. FILEPARTS is expensive.
				items = cellfun(@(p)fileparts(p), items, ...
					'UniformOutput', false);
				items = unique(items,'stable');
			end
		end

		function [resolved, unresolved] = resolveUnknownType(~, unknownType)
			% resolveUnknownType Add Extrinsic symbol to root set if file exists
			import matlab.depfun.internal.MatlabSymbol;
			import matlab.depfun.internal.MatlabType;
			import matlab.depfun.internal.cacheWhich;
			import matlab.depfun.internal.cacheExist;

			unresolved = {};
			resolved = {};
			for u = 1:numel(unknownType)
				% Full path to file, or file on the MATLAB path. (Check
				% here for MATLAB file types too, in case they were missed
				% by earlier classifications.)
				if ~isempty(unknownType{u})
					e = cacheExist(unknownType{u}, 'file');
					if e == 2 || e == 3 || e == 4 || e == 6
						[~,name,~]=fileparts(unknownType{u});
						% Do we have a full path, or do we need to look for
						% the file with WHICH?
						if isfullpath(unknownType{u})
							pth = unknownType{u};
						else
							pth = cacheWhich(unknownType{u});
						end
						% Three-argument MatlabSymbol: specify name, type and
						% full path.
						uSym = MatlabSymbol(name, MatlabType.Extrinsic, pth);
						resolved = [ resolved, uSym ]; %#ok
					else
						unresolved = [ unresolved, unknownType(u) ]; %#ok
					end
				end
			end
		end

		function [symbols, undeterminedType] = resolveRootSet(obj, ...
				fileList, ignorableFiles)
			% resolveRootSet Create symbols from the files in the input list.
			% Defer to the expertise of the Inspectors to determine the actual
			% symbol type. Some input names may be unclassifiable; return a
			% list of these names without prejudice.
			import matlab.depfun.internal.MatlabInspector;
			import matlab.depfun.internal.MatlabSymbol;

			% retrieve dependencies for MATLAB files directly from
			% existing database
			if obj.useDB
				userFiles = PickOutUserFiles(obj, fileList);
				fileList = userFiles;
				if ~isempty(ignorableFiles)
					ignorableFiles = PickOutUserFiles(obj, ignorableFiles);
				end
			end

			undeterminedType = {};
			symbols = [];

			% Process excluded and expected files
			for idx = 1:numel(ignorableFiles)
				name = ignorableFiles{idx};
				maybeDir = strrep(fullpath(name,pwd),'\','/');
				s = matlab.depfun.internal.MatlabSymbol('', ...
					matlab.depfun.internal.MatlabType.Ignorable,...
					maybeDir);
				symbols = [ symbols s ]; %#ok
			end

			% For every input name
			num_file = numel(fileList);
			new_sym_list = matlab.depfun.internal.MatlabSymbol.empty(0,num_file);
			for k = 1:num_file
				% Get the next name on the list.
				name = fileList{k};

				% Look for an inspector for the name's file type.
				[~,~,ext] = fileparts(name);

				% Try to find an inspector that knows about name's type of
				% file.
				if ~isempty(ext) && isKey(obj.Inspectors, ext)
					% If the file has an extension, look for an
					% inspector specialized for that file type.
					inspector = obj.Inspectors(ext);
				else
					% No matching inspector -- let MATLAB have the last
					% crack at the name. Note that MatlabInspector will
					% attempt to identify names with no extension.
					inspector = obj.Inspectors('.m');
				end

				%                futures(k) = parfeval(obj.ThreadedPool,@determineType,2,inspector,name);
				%                [a,b] = fetchNext(futures);
				%                    futures = parfeval(obj.ThreadedPool, @matlab.depfun.internal.cacheMtree, 1, name);
				[newSymbol, unknownType] = determineType(inspector,name);
				if ~isempty(newSymbol)
					new_sym_list(k) = newSymbol;
				else
					undeterminedType = [undeterminedType unknownType]; %#ok<AGROW>
				end
			end
			symbols = [symbols new_sym_list(~cellfun('isempty',{new_sym_list.Symbol}))];
		end


		%         function [symbols, undeterminedType] = resolveRootSet(obj, nameList)
		%         % resolveRootSet Create symbols from the files in the input list.
		%         % Defer to the expertise of the Inspectors to determine the actual
		%         % symbol type. Some input names may be unclassifiable; return a
		%         % list of these names without prejudice.
		%             import matlab.depfun.internal.MatlabInspector;
		%             import matlab.depfun.internal.MatlabSymbol;
		%             import matlab.depfun.internal.cacheWhich;
		%             import matlab.depfun.internal.cacheExist;
		%
		%             % retrieve dependencies for MATLAB files directly from
		%             % existing database
		%             if obj.useDB
		%                 userFiles = PickOutUserFiles(obj, nameList);
		%                 nameList = userFiles;
		%             end
		%
		%             undeterminedType = {};
		%             symbols = [];
		%
		%             % For every input name
		%             for k = 1:numel(nameList)
		%                 % Get the next name on the list.
		%                 name = nameList{k};
		%
		%                 % If the name is a directory, recursively add all the files
		%                 % -- but don't process expected or excluded directories.
		%                 % Make sure that filesep is always /, because that's what
		%                 % the expected and excluded patterns use.
		%                 maybeDir = strrep(fullpath(name,pwd),'\','/');
		%                 if exist(maybeDir,'dir') == 7
		%                     if ~isExpected(obj, maybeDir) && ...
		%                         ~isExcluded(obj, maybeDir)
		%                         aDir=maybeDir;
		%
		%                         contents = dir(aDir);
		%                         % Remove '.' and '..'. Use a while loop on the theory
		%                         % that it will be faster on average than find followed
		%                         % by indexed delete -- the entries we wish to discard
		%                         % will almost always be the the first two in the
		%                         % structure.
		%                         n = 1; len = numel(contents);
		%                         chopped = 0;
		%                         while n <= len && chopped < 2
		%                             if strcmp(contents(n).name,'..') || ...
		%                                strcmp(contents(n).name, '.')
		%                                 contents(n) = [];
		%                                 len = len - 1;
		%                                 chopped = chopped + 1;
		%                                 continue; % Don't increment N after deletion.
		%                             end
		%                             n = n + 1;
		%                         end
		%                         % Make a list of full paths to the files in the
		%                         % subdirectory.
		%                         dirFiles = cellfun(@(f)fullfile(aDir,f), ...
		%                                   {contents.name}, 'UniformOutput', false);
		%                         % Recursively resolve the files in the subdirectory.
		%                         [s,uT] = resolveRootSet(obj, dirFiles);
		%                         symbols = [symbols s]; %#ok
		%                         undeterminedType = [undeterminedType uT]; %#ok
		%                     else
		%                         s = matlab.depfun.internal.MatlabSymbol('', ...
		%                             matlab.depfun.internal.MatlabType.Ignorable,...
		%                             maybeDir);
		%                         symbols = [ symbols s ]; %#ok
		%                     end
		%
		%                     % GOTO the next entry
		%                     continue;
		%                 end
		%
		%                 % Look for an inspector for the name's file type.
		%                 [~,~,ext] = fileparts(name);
		%
		%                 % Try to find an inspector that knows about name's type of
		%                 % file.
		%                 if ~isempty(ext) && isKey(obj.Inspectors, ext)
		%                     % If the file has an extension, look for an
		%                     % inspector specialized for that file type.
		%                     inspector = obj.Inspectors(ext);
		%                 else
		%                     % No matching inspector -- let MATLAB have the last
		%                     % crack at the name. Note that MatlabInspector will
		%                     % attempt to identify names with no extension.
		%                     inspector = obj.Inspectors('.m');
		%                 end
		%
		%                 [newSymbol, unknownType] = ...
		%                         determineType(inspector, name);
		%                 % Add the non-excluded resolved symbols to the
		%                 % root set.
		%                 symbols = [ symbols newSymbol ]; %#ok
		%
		%                 % Add the unknownType symbols to the
		%                 % undeterminedType list
		%                 undeterminedType = [undeterminedType unknownType]; %#ok
		%             end
		%         end

		% Excluded: The file should never be part of the completion.
		%
		% Expected: The file forms part of the target environment, and
		%   generally should not be part of the completion. This is both an
		%   optimization (ship fewer files) and an enforcement of business
		%   rules -- our license specifies that expected files should not be
		%   transferred from one machine to another.
		%
		% Allowed: If the file would be removed from the completion because it
		%   is expected, allow it to be present. A file that is both excluded
		%   and allowed is excluded.

		function allowed = isAllowed(obj, fileSet, file)
			% isAllowed Is the file allowed to be part of the given file set?
			allowed = false;
			if ~isempty(obj.Schema)
				allowed = isAllowed(obj.Schema, fileSet, obj.Target, file);
			end
		end

		function [expeto, why] = isExpected(obj, files)
			% isExpected Is the file part of the target's expected feature set?
			if ischar(files)
				files = {files};
			end

			[expeto, why] = matlab.depfun.internal.cacheIsExpected(...
				obj.Schema, obj.Target, files);

			idx = find(expeto);
			for i = idx
				recordExpected(obj, files{i}, why(i));
			end
		end

		function [verboten, why] = isExcluded(obj, files)
			% isExcluded Determine if the Schema excludes a given file
			% Optionally record exclusions.
			if ischar(files)
				files = {files};
			end

			[verboten, why] = matlab.depfun.internal.cacheIsExcluded( ...
				obj.Schema, obj.Target, files, obj.useExclusionListFromDB);

			idx = find(verboten);
			for i = idx
				recordExclusion(obj, files{i}, why(i));
			end
		end

		function findDependentFiles(obj)
			% findDependentFiles Determine the files required by the root set.
			% findDependentFiles computes the completion of the root set. This
			% is the driver function that orchestrates the entire process.
			%
			% 1. Get a file from the list of files to analyze.
			% 2. Examine the file to discover the symbols it uses
			% 3. Determine which of those symbols correspond to functions
			%    or methods.
			% 4. Filter the resulting dependencies against the exclusion list
			%    in the schema.
			% 5. Record the surviving dependencies in the call tree graph.
			% 6. Add the corresponding files to the list of files to analyze.
			% 7. Check the Schema to for dependencies mandated by the newly
			%    discovered files, methods or classes. Add them to the graph and
			%    file list, as appropriate.
			% 8. If there are files left in the list, go back to step 1.
			%
			% The accuracy of steps 2 and 3 is both the most difficult and
			% most important part of the computation. Statically determining the
			% fully-qualified symbol names in a dynamically dispatched language
			% is a difficult problem, especially in the absense of runtime type
			% data.
			import matlab.depfun.internal.requirementsConstants

			% Implements the steps of the driver process
			while ~isempty(obj.ScanList)
				% Get the next file to analyze
				symbol = obj.ScanList.dequeue();
				fileName = symbol.WhichResult;

				% Don't analyze a same file
				if isKey(obj.isAnalyzed,fileName)
					continue;
				end

				% Don't do any work if the file should be excluded
				if isExcluded(obj, fileName), continue; end

				% Stop processing if the file is part of the required
				% target environment, but remember that we need it.
				if obj.PathUtility.underMatlabroot(fileName) && ...
						isExpected(obj, fileName) && ...
						~isAllowed(obj, 'COMPLETION', fileName)
					continue;
				end

				% Code inspectors examine a file to determine what symbols
				% it uses. Look up a code inspector for this file, based
				% on file extension.
				% Note, we cannot use proxySym's Ext because the Ext of
				% a built-in class constructor is empty.
				ext = symbol.Ext;

				if ismember(ext, requirementsConstants.analyzableSimulinkFileExt)
					% Defer the analysis of Simulink model files till the
					% end, only if Simulink is license.
					if requirementsConstants.isSimulinkCompilerAccessible
						obj.DeferredScanList.enqueue(symbol);
						continue;
					end
				end

				% If there's no Inspector for this extension, add the
				% file to the graph as an unconnected vertex. This creates
				% a weakly justified dependency (we know we depend on
				% this file, but we don't know why).
				%
				% Empty extensions fall into this category too, until
				% it becomes necessary to be more sophisticated. (Note that
				% empty filenames have empty extensions, so symbols with
				% no associated file become weakly justified dependencies
				% as well.)
				if ~isKey(obj.Inspectors, ext) || symbol.Type == ...
						matlab.depfun.internal.MatlabType.Extrinsic
					findOrCreateVertex(obj, symbol, true);
					recordPlatform(obj, symbol);

					if strcmp(ext(2:end), mexext)
						Mfile = strrep(symbol.WhichResult,ext,'.m');
						if matlab.depfun.internal.cacheExist(Mfile,'file')
							tmpSym = CopyMatlabSymbol(symbol);
							tmpSym.WhichResult = Mfile;
							tmpSym.Ext = '.m';
							findOrCreateVertex(obj, tmpSym, true);
						end
					end

					continue;
				end

				% for libMATLAB dependency analysis, we want the exception to be handled
				% here and save the problematic file into problematicFiles so that the program
				% can continue
				% for all other analysis, we want the program to stop on any error condition

				if obj.isLibMATLABDeps
					try
						% If symbol doesn't have a proxy, it is its own proxy.
						proxySym = proxy(symbol);
					catch ME
						obj.problematicFiles(symbol.WhichResult) = ME.message();
					end
				else
					% If symbol doesn't have a proxy, it is its own proxy.
					proxySym = proxy(symbol);
				end


				if isClass(symbol)
					recordClassDependency(obj,symbol,symbol);
				else
					findOrCreateVertex(obj, proxySym, true);
					% Remember any platform dependencies created by
					% this file.
					recordPlatform(obj, symbol);
				end

				% Fetch the appropriate code Inspector
				inspector = obj.Inspectors(ext);

				% Analyze the symbols used by the file. The inspector may
				% call back to recordDependency and recordClassDependency,
				% so it is likely that our internal data will change as a
				% result of this call.
				%
				% for libMATLAB dependency analysis, we want the exception to be handled
				% here and save the problematic file into problematicFiles so that the program
				% can continue
				% for all other analysis, we want the program to stop on any error condition

				try
					analyzeSymbol(inspector, symbol);
				catch ME
					obj.problematicFiles(symbol.WhichResult) = ME.message();
				end

				% record files that have been analyzed
				obj.isAnalyzed(fileName) = 1;

				% Add any toolbox-specific includes to the dependency graph.
				% Make sure to pass the full path, or the machinery to identify
				% the owning toolbox may fail.
				reqList = statutoryIncludes(obj.Schema, obj.Target, fileName);
				% TODO: For performance, lookup symbol's VertexID here, and
				% use it in addEdge below.
				for k=1:length(reqList)
					if strcmp(reqList{k}.language, 'data')
						type = matlab.depfun.internal.MatlabType.Ignorable;
					else
						type = matlab.depfun.internal.MatlabType.Function;
					end
					reqSymbol = ...
						matlab.depfun.internal.MatlabSymbol.makeFileSymbol(...
						reqList{k}.path, type);
					addEdge(obj.DependencyGraph, proxySym, reqSymbol);
				end
			end

			while ~isempty(obj.DeferredScanList)
				% Get the next file to analyze
				symbol = obj.DeferredScanList.dequeue();
				fileName = symbol.WhichResult;

				% Don't analyze a same file
				if isKey(obj.isAnalyzed,fileName)
					continue;
				end

				% Fetch the appropriate code Inspector
				inspector = obj.Inspectors(symbol.Ext);

				analyzeSymbol(inspector, symbol);

				% record files that have been analyzed
				obj.isAnalyzed(fileName) = 1;
			end
		end

		function fileSet = applySetRules(obj, fileSet, setName)
			% Apply the rules for a named set to the contents of the set.
			[addedFiles, keep, ~] = ruleActions(obj, setName, fileSet);
			fileSet = fileSet(keep);
			fileSet = [fileSet addedFiles];
			[exc, exp] = notShipping(obj, fileSet, setName);
			gone = exc | exp;
			fileSet = fileSet(~gone);
		end

		function traceList = filterTraceList(obj, traceList, ruleSetName)
			fileSet = {traceList.path};
			[~, keep] = ruleActions(obj, ruleSetName, fileSet);
			traceList = traceList(keep);
			fileSet = {traceList.path};
			[exc, exp] = notShipping(obj, fileSet, ruleSetName);
			gone = exc | exp;
			traceList = traceList(~gone);
		end

		function [addedFiles, rmFilter, rMap] = ruleActions(obj, fileSet, files)
			% Apply the rule sets to determine if they add or remove any
			% additional files.
			[modifiedList, rMap] = ...
				applySetRules(obj.Schema, obj.Target, fileSet, ...
				files);
			% Don't add duplicate files to the list. Filter out (from the
			% list of added files) any files we already have in the list
			% of input files.
			addedFiles = setdiff(modifiedList, files, 'legacy');

			% Should any files be removed from the list of files? Make a
			% logical index to actually remove them.
			[~,rmIdx] = setdiff(files, modifiedList, 'legacy');
			rmFilter = true(1,numel(files));
			rmFilter(rmIdx) = false;
		end

		function [excluded, expected] = notShipping(obj, files, setName)
			% notShipping Compute logical index of excluded and expected files.
			fcount = numel(files);
			expected = false(1,fcount);
			excluded = false(1,fcount);

			if obj.USE_TASKS && numel(files) > obj.TASK_THREASHOLD
				obj.preloadIsExpectedCache(files);
			end

			for k=1:numel(files)
				f = files{k};
				excluded(k) = isExcluded(obj, f);
				expected(k) = obj.PathUtility.underMatlabroot(f) && ...
					isExpected(obj, f) && ...
					~isAllowed(obj, setName, f);
			end
		end

		function preloadIsExpectedCache(obj, files)
			% preloadIsExpecedCache load isExpeced using Tasks workers and
			% preload data into cache
			import matlab.depfun.internal.cacheIsExpected

			pool = obj.ThreadedPool;
			numWorkers = pool.NumWorkers;
			fileLens = numel(files);

			for idx = 1:numWorkers
				[startIdx, endIdx] = obj.calculateChunkRange(idx, numWorkers, fileLens);
				if (startIdx > 0)
					list = files(startIdx:endIdx);
					futures(idx) = parfeval(pool, @isExpected, 2,...
						obj.Schema, obj.Target, list); %#ok<AGROW>
				end
			end
			cancelFutures = onCleanup(@() cancel(futures));

			% Collect result from workers and load data into cache
			for idx = 1:numel(futures)
				[finishIdx, ue, uw] = fetchNext(futures);

				[startIdx, endIdx] = obj.calculateChunkRange(finishIdx, numWorkers, fileLens);
				list = files(startIdx:endIdx);

				e = false(1,numel(list));
				w(1:numel(list)) = struct('identifier', '', 'message', '', 'rule', '');

				if ~isempty(uw)
					e(listIdx(ue)) = true;
					w(listIdx(ue)) = uw(ue); %#ok<AGROW>
				end

				ce = num2cell(e);
				cw = num2cell(w);
				ie(numel(list)) = struct; %#ok<AGROW>
				[ie.expeto] = ce{:};
				[ie.why] = cw{:};

				append = containers.Map(list, num2cell(ie));
				cacheIsExpected(append);
				clear ie;
			end

			%             [ue, uw] = isExpected(obj.Schema, obj.Target, files);
		end

		function [startIdx, endIdx] = calculateChunkRange(obj, idx, numWorkers, length)
			unitLens = ceil(length / numWorkers);
			if unitLens <= obj.TASK_THREASHOLD
				unitLens = obj.TASK_THREASHOLD;
			end

			startIdx = 1 + (idx-1)*unitLens;
			if startIdx > length
				startIdx = -1;
				endIdx = -1;
				return;
			end

			endIdx = idx*unitLens;
			if endIdx > length
				endIdx = length;
			end
		end

		function rootSymbols = initializeRootSet(obj, files)
			% initializeRootSet Process the files that will form the roots of
			% the dependency forest (there may be multiple roots if there is
			% more than one entry point).
			%
			% Called by the constructor and no other function. Factored out
			% to reduce code complexity (the constructor may be called with
			% no files.)

			% Expand directories to files to eliminate recursive call of
			% resolveRootSet
			% Only do this when users are calling dependency analysis on
			% user-defined code
			if ~obj.inDBCreationMode
				[files, ignoreFileList] = obj.findAllFiles(files);
			else
				ignoreFileList = {};
			end

			if obj.USE_TASKS && numel(files) > obj.TASK_THREASHOLD
				% Pre-populate Mtree cache
				% obj.preloadMtreeCache(files);
				% Pre-populate Which and Exist Cache
				obj.preloadExistWhichCache(files);
				if ~isempty(ignoreFileList)
					obj.preloadExistWhichCacheTasks(ignoreFileList);
				end
			end

			% Must create Inspector map before processing arguments, because
			% function classification uses Inspectors.
			[rootSymbols, unknownType] = resolveRootSet(obj, files, ignoreFileList);

			% Add the discoverable (apparently real) files of unclaimed
			% type (those for which there are no inspectors) to the root
			% set.
			[resolved, ~] = resolveUnknownType(obj, unknownType);
			rootSymbols = [rootSymbols resolved];

			% It's an error if there's nothing in the root set. That means
			% we couldn't locate any of the input files.
			if isempty(rootSymbols)
				if obj.useDB
					return;
				else
					% input may be more than one empty folders
					if ischar(files)
						tmpStr = files;
					else
						tmpStr = sprintf('%s, ', files{:});
						tmpStr = tmpStr(1:end-2);
					end
					error(message('MATLAB:depfun:req:NameIsAnEmptyDirectory', tmpStr));
				end
			end

			% Some symbol may have multiple WhichResult's. In other words, a
			% cell in the cell array 'files' may be also a cell array.
			% This causes problem in the following steps. Thus, we need
			% to reformat the cell array 'files' to make sure each cell
			% only contain one string.
			org_num_rootSymbols = numel(rootSymbols);
			actual_num_rootSymbols = 0;
			for i = 1:org_num_rootSymbols
				if iscell(rootSymbols(i).WhichResult)
					actual_num_rootSymbols = actual_num_rootSymbols + length(rootSymbols(i).WhichResult);
				else
					actual_num_rootSymbols = actual_num_rootSymbols + 1;
				end
			end

			if actual_num_rootSymbols ~= org_num_rootSymbols
				tmp_list = [];
				for i = 1:org_num_rootSymbols
					if ~iscell(rootSymbols(i).WhichResult)
						tmp_list = [tmp_list rootSymbols(i)]; %#ok
					else
						SymbolList = makeSymbolList(rootSymbols(i));
						for j = 1:length(SymbolList)
							tmp_list = [tmp_list SymbolList(j)]; %#ok
						end
					end
				end
				rootSymbols = tmp_list;
			end

			rootSymbols = unique(rootSymbols);

			% Extrinsic symbols should be separated from rootSymbols.
			% They will be firstly added to the scanlist then be added to
			% dependency graph later without analysis.
			% For performance we will not add another rule in the rdl file.
			extrinsic = [rootSymbols.Type] == ...
				matlab.depfun.internal.MatlabType.Extrinsic;
			extrinsicSymbols = rootSymbols(extrinsic);
			rootSymbols = rootSymbols(~extrinsic);
			for k=1:numel(extrinsicSymbols)
				obj.ScanList.enqueue(extrinsicSymbols(k));
			end

			[addedFiles, ruleFilter, notes] = ...
				ruleActions(obj, 'ROOTSET', {rootSymbols.WhichResult});

			% Filter out the files removed by the rules. ruleFilter is a
			% logical index (a mask). FALSE means remove the file at that
			% position.
			removed = rootSymbols(~ruleFilter);
			rootSymbols = rootSymbols(ruleFilter);

			% The rules may have shifted some files from the ROOTSET into
			% the COMPLETION. Add those files to the scan list. Note:
			% symbols for these moved files are already on the removed
			% list.
			if isKey(notes, 'COMPLETION') && ~isempty(notes('COMPLETION'))
				% Get the list of files moved to the COMPLETION
				movedFiles = notes('COMPLETION');
				% Prepare a logical index to extract the moved files from
				% the removed files list.
				movedIdx = zeros(size(removed));
				% For efficiency, create the cell array of removed files
				% outside the loop.
				removedFiles = { removed.WhichResult };
				% For each moved file, find the index of the corresponding
				% symbol in the removed list.
				for k=1:numel(movedFiles)
					movedIdx = movedIdx | strcmp(movedFiles{k}, removedFiles);
				end
				% Extract the symbols for the moved files from the removed
				% file list.
				sym = removed(movedIdx);
				% The moved files weren't really removed, so we don't want
				% to record them on the exclusion list. So, take the
				% moved files off the removed files list. (Moved / removed,
				% the terminology is a bit confusing, for which I
				% apologize.)
				removed = removed(~movedIdx);
				% Filter the moved files against the exclusion and expected
				% lists, just in case some of the moved files actually need
				% to be excluded.
				[exc, exp] = notShipping(obj, {sym.WhichResult}, 'COMPLETION');
				% Put the moved (yet excluded) files back on the removed
				% list.
				removed = [removed sym(exc)];
				% Take the moved, yet excluded or expected files off of the
				% moved files list. Remember the expected files.
				expected = sym(exp);
				sym = sym(~(exc | exp));

				% Add the expected files to the list of expected files.
				for k=1:numel(expected)
					file = expected(k).WhichResult;
					recordExpected(obj, file, notes(file));
				end

				% Finally, place the brave survivors on the ScanList,
				% whence they will eventually enter the COMPLETION.
				for k=1:numel(sym)
					% enqueue the original symbol
					obj.ScanList.enqueue(sym(k));

					% (1) If the file is p-code, link it to
					%     its correspondent m-code. If the corresponding
					%     m-code doesn't exist or is empty/nothing but
					%     comments, throw a warning.
					% (2) If the file is m-code, then do nothing.
					if strcmp(sym(k).Ext,'.p')
						% Since MatlabSymbol is a handle object, we have to
						% create a new object to contain new information.
						pSym = CopyMatlabSymbol(sym(k));
						if findCorrespondentMCode(pSym,'.m')
							addedFiles = [addedFiles pSym.WhichResult]; %#ok
						end
					end

					% (1) If the file is fig-file, link it to its
					%     correspondent .m and .mlx file. If the
					%     m-code doesn't exist or is empty/nothing but
					%     comments, throw a warning.
					% (2) If the file is m-code, then do nothing.
					if strcmpi(sym(k).Ext,'.fig')
						figSym1 = CopyMatlabSymbol(sym(k));
						if findCorrespondentMCode(figSym1,'.mlx')
							addedFiles = [addedFiles figSym1.WhichResult]; %#ok
						end

						figSym2 = CopyMatlabSymbol(sym(k));
						if findCorrespondentMCode(figSym2,'.m')
							addedFiles = [addedFiles figSym2.WhichResult]; %#ok
						end
					end
				end
			end

			% Add the files that were truly removed (not those that just
			% got moved to the COMPLETION) to the exclusion list.
			for k=1:numel(removed)
				file = removed(k).WhichResult;
				recordExclusion(obj, file, notes(file));
			end

			% Resolve the new files into symbols (and add them to the root
			% set); a Completion is a handle object, so methods can have
			% side-effects.
			if ~isempty(addedFiles)
				[addFiles, ignoreAddedFiles] = obj.findAllFiles(addedFiles);
				rootSymbols = [ rootSymbols resolveRootSet(obj, addFiles, ignoreAddedFiles) ];
			end

			% Test root set files for exclusion.
			[exc, exp] = notShipping(obj, {rootSymbols.WhichResult}, 'ROOTSET');
			gone = exc | exp;

			% Remove excluded files from the root set. (Or, more precisely,
			% retain all non-excluded files in the root set.)
			rootSymbols = rootSymbols(~gone);

			% If there are no symbols in the root set, warn the user that
			% the Completion contains no entry points.
			%             if isempty(rootSymbols)
			%                 warning(message('MATLAB:depfun:req:NoEntryPoints', ...
			%                                  char(obj.Target)));
			%             end

		end

		% Get which and exist result of files using Tasks workers and
		% load data into cache
		function preloadExistWhichCache(obj, files)
			import matlab.depfun.internal.cacheWhich
			import matlab.depfun.internal.cacheExist

			pool = obj.ThreadedPool;
			numWorkers = pool.NumWorkers;
			length = numel(files);
			creatDB = obj.inDBCreationMode;

			for idx = 1:numWorkers
				% Break down files into chunks and get chunk range
				[startIdx, endIdx] = obj.calculateChunkRange(...
					idx, numWorkers, length);
				% If a chunk is available, start a worker to get which and
				% exist results for this chunk
				if startIdx > 0
					futures(idx) = parfeval(pool, ...
						@preloadWhichExistCacheTasks, 3, ...
						creatDB, files(startIdx:endIdx)); %#ok<AGROW>
				end
			end
			cancelFuture = onCleanup(@() cancel(futures));

			% Collect which and exist results from workers and load into
			% cache
			for idx =1:numel(futures)
				[~, finishFiles, finishWhich, finishExist] = fetchNext(futures);
				if ~isempty(finishFiles)
					cacheWhich(finishFiles, finishWhich);
					cacheExist(finishFiles, 'file', finishExist);
				end
			end
		end

		function [result, ignorableList] = findAllFiles(obj, nameList)
			% retrieve dependencies for MATLAB files directly from
			% existing database
			if obj.useDB
				userFiles = PickOutUserFiles(obj, nameList);
				nameList = userFiles;
			end

			result = {};
			ignorableList = {};
			listLen = numel(nameList);

			% For every input name
			for ii = 1:listLen
				name = nameList{ii};

				% If the name is a directory, recursively add all the files
				% -- but don't process expected or excluded directories.
				% Make sure that filesep is always /, because that's what
				% the expected and excluded patterns use.
				maybeDir = strrep(fullpath(name,pwd),'\','/');
				if exist(maybeDir,'dir') == 7
					if (~obj.PathUtility.underMatlabroot(maybeDir) ...
							|| ~isExpected(obj, maybeDir)) && ...
							~isExcluded(obj, maybeDir)
						aDir=maybeDir;

						contents = dir(aDir);
						% Remove '.' and '..'. Use a while loop on the theory
						% that it will be faster on average than find followed
						% by indexed delete -- the entries we wish to discard
						% will almost always be the the first two in the
						% structure.
						n = 1; len = numel(contents);
						chopped = 0;
						while n <= len && chopped < 2
							if strcmp(contents(n).name,'..') || ...
									strcmp(contents(n).name, '.')
								contents(n) = [];
								len = len - 1;
								chopped = chopped + 1;
								continue; % Don't increment N after deletion.
							end
							n = n + 1;
						end
						% Make a list of full paths to the files in the
						% subdirectory.
						dirFiles = cellfun(@(f)fullfile(aDir,f), ...
							{contents.name}, 'UniformOutput', false);
						% Recursively resolve the files in the subdirectory.
						[newNameList, newIgnore] = obj.findAllFiles(dirFiles);
						result = [ result newNameList ];%#ok
						ignorableList = [ignorableList newIgnore];%#ok
					else
						ignorableList = [ignorableList maybeDir];%#ok
					end
				else
					name = {name};
					result = [ result name ];%#ok
				end
			end
		end

		%         % This appears unused?
		%         function preloadWhichExistCache(obj, files)
		%             for idx = 1:numWorkers
		%                 % Break down files into chunks and get chunk range
		%                 [startIdx, endIdx] = obj.calculateChunkRange(...
		%                     idx, numWorkers, length);
		%                 % If a chunk is available, start a worker to get which and
		%                 % exist results for this chunk
		%                 if startIdx > 0
		%                     futures(idx) = parfeval(pool, ...
		%                         @preloadWhichExistCacheTasks, 3, ...
		%                         creatDB, files(startIdx:endIdx)); %#ok<AGROW>
		%                 end
		%             end
		%             cancelFuture = onCleanup(@() cancel(futures));
		%
		%             % Collect which and exist results from workers and load into
		%             % cache
		%             for idx =1:numel(futures)
		%                 [~, finishFiles, finishWhich, finishExist] = fetchNext(futures);
		%                 if ~isempty(finishFiles)
		%                     cacheWhich(finishFiles, finishWhich);
		%                     cacheExist(finishFiles, 'file', finishExist);
		%                 end
		%             end
		%
		%         end

		% Get mtree for files using Tasks workers and load mtrees into
		% cache
		%         function preloadMtreeCache(obj, files)
		%             import matlab.depfun.internal.cacheMtree
		%
		%             pool = obj.ThreadedPool;
		%             numWorkers = pool.NumWorkers;
		%             fileLens = numel(files);
		%
		%             % Start workers to execute mtree
		%             % Each worker process at least obj.TASK_THREASHOLD number of
		%             % files
		%             for idx = 1:numWorkers
		%                 [startIdx, endIdx] = obj.calculateChunkRange(idx, numWorkers, fileLens);
		%                if startIdx > 0
		%                     list = files(startIdx:endIdx);
		%                     futures(idx) = parfeval(pool, @preloadMtreeCacheTasks, 1,...
		%                         list);
		%                end
		%             end
		%
		%             for nCompleted = 1:numel(futures)
		%                 [~,finishMtree] = fetchNext(futures);
		%                 cacheMtree(finishMtree);
		%             end
		%             clear futures;
		%         end

		function buildInspector(obj)
			% Create an expandable struct to pass object handles to inspectors.
			objHandles.rules = obj.Schema;
			objHandles.target = obj.Target;
			objHandles.fsCache = obj.FsCache;
			objHandles.pathutil = obj.PathUtility;

			% Create an expandable struct to pass flags to inspectors.
			flags.useDB = obj.useDB;

			% Create functions that allow inspectors to add dependencies
			% and exclusions to the completion.
			weakRefObj = matlab.lang.WeakReference(obj);
			fcnHandles.addDep = @(client, symbol)recordDependency(weakRefObj.Handle, client, symbol);
			fcnHandles.addClassDep = @(client, symbol)recordClassDependency(weakRefObj.Handle, client, symbol);
			fcnHandles.addComponentDep = @(client, service)recordComponentDependency(weakRefObj.Handle, client, service);
			fcnHandles.addPackageDep = @(client, service)recordPackageDependency(weakRefObj.Handle, client, service);
			fcnHandles.addExclusion = @(file, why)recordExclusion(weakRefObj.Handle, file, why);
			fcnHandles.addExpected =  @(file, why)recordExpected(weakRefObj.Handle, file, why);
			fcnHandles.pickUserFiles = @(files)PickOutUserFiles(weakRefObj.Handle, files);

			m = matlab.depfun.internal.MatlabInspector(objHandles, fcnHandles, flags);

			% .m, .mlx, and .mlapp files share the same inspector.
			% .p files are not analyzed.
			import matlab.depfun.internal.requirementsConstants;
			for ext = requirementsConstants.analyzableMatlabFileExt
				obj.Inspectors(ext{1}) = m;
			end
			obj.Inspectors('.sfx') = m;

			mat = matlab.depfun.internal.MatFileInspector(objHandles, fcnHandles, flags);
			obj.Inspectors('.mat') = mat;

			if requirementsConstants.isSimulinkCompilerAccessible
				slx = matlab.depfun.internal.SimulinkModelInspector(objHandles, fcnHandles, flags);
				for ext = requirementsConstants.analyzableSimulinkFileExt
					obj.Inspectors(ext{1}) = slx;
				end
			end
		end

		function userFiles = PickOutUserFiles(obj, inputs, varargin)
			% Differentiate MATLAB files and user files. Note that inputs may
			% be symbols as well -- all inputs are passed to WHICH. If WHICH
			% finds a file, this function copies that file -- name unchanged,
			% even if the name was partial or relative -- to the output
			% userFiles. The test for case-sensitive function name matching
			% relies on this behavior (that the names are unchanged).
			import matlab.depfun.internal.cacheWhich;
			import matlab.depfun.internal.cacheExist;
			import matlab.depfun.internal.requirementsConstants;

			if ischar(inputs)
				inputs = { inputs };
			end

			if numel(varargin) == 0
				isWhichResult = false;
			else
				isWhichResult = varargin{1};
			end

			MatlabFiles = {};
			userFiles = {};
			for i = 1:numel(inputs)
				% If the input is already a result returned by WHICH, don't
				% call WHICH again.
				if isWhichResult
					w = inputs{i};
				else
					w = cacheWhich(inputs{i});
				end

				% 16b work-around for g1329309
				% Ignore files from undeployable matlab modules.
				% Files under $(MATLABROOT)/toolbox but not on the
				% MATLAB search path.
				% No exclude reason is needed because they are not supposed
				% to be found at all.
				fpath = '';
				if ~isempty(w)
					fpath = w;
				elseif cacheExist(inputs{i},'file')
					fpath = inputs{i};
				end

				if obj.PathUtility.isFromUndeployableMatlabModule(fpath,obj.undeployableMatlabModules)
					continue;
				end

				% Ignore class methods except static methods,
				% because which('symbol') is an inappropriate question
				% for class methods.
				if isWhichResult || (~isWhichResult && isempty(strfind(inputs{i},'.')))
					if obj.DepDepot.isPrincipal(w)
						continue;
					end
				end

				% G954614: Put built-in's in userFiles so that they can be
				% removed with an explicit reason in a later step
				% in initializeRootSet().
				if ~isempty(w) && ~strncmp(w, ...
						requirementsConstants.BuiltInStrAndATrailingSpace,...
						requirementsConstants.lBuiltInStrAndATrailingSpace)
					if isExcluded(obj, w)
						continue;
					end

					% If a file path doesn't start with matlabroot, don't
					% waste time to check if it is expected.
					if obj.PathUtility.underMatlabroot(w) && isExpected(obj, w)
						MatlabFiles{end+1} = w; %#ok
						% look up corresponding m-code for p-code
						if hasext(w,'.p')
							MatlabFiles{end+1} = regexprep(w,'\.p$','.m'); %#ok
						end
					else
						userFiles{end+1} = inputs{i}; %#ok
					end
				else
					userFiles{end+1} = inputs{i}; %#ok
				end
			end

			obj.matlabFiles = [obj.matlabFiles MatlabFiles];
		end

		function builtinList = retrieveBuiltinList(obj)
			% retrieve used built-ins from inspectors
			builtinList = cell(1,0);
			inspectorName = keys(obj.Inspectors);
			for i = 1:numel(inspectorName)
				% tmpLis is a cell array of MatlabSymbol
				tmpList = matlab.depfun.internal.flatten(values(obj.Inspectors(inspectorName{i}).BuiltinListMap));

				builtinSymbol = cell(1, numel(tmpList));
				for j = 1:numel(tmpList)
					builtinSymbol{j} = tmpList{j}.Symbol;
				end
				builtinSymbol = unique(builtinSymbol);

				% Ignore MW non-namespaced functions if they have the same name
				% as methods of detected classes.
				if ~isempty(builtinSymbol) && obj.Target == matlab.depfun.internal.Target.MATLAB
					builtinSymbol = filterNonNamespacedFcnAgainstDetectedClsList(obj, builtinSymbol);
				end
				if ~isempty(builtinSymbol)
					builtinList = union(builtinList, builtinSymbol);
				end
			end
		end

		function list = filterNonNamespacedFcnAgainstDetectedClsList(~, list)
			ignore_idx = false(size(list));
			detected_cls = knownClasses(matlab.depfun.internal.MatlabSymbol.classList);
			detected_cls = setdiff(detected_cls, matlab.depfun.internal.requirementsConstants.specialClassSet);
			for k = 1:numel(detected_cls)
				try
					% Only check method names. Class constructor should be remove from the list.
					mth_name = setdiff(methods(detected_cls{k}), detected_cls{k});
					if ~isempty(mth_name)
						ignore_idx = ignore_idx | ismember(list, mth_name);
					end
				catch
					% METHODS may throw. Ignore it and move on.
					% For example, if the super class of the detected class cannot
					% be found in the MATLAB search path.
				end
			end
			if any(ignore_idx)
				list(ignore_idx) = [];
			end
		end

		function componentID = checkBuiltinComponentMembership(obj, bltins)
			% Find the owning components and modules for given built-in symbols

			if ischar(bltins)
				bltins = {bltins};
			end
			num_bltins = numel(bltins);

			componentID = cell(num_bltins, 1);
			for k = 1:num_bltins
				mname = obj.pcm_navigator.moduleOwningBuiltin(bltins{k});
				componentID{k} = obj.DepDepot.componentOwningModule(mname);
			end
		end

		function list = computePartsList(obj, canonicalPath)
			% Do the work to determine the parts list -- compute and filter the
			% dependencies.
			%
			% This list may be empty if all the entry-point files in the
			% application are non-deployable. Use the ISDEPLOYABLE function to
			% determine if a file may be shipped to the target environment.

			% Don't canonicalize file paths by default.
			if nargin == 1
				canonicalPath = false;
			end

			computeDependencies(obj);
			list = buildTraceList(obj, canonicalPath);

			if obj.useDB
				builtinP = obj.builtinPrincipals();
				obj.applySetRules(builtinP, 'COMPLETION');
			end
			% Cache the user called expected file list.
			if obj.Target == matlab.depfun.internal.Target.MCR
				obj.LicensedToolboxFilesInRuntimeCalledByUser = obj.filterFilesWithLicenseTest(obj.expectedFiles());
			else
				obj.LicensedToolboxFilesInRuntimeCalledByUser = obj.expectedFiles();
			end

			% verify the existence of each part -- remove parts that
			% don't exist from the list of returned parts.
			if ~isempty(list)
				nonExistIdx = logical(...
					cellfun(...
					@(f)matlab.depfun.internal.cacheExist(f,'file'),...
					{list.path})==0);
				if any(nonExistIdx)
					nonExistFiles = list(nonExistIdx);
					list(nonExistIdx) = [];

					% A work-around for the racing condition (G982509).
					% Ask one more question before removing non-existent
					% files. If a m-file does not exist, does its p-file
					% exist?
					nonExistMFilesIdx = ~cellfun('isempty', ...
						regexp({nonExistFiles.path},'\.m$'));
					if any(nonExistMFilesIdx)
						nonExistMFiles = nonExistFiles(nonExistMFilesIdx);
						% checkPFiles is a cell array
						checkPFiles = regexprep({nonExistMFiles.path}, '\.m$', '.p');
						existPFilesIdx = logical(...
							cellfun(...
							@(f)matlab.depfun.internal.cacheExist(f,'file'),...
							checkPFiles)==6);
						lostAndFound = nonExistMFiles(existPFilesIdx);
						% replace non-existent m-file with its
						% corresponding existent p-file
						for k = 1:numel(lostAndFound)
							lostAndFound(k).path = regexprep(lostAndFound(k).path,'\.m$','.p');
						end

						if ~isempty(lostAndFound)
							list = [list lostAndFound];
						end
					end
				end
			end

			if ~isempty(list)
				[~,idx] = unique({list.path},'legacy');
				list = list(idx);
			end

			% Add a boolen field to indicate if a file is
			% directly called by user file(s)
			if obj.Target == matlab.depfun.internal.Target.MCR ...
					&& ~isempty(list)
				isDirectlyCalledByUserFile = ...
					ismember({list.path}, obj.matlabFiles);
				% Dear MATLAB, why can't I just do
				% list(isDirectlyCalledByUserFile).userCalled = true; ?
				for k=1:length(list)
					list(k).userCalled = isDirectlyCalledByUserFile(k);
				end
			end
		end

		function computeSupportPackagesList(obj, parts)
			%for the onCleanup
			function resetTarget(oldTarget)
				obj.Target = oldTarget;
			end

			% if SPMode.NONE is is a no-op
			if(obj.supportPackageMode ~= matlab.depfun.internal.SPMode.NONE)
				%toponly filelist used in both support package detection and
				%file inclusion

				toFileList = {};
				if(~isempty(parts))
					toFileList = { parts.path };
				end
				if(~isempty(obj.expectedFiles))
					toFileList = union(toFileList, obj.expectedFiles);
				end

				% add support package logic
				if(obj.supportPackageMode == matlab.depfun.internal.SPMode.AUTODETECT)
					% Id AUTODETECT we need to determine the list of support
					% packages to include

					deployableSupportPkgs = matlab.depfun.internal.DeployableSupportPackages;
					% only try to detect support packages if there are
					% support packages installed
					if(~isempty(deployableSupportPkgs.getSupportPackageList()))
						%need to map runtime products to matlab products
						% ideal logic (what happens today in deploytool) is the products are
						% determined based off of obj.LicensedToolboxFilesInRuntimeCalledByUser
						% we don't have an easy way of doing this RN so this is
						% a hack.
						originalTarget = obj.Target;

						targetCleanup = onCleanup(@() resetTarget(originalTarget));
						obj.Target = matlab.depfun.internal.Target.MATLAB;
						matlabProducts = requiredProducts(obj, obj.expectedFiles);
						clear targetCleanup;

						% only use products that are certain
						matlabProducts = matlabProducts([matlabProducts.Certain]);

						obj.supportPackageList = deployableSupportPkgs.determineSupportPackages(toFileList, {matlabProducts.Name});
					end
				end
			end
		end

		function parts = updatePartsForSupportPackages(obj, parts)
			% don't need to check the SPmode. If there is a list of support
			% packages to include, include the appropriate files
			if(~isempty(obj.supportPackageList))

				toFileList = {};
				if(~isempty(parts))
					toFileList = { parts.path };
				end
				if(~isempty(obj.expectedFiles))
					toFileList = union(toFileList, obj.expectedFiles);
				end

				% get the list of files to include
				fileAndFolderList = cellfun(@(X) getIncludeListCellStr(X, toFileList) , obj.supportPackageList, 'UniformOutput', false);
				fileAndFolderList = unique(horzcat(fileAndFolderList{:}));

				% spFileList can have folders or wildcards
				% need to resolve any non-file entries to a list of files
				spFileList = matlab.depfun.internal.findAllFiles(fileAndFolderList);

				if ~isempty(spFileList)
					% get the symbols for the new files and add them to the
					% scanlist
					rootsymbols = initializeRootSet(obj, spFileList);
					arrayfun(@(f) obj.ScanList.enqueue(f), rootsymbols);
					parts = computePartsList(obj, false);
				end

				% now get the list of files to include without
				% analyzing them
				fileAndFolderList = cellfun(@(X) getIncludeAsIsListCellStr(X) , obj.supportPackageList, 'UniformOutput', false);
				fileAndFolderList = unique(horzcat(fileAndFolderList{:}));

				if(~isempty(fileAndFolderList))
					% To error or remove files under matlabroot, that is
					% the question. Remove them for now.
					fileAndFolderList = fileAndFolderList(~obj.PathUtility.underMatlabroot(fileAndFolderList));

					% now remove anything that matlabroot begins with
					fileAndFolderList = fileAndFolderList(cellfun(@(X) ~obj.PathUtility.underDirectory(matlabroot, X), fileAndFolderList));

					% spFileList can have folders or wildcards
					% need to resolve any non-file entries to a list of files
					spFileList = matlab.depfun.internal.findAllFiles(fileAndFolderList);

					% remove any files that are already in the parts list
					spFileList = setdiff(spFileList, {parts.path});

					if ~isempty(spFileList)
						[~,names,~] = fileparts(spFileList);
						if obj.Target == matlab.depfun.internal.Target.MCR
							asIsParts = struct('name', names, ...
								'type', 'Extrinsic', ...
								'path', spFileList, ...
								'language', 'MATLAB', ...
								'userCalled', 0);
						else
							asIsParts = struct('name', names, ...
								'type', 'Extrinsic', ...
								'path', spFileList, ...
								'language', 'MATLAB');
						end
						parts = [parts, asIsParts];
					end
				end
			end
		end

		function result = filterFilesWithLicenseTest(obj, list)
			result = list;
			keep = true(size(list));
			test_license = true;

			lic_protected_shared_dirs = {};
			if isConfigured(obj.protectedDirs)
				lic_protected_shared_dirs = keys(obj.protectedDirs);
			end

			for k = 1:numel(list)
				cname = obj.findComponentBasedOnScmData(list(k));
				if isempty(cname)
					keep(k) = false;
					continue;
				else
					cname = cname{1};
				end

				for t = 1:numel(lic_protected_shared_dirs)
					if startsWith(list(k), lic_protected_shared_dirs(t))
						info = obj.protectedDirs(lic_protected_shared_dirs(t));
						if strcmp(cname, info.component)
							cname = info.identifying_component;
							break;
						end
					end
				end

				if ~ismember(cname, matlab.depfun.internal.requirementsConstants.componentsInMATLAB)
					pinfo = obj.pcm_navigator.productShippingComponentWithLicenseTest(cname, ...
						matlab.depfun.internal.Target.MATLAB, test_license);
					pinfo = pinfo{1};
					if isempty(pinfo)
						keep(k) = false;
					end
				end
			end
			result = result(keep);
		end
	end   % End private methods

	methods

		function obj = Completion(varargin)
			% Completion Create a DEPFUN Completion object.
			% A Completion is similar to a transitive closure -- it represents
			% the complete set of files that an input "root set" of files
			% requires in order to execute in a given context.
			%
			% Signature:
			%   c = Completion( { files } [, target ] [, level0] [, 'useDatabase'])
			%
			% Inputs:
			%   files  : full paths or resolvable against the MATLAB path.
			%   target : The context or environment in which the Completion
			%            must execute.
			%   level0 : true - level 0 dependency only
			%            false (by default) - level inf
			%   'useDatabase': an indicator that shows whether depfun database
			%                  is used (set) or not used (unset).
			%
			% Outputs:
			%        c : A Completion object.
			%
			% Methods:
			%
			% * parts(c) retrieves the list of required parts.
			%
			% * products(c) retrieves the list of MathWorks products which are
			%   assumed to be present on the target.
			%
			% * platforms(c) retrieves the list of platforms that the parts
			%   list supports.
			%
			% Example:
			%   c = Completion( { 'fcn1.m', 'fcn2.m', 'data.txt' }, ...
			%                  matlab.depfun.internal.Target.MCR )
			import matlab.depfun.internal.requirementsConstants
			% Initialize constructible properties
			env = matlab.depfun.internal.reqenv;
			obj.dfdb_path = env.DependencyDatabasePath;

			% Initialize instance properties
			obj.ExclusionList = struct.empty;
			obj.ExpectedList = struct.empty;
			obj.RootSet = {};
			obj.Inspectors = containers.Map;
			obj.matlabFiles = {};
			obj.useExclusionListFromDB = false;
			obj.useDB = false;
			obj.CompletionLevel = inf;
			obj.sliceClass = false;
			obj.symCls = 'matlab.depfun.internal.MatlabSymbol';

			obj.PathUtility = matlab.depfun.internal.PathUtility;
			obj.pcm_navigator = requirementsConstants.pcm_nv;

			% if no input, it is used by loadobj to only
			% create a new empty Completion object
			if nargin == 0
				return;
			end

			% Empty / null values for possible inputs.
			files = {};
			obj.Target = matlab.depfun.internal.Target.Unknown;
			obj.CachedTbxData = [];

			obj.Platforms = matlab.depfun.internal.StringSet;
			obj.File2Vertex = containers.Map('KeyType', 'char', ...
				'ValueType', 'any');
			obj.isAnalyzed = containers.Map('KeyType', 'char', ...
				'ValueType', 'logical');
			obj.problematicFiles = containers.Map('KeyType', 'char', ...
				'ValueType', 'any');

			obj.isLibMATLABDeps = strcmp(getenv('LIBMATLABDEPS'), 'TRUE');

			obj.inDBCreationMode = false;

			% Check for too many or too few inputs
			if nargin > 4 || nargin == 0
				error(message('MATLAB:depfun:req:BadInputCount', ...
					'1, 2, 3, or 4', nargin, ...
					'matlab.depfun.internal.Completion.Completion'));
			end

			% Process the arguments by data type.
			%   * The file list must be a cell array.
			%   * The target must be a matlab.depfun.internal.Target
			%   * The level-0 must be a logical value, which indicates the
			%     depth of dependency.
			%   * The 'useDatabase' is a string flag showing whether
			%     the depfun database is used.
			%
			% No other types are allowed. At least one of file list or
			% target must be specified. The rules argument is entirely
			% optional.
			k = 1;
			while k <=numel(varargin)
				switch class(varargin{k})
					case 'cell'
						if ~isempty(files)
							error(message('MATLAB:depfun:req:DuplicateArgType',...
								'cell',k,filesK,'cell'));
						end
						files = varargin{k};
						filesK = k;
					case 'matlab.depfun.internal.Target'
						if obj.Target ~= matlab.depfun.internal.Target.Unknown
							error(message('MATLAB:depfun:req:DuplicateArgType',...
								'matlab.depfun.internal.Target',k,targetK,...
								'matlab.depfun.internal.Target'));
						end
						obj.Target = varargin{k};
						targetK = k;
					case 'logical'
						% Allow user to restrict completion analysis to
						% immediate requirements only. If isLevel0 is true,
						% set CompletionLevel to 0. Otherwise, keep its
						% default value, inf.
						if obj.CompletionLevel == 0
							error(...
								message('MATLAB:depfun:req:DuplicateArgType',...
								'logical',k,levelK, 'logical'));
						end
						if varargin{k} == true
							obj.CompletionLevel = 0;
						end
						levelK = k;
					case 'char'
						% If making use of existing database for MATLAB files
						% is specified by the user, set the flag true;
						% otherwise keep its default value, false.
						if strcmpi(varargin{k},'useDatabase')
							if exist(obj.dfdb_path,'file')
								obj.useDB = true;
								obj.useExclusionListFromDB = true;
							end
						elseif strncmpi(varargin{k},'createDatabase ',15)
							obj.useDB = false;
							obj.dfdb_path = varargin{k}(16:end);
							if exist(obj.dfdb_path,'file')
								obj.useExclusionListFromDB = true;
							end
							obj.inDBCreationMode = true;
						else
							error(message('MATLAB:depfun:req:BadStringFlag', ...
								varargin{k}, ...
								'matlab.depfun.internal.Completion'));
						end
					otherwise
						error(message('MATLAB:depfun:req:InvalidInputType',...
							k,class(varargin{k}), ...
							'cell, Target, logical, or char'));
				end
				k = k + 1;
			end

			% At least one of files and target must be specified.
			if isempty(files) && ...
					obj.Target == matlab.depfun.internal.Target.Unknown
				error(message('MATLAB:depfun:req:NeedFilesOrTargetToCreate'));
			end

			obj.USE_TASKS = false;

			% Initialize threaded workers and set MATLAB path as fullpath
			if obj.USE_TASKS
				setupEnvironmentVariable();
				obj.ThreadedPool = matlab.internal.taskpool.gcp;
				disp(['Using MATLAB Tasks, '...
					num2str(obj.ThreadedPool.NumWorkers) ' workers running']);
				obj.EnvironmentVariableCleanup = onCleanup(@() recoverEnviromentVariable);
			end

			% Create file system cache object
			obj.FsCache = matlab.depfun.internal.FileSystemCache;

			% reset caches -- must happen before building the inspectors,
			% since some of them use the caches.
			matlab.depfun.internal.initCaches();

			% Get the schema map for this target.
			obj.Schema = schemaMap(obj.Target, false, obj.inDBCreationMode);

			% Notify the class set it should use exclude, expect and
			% allow filters.

			excludeFilter = @(files)isExcluded(obj, files);
			expectFilter = @(files)isExpected(obj, files);
			allowFilter = @(files)isAllowed(obj, 'COMPLETION', files);
			matlab.depfun.internal.ClassSet.registerClassFilters(...
				excludeFilter, expectFilter, allowFilter);

			% Add CodeInspectors to the Map -- one per file extension we
			% know how to analyze.
			buildInspector(obj);

			if obj.Target == matlab.depfun.internal.Target.MCR
				% Avoid analyzing functions from these locations when the
				% target is the MCR. TODO: Rework into mcr.rdl.
				matlab.depfun.internal.ClassSymbol.declareToxic(...
					{ '$MATLAB/toolbox/symbolic' } );
			end

			% Initialize the file to required compnents map.
			obj.fileToComponents = containers.Map('KeyType','char',...
				'ValueType','any');

			% Initialize the file to required packages map.
			obj.fileToPackages = containers.Map('KeyType','char',...
				'ValueType','any');

			% If the PCM database exists, preload builtins into the WHICH cache.
			if obj.useDB && obj.PathUtility.pcmexist
				matlab.depfun.internal.preloadWhichCache(obj.pcm_navigator);
			end

			% If the database exists, and notify the Schema that
			% a valid REQUIREMENTS database exists.
			if obj.useDB && exist(obj.dfdb_path, 'file') == 2
				obj.DepDepot = matlab.depfun.internal.DependencyDepot(obj.dfdb_path, true); %readonly
				obj.Schema.depDepot = obj.dfdb_path;
			else
				% The Schema object is stored in a persistent map in the
				% local function schemaMap(). Here its property 'depDepot'
				% needs to be cleared when useDB is set to false.
				obj.DepDepot = [];
				obj.Schema.depDepot = [];
			end

			% reset the cache of exclusion list
			if obj.useExclusionListFromDB
				matlab.depfun.internal.cacheIsExcluded(obj.dfdb_path, obj.Target);
			end

			% If there are inputs to process, determine which inputs will
			% form the roots of the dependency forest.
			if ~isempty(files)

				% Correct obvious errors in the file names. For example,
				% remove doubled file separators: /my/path//to/a/file can
				% be corrected to /my/path/to/a/file.
				files = realpath(files);

				% Create the scan list first, since initializeRootSet may
				% need to put some files on the scan list.
				obj.ScanList = matlab.depfun.internal.SymbolQueue;

				% Symbols on the DeferredScanList will be analyzed
				% after the ScanList is empty.
				obj.DeferredScanList = matlab.depfun.internal.SymbolQueue;

				% Create symbols for the input files -- and filter them
				% against the active rules and exclusions. After this
				% operation on those files allowed as entry points remain
				% in the root set.
				obj.RootSet = initializeRootSet(obj, files);

				% Add the symbols to the scan list -- enqueue the root set
				% files. Since the scan list is a handle object, the
				% modifications performed during cellfun will persist.
				arrayfun(@(f) obj.ScanList.enqueue(f), obj.RootSet);
			end
		end

		function gph = calltree(obj, ~, ~, ~)
			% If the dependency graph is empty, compute it.
			computeDependencies(obj);
			gph = obj.DependencyGraph;
		end

		function exc = excludedFiles(obj)
			% remove duplicated records
			if ~isempty(obj.ExclusionList)
				[~,idx] = unique({obj.ExclusionList.file},'legacy');
				exc = obj.ExclusionList(idx);
			else
				exc = obj.ExclusionList;
			end
		end

		function  exp = expectedFiles(obj)
			% Expected directories are also recorded in
			% obj.ExpectedList. It was OK in the past.
			% But now, we want to know the explicit list of expected
			% files to identify required components for those files.

			if isempty(obj.ExpectedList)
				exp = cell(1,0);
				return;
			end
			list = {obj.ExpectedList.file};

			% Ignore MW non-namespaced functions if they have the same name
			% as methods of detected classes.
			if ~isempty(list) && obj.Target == matlab.depfun.internal.Target.MATLAB
				to_check_idx = startsWith(list, matlab.depfun.internal.requirementsConstants.MatlabRoot) ...
					& cellfun('isempty', cellfun(@(p)at_plus_private_idx(p), list, 'UniformOutput', false));
				if any(to_check_idx)
					to_check = list(to_check_idx);
					rest = list(~to_check_idx);

					[~,name_to_check,~] = fileparts(to_check);
					name_to_keep = filterNonNamespacedFcnAgainstDetectedClsList(obj, name_to_check);
					to_keep_idx = ismember(name_to_check, name_to_keep);
					to_keep = to_check(to_keep_idx);

					list = [rest to_keep];
				end
			end

			dir_idx = matlab.depfun.internal.cacheExist(list, 'dir') == 7;
			non_dir_idx = ~dir_idx;
			exp = list(non_dir_idx);

			subDir = cellfun(@(b)getSubDirRecursively(b), list(dir_idx), ...
				'UniformOutput', false);
			subDir = [subDir{:}];
			if ~isempty(subDir)
				exp = union(exp, subDir);
			end

			% Everything under toolbox/matlab is expected except codetools,
			% because it is excluded for MCR target.
			if ~isempty(exp)
				remove = obj.isExcluded(exp);
				exp(remove) = [];
			end

			function subDir = getSubDirRecursively(baseDir)
				subDir = {};

				if ispc
					cmd = ['dir /s /A:D /B "' baseDir '"\*'];
				elseif isunix
					cmd = ['ls -r -d -A "' baseDir '"/*'];
				else
					return;
				end

				[failed, msg] = system(cmd);
				if ~failed && ~isempty(msg)
					garbage_can = textscan(msg, '%s', 'Delimiter', '\n');
					if ~isempty(garbage_can)
						garbage_can = garbage_can{1};
						idx = strncmp(garbage_can, baseDir, ...
							length(baseDir));
						subDir = garbage_can(idx)';
					end
				end
			end
		end

		function setSupportPackageList(obj,newList)

			if isempty(newList)
				newList = {};
			else
				validateattributes(newList,{'cell'},{'vector'})

				for n = 1:numel(newList)
					validateattributes(newList{n}, ...
						{'matlab.addons.internal.SupportPackageInfoBase'}, ...
						{'scalar'})
				end
			end

			obj.supportPackageList = newList;
		end

		function setSupportPackageMode(obj, newMode)

			validateattributes(newMode, ...
				{'matlab.depfun.internal.SPMode'},{'scalar'})
			obj.supportPackageMode = newMode;
		end

		function [parts, resources] = requirements(obj)
			% REQUIREMENTS Determine required parts, products and platforms.
			% Much more efficient than calling parts, products and platforms
			% individually.

			parts = computePartsList(obj, false);

			% Like Products return support packages as a struct to
			% facilitate returning additional info if needed
			function res = spkgStruct(spkg)
				res.name = spkg.name;
				res.baseProduct = spkg.baseProduct;
				res.displayName = spkg.displayName;
				res.thirdPartyName = spkg.thirdPartyName;
				res.thirdPartyURL = spkg.thirdPartyURL;
			end

			obj.computeSupportPackagesList(parts);
			if ~isempty(obj.supportPackageList)
				if obj.Target ~= matlab.depfun.internal.Target.Deploytool
					parts = obj.updatePartsForSupportPackages(parts);
				end
				% should we be smart and only list a suppot package if
				% files were included?
				resources.supportpackages = cellfun(@spkgStruct, obj.supportPackageList);
			else
				resources.supportpackages = [];
			end

			if ~isempty(parts)
				list = { parts.path };

				% Additional files can be pulled out of the database.
				% Need to update obj.Platforms after querying the DB.
				ext = cell(numel(list),1);
				% CELLFUN is slower than FOR loop in this case.
				for i = 1:numel(list)
					[~,~,ext{i}] = fileparts(list{i});
				end
				cellfun(@(e)recordPlatformExt(obj,e), unique(ext));
			end

			resources.products = products(obj);
			resources.platforms = members(obj.Platforms);
			resources.packages = packages(obj);
		end

		function unresolved = unresolvedSymbols(obj)
			unresolved = containers.Map('KeyType', 'char', 'ValueType', 'any');
			inspectorName = keys(obj.Inspectors);
			for i = 1:numel(inspectorName)
				UnresolvedSymbolMap = obj.Inspectors(inspectorName{i}).UnresolvedSymbols;

				% Some class method names are not resolvable by WHICH when they are
				% detected in the first place. However, they may be resolvable
				% at this point, because the MCOS cache gains knowledge in the
				% analysis process.
				% They can be safely ignored because we don't slice classes.
				files = keys(UnresolvedSymbolMap);
				for k = 1:numel(files)
					symlist = UnresolvedSymbolMap(files{k});
					keep = cellfun('isempty', ...
						cellfun(@(s)matlab.depfun.internal.which.callWhich(s), ...
						symlist, 'UniformOutput', false));

					% find out which symbol is builtin from undeployable
					builtinFromUndeployable = ismember(symlist, matlab.depfun.internal.requirementsConstants.undeployableBuiltins);

					% keep the unresolvable & builtin from undeployable
					keep = keep | builtinFromUndeployable;

					if ~all(keep)
						UnresolvedSymbolMap(files{k}) = symlist(keep);
					end
				end
				unresolved = [unresolved; UnresolvedSymbolMap]; %#ok
			end
		end

		function builtinListMap = retrieveBuiltinListMap(obj)
			% retrieve used built-ins from inspectors
			builtinListMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			inspectorName = keys(obj.Inspectors);
			for i = 1:numel(inspectorName)
				% tmpLis is a map of files and a cell array of MatlabSymbol
				tmpMap = obj.Inspectors(inspectorName{i}).BuiltinListMap;
				builtinListMap = [builtinListMap; tmpMap]; %#ok
			end
		end

		function p = products(obj)
			% PRODUCTS What products does this Completion require?
			% This list of products must be present in the target environment
			% in order for the application represented by the Completion to
			% run.
			list = {};
			% This call to computePartsList typically does not recompute
			% dependencies, because the scan list is empty.
			plist = computePartsList(obj);
			if ~isempty(plist)
				list = { plist.path };
			end
			if ~isempty(obj.LicensedToolboxFilesInRuntimeCalledByUser)
				list = [ list, reshape(obj.LicensedToolboxFilesInRuntimeCalledByUser,1,[]) ];
			end

			p = requiredProducts(obj, list);
		end

		function pkg = packages(obj)
			% PACKAGES What MATLAB Packages does this Completion require?
			% It returns a struct array of MATLAB Packages,
			% i.e., ID, Name, Version, and Root.
			pkg = struct([]);
			pkgID = values(obj.fileToPackages);
			pkgID = unique([pkgID{:}]);
			if ~isempty(pkgID)
				%pkgInfo = cellfun(@(id)matlab.mpm.internal.info(id), pkgID, 'UniformOutput',false);

				% Temp workaround
				% MCOS class currently returns an invalid package specifier,
				% which causes MPM to error.
				pkgInfo = {};
				for p = 1:numel(pkgID)
					try
						pinfo = matlab.mpm.internal.info(pkgID{p});
						pkgInfo{end+1} = pinfo;%#ok
					catch
					end
				end

				pkgInfo = [pkgInfo{:}];
				pkg = struct('UUID', convertStringsToChars([pkgInfo.ID]), ...
					'Name', convertStringsToChars([pkgInfo.Name]), ...
					'Version', convertStringsToChars([pkgInfo.Version]), ...
					'Root', convertStringsToChars([pkgInfo.InstallationLocation]));
			end

		end

		function list = parts(obj, canonicalPath)
			% PARTS List the parts (files) in the Completion.
			% Ship these files to the target environment to run the application
			% represented by the Completion.

			if nargin == 1, canonicalPath = false; end

			list = computePartsList(obj, canonicalPath);
		end

		function [deployable, reason] = isdeployable(obj, files, entryPoint)
			% ISDEPLOYABLE Can the files be shipped to the target environment?
			% Files that are not deployable may still be useable by
			% applications because the files may be present in the target
			% environment.
			%
			% Return values:
			%    deployable: Logical mask the same size as files.
			%
			%    reason    : Structure explaining each file's deployability. The
			%                same size as deployable.
			%
			% A file is deployable if (and only if) it is:
			%
			%  * Not excluded.
			%  * Not removed from the ROOTSET or COMPLETION by a set
			%    manipulation rule.
			%  * Not expected, or expected and allowed.
			%
			% All three of these conditions must be true for a file to be
			% deployable.
			%
			% isdeployable very specifically determines ONLY if the file may be
			% placed in a package to be shipped from the source machine to the
			% target environment. It does not determine whether or not a
			% deployed application may use the file in question, as that
			% knowledge is not available.

			% Flag directories in the file list
			idx = matlab.depfun.internal.cacheExist(files, 'file') == 7;
			if any(idx)
				error(message('MATLAB:depfun:req:InternalInvalidDirectoryInput', ...
					strjoin(files(idx), ', ')));
			end

			% By default, test for the broadest notion of deployability: can
			% the file be part of the package at all? (Test for inclusion
			% in the COMPLETION.) The ROOTSET is the set of entry points,
			% or the main file in the case of an App. (The name ROOTSET is
			% meant to suggest the ROOTS from which the forest of
			% requirements grows.)
			fileSet = 'COMPLETION';
			if entryPoint
				fileSet = 'ROOTSET';
			end

			% This message used to explain why a file is deployable. By
			% default, let all files be deployable.
			deployableWhy = ...
				msg2why(message('MATLAB:depfun:req:DeployableFile', ...
				matlab.depfun.internal.Target.str(obj.Target)));
			reason = repmat(deployableWhy,1,numel(files));

			% Turn the input files into symbols.
			ignoreFileList = {};
			[symbols, uType] = resolveRootSet(obj, files, ignoreFileList);

			% Determine if the set operations remove or add the files in
			% question to the indicated file set.
			if ~isempty(symbols)
				paths = { symbols.WhichResult };
			else
				paths = uType;
			end
			% keep is a logical index the same length as the file list.
			% Where keep is false, the rule set mandates file removal.
			% Removed files are not deployable.
			[~, keep, rMap] = ruleActions(obj, fileSet, paths);

			% Add the reasons for removal to the list of reasons.
			% Map is poorly vectorizable, so must use a manual loop
			if ~all(keep)
				removed = paths(~keep);
				reason(~keep) = cell2mat(values(rMap, removed));
			end

			% Determine which files are excluded, expected and allowed,
			% or replaced.
			%
			% If a file has been removed by the set rules, don't overwrite
			% the set rule-related explanation.
			replacedFiles = {};
			if isKey(rMap,'#REPLACED')
				replacedFiles = rMap('#REPLACED');
			end

			[excluded, whyExcluded] = isExcluded(obj, paths);
			if ~all(excluded)

				replaced = zeros(1,numel(paths));
				if numel(replacedFiles) > 0
					for k=1:numel(paths)
						replaced(k) = ismember(paths{k}, replacedFiles);
						reason(k) = deployableWhy;
					end
					paths(replaced) = rMap('#REPLACEMENT');
					keep = keep | replaced;
				end

				[expected, whyExpected] = isExpected(obj, paths);
				allowed = isAllowed(obj, fileSet, paths);

				expected = expected & ~allowed;
				explain = expected & keep;  % Kept by rules, but expected
				if ~isempty(whyExpected)
					reason(explain) = whyExpected(explain);
				end
			else
				expected = false(1,numel(paths));
			end

			% Merge the results -- excluded trumps expected and allowed, and
			% allowed trumps expected.
			deployable = keep & ~excluded & ~expected;
			explain = excluded & keep;  % Kept by rules, but excluded
			if ~isempty(whyExcluded)
				reason(explain) = whyExcluded(explain);
			end
		end

		function S = saveobj(obj)
			S.Schema = obj.Schema;
			S.PathUtility = obj.PathUtility;
			S.Platforms = obj.Platforms;
			S.Target = obj.Target;
			S.DependencyGraph = obj.DependencyGraph;
			S.ExclusionList = obj.ExclusionList;
			S.ExpectedList = obj.ExpectedList;
			S.RootSet = obj.RootSet;
			S.Inspectors = obj.Inspectors;
			S.ScanList = obj.ScanList;
			S.DeferredScanList = obj.DeferredScanList;
			S.CompletionLevel = obj.CompletionLevel;
			S.File2Vertex = obj.File2Vertex;
			S.CachedTbxData = obj.CachedTbxData;
			S.PlatformExt = obj.PlatformExt;
			S.sliceClass = obj.sliceClass;
			S.FsCache = obj.FsCache;
			S.isAnalyzed = obj.isAnalyzed;
			S.useDB = obj.useDB;
			S.matlabFiles = obj.matlabFiles;
			S.dfdb_path = obj.dfdb_path;
			S.symCls = obj.symCls;
			S.builtinSymbolToComponent = obj.builtinSymbolToComponent;
			S.sourceToComponent = obj.sourceToComponent;
			S.fileToComponents = obj.fileToComponents;
			S.fileToPackages = obj.fileToPackages;
			S.problematicFiles = obj.problematicFiles;
			S.USE_TASKS = obj.USE_TASKS;
		end

		function setDependencyGraph(obj, graph, file2vertex)
			obj.DependencyGraph = graph;
			obj.File2Vertex = file2vertex;
		end

		function g = getDependencyGraph(obj)
			obj.computeDependencies();
			g = obj.DependencyGraph;
		end

		function b2c = get.builtinSymbolToComponent(obj)
			% Extract the mapping of built-in symbols to owning components.
			if isempty(obj.builtinSymbolToComponent)
				obj.builtinSymbolToComponent = obj.pcm_navigator.builtinToComponentMap;
			end

			b2c = obj.builtinSymbolToComponent;
		end

		function s2c = get.sourceToComponent(obj)
			% Extract the mapping of MATLAB modules and sub-directories to owning components.
			if isempty(obj.sourceToComponent)
				obj.sourceToComponent = obj.pcm_navigator.sourceToComponentMap;
			end

			s2c = obj.sourceToComponent;
		end

		function d = get.protectedDirs(obj)
			import matlab.depfun.internal.requirementsConstants
			if isempty(obj.protectedDirs)
				obj.protectedDirs = dictionary;

				pd = fullfile(matlabroot, ...
					['toolbox/matlab/depfun/+matlab/+depfun/+internal/private/lm_' requirementsConstants.arch '.mat']);
				if exist(pd, 'file')
					S = load(pd);
					if isConfigured(S.lic_protected_shared_dir_dictionary)
						% protected_dirs are strings, as implememted in DICTIONARY
						protected_dirs = keys(S.lic_protected_shared_dir_dictionary);
						for k = 1:numel(protected_dirs)
							query = sprintf(['SELECT Product.External_Product_ID, Component.Name FROM Product, Component ' ...
								' WHERE Product.LICENSE_NAME =''%s''' ...
								'   AND Product.Identifying_Component = Component.ID;'], ...
								S.lic_protected_shared_dir_dictionary(protected_dirs(k)));
							obj.pcm_navigator.doSql(query);
							tmp = obj.pcm_navigator.fetchRows();
							if ~isempty(tmp) && isKey(obj.sourceToComponent, char(protected_dirs(k)))
								tmp = tmp{1};
								protected_dir_fullpath = fullfile(requirementsConstants.MatlabRoot, ...
									protected_dirs(k) + requirementsConstants.FileSep);
								obj.protectedDirs(protected_dir_fullpath) = ...
									struct('component', obj.sourceToComponent(char(protected_dirs(k))), ...
									'pid', tmp{1}, ...
									'identifying_component', tmp{2});
							end
						end
					end
				end
			end
			d = obj.protectedDirs;
			if  obj.Target == matlab.depfun.internal.Target.MCR && isConfigured(d)
				for k = keys(d)'
					d(k).pid = d(k).pid + requirementsConstants.base_mcr_pid_max;
				end
			end
		end

		function result = get.undeployableMatlabModules(obj)
			if isempty(obj.undeployableMatlabModules)
				obj.undeployableMatlabModules = obj.pcm_navigator.getUndeployableMatlabModule();
			end

			result = obj.undeployableMatlabModules;
		end

		function f2c = fileToComponentMap(obj)
			% Return the map of files and required components.
			f2c = obj.fileToComponents;
		end

		function failedFiles = problematicfilesEncountered(obj)
			% Return the list of files that depfun has trouble to analyze.
			failedFiles = obj.problematicFiles;
		end
	end
end

function m = schemaMap(target, clobber, inCreatingDBMode)
% schemaMap Return the Target to Schema map for the current MCR
% Create maps as necessary.
persistent mcrMap

% Retrieve corresponding enum integer
tgt = matlab.depfun.internal.Target.int(target);

m = [];

if nargin > 1 && clobber
	mcrMap = [];
	return;
end


if nargin < 3
	inCreatingDBMode = false;
end
% If there are no rules at all yet, create the MCR index map
if isempty(mcrMap)
	mcrMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
end

% If there's no schema map for the current MCR, create one. If there is,
% set rulesMap to refer to it.
if ~isKey(mcrMap, get_current_mcr_id)
	rulesMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
	mcrMap(get_current_mcr_id) = rulesMap;
else
	rulesMap = mcrMap(get_current_mcr_id);
end

% If the current rules map contains no Schema for the current target,
% create one.
if ~isKey(rulesMap, tgt)
	rulesMap(tgt) = targetSchema(target, inCreatingDBMode);
end
m = rulesMap(tgt);
end

function s = targetSchema(target, inCreatingDBMode)
import matlab.depfun.internal.Target;
if nargin < 2
	inCreatingDBMode = false;
end
% Use target to determine rules file
switch target
	case Target.PCTWorker
		rulesFile = 'pctworker.rdl';
	case Target.MATLAB
		rulesFile = 'matlab.rdl';
	case Target.MCR
		rulesFile = 'mcr.rdl';
	case Target.Deploytool
		rulesFile = 'deploytool.rdl';
	case { Target.None, Target.All }
		% Empty rules file for these targets
		rulesFile = 'empty.rdl';
	otherwise
		error(message('MATLAB:depfun:req:BadTarget', Target.str(target)));
end

if isempty(rulesFile)
	error(message('MATLAB:depfun:req:InternalNoRules'));
end

[deproot, ~, ~] = fileparts(mfilename('fullpath'));
rulesFile = fullfile(deproot,rulesFile);

if exist(rulesFile, 'file') ~= 2
	error(message('MATLAB:depfun:req:RulesFileMustExist', rulesFile));
end

s = matlab.depfun.internal.Schema();
s.CalledDuringDBBuild = inCreatingDBMode;
s.addRules(rulesFile);
end

% ---------------------------------------------------------------------------
% Local functions

function pth = fullpath(file, rootDir)
% Return the fullpath to a file. Why is this tricky? Because the file
% string may be a full path already.
pth = '';
if isfullpath(file)
	pth = file;
elseif ~isempty(file)
	pth = fullfile(rootDir,file);
end
end

%---------------------------------------------------------------------------
function pext = initPlatformExt()
% Create the platform extension map: extension -> list of architectures
% Each value in the map is a cell array of strings, even singletons.
import matlab.depfun.internal.StringSet;

mexall = mexext('all');
pext = containers.Map(...
	strcat('.', { mexall.ext } ), ...
	cellfun(@(e){e},{mexall.arch},'UniformOutput',false));
pext('.dll') = { 'win64' };
pext('.so') = { 'glnxa64' };
pext('.dylib') = { 'maca64' 'maci64' };

end

%---------------------------------------------------------------------------
function uddPkgSchema = getUDDPackageSchema(uddClsDir)
%getUDDPackageSchema Get package schema.m and/or schema.p for UDD class
import matlab.depfun.internal.cacheExist;

uddPkgSchema ={};
atIdx = strfind(uddClsDir, [matlab.depfun.internal.requirementsConstants.FileSep '@']);
uddPkgPath = uddClsDir(1:atIdx(end)); % Package name ends at the 2nd @
uddPkgSchemaM = [uddPkgPath 'schema.m'];
if cacheExist(uddPkgSchemaM,'file')
	uddPkgSchema = [ uddPkgSchema uddPkgSchemaM ];
end

uddPkgSchemaP = [uddPkgPath 'schema.p'];
if cacheExist(uddPkgSchemaP,'file')
	uddPkgSchema = [ uddPkgSchema uddPkgSchemaP ];
end
end

%---------------------------------------------------------------------------
function uddClsSchema = getUDDClassSchema(uddClsDir)
%getUDDClassSchema  Get class schema.m for UDD class
import matlab.depfun.internal.cacheExist;
fs = matlab.depfun.internal.requirementsConstants.FileSep;
% Class name ends at the first filesep after the last @
atIdx = strfind(uddClsDir, [fs '@']) + 1;
sepIdx = strfind(uddClsDir, fs);
n = numel(uddClsDir);
if ~isempty(atIdx) && ~isempty(sepIdx)
	n = find(sepIdx > atIdx(end));
	if ~isempty(n), n = sepIdx(n); end
end

uddPkgPath = uddClsDir(1:n);
uddClsSchema = [uddPkgPath 'schema.m'];
if ~cacheExist(uddClsSchema,'file')
	uddClsSchema = '';
end
end

%---------------------------------------------------------------------------
function uddPkgSchema = getUDDPackageFunctionSchema(w)
% getUDDPackageFunctionSchema
% Get package schema.m and/or schema.p for UDD package function
import matlab.depfun.internal.cacheExist;
fs = matlab.depfun.internal.requirementsConstants.FileSep;
uddPkgSchema = {};
atIdx = strfind(w, [fs '@']) + 1;
if isscalar(atIdx) && atIdx > 1
	% Find the file separators
	fsIdx = strfind(w, fs);
	% The file separator that ends the package directory path is the
	% first one after the @.
	pkgIdx = find(fsIdx > atIdx);
	if ~isempty(pkgIdx)
		uddPkgPath = w(1:(fsIdx(pkgIdx(1))-1));
		uddPkgSchemaM = fullfile(uddPkgPath,'schema.m');
		if cacheExist(uddPkgSchemaM,'file')
			uddPkgSchema = [ uddPkgSchema uddPkgSchemaM ];
		end

		uddPkgSchemaP = fullfile(uddPkgPath,'schema.p');
		if cacheExist(uddPkgSchemaP,'file')
			uddPkgSchema = [ uddPkgSchema uddPkgSchemaP ];
		end
	end
end
end

%-------------------------------------------------------------
function user_alias = findUserAliasFiles(traceList)
import matlab.depfun.internal.requirementsConstants

user_alias = {};
if ~isempty(traceList)
	w = {traceList.path};
	user_files = w(~contains(w, requirementsConstants.MatlabRoot));
	if ~isempty(user_files)
		user_paths = unique(filename2path(user_files));
		possible_user_alias = strcat(user_paths, requirementsConstants.FileSep, ...
			'resources', requirementsConstants.FileSep, 'alias.json');
		exist_idx = cellfun(@(f)matlab.depfun.internal.cacheExist(f,'file')==2, possible_user_alias);
		user_alias = possible_user_alias(exist_idx);
	end
end
end


% function treeMap = preloadMtreeCacheTasks(files)
%
% treeMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
% for idx = 1:numel(files)
%     file = files{idx};
%     [~,~,ext] = fileparts(file);
%     if strcmp(ext,'.m')
%         t = mtree(file, '-file', '-com');
%
%         mterr = mtfind(t, 'Kind', 'ERR');
%         if ~isempty(mterr)
%             error(message('MATLAB:depfun:req:BadSyntax', file, string(mterr)))
%         end
%         treeMap(file) = t;
%     end
% end
% end

function [finalFiles, finalWhich, finahExist] = preloadWhichExistCacheTasks(createDB, files)
% Prelocate space for results, 3* is for extra MEX and DLL files
fileList = cell(1, 3*numel(files));
whichResult = cell(1, 3*numel(files));
existFileResult = cell(1, 3*numel(files));
tailIdx = 1;

for idx = 1:numel(files)
	file = files{idx};
	% If in DB Creation mode, file name is fullpath and exist returns 2
	% ASSUMPTION: if file name is fullpath, then the file exist and
	% exist returns 2
	if createDB || isfullpath(file)
		whichResult{tailIdx} = file;
		existFileResult{tailIdx} = 2;
		fileList{tailIdx} = file;
		tailIdx = tailIdx + 1;
		% If it is a M-code, look for its corresponding MEX file too
		mExtIdx = regexp(file, '.\m$', 'ONCE');
		if ~isempty(mExtIdx)
			MEXname = [file(1:mExtIdx) mexext];
			fileList{tailIdx} = MEXname;
			whichResult{tailIdx} =  which(MEXname);
			existFileResult{tailIdx} = exist(MEXname, 'file');
			tailIdx = tailIdx + 1;
		end
	else
		path = which(file);
		fileList{tailIdx} = file;
		whichResult{tailIdx} = path;
		existFileResult{tailIdx} = exist(file,'file');
		tailIdx = tailIdx + 1;
	end
end

% Remove empty results
existIdx = ~cellfun('isempty',whichResult);
finalFiles = fileList(existIdx);
finalWhich = whichResult(existIdx);
finahExist = existFileResult(existIdx);
end

% Sequentially preload mtree cache
% This function is sequential version of preloadMtreeCache function
% function preloadMtreeCacheSequentially(files)
%     import matlab.depfun.internal.cacheMtree
%     trees = preloadMtree(files);
%     for idx = 1:numel(files)
%         file = files{idx};
%         if isKey(trees,file)
%             cacheMtree(file,trees(file));
%         end
%     end
% end

function setupEnvironmentVariable()
feature('diagnosticSpec', 'mtasks::constraints::builtins=all');
feature('diagnosticDest', 'file');
end

function recoverEnviromentVariable()
feature('diagnosticSpec', '.*=none');
feature('diagnosticDest', '');
end

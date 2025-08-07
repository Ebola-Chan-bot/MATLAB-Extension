classdef (Hidden, Sealed) BuildRunner < ...
        matlab.buildtool.internal.BuildContentOperator & ...
        matlab.buildtool.internal.PluginOperator & ...
        matlab.buildtool.internal.BuildRunnerExtension
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % BuildRunner - Runner of tasks in plan
    %
    %   The matlab.buildtool.BuildRunner class lets you run the tasks in a
    %   plan. You can use this class to customize your build run.
    %
    %   Create a BuildRunner instance using one of its static methods:
    %
    %   - To create a minimal runner with no plugins installed, call the 
    %   withNoPlugins static method.
    %   
    %   - To create a runner that is configured for text output, call the
    %   withTextOutput static method.
    %
    %   BuildRunner methods:
    %      withNoPlugins  - Create minimal build runner with no plugins installed
    %      withTextOutput - Create build runner configured for text output
    %      run            - Run the build
    %
    %   Example:
    %
    %      % Load a plan from buildfile.m in your current folder.
    %      plan = matlab.buildtool.Plan.load;
    %
    %      % Create a build runner that produces text output.
    %      runner = matlab.buildtool.BuildRunner.withTextOutput;
    %
    %      % Run the default tasks in the plan.
    %      result = runner.run(plan);
    %
    %   See also matlab.buildtool.Plan, matlab.buildtool.BuildResult
    
    %   Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Dependent, SetAccess = private, Hidden)
        Plugins (1,:) matlab.buildtool.plugins.BuildRunnerPlugin
    end
    
    properties (Access = private)
        PluginData (1,1) struct
        Fingerprinters (1,:) matlab.buildtool.fingerprints.Fingerprinter
        BuildRunData matlab.buildtool.internal.BuildRunData {mustBeScalarOrEmpty}
        OperatorList matlab.buildtool.internal.BuildContentOperatorList {mustBeScalarOrEmpty}

        ActiveFixtures (1,:) matlab.buildtool.internal.fixtures.Fixture
        FixtureToCreate matlab.buildtool.internal.fixtures.Fixture {mustBeScalarOrEmpty}
        FixtureErrored (1,1) logical

        CurrentTaskContext matlab.buildtool.TaskContext {mustBeScalarOrEmpty}
        
        PluginsInvokedRunnerContent (1,1) logical
    end
    
    methods (Static)
        function runner = withNoPlugins()
            % withNoPlugins - Create minimal build runner with no plugins installed
            %
            %   RUNNER = matlab.buildtool.BuildRunner.withNoPlugins creates a minimal,
            %   silent build runner with no plugins installed, and returns it as a 
            %   matlab.buildtool.BuildRunner object. The returned build runner is the
            %   simplest runner possible and produces no text output.
            %
            %   Example:
            %
            %      % Load a plan from buildfile.m in your current folder.
            %      plan = matlab.buildtool.Plan.load;
            %
            %      % Create a build runner with no plugins. This code creates a silent
            %      % runner that produces no output.
            %      runner = matlab.buildtool.BuildRunner.withNoPlugins;
            %
            %      % Run the default tasks in the plan.
            %      result = runner.run(plan);
            %
            %   See also matlab.buildtool.Plan, matlab.buildtool.BuildResult
            
            import matlab.buildtool.BuildRunner;
            
            runner = BuildRunner();
        end
        
        function runner = withTextOutput(options)
            % withTextOutput - Create build runner configured for text output
            %
            %   RUNNER = matlab.buildtool.BuildRunner.withTextOutput creates a build
            %   runner that is configured for text output, and returns it as a 
            %   matlab.buildtool.BuildRunner object. The text output produced includes
            %   build progress as well as diagnostics in the event of build failures.
            %
            %   Example:
            %
            %      % Load a plan from buildfile.m in your current folder.
            %      plan = matlab.buildtool.Plan.load;
            %
            %      % Create a build runner that produces text output.
            %      runner = matlab.buildtool.BuildRunner.withTextOutput;
            %
            %      % Run the default tasks in the plan.
            %      result = runner.run(plan);
            %
            %   See also matlab.buildtool.Plan, matlab.buildtool.BuildResult
            
            arguments
                options.Verbosity (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
            end

            import matlab.buildtool.BuildRunner;
            import matlab.buildtool.plugins.BuildRunProgressPlugin;
            import matlab.buildtool.plugins.DiagnosticsOutputPlugin;

            runner = BuildRunner();
            runner.addPlugin(BuildRunProgressPlugin.withVerbosity(options.Verbosity));
            runner.addPlugin(DiagnosticsOutputPlugin(OutputDetail=options.Verbosity,LoggingLevel=options.Verbosity));
        end
    end

    methods (Hidden, Static)
        function runner = withDefaultPlugins(options)
            arguments
                options (1,1) struct = struct
            end
            import matlab.buildtool.BuildRunner;
            import matlab.buildtool.internal.getDefaultPlugins;

            runner = BuildRunner();
            
            plugins = getDefaultPlugins(options);
            for p = plugins(:)'
                runner.addPlugin(p);
            end
        end
    end
    
    methods
        function result = run(runner, plan, varargin)
            % RUN - Run the build
            %
            %   RESULT = RUN(RUNNER,PLAN) runs the default tasks in the plan using the
            %   specified build runner. It also runs all tasks on which the default
            %   tasks depend. The method returns the result of the run as a
            %   matlab.buildtool.BuildResult object.
            %
            %   To ensure that relative paths in tasks remain valid, the build runner
            %   first changes the current folder to the root folder of the plan. Once
            %   the run is complete, the build runner restores the current folder to
            %   its original state.
            %
            %   RESULT = RUN(RUNNER,PLAN,TASKNAME) runs the task named TASKNAME as well
            %   as all tasks on which the specified task depends. TASKNAME can be a
            %   string vector, character vector, or cell vector of character vectors.
            %
            %   RESULT = RUN(RUNNER,PLAN,TASKNAME,TASKARGS) runs the task named TASKNAME
            %   using the arguments in TASKARGS. Specify TASKARGS as a cell array.
            %
            %   Example:
            %
            %      % Load a plan from buildfile.m in your current folder.
            %      plan = matlab.buildtool.Plan.load;
            %
            %      % Create a build runner that produces text output.
            %      runner = matlab.buildtool.BuildRunner.withTextOutput;
            %
            %      % Run the default tasks in the plan.
            %      result = runner.run(plan);
            %
            %      % Run the "test" task.
            %      result = runner.run(plan,"test");
            %
            %      % Run the "release" task with the argument "minor".
            %      result = runner.run(plan,"release",{"minor"});
            %
            %   See also matlab.buildtool.Plan, matlab.buildtool.BuildResult,
            %      matlab.buildtool.Task, BUILDTOOL
            
            import matlab.buildtool.internal.parseRunArgs;

			%埃博拉酱修复开始
			try
				RequiredAddons=struct2table(plan('Toolbox:Package').AdditionalOptions.RequiredAddons);
				InstalledAddons=matlab.addons.installedAddons;
				[~,Index]=ismember(RequiredAddons.Name,InstalledAddons.Name);
				RequiredAddons.Identifier=InstalledAddons.Identifier(Index);
				plan('Toolbox:Package').AdditionalOptions.RequiredAddons=table2struct(RequiredAddons);
			catch ME
				if ME.identifier~="MATLAB:buildtool:TaskContainer:TaskNotFound"
					ME.rethrow;
				end
			end
			%埃博拉酱修复结束

            [taskName, taskArgs, options] = parseRunArgs(plan, varargin{:}, Parallel=false);
            result = runCore(runner, plan, taskName, taskArgs, options);
        end
        
        function plugins = get.Plugins(runner)
            plugins = [matlab.buildtool.plugins.BuildRunnerPlugin.empty(1,0), runner.OperatorList.Plugins{:}];
        end
    end

    methods (Hidden)
        function result = runCore(runner, plan, taskName, taskArgs, options)
            import matlab.buildtool.TaskGraph;
            import matlab.buildtool.BuildResult;
            import matlab.buildtool.internal.BuildRunData;
            import matlab.buildtool.plugins.plugindata.RunPluginData;

            if isempty(taskName)
                error(message("MATLAB:buildtool:BuildRunner:NoTaskSpecified"));
            end
            
            checkedTasks = [taskName, options.Skip, options.Prune];
            tf = plan.isTask(checkedTasks);
            if ~all(tf)
                error(message("MATLAB:buildtool:BuildRunner:UnableToFindTask", checkedTasks(find(~tf,1))));
            end
            
            if ~all(cellfun(@iscell, taskArgs))
                taskArgs = {taskArgs};
            end
            taskArgsDict = dictionary(taskName, taskArgs);

            % If a task is specified more than once, verify the args are consistent
            taskCounts = counts(taskName);
            for i = 1:numel(taskName)
                if taskCounts(taskName(i)) > 1 && ...
                        ~isscalar(taskArgs) && ...
                        ~isequaln(taskArgsDict{taskName(i)}, taskArgs{i})
                    error(message("MATLAB:buildtool:BuildRunner:TaskArgsMismatch", taskName(i)));
                end
            end

            runner.BuildRunData = BuildRunData.fromPlan(plan, taskName, ...
                taskArgsDict, options); %#ok<PROPLC>
            
            runner.PluginData.runTaskGraph = RunPluginData("", ...
                runner.BuildRunData, ...
                1:numel(runner.BuildRunData.TaskGraph.Tasks));
            
            t0 = tic();
            runner.evaluateMethodOnPlugins("runTaskGraph", runner.PluginData.runTaskGraph);
            duration = seconds(toc(t0));
            
            result = BuildResult( ...
                TaskResults=runner.BuildRunData.TaskResults, ...
                Duration=duration, ...
                Errored=runner.FixtureErrored);
        end

        function addPlugin(runner, plugin)
            arguments
                runner (1,1) matlab.buildtool.BuildRunner
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
            end
            
            runner.OperatorList.addPlugin(plugin);
        end
    end
    
    methods (Access = private)
        function runner = BuildRunner()
            import matlab.buildtool.fingerprints.Fingerprinter;
            import matlab.buildtool.internal.BuildContentOperatorList;
            
            runner.Fingerprinters = Fingerprinter.default();
            runner.OperatorList = BuildContentOperatorList(runner);
        end        
        
        function varargout = evaluateMethodOnPlugins(runner, methodName, pluginData)
            plugin = runner.prepareToEvaluateMethodOnPlugins(methodName);
            [varargout{1:nargout}] = plugin.(methodName)(pluginData);
            runner.completePluginMethodEvaluation();
        end
        
        function plugin = prepareToEvaluateMethodOnPlugins(runner, methodName)
            runner.PluginsInvokedRunnerContent = false;
            
            iter = runner.OperatorList.getIteratorFor(methodName);
            plugin = iter.getCurrentOperator;
            plugin.acceptOperatorIterator_(iter);
        end
        
        function completePluginMethodEvaluation(runner)
            if ~runner.PluginsInvokedRunnerContent
                error(message("MATLAB:buildtool:BuildRunner:MustCallSuperclassMethod"));
            end
        end
        
        function beginPluginMethod(runner, methodName, pluginData)
            if runner.PluginData.(methodName) ~= pluginData
                error(message("MATLAB:buildtool:BuildRunner:PluginDataMismatch", methodName));
            end
        end
        
        function completePluginMethod(runner)
            runner.PluginsInvokedRunnerContent = true;
        end
    end
    
    % Duck-typed PluginOperator interface
    methods (Hidden, Access = {?matlab.buildtool.internal.PluginOperator, ?matlab.buildtool.plugins.BuildRunnerPlugin})
        function acceptOperatorIterator_(~, ~)
            % No-op; BuildRunner does not need the OperatorIterator
        end
    end
    
    methods (Hidden, Access = protected)        
        function runTaskGraph(runner, pluginData)
            import matlab.buildtool.fingerprints.TaskChanges;
            import matlab.buildtool.fingerprints.FingerprintContext;
            import matlab.buildtool.plugins.plugindata.TaskRunReason;
            import matlab.buildtool.plugins.plugindata.TaskSkipReason;
            import matlab.buildtool.plugins.plugindata.TaskRunPluginData;
            import matlab.buildtool.plugins.plugindata.TaskSkipPluginData;
            import matlab.buildtool.plugins.plugindata.TaskContextCreationPluginData;
            import matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository;
            import matlab.buildtool.internal.fingerprints.detectTaskChanges;
            import matlab.buildtool.internal.fingerprints.computeTaskTrace;
            
            runner.beginPluginMethod("runTaskGraph", pluginData);

            % Create task trace repository
            cacheFolder = runner.BuildRunData.CacheFolder;
            [success, ~] = mkdir(cacheFolder);
            if ~success
                error(message("MATLAB:buildtool:BuildRunner:CannotCreateCacheFolder", cacheFolder));
            end
            traceRepo = PersistentTaskTraceRepository(cacheFolder);

            % Set up build fixtures
            teardownFixtures = onCleanup(@()runner.teardownAllBuildFixtures());
            runner.setupAllBuildFixtures();

            % If build fixtures failed to set up, do not run the tasks
            if runner.FixtureErrored && ~runner.BuildRunData.ContinueOnFailure
                runner.skipRemainingTasks(TaskSkipReason.DependencyFailed);
            end
            
            buildOptions = struct( ...
                "Parallel", runner.BuildRunData.Parallel, ...
                "CacheFolder", runner.BuildRunData.CacheFolder, ...
                "Verbosity", runner.BuildRunData.Verbosity);

            while runner.BuildRunData.hasTasksRemaining()
                task = runner.BuildRunData.selectNextTask();

                shouldTrack = task.supportsIncremental() ...
                    && ~task.DisableIncremental ...
                    && (~isempty(task.inputList()) || ~isempty(task.outputList()));

                fpArgs = { ...
                    "Fingerprinters", runner.Fingerprinters, ...
                    "FingerprintContext", FingerprintContext(RootFolder=runner.BuildRunData.Plan.RootFolder)};
                
                % Determine if task should run or skip
                runReason = TaskRunReason.empty();
                skipReason = TaskSkipReason.empty();
                
                if ismember(task.Name,runner.BuildRunData.Skip) || startsWith(task.Name,runner.BuildRunData.Skip+":")
                    skipReason = TaskSkipReason.UserRequested;
                elseif shouldTrack
                    previousTrace = traceRepo.lookupTrace(task.Name);
                    if ~isempty(previousTrace)
                        currentTrace = computeTaskTrace(task, runner.BuildRunData.CurrentTaskArguments, fpArgs{:});
                        taskChanges = detectTaskChanges(previousTrace, currentTrace);
                        if taskChanges.hasChanges()
                            runReason = TaskRunReason.Changed;
                        else
                            skipReason = TaskSkipReason.UpToDate;
                        end
                    else
                        taskChanges = TaskChanges.withAllPropertiesAdded(task, runner.BuildRunData.CurrentTaskArguments, fpArgs{:});
                        runReason = TaskRunReason.NoTrace;
                    end
                else
                    taskChanges = TaskChanges.withAllPropertiesAdded(task, runner.BuildRunData.CurrentTaskArguments, fpArgs{:});
                    if ~task.supportsIncremental()
                        runReason = TaskRunReason.IncrementalNotSupported;
                    elseif task.DisableIncremental
                        runReason = TaskRunReason.IncrementalDisabled;
                    else
                        runReason = TaskRunReason.NoInputsOrOutputs;
                    end
                end

                % Run or skip task
                if ~isempty(runReason)
                    % Create task context
                    runner.PluginData.createTaskContext = TaskContextCreationPluginData(task.Name, taskChanges, buildOptions);
                    
                    runner.CurrentTaskContext = runner.evaluateMethodOnPlugins("createTaskContext", runner.PluginData.createTaskContext);
                    cleanupContext = onCleanup(@()delete(runner.CurrentTaskContext));
    
                    delete(runner.PluginData.createTaskContext);

                    % Run task
                    runner.PluginData.runTask = TaskRunPluginData( ...
                        task.Name, ...
                        runner.BuildRunData, ...
                        runner.BuildRunData.CurrentIndex, ...
                        runReason, ...
                        taskChanges.diagnostics());
                    
                    runner.evaluateMethodOnPlugins("runTask", runner.PluginData.runTask);
                    
                    delete(runner.PluginData.runTask);

                    % Delete task context
                    delete(cleanupContext);
                else
                    % Skip task
                    runner.PluginData.skipTask = TaskSkipPluginData( ...
                        task.Name, ...
                        runner.BuildRunData, ...
                        runner.BuildRunData.CurrentIndex, ...
                        skipReason);
                    
                    runner.evaluateMethodOnPlugins("skipTask", runner.PluginData.skipTask);
                    
                    delete(runner.PluginData.skipTask);
                end
                
                % Skip remaining tasks or record trace, depending on task result
                if runner.BuildRunData.CurrentResult.Failed && ~runner.BuildRunData.ContinueOnFailure
                    runner.skipRemainingTasks(TaskSkipReason.DependencyFailed);
                elseif shouldTrack && ~runner.BuildRunData.CurrentResult.Skipped
                    newTrace = computeTaskTrace(task, runner.BuildRunData.CurrentTaskArguments, fpArgs{:});
                    if ~isequal(newTrace, previousTrace)
                        traceRepo.updateTrace(task.Name, newTrace);
                    end
                end
            end

            % Tear down build fixtures instead of waiting for clean up to do it because
            % errors in clean up become warnings
            runner.teardownAllBuildFixtures();
            
            runner.completePluginMethod();
        end

        function fixture = createBuildFixture(runner, pluginData)
            runner.beginPluginMethod("createBuildFixture", pluginData);
            fixture = copy(runner.FixtureToCreate);
            runner.completePluginMethod();
        end

        function setupBuildFixture(runner, pluginData)
            runner.beginPluginMethod("setupBuildFixture", pluginData);

            fixture = pluginData.Fixture;
            try
                fixture.setup();
            catch exception
                fixture.notifyExceptionThrownEvent_(exception);
                runner.FixtureErrored = true;
            end

            % Update the description which the fixture may have set during setup
            runner.PluginData.setupBuildFixture.Description = fixture.SetupDescription;

            runner.completePluginMethod();
        end

        function teardownBuildFixture(runner, pluginData)
            runner.beginPluginMethod("teardownBuildFixture", pluginData);

            fixture = pluginData.Fixture;
            try
                fixture.teardown();
            catch exception
                fixture.notifyExceptionThrownEvent_(exception);
                runner.FixtureErrored = true;
            end

            % Update the description which the fixture may have set during teardown
            runner.PluginData.teardownBuildFixture.Description = fixture.TeardownDescription;
            
            runner.completePluginMethod();
        end

        function context = createTaskContext(runner, pluginData)
            import matlab.buildtool.TaskContext;
            
            runner.beginPluginMethod("createTaskContext", pluginData);

            context = TaskContext(runner.BuildRunData.CurrentTask, runner.BuildRunData.Plan, ...
                TaskChanges=pluginData.TaskChanges, ...
                BuildOptions=pluginData.BuildOptions);

            context.addPostFailureEventCallback(@(info)runner.recordTaskFailure(info.Type));

            runner.completePluginMethod();
        end
        
        function runTask(runner, pluginData)
            import matlab.buildtool.plugins.plugindata.PluginData;
            import matlab.buildtool.plugins.plugindata.TaskActionRunPluginData;
            import matlab.buildtool.internal.validations.preValidateTask;
            import matlab.buildtool.internal.validations.postValidateTask;
            
            runner.beginPluginMethod("runTask", pluginData);

            task = runner.BuildRunData.CurrentTask;

            % Pre-validate task
            failures = preValidateTask(task);
            for failure = failures
                runner.CurrentTaskContext.notifyValidationFailedEvent_(failure);
            end
            runner.BuildRunData.CurrentResult.ValidationFailed = ~isempty(failures);

            % Store current folder in case a task action changes it
            currentFolder = pwd();
            restoreFolder = onCleanup(@()cd(currentFolder));
            
            % Run task actions
            for action = task.Actions
                if runner.BuildRunData.CurrentResult.Failed
                    break;
                end

                runner.PluginData.runTaskAction = TaskActionRunPluginData( ...
                    action.Name, ...
                    runner.BuildRunData, ...
                    runner.BuildRunData.CurrentIndex, ...
                    action, ...
                    runner.BuildRunData.CurrentTaskArguments);
                
                runner.evaluateMethodOnPlugins("runTaskAction", runner.PluginData.runTaskAction);
                
                delete(runner.PluginData.runTaskAction);
            end

            % Restore original folder in case a task action changed it
            delete(restoreFolder);

            % Post-validate task
            if ~runner.BuildRunData.CurrentResult.Failed
                failures = postValidateTask(task);
                for failure = failures
                    runner.CurrentTaskContext.notifyValidationFailedEvent_(failure);
                end
                runner.BuildRunData.CurrentResult.ValidationFailed = ~isempty(failures);
            end
            
            runner.completePluginMethod();
        end
        
        function runTaskAction(runner, pluginData)
            runner.beginPluginMethod("runTaskAction", pluginData);
            
            action = pluginData.TaskAction;
            try
                t0 = tic();
                action.evaluate(runner.CurrentTaskContext, runner.BuildRunData.CurrentTaskArguments{:});
                duration = seconds(toc(t0));
                runner.BuildRunData.addDurationToCurrentResult(duration);
            catch exception
                duration = seconds(toc(t0));
                runner.BuildRunData.addDurationToCurrentResult(duration);
                if ~(metaclass(exception) < ?matlab.buildtool.internal.qualifications.QualificationFailedException)
                    runner.CurrentTaskContext.notifyExceptionThrownEvent_(exception);
                    runner.recordTaskFailure("Errored");
                end
            end            
            runner.completePluginMethod();
        end

        function skipTask(runner, pluginData)
            import matlab.buildtool.plugins.plugindata.TaskSkipReason;

            runner.beginPluginMethod("skipTask", pluginData);
            runner.BuildRunData.CurrentResult.Skipped = true;
            runner.BuildRunData.CurrentResult.UpToDate = pluginData.SkipReason == TaskSkipReason.UpToDate;
            runner.completePluginMethod();
        end
    end
    
    methods (Access = private)
        function setupAllBuildFixtures(runner)
            import matlab.buildtool.internal.fixtures.Fixture;
            import matlab.buildtool.plugins.plugindata.PluginData;
            import matlab.buildtool.plugins.plugindata.BuildFixturePluginData;

            runner.ActiveFixtures = Fixture.empty();
            runner.FixtureErrored = false;

            plan = runner.BuildRunData.Plan;
            for fixture = plan.Fixtures
                % Create fixture copy
                runner.PluginData.createBuildFixture = PluginData( ...
                    class(fixture)); %#ok<CPROP>

                runner.FixtureToCreate = fixture;
                fixtureCopy = runner.evaluateMethodOnPlugins("createBuildFixture", runner.PluginData.createBuildFixture);

                delete(runner.PluginData.createBuildFixture);

                % Set up fixture
                runner.PluginData.setupBuildFixture = BuildFixturePluginData( ...
                    class(fixtureCopy), ...
                    fixtureCopy.SetupDescription, ...
                    fixtureCopy);

                runner.evaluateMethodOnPlugins("setupBuildFixture", runner.PluginData.setupBuildFixture);
    
                delete(runner.PluginData.setupBuildFixture);

                % Store active fixture
                runner.ActiveFixtures(end+1) = fixtureCopy;
            end
        end

        function teardownAllBuildFixtures(runner)
            import matlab.buildtool.plugins.plugindata.BuildFixturePluginData;

            exceptions = MException.empty();

            for i = numel(runner.ActiveFixtures):-1:1
                fixture = runner.ActiveFixtures(i);

                runner.PluginData.teardownBuildFixture = BuildFixturePluginData( ...
                    class(fixture), ...
                    fixture.TeardownDescription, ...
                    fixture);

                try
                    % Attempt to tear down fixture through plugins
                    runner.evaluateMethodOnPlugins("teardownBuildFixture", runner.PluginData.teardownBuildFixture);
                catch ex
                    % By-pass plugins to get the fixture torn down
                    runner.teardownBuildFixture(runner.PluginData.teardownBuildFixture);
                    exceptions(end+1) = ex; %#ok<AGROW>
                end

                delete(runner.PluginData.teardownBuildFixture);

                delete(runner.ActiveFixtures(i));
                runner.ActiveFixtures(i) = [];
            end

            if ~isempty(exceptions)
                ex = MException(message("MATLAB:buildtool:BuildRunner:FixtureTearDownException"));
                for cause = exceptions
                    ex = addCause(ex, cause);
                end
                throw(ex);
            end
        end

        function skipRemainingTasks(runner, reason)
            import matlab.buildtool.plugins.plugindata.TaskSkipPluginData;

            while runner.BuildRunData.hasTasksRemaining()
                runner.BuildRunData.selectNextTask();
                
                runner.PluginData.skipTask = TaskSkipPluginData( ...
                    runner.BuildRunData.CurrentTask.Name, ...
                    runner.BuildRunData, ...
                    runner.BuildRunData.CurrentIndex, ...
                    reason);

                runner.evaluateMethodOnPlugins("skipTask", runner.PluginData.skipTask);

                delete(runner.PluginData.skipTask);
            end
        end

        function recordTaskFailure(runner, property)
            runner.BuildRunData.CurrentResult.(property) = true;
        end
    end
end

function c = counts(array)
c = dictionary(array, 0);
for i = array(:)'
    c(i) = c(i) + 1;
end
end

% LocalWords:  buildfile TASKNAME TASKARGS Fingerprinters

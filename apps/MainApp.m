classdef MainApp < matlab.apps.AppBase

    % 与 App 组件对应的属性
    properties (Access = public)
        ElectriSimUIFigure  matlab.ui.Figure
        MainGrid            matlab.ui.container.GridLayout
        BodyGrid            matlab.ui.container.GridLayout
        RightPanel          matlab.ui.container.Panel
        rightGrid           matlab.ui.container.GridLayout
        RightTabs           matlab.ui.container.TabGroup
        ParamTab            matlab.ui.container.Tab
        KnowledgeTab        matlab.ui.container.Tab
        LogTab              matlab.ui.container.Tab
        LogGrid             matlab.ui.container.GridLayout
        LogTextArea         matlab.ui.control.TextArea
        CenterTabs          matlab.ui.container.TabGroup
        SceneTab            matlab.ui.container.Tab
        sceneGrid           matlab.ui.container.GridLayout
        SceneAxes           matlab.ui.control.UIAxes
        PlotsTab            matlab.ui.container.Tab
        plotsGrid           matlab.ui.container.GridLayout
        PlotsAxes           matlab.ui.control.UIAxes
        LeftPanel           matlab.ui.container.Panel
        TemplateGrid        matlab.ui.container.GridLayout
        TemplateTree        matlab.ui.container.Tree
        TopBarGrid          matlab.ui.container.GridLayout
        LogButton           matlab.ui.control.Button
        HelpButton          matlab.ui.control.Button
        ModeSwitch          matlab.ui.control.Switch
        ModeLabel           matlab.ui.control.Label
        ResetButton         matlab.ui.control.Button
        PauseButton         matlab.ui.control.Button
        PlayButton          matlab.ui.control.Button
        SpeedRow            matlab.ui.container.GridLayout
        SpeedLabel          matlab.ui.control.Label
        SpeedSlider         matlab.ui.control.Slider
        SpeedPlusButton     matlab.ui.control.Button
        SpeedMinusButton    matlab.ui.control.Button
        SpeedValueField     matlab.ui.control.NumericEditField
        SpeedValueLabel     matlab.ui.control.Label

        % 控制层/界面层/引擎层共享的运行时状态
        CurrentTemplateId   (1,1) string = "M1"
        CurrentSchemaKey    (1,1) string = "particle"
        CurrentEngineKey    (1,1) string = "particle"
        Params              (1,1) struct = struct()
        State               (1,1) struct = struct()

        % 参数组件容器与当前参数组件实例
        ParamHostGrid
        ParamComponent
    end

    properties (Access = private)
        ParamChangedListener = event.listener.empty
        LogLines            string = strings(0, 1)
        MaxLogLines         (1,1) double = 500
        PlaybackTimer       = []
        PlaybackPeriod      (1,1) double = 0.05
        IsPlaying           (1,1) logical = false
    end

    % 组件初始化
    methods (Access = private)

        % 创建主界面与各组件
        function createComponents(app)

            % 创建主窗口（先隐藏，待全部组件创建后再显示）
            app.ElectriSimUIFigure = uifigure('Visible', 'off');
            app.ElectriSimUIFigure.Position = [100 100 1280 720];
            app.ElectriSimUIFigure.Name = 'ElectriSim';
            app.ElectriSimUIFigure.WindowState = 'maximized';

            % 创建 MainGrid
            app.MainGrid = uigridlayout(app.ElectriSimUIFigure);
            app.MainGrid.ColumnWidth = {'1x'};
            app.MainGrid.RowHeight = {30, 30, '1x'};

            % 创建 SpeedRow
            app.SpeedRow = uigridlayout(app.MainGrid);
            app.SpeedRow.ColumnWidth = {70, '1x', 70, 70, 80, 80};
            app.SpeedRow.RowHeight = {'1x'};
            app.SpeedRow.ColumnSpacing = 8;
            app.SpeedRow.RowSpacing = 6;
            app.SpeedRow.Padding = [0 0 0 0];
            app.SpeedRow.Layout.Row = 2;
            app.SpeedRow.Layout.Column = 1;

            % 创建 SpeedValueLabel
            app.SpeedValueLabel = uilabel(app.SpeedRow);
            app.SpeedValueLabel.Layout.Row = 1;
            app.SpeedValueLabel.Layout.Column = 3;
            app.SpeedValueLabel.Text = '1.00×';

            % 创建 SpeedValueField
            app.SpeedValueField = uieditfield(app.SpeedRow, 'numeric');
            app.SpeedValueField.Limits = [0.25 4];
            app.SpeedValueField.Layout.Row = 1;
            app.SpeedValueField.Layout.Column = 4;
            app.SpeedValueField.Value = 1;

            % 创建 SpeedMinusButton
            app.SpeedMinusButton = uibutton(app.SpeedRow, 'push');
            app.SpeedMinusButton.Layout.Row = 1;
            app.SpeedMinusButton.Layout.Column = 5;
            app.SpeedMinusButton.Text = '-0.5';

            % 创建 SpeedPlusButton
            app.SpeedPlusButton = uibutton(app.SpeedRow, 'push');
            app.SpeedPlusButton.Layout.Row = 1;
            app.SpeedPlusButton.Layout.Column = 6;
            app.SpeedPlusButton.Text = '+0.5';

            % 创建 SpeedSlider
            app.SpeedSlider = uislider(app.SpeedRow);
            app.SpeedSlider.Limits = [0.25 4];
            app.SpeedSlider.MajorTicks = [];
            app.SpeedSlider.MajorTickLabels = {''};
            app.SpeedSlider.MinorTicks = 0;
            app.SpeedSlider.Layout.Row = 1;
            app.SpeedSlider.Layout.Column = 2;
            app.SpeedSlider.Value = 1;

            % 创建 SpeedLabel
            app.SpeedLabel = uilabel(app.SpeedRow);
            app.SpeedLabel.HorizontalAlignment = 'right';
            app.SpeedLabel.Layout.Row = 1;
            app.SpeedLabel.Layout.Column = 1;
            app.SpeedLabel.Text = '速度：';

            % 创建 TopBarGrid
            app.TopBarGrid = uigridlayout(app.MainGrid);
            app.TopBarGrid.ColumnWidth = {70, 70, 70, 80, 120, '1x', 80, 80};
            app.TopBarGrid.RowHeight = {30};
            app.TopBarGrid.ColumnSpacing = 8;
            app.TopBarGrid.RowSpacing = 0;
            app.TopBarGrid.Padding = [0 0 0 0];
            app.TopBarGrid.Layout.Row = 1;
            app.TopBarGrid.Layout.Column = 1;

            % 创建 PlayButton
            app.PlayButton = uibutton(app.TopBarGrid, 'push');
            app.PlayButton.Layout.Row = 1;
            app.PlayButton.Layout.Column = 1;
            app.PlayButton.Text = '运行';

            % 创建 PauseButton
            app.PauseButton = uibutton(app.TopBarGrid, 'push');
            app.PauseButton.Layout.Row = 1;
            app.PauseButton.Layout.Column = 2;
            app.PauseButton.Text = '暂停';

            % 创建 ResetButton
            app.ResetButton = uibutton(app.TopBarGrid, 'push');
            app.ResetButton.Layout.Row = 1;
            app.ResetButton.Layout.Column = 3;
            app.ResetButton.Text = '重置';

            % 创建 ModeLabel
            app.ModeLabel = uilabel(app.TopBarGrid);
            app.ModeLabel.HorizontalAlignment = 'right';
            app.ModeLabel.Layout.Row = 1;
            app.ModeLabel.Layout.Column = 4;
            app.ModeLabel.Text = '模式：';

            % 创建 ModeSwitch
            app.ModeSwitch = uiswitch(app.TopBarGrid, 'slider');
            app.ModeSwitch.Items = {'教学', '创造'};
            app.ModeSwitch.Layout.Row = 1;
            app.ModeSwitch.Layout.Column = 5;
            app.ModeSwitch.Value = '教学';

            % 创建 LogButton
            app.LogButton = uibutton(app.TopBarGrid, 'push');
            app.LogButton.Layout.Row = 1;
            app.LogButton.Layout.Column = 7;
            app.LogButton.Text = '导出日志';

            % 创建 HelpButton
            app.HelpButton = uibutton(app.TopBarGrid, 'push');
            app.HelpButton.Layout.Row = 1;
            app.HelpButton.Layout.Column = 8;
            app.HelpButton.Text = '帮助';

            % 创建 BodyGrid
            app.BodyGrid = uigridlayout(app.MainGrid);
            app.BodyGrid.ColumnWidth = {260, '1x', 320};
            app.BodyGrid.RowHeight = {'1x'};
            app.BodyGrid.Layout.Row = 3;
            app.BodyGrid.Layout.Column = 1;

            % 创建 LeftPanel
            app.LeftPanel = uipanel(app.BodyGrid);
            app.LeftPanel.Title = '教学目录';
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % 创建 TemplateGrid
            app.TemplateGrid = uigridlayout(app.LeftPanel);
            app.TemplateGrid.ColumnWidth = {'1x'};
            app.TemplateGrid.RowHeight = {'1x'};
            app.TemplateGrid.Padding = [6 6 6 6];

            % 创建 TemplateTree
            app.TemplateTree = uitree(app.TemplateGrid);
            app.TemplateTree.Layout.Row = 1;
            app.TemplateTree.Layout.Column = 1;

            % 创建 CenterTabs
            app.CenterTabs = uitabgroup(app.BodyGrid);
            app.CenterTabs.Layout.Row = 1;
            app.CenterTabs.Layout.Column = 2;

            % 创建 SceneTab
            app.SceneTab = uitab(app.CenterTabs);
            app.SceneTab.Title = '场景';

            % 创建 sceneGrid
            app.sceneGrid = uigridlayout(app.SceneTab);
            app.sceneGrid.ColumnWidth = {'1x'};
            app.sceneGrid.RowHeight = {'1x'};
            app.sceneGrid.Padding = [6 6 6 6];

            % 创建 SceneAxes
            app.SceneAxes = uiaxes(app.sceneGrid);
            title(app.SceneAxes, '粒子运动场景')
            xlabel(app.SceneAxes, 'x (m)')
            ylabel(app.SceneAxes, 'y (m)')
            app.SceneAxes.XGrid = 'on';
            app.SceneAxes.YGrid = 'on';
            app.SceneAxes.DataAspectRatio = [1 1 1];
            app.SceneAxes.DataAspectRatioMode = 'manual';
            app.SceneAxes.Layout.Row = 1;
            app.SceneAxes.Layout.Column = 1;

            % 创建 PlotsTab
            app.PlotsTab = uitab(app.CenterTabs);
            app.PlotsTab.Title = '曲线';

            % 创建 plotsGrid
            app.plotsGrid = uigridlayout(app.PlotsTab);
            app.plotsGrid.ColumnWidth = {'1x'};
            app.plotsGrid.RowHeight = {'1x'};
            app.plotsGrid.Padding = [6 6 6 6];

            % 创建 PlotsAxes
            app.PlotsAxes = uiaxes(app.plotsGrid);
            title(app.PlotsAxes, '粒子运动场景')
            xlabel(app.PlotsAxes, 'x (m)')
            ylabel(app.PlotsAxes, 'y (m)')
            app.PlotsAxes.XGrid = 'on';
            app.PlotsAxes.YGrid = 'on';
            app.PlotsAxes.Layout.Row = 1;
            app.PlotsAxes.Layout.Column = 1;

            % 创建 RightPanel
            app.RightPanel = uipanel(app.BodyGrid);
            app.RightPanel.Title = '控制台';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % 创建 rightGrid
            app.rightGrid = uigridlayout(app.RightPanel);
            app.rightGrid.ColumnWidth = {'1x'};
            app.rightGrid.RowHeight = {'1x'};
            app.rightGrid.Padding = [6 6 6 6];

            % 创建 RightTabs
            app.RightTabs = uitabgroup(app.rightGrid);
            app.RightTabs.Layout.Row = 1;
            app.RightTabs.Layout.Column = 1;

            % 创建 ParamTab
            app.ParamTab = uitab(app.RightTabs);
            app.ParamTab.Title = '参数';

            % 创建 KnowledgeTab
            app.KnowledgeTab = uitab(app.RightTabs);
            app.KnowledgeTab.Title = '知识点';

            % 创建 LogTab
            app.LogTab = uitab(app.RightTabs);
            app.LogTab.Title = '日志';

            % 创建 LogGrid
            app.LogGrid = uigridlayout(app.LogTab);
            app.LogGrid.ColumnWidth = {'1x'};
            app.LogGrid.RowHeight = {'1x'};
            app.LogGrid.Padding = [6 6 6 6];

            % 创建 LogTextArea
            app.LogTextArea = uitextarea(app.LogGrid);
            app.LogTextArea.Layout.Row = 1;
            app.LogTextArea.Layout.Column = 1;
            app.LogTextArea.Editable = 'off';

            % 所有组件创建完成后再显示窗口
            app.ElectriSimUIFigure.Visible = 'on';
        end

        function initializeRuntimeWiring(app)
            %INITIALIZERUNTIMEWIRING  构建 M1 最小闭环接线
            logger.logEvent(app, '信息', '应用接线开始', struct('entry', 'initializeRuntimeWiring'));
            app.buildTemplateTree();
            app.ensureParamComponent();
            app.bindUiCallbacks();
            boot.startup(app);
            app.syncSpeedWidgets(app.getSpeedScaleFromParams());
            app.selectTemplateNode(app.CurrentTemplateId);
            logger.logEvent(app, '信息', '应用接线完成', struct('template', app.CurrentTemplateId));
        end

        function buildTemplateTree(app)
            %BUILDTEMPLATETREE  根据 templates.registry() 构建模板树节点
            if ~isgraphics(app.TemplateTree)
                return;
            end

            delete(app.TemplateTree.Children);
            list = templates.registry();
            if isempty(list)
                return;
            end

            groups = unique(string({list.group}), 'stable');
            tplCount = numel(list);
            for ig = 1:numel(groups)
                g = groups(ig);
                parentNode = uitreenode(app.TemplateTree, ...
                    'Text', char(g), ...
                    'NodeData', "");
                idx = find(string({list.group}) == g);
                for k = idx
                    tpl = list(k);
                    uitreenode(parentNode, ...
                        'Text', char(tpl.title), ...
                        'NodeData', string(tpl.id));
                end
            end
            expand(app.TemplateTree);
            logger.logEvent(app, '信息', '模板树构建完成', struct('group_count', numel(groups), 'template_count', tplCount));
        end

        function ensureParamComponent(app)
            %ENSUREPARAMCOMPONENT  确保 M1 参数组件已挂载
            if isempty(app.ParamHostGrid) || ~isgraphics(app.ParamHostGrid)
                app.ParamHostGrid = uigridlayout(app.ParamTab);
                app.ParamHostGrid.ColumnWidth = {'1x'};
                app.ParamHostGrid.RowHeight = {'1x'};
                app.ParamHostGrid.Padding = [6 6 6 6];
            end

            if ~isempty(app.ParamComponent) && isa(app.ParamComponent, 'handle') && isvalid(app.ParamComponent)
                logger.logEvent(app, '调试', '参数组件复用', struct('class_name', class(app.ParamComponent)));
                return;
            end

            if exist('M1_for_test', 'class') == 8
                app.ParamComponent = M1_for_test(app.ParamHostGrid);
                app.ParamComponent.Layout.Row = 1;
                app.ParamComponent.Layout.Column = 1;
                propCount = numel(properties(app.ParamComponent));
                logger.logEvent(app, '信息', '参数组件加载成功', struct('class_name', 'M1_for_test', 'property_count', propCount));
            else
                app.ParamComponent = [];
                logger.logEvent(app, '警告', '参数组件缺失', struct('class_name', 'M1_for_test'));
            end

            if ~isempty(app.ParamChangedListener) && isvalid(app.ParamChangedListener)
                delete(app.ParamChangedListener);
            end
            app.ParamChangedListener = event.listener.empty;
            if ~isempty(app.ParamComponent)
                try
                    app.ParamChangedListener = addlistener( ...
                        app.ParamComponent, ...
                        'PayloadChanged', ...
                        @(~,~)control.onParamsChanged(app));
                    logger.logEvent(app, '信息', '参数组件监听已绑定', struct('event', 'PayloadChanged'));
                catch
                    app.ParamChangedListener = event.listener.empty;
                    logger.logEvent(app, '错误', '参数组件监听绑定失败', struct('event', 'PayloadChanged'));
                end
            end
        end

        function bindUiCallbacks(app)
            %BINDUICALLBACKS  绑定顶层 UI 回调到控制层
            app.TemplateTree.SelectionChangedFcn = @(~, evt)control.onTemplateChanged(app, evt);
            app.PlayButton.ButtonPushedFcn = @(~,~)control.onPlay(app);
            app.ResetButton.ButtonPushedFcn = @(~,~)control.onReset(app);
            app.PauseButton.ButtonPushedFcn = @(~,~)control.onPause(app);

            app.SpeedSlider.ValueChangedFcn = @(~,~)app.onSpeedSliderChanged();
            app.SpeedValueField.ValueChangedFcn = @(~,~)app.onSpeedFieldChanged();
            app.SpeedMinusButton.ButtonPushedFcn = @(~,~)app.bumpSpeed(-0.5);
            app.SpeedPlusButton.ButtonPushedFcn = @(~,~)app.bumpSpeed(0.5);
            app.LogButton.ButtonPushedFcn = @(~,~)app.onExportLog();
        end

        function onSpeedSliderChanged(app)
            app.syncSpeedWidgets(app.SpeedSlider.Value);
            logger.logEvent(app, '调试', '速度已修改', struct('source', 'slider', 'value', app.SpeedSlider.Value));
        end

        function onSpeedFieldChanged(app)
            app.syncSpeedWidgets(app.SpeedValueField.Value);
            logger.logEvent(app, '调试', '速度已修改', struct('source', 'field', 'value', app.SpeedValueField.Value));
        end

        function bumpSpeed(app, delta)
            app.syncSpeedWidgets(app.SpeedSlider.Value + delta);
            logger.logEvent(app, '调试', '速度步进调整', struct('delta', delta, 'value', app.SpeedSlider.Value));
        end

        function syncSpeedWidgets(app, speedValue)
            %SYNCSPEEDWIDGETS  保持速度控件与参数结构同步
            val = max(0.25, min(4.0, double(speedValue)));

            if isgraphics(app.SpeedSlider)
                app.SpeedSlider.Value = val;
            end
            if isgraphics(app.SpeedValueField)
                app.SpeedValueField.Value = val;
            end
            if isgraphics(app.SpeedValueLabel)
                app.SpeedValueLabel.Text = sprintf('%.2fx', val);
            end

            if isstruct(app.Params)
                app.Params.speedScale = val;
            end
        end

        function speedValue = getSpeedScaleFromParams(app)
            speedValue = 1.0;
            if isstruct(app.Params) && isfield(app.Params, 'speedScale')
                speedValue = app.Params.speedScale;
            end
        end

        function selectTemplateNode(app, tplId)
            %SELECTTEMPLATENODE  按模板 id 选中模板树节点
            if ~isgraphics(app.TemplateTree)
                return;
            end

            target = upper(strtrim(string(tplId)));
            allNodes = app.TemplateTree.Children;
            for i = 1:numel(allNodes)
                hit = app.findNodeById(allNodes(i), target);
                if ~isempty(hit)
                    app.TemplateTree.SelectedNodes = hit;
                    return;
                end
            end
        end

        function hit = findNodeById(app, node, targetId)
            %#ok<INUSL>
            hit = [];
            if isprop(node, 'NodeData')
                nodeId = upper(strtrim(string(node.NodeData)));
                if nodeId == targetId
                    hit = node;
                    return;
                end
            end

            children = node.Children;
            for i = 1:numel(children)
                hit = app.findNodeById(children(i), targetId);
                if ~isempty(hit)
                    return;
                end
            end
        end

        function ensureDevPaths(~)
            %ENSUREDEVPATHS  确保 apps/src/m 目录已加入 MATLAB 路径
            appPath = mfilename('fullpath');
            root = fileparts(fileparts(appPath));
            srcDir = fullfile(root, 'src');
            mDir = fullfile(root, 'm');

            if isfolder(srcDir) && isempty(which('boot.startup'))
                addpath(srcDir, '-begin');
            end
            if isfolder(mDir) && isempty(which('M1_for_test'))
                addpath(mDir, '-begin');
            end
        end

        function appendLogLineImpl(app, line)
            %APPENDLOGLINEIMPL  向日志缓冲区与 LogTextArea 追加一行文本
            if nargin < 2
                return;
            end

            app.LogLines(end+1, 1) = string(line);
            if numel(app.LogLines) > app.MaxLogLines
                app.LogLines = app.LogLines(end-app.MaxLogLines+1:end);
            end

            if isprop(app, 'LogTextArea') && isgraphics(app.LogTextArea)
                app.LogTextArea.Value = cellstr(app.LogLines);
            end
        end

        function onExportLog(app)
            %ONEXPORTLOG  导出当前日志到文本文件
            if isempty(app.LogLines)
                logger.logEvent(app, '警告', '导出日志失败', struct('reason', '当前无日志内容'));
                return;
            end

            defaultName = sprintf('emsimlab_log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
            [fileName, folder] = uiputfile('*.txt', '导出日志', defaultName);
            if isequal(fileName, 0) || isequal(folder, 0)
                logger.logEvent(app, '信息', '导出日志已取消', struct());
                return;
            end

            outputPath = fullfile(folder, fileName);
            fid = fopen(outputPath, 'w', 'n', 'UTF-8');
            if fid < 0
                logger.logEvent(app, '错误', '导出日志失败', struct('reason', '文件打开失败', 'path', outputPath));
                return;
            end

            cleaner = onCleanup(@()fclose(fid)); %#ok<NASGU>
            for i = 1:numel(app.LogLines)
                fprintf(fid, '%s\n', app.LogLines(i));
            end

            logger.logEvent(app, '信息', '导出日志成功', struct('path', outputPath, 'line_count', numel(app.LogLines)));
        end

        function ensurePlaybackTimer(app)
            %ENSUREPLAYBACKTIMER  懒创建播放定时器，并保持参数一致
            %
            % 设计说明
            %   1) 使用 fixedSpacing，保证播放节奏稳定
            %   2) BusyMode=drop，防止渲染慢导致回调堆积
            %   3) TimerFcn 只做一步推进，主逻辑仍在 control.onTick
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer)
                if abs(app.PlaybackTimer.Period - app.PlaybackPeriod) > 1e-9
                    app.PlaybackTimer.Period = app.PlaybackPeriod;
                end
                return;
            end

            app.PlaybackTimer = timer( ...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', app.PlaybackPeriod, ...
                'BusyMode', 'drop', ...
                'TimerFcn', @(~,~)control.onTick(app), ...
                'ErrorFcn', @(~,evt)app.onPlaybackTimerError(evt));
        end

        function onPlaybackTimerError(app, evt)
            %ONPLAYBACKTIMERERROR  定时器异常处理，防止卡死在播放态
            app.IsPlaying = false;
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer) ...
                    && strcmpi(app.PlaybackTimer.Running, 'on')
                stop(app.PlaybackTimer);
            end

            messageText = "未知错误";
            if nargin >= 2 && isstruct(evt) && isfield(evt, 'Data')
                if isfield(evt.Data, 'message')
                    messageText = string(evt.Data.message);
                elseif isfield(evt.Data, 'Message')
                    messageText = string(evt.Data.Message);
                end
            end
            logger.logEvent(app, '错误', '播放定时器异常', struct('reason', messageText));
        end
    end

    % App 创建与销毁
    methods (Access = public)

        function appendLogLine(app, line)
            %APPENDLOGLINE  对外公开的日志追加入口（供 logger.logEvent 调用）
            app.appendLogLineImpl(line);
        end

        function startPlayback(app)
            %STARTPLAYBACK  启动连续播放（若已播放则忽略）
            if app.IsPlaying
                logger.logEvent(app, '调试', '播放已在进行', struct());
                return;
            end

            app.ensurePlaybackTimer();
            if isempty(app.PlaybackTimer) || ~isvalid(app.PlaybackTimer)
                logger.logEvent(app, '错误', '播放启动失败', struct('reason', '定时器未就绪'));
                return;
            end

            if ~strcmpi(app.PlaybackTimer.Running, 'on')
                start(app.PlaybackTimer);
            end
            app.IsPlaying = true;
            logger.logEvent(app, '信息', '开始连续播放', struct('dt', app.PlaybackPeriod));
        end

        function pausePlayback(app)
            %PAUSEPLAYBACK  暂停连续播放（若未播放则忽略）
            if ~app.IsPlaying
                logger.logEvent(app, '调试', '播放当前已暂停', struct());
                return;
            end

            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer) ...
                    && strcmpi(app.PlaybackTimer.Running, 'on')
                stop(app.PlaybackTimer);
            end
            app.IsPlaying = false;
            logger.logEvent(app, '信息', '连续播放已暂停', struct());
        end

        function tf = isPlaybackRunning(app)
            %ISPLAYBACKRUNNING  查询连续播放状态
            tf = app.IsPlaying;
        end

        function dt = getPlaybackPeriod(app)
            %GETPLAYBACKPERIOD  获取连续播放单帧步长（秒）
            dt = app.PlaybackPeriod;
        end

        % 构造函数
        function app = MainApp

            app.ensureDevPaths();

            % 创建主界面与各组件
            createComponents(app)

            app.initializeRuntimeWiring();

            % 向 App Designer 注册 app 对象
            registerApp(app, app.ElectriSimUIFigure)

            logger.logEvent(app, '信息', '应用已创建', struct('class_name', class(app)));

            if nargout == 0
                clear app
            end
        end

        % App 删除前执行
        function delete(app)
            logger.logEvent(app, '信息', '应用销毁', struct());

            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer)
                if strcmpi(app.PlaybackTimer.Running, 'on')
                    stop(app.PlaybackTimer);
                end
                delete(app.PlaybackTimer);
            end

            if ~isempty(app.ParamChangedListener) && isvalid(app.ParamChangedListener)
                delete(app.ParamChangedListener);
            end

            % 删除 app 时释放主窗口
            if ~isempty(app.ElectriSimUIFigure) && isvalid(app.ElectriSimUIFigure)
                delete(app.ElectriSimUIFigure)
            end
        end
    end
end


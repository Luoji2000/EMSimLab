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
        MaxStoredLogLines   (1,1) double = 0   % 0 表示不截断，导出保留完整会话日志
        MaxUiLogLines       (1,1) double = 200
        LogUiFlushIntervalSec (1,1) double = 0.25
        LastLogUiFlushAt    (1,1) double = -inf
        PendingLogUiDirty   (1,1) logical = false
        PlaybackTimer       = []
        % 播放器渲染节拍（秒）：默认 30 FPS，视觉更平滑
        PlaybackPeriod      (1,1) double = 1/30
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

        function ensureParamComponent(app, templateId, forceRecreate)
            %ENSUREPARAMCOMPONENT  按模板确保参数组件已挂载
            %
            % 输入
            %   templateId : 模板 ID（可选，缺省使用 app.CurrentTemplateId）
            %
            % 规则
            %   1) 不同模板族使用不同参数组件类
            %   2) 若当前组件类不匹配，则销毁旧组件并重建
            %   3) 组件创建后统一绑定 PayloadChanged 监听

            if nargin < 2 || strlength(strtrim(string(templateId))) == 0
                templateId = app.CurrentTemplateId;
            end
            if nargin < 3
                forceRecreate = false;
            end
            className = app.resolveParamComponentClass(templateId);
            oldClass = "无";
            hasOldComponent = false;
            if ~isempty(app.ParamComponent) && isa(app.ParamComponent, 'handle')
                try
                    hasOldComponent = isvalid(app.ParamComponent);
                    if hasOldComponent
                        oldClass = string(class(app.ParamComponent));
                    end
                catch
                    hasOldComponent = false;
                end
            end

            logger.logEvent(app, '调试', '参数组件装载决策', struct( ...
                'template_id', string(templateId), ...
                'current_template', string(app.CurrentTemplateId), ...
                'engine_key', string(app.CurrentEngineKey), ...
                'force_recreate', logical(forceRecreate), ...
                'resolved_class', className, ...
                'old_class', oldClass, ...
                'has_old_component', hasOldComponent, ...
                'm1_class_exists', exist('M1_for_test', 'class') == 8, ...
                'm4_class_exists', exist('M4_for_test', 'class') == 8, ...
                'r2_class_exists', exist('R2_for_test', 'class') == 8, ...
                'r8_class_exists', exist('R8_for_test', 'class') == 8, ...
                'm5_class_exists', exist('M5_for_test', 'class') == 8, ...
                'm1_path', string(which('M1_for_test')), ...
                'm4_path', string(which('M4_for_test')), ...
                'r2_path', string(which('R2_for_test')), ...
                'r8_path', string(which('R8_for_test')), ...
                'm5_path', string(which('M5_for_test')) ...
            ));

            if isempty(app.ParamHostGrid) || ~isgraphics(app.ParamHostGrid)
                app.ParamHostGrid = uigridlayout(app.ParamTab);
                app.ParamHostGrid.ColumnWidth = {'1x'};
                app.ParamHostGrid.RowHeight = {'1x'};
                app.ParamHostGrid.Padding = [6 6 6 6];
            end

            needCreate = true;
            if ~isempty(app.ParamComponent) && isa(app.ParamComponent, 'handle') && isvalid(app.ParamComponent)
                oldClass = string(class(app.ParamComponent));
                if ~forceRecreate && strcmpi(oldClass, className)
                    needCreate = false;
                    logger.logEvent(app, '调试', '参数组件复用', struct('class_name', char(oldClass)));
                else
                    logger.logEvent(app, '信息', '参数组件切换', struct('from_class', char(oldClass), 'to_class', char(className)));
                    delete(app.ParamComponent);
                    app.ParamComponent = [];
                end
            end

            if needCreate
                if exist(char(className), 'class') == 8
                    app.ParamComponent = feval(char(className), app.ParamHostGrid);
                    app.ParamComponent.Layout.Row = 1;
                    app.ParamComponent.Layout.Column = 1;
                    propCount = numel(properties(app.ParamComponent));
                    logger.logEvent(app, '信息', '参数组件加载成功', struct('class_name', char(className), 'property_count', propCount));
                else
                    app.ParamComponent = [];
                    logger.logEvent(app, '警告', '参数组件缺失', struct('class_name', char(className)));
                end
            end

            logger.logEvent(app, '调试', '参数组件装载结果', struct( ...
                'resolved_class', className, ...
                'actual_class', app.readParamComponentClassName() ...
            ));

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

        function className = resolveParamComponentClass(app, templateId)
            %RESOLVEPARAMCOMPONENTCLASS  按模板 ID 解析参数组件类名
            token = upper(strtrim(string(templateId)));
            engineToken = "";
            if isprop(app, 'CurrentEngineKey')
                engineToken = lower(strtrim(string(app.CurrentEngineKey)));
            end

            if token == "R8"
                className = "R8_for_test";
                return;
            end
            if token == "M5"
                className = "M5_for_test";
                return;
            end
            if token == "M4"
                className = "M4_for_test";
                return;
            end

            if startsWith(token, "R") || engineToken == "rail"
                className = "R2_for_test";
                return;
            end

            % 其余模板先统一回退到 M1 参数组件
            className = "M1_for_test";
        end

        function className = readParamComponentClassName(app)
            %READPARAMCOMPONENTCLASSNAME  读取当前参数组件类名（用于日志）
            className = "无";
            if ~isempty(app.ParamComponent) && isa(app.ParamComponent, 'handle')
                try
                    if isvalid(app.ParamComponent)
                        className = string(class(app.ParamComponent));
                    end
                catch
                    className = "未知";
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
            app.RightTabs.SelectionChangedFcn = @(~,~)app.onRightTabsSelectionChanged();
        end

        function onRightTabsSelectionChanged(app)
            %ONRIGHTTABSSELECTIONCHANGED  切换到日志页时立即刷新一次缓存日志
            if app.isLogTabSelected()
                app.flushLogTextArea(true);
            end
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
            appsDir = fullfile(root, 'apps');
            srcDir = fullfile(root, 'src');
            mDir = fullfile(root, 'm');

            % 强制将当前工程路径置顶，避免被旧项目同名函数抢占
            if isfolder(appsDir)
                addpath(appsDir, '-begin');
            end
            if isfolder(srcDir)
                addpath(srcDir, '-begin');
            end
            if isfolder(mDir)
                addpath(mDir, '-begin');
            end
        end

        function appendLogLineImpl(app, line)
            %APPENDLOGLINEIMPL  向日志缓冲区与 LogTextArea 追加一行文本
            if nargin < 2
                return;
            end

            app.LogLines(end+1, 1) = string(line);
            if app.MaxStoredLogLines > 0 && numel(app.LogLines) > app.MaxStoredLogLines
                app.LogLines = app.LogLines(end-app.MaxStoredLogLines+1:end);
            end

            app.PendingLogUiDirty = true;
            app.flushLogTextArea(app.shouldForceLogUiFlush(line));
        end

        function tf = shouldForceLogUiFlush(~, line)
            %SHOULDFORCELOGUIFLUSH  错误/警告日志立即刷新到日志面板
            textLine = string(line);
            tf = contains(textLine, "[错误]") || contains(textLine, "[警告]");
        end

        function tf = isLogTabSelected(app)
            %ISLOGTABSELECTED  当前右侧是否位于日志标签页
            tf = false;
            if ~(isgraphics(app.RightTabs) && isgraphics(app.LogTab))
                return;
            end
            try
                tf = isequal(app.RightTabs.SelectedTab, app.LogTab);
            catch
                tf = false;
            end
        end

        function flushLogTextArea(app, forceFlush)
            %FLUSHLOGTEXTAREA  按策略将日志缓冲区刷新到 TextArea
            if nargin < 2
                forceFlush = false;
            end

            if ~app.PendingLogUiDirty
                return;
            end
            if ~(isprop(app, 'LogTextArea') && isgraphics(app.LogTextArea))
                app.PendingLogUiDirty = false;
                return;
            end

            nowSec = posixtime(datetime('now'));
            if ~forceFlush
                % 仅在日志页可见时进行常规刷新，减少隐藏页无效重绘
                if ~app.isLogTabSelected()
                    return;
                end
                if isfinite(app.LastLogUiFlushAt) ...
                        && (nowSec - app.LastLogUiFlushAt) < app.LogUiFlushIntervalSec
                    return;
                end
            end

            tailCount = min(numel(app.LogLines), app.MaxUiLogLines);
            if tailCount <= 0
                app.LogTextArea.Value = {''};
            else
                tailLines = app.LogLines(end-tailCount+1:end);
                app.LogTextArea.Value = cellstr(tailLines);
            end
            app.LastLogUiFlushAt = nowSec;
            app.PendingLogUiDirty = false;
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
            safePeriod = app.normalizePlaybackPeriod(app.PlaybackPeriod);
            app.PlaybackPeriod = safePeriod;

            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer)
                if abs(app.PlaybackTimer.Period - safePeriod) > 1e-9
                    app.PlaybackTimer.Period = safePeriod;
                end
                return;
            end

            app.PlaybackTimer = timer( ...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', safePeriod, ...
                'BusyMode', 'drop', ...
                'TimerFcn', @(~,~)control.onTick(app), ...
                'ErrorFcn', @(~,evt)app.onPlaybackTimerError(evt));
        end

        function dt = normalizePlaybackPeriod(~, dtRaw)
            %NORMALIZEPLAYBACKPERIOD  将播放周期量化到毫秒，避免 timer 精度警告
            %
            % 规则
            %   1) 非法值回退到 1/30
            %   2) 最小周期限制为 1ms（timer 平台精度下限）
            %   3) 最终按 1ms 网格量化，避免“亚毫秒精度被忽略”警告
            dt = double(dtRaw);
            if ~isfinite(dt) || dt <= 0
                dt = 1/30;
            end
            dt = max(0.001, dt);
            dt = round(dt * 1000) / 1000;
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

        function reloadParamComponent(app, templateId, forceRecreate)
            %RELOADPARAMCOMPONENT  控制层可调用的参数组件重载入口
            %
            % 说明
            %   - control.* 位于类外部，无法直接调用 private 方法
            %   - 这里提供公开包装，内部转发到 ensureParamComponent
            if nargin < 2
                templateId = app.CurrentTemplateId;
            end
            if nargin < 3
                forceRecreate = true;
            end
            app.ensureParamComponent(templateId, forceRecreate);
        end

        function appendLogLine(app, line)
            %APPENDLOGLINE  对外公开的日志追加入口（供 logger.logEvent 调用）
            app.appendLogLineImpl(line);
        end

        function tf = shouldEchoLogToConsole(app, entryOrLevel, varargin)
            %SHOULDECHOLOGTOCONSOLE  控制日志是否打印到 MATLAB 命令行
            %
            % 规则（性能优先）
            %   1) 仅保留“应用已创建/应用销毁”命令行输出
            %   2) 其他日志只写入 UI 日志区，不写命令行
            %
            % 兼容性
            %   - 支持旧签名：shouldEchoLogToConsole(level)
            %   - 支持新签名：shouldEchoLogToConsole(entryStruct)
            %#ok<INUSD>
            tf = false;

            eventName = "";
            if nargin >= 2 && isstruct(entryOrLevel)
                if isfield(entryOrLevel, 'event')
                    eventName = string(entryOrLevel.event);
                end
            else
                if nargin >= 3
                    eventName = string(varargin{1});
                end
            end

            tf = any(eventName == ["应用已创建", "应用销毁"]);
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
            dt = app.normalizePlaybackPeriod(app.PlaybackPeriod);
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


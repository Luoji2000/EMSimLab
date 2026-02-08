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

            % 所有组件创建完成后再显示窗口
            app.ElectriSimUIFigure.Visible = 'on';
        end

        function initializeRuntimeWiring(app)
            %INITIALIZERUNTIMEWIRING  构建 M1 最小闭环接线
            app.buildTemplateTree();
            app.ensureParamComponent();
            app.bindUiCallbacks();
            boot.startup(app);
            app.syncSpeedWidgets(app.getSpeedScaleFromParams());
            app.selectTemplateNode(app.CurrentTemplateId);
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
                return;
            end

            if exist('M1_for_test', 'class') == 8
                app.ParamComponent = M1_for_test(app.ParamHostGrid);
                app.ParamComponent.Layout.Row = 1;
                app.ParamComponent.Layout.Column = 1;
            else
                app.ParamComponent = [];
                hint = uilabel(app.ParamHostGrid);
                hint.Layout.Row = 1;
                hint.Layout.Column = 1;
                hint.WordWrap = 'on';
                hint.Text = '未找到 m/M1_for_test.m（参数组件未加载）';
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
                catch
                    app.ParamChangedListener = event.listener.empty;
                end
            end
        end

        function bindUiCallbacks(app)
            %BINDUICALLBACKS  绑定顶层 UI 回调到控制层
            app.TemplateTree.SelectionChangedFcn = @(~, evt)control.onTemplateChanged(app, evt);
            app.PlayButton.ButtonPushedFcn = @(~,~)control.onPlay(app);
            app.ResetButton.ButtonPushedFcn = @(~,~)control.onReset(app);
            app.PauseButton.ButtonPushedFcn = @(~,~)[];

            app.SpeedSlider.ValueChangedFcn = @(~,~)app.onSpeedSliderChanged();
            app.SpeedValueField.ValueChangedFcn = @(~,~)app.onSpeedFieldChanged();
            app.SpeedMinusButton.ButtonPushedFcn = @(~,~)app.bumpSpeed(-0.5);
            app.SpeedPlusButton.ButtonPushedFcn = @(~,~)app.bumpSpeed(0.5);
        end

        function onSpeedSliderChanged(app)
            app.syncSpeedWidgets(app.SpeedSlider.Value);
        end

        function onSpeedFieldChanged(app)
            app.syncSpeedWidgets(app.SpeedValueField.Value);
        end

        function bumpSpeed(app, delta)
            app.syncSpeedWidgets(app.SpeedSlider.Value + delta);
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
                addpath(srcDir);
            end
            if isfolder(mDir) && isempty(which('M1_for_test'))
                addpath(mDir);
            end
        end
    end

    % App 创建与销毁
    methods (Access = public)

        % 构造函数
        function app = MainApp

            app.ensureDevPaths();

            % 创建主界面与各组件
            createComponents(app)

            app.initializeRuntimeWiring();

            % 向 App Designer 注册 app 对象
            registerApp(app, app.ElectriSimUIFigure)

            if nargout == 0
                clear app
            end
        end

        % App 删除前执行
        function delete(app)

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


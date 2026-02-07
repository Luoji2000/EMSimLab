classdef MainApp < matlab.apps.AppBase

    % Properties that correspond to app components
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
    end

    
    properties (Access = private)
    end
    

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ElectriSimUIFigure and hide until all components are created
            app.ElectriSimUIFigure = uifigure('Visible', 'off');
            app.ElectriSimUIFigure.Position = [100 100 1280 720];
            app.ElectriSimUIFigure.Name = 'ElectriSim';
            app.ElectriSimUIFigure.WindowState = 'maximized';

            % Create MainGrid
            app.MainGrid = uigridlayout(app.ElectriSimUIFigure);
            app.MainGrid.ColumnWidth = {'1x'};
            app.MainGrid.RowHeight = {30, 30, '1x'};

            % Create SpeedRow
            app.SpeedRow = uigridlayout(app.MainGrid);
            app.SpeedRow.ColumnWidth = {70, '1x', 70, 70, 80, 80};
            app.SpeedRow.RowHeight = {'1x'};
            app.SpeedRow.ColumnSpacing = 8;
            app.SpeedRow.RowSpacing = 6;
            app.SpeedRow.Padding = [0 0 0 0];
            app.SpeedRow.Layout.Row = 2;
            app.SpeedRow.Layout.Column = 1;

            % Create SpeedValueLabel
            app.SpeedValueLabel = uilabel(app.SpeedRow);
            app.SpeedValueLabel.Layout.Row = 1;
            app.SpeedValueLabel.Layout.Column = 3;
            app.SpeedValueLabel.Text = '1.00×';

            % Create SpeedValueField
            app.SpeedValueField = uieditfield(app.SpeedRow, 'numeric');
            app.SpeedValueField.Limits = [0.25 4];
            app.SpeedValueField.Layout.Row = 1;
            app.SpeedValueField.Layout.Column = 4;
            app.SpeedValueField.Value = 1;

            % Create SpeedMinusButton
            app.SpeedMinusButton = uibutton(app.SpeedRow, 'push');
            app.SpeedMinusButton.Layout.Row = 1;
            app.SpeedMinusButton.Layout.Column = 5;
            app.SpeedMinusButton.Text = '-0.5';

            % Create SpeedPlusButton
            app.SpeedPlusButton = uibutton(app.SpeedRow, 'push');
            app.SpeedPlusButton.Layout.Row = 1;
            app.SpeedPlusButton.Layout.Column = 6;
            app.SpeedPlusButton.Text = '+0.5';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.SpeedRow);
            app.SpeedSlider.Limits = [0.25 4];
            app.SpeedSlider.MajorTicks = [];
            app.SpeedSlider.MajorTickLabels = {''};
            app.SpeedSlider.MinorTicks = 0;
            app.SpeedSlider.Layout.Row = 1;
            app.SpeedSlider.Layout.Column = 2;
            app.SpeedSlider.Value = 1;

            % Create SpeedLabel
            app.SpeedLabel = uilabel(app.SpeedRow);
            app.SpeedLabel.HorizontalAlignment = 'right';
            app.SpeedLabel.Layout.Row = 1;
            app.SpeedLabel.Layout.Column = 1;
            app.SpeedLabel.Text = '速度：';

            % Create TopBarGrid
            app.TopBarGrid = uigridlayout(app.MainGrid);
            app.TopBarGrid.ColumnWidth = {70, 70, 70, 80, 120, '1x', 80, 80};
            app.TopBarGrid.RowHeight = {30};
            app.TopBarGrid.ColumnSpacing = 8;
            app.TopBarGrid.RowSpacing = 0;
            app.TopBarGrid.Padding = [0 0 0 0];
            app.TopBarGrid.Layout.Row = 1;
            app.TopBarGrid.Layout.Column = 1;

            % Create PlayButton
            app.PlayButton = uibutton(app.TopBarGrid, 'push');
            app.PlayButton.Layout.Row = 1;
            app.PlayButton.Layout.Column = 1;
            app.PlayButton.Text = '运行';

            % Create PauseButton
            app.PauseButton = uibutton(app.TopBarGrid, 'push');
            app.PauseButton.Layout.Row = 1;
            app.PauseButton.Layout.Column = 2;
            app.PauseButton.Text = '暂停';

            % Create ResetButton
            app.ResetButton = uibutton(app.TopBarGrid, 'push');
            app.ResetButton.Layout.Row = 1;
            app.ResetButton.Layout.Column = 3;
            app.ResetButton.Text = '重置';

            % Create ModeLabel
            app.ModeLabel = uilabel(app.TopBarGrid);
            app.ModeLabel.HorizontalAlignment = 'right';
            app.ModeLabel.Layout.Row = 1;
            app.ModeLabel.Layout.Column = 4;
            app.ModeLabel.Text = '模式：';

            % Create ModeSwitch
            app.ModeSwitch = uiswitch(app.TopBarGrid, 'slider');
            app.ModeSwitch.Items = {'教学', '创造'};
            app.ModeSwitch.Layout.Row = 1;
            app.ModeSwitch.Layout.Column = 5;
            app.ModeSwitch.Value = '教学';

            % Create HelpButton
            app.HelpButton = uibutton(app.TopBarGrid, 'push');
            app.HelpButton.Layout.Row = 1;
            app.HelpButton.Layout.Column = 8;
            app.HelpButton.Text = '帮助';

            % Create BodyGrid
            app.BodyGrid = uigridlayout(app.MainGrid);
            app.BodyGrid.ColumnWidth = {260, '1x', 320};
            app.BodyGrid.RowHeight = {'1x'};
            app.BodyGrid.Layout.Row = 3;
            app.BodyGrid.Layout.Column = 1;

            % Create LeftPanel
            app.LeftPanel = uipanel(app.BodyGrid);
            app.LeftPanel.Title = '教学目录';
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create TemplateGrid
            app.TemplateGrid = uigridlayout(app.LeftPanel);
            app.TemplateGrid.ColumnWidth = {'1x'};
            app.TemplateGrid.RowHeight = {'1x'};
            app.TemplateGrid.Padding = [6 6 6 6];

            % Create TemplateTree
            app.TemplateTree = uitree(app.TemplateGrid);
            app.TemplateTree.Layout.Row = 1;
            app.TemplateTree.Layout.Column = 1;

            % Create CenterTabs
            app.CenterTabs = uitabgroup(app.BodyGrid);
            app.CenterTabs.Layout.Row = 1;
            app.CenterTabs.Layout.Column = 2;

            % Create SceneTab
            app.SceneTab = uitab(app.CenterTabs);
            app.SceneTab.Title = '场景';

            % Create sceneGrid
            app.sceneGrid = uigridlayout(app.SceneTab);
            app.sceneGrid.ColumnWidth = {'1x'};
            app.sceneGrid.RowHeight = {'1x'};
            app.sceneGrid.Padding = [6 6 6 6];

            % Create SceneAxes
            app.SceneAxes = uiaxes(app.sceneGrid);
            title(app.SceneAxes, '粒子运动场景')
            xlabel(app.SceneAxes, 'x (m)')
            ylabel(app.SceneAxes, 'y (m)')
            app.SceneAxes.XGrid = 'on';
            app.SceneAxes.YGrid = 'on';
            app.SceneAxes.Layout.Row = 1;
            app.SceneAxes.Layout.Column = 1;

            % Create PlotsTab
            app.PlotsTab = uitab(app.CenterTabs);
            app.PlotsTab.Title = '曲线';

            % Create plotsGrid
            app.plotsGrid = uigridlayout(app.PlotsTab);
            app.plotsGrid.ColumnWidth = {'1x'};
            app.plotsGrid.RowHeight = {'1x'};
            app.plotsGrid.Padding = [6 6 6 6];

            % Create PlotsAxes
            app.PlotsAxes = uiaxes(app.plotsGrid);
            title(app.PlotsAxes, '粒子运动场景')
            xlabel(app.PlotsAxes, 'x (m)')
            ylabel(app.PlotsAxes, 'y (m)')
            app.PlotsAxes.XGrid = 'on';
            app.PlotsAxes.YGrid = 'on';
            app.PlotsAxes.Layout.Row = 1;
            app.PlotsAxes.Layout.Column = 1;

            % Create RightPanel
            app.RightPanel = uipanel(app.BodyGrid);
            app.RightPanel.Title = '控制台';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create rightGrid
            app.rightGrid = uigridlayout(app.RightPanel);
            app.rightGrid.ColumnWidth = {'1x'};
            app.rightGrid.RowHeight = {'1x'};
            app.rightGrid.Padding = [6 6 6 6];

            % Create RightTabs
            app.RightTabs = uitabgroup(app.rightGrid);
            app.RightTabs.Layout.Row = 1;
            app.RightTabs.Layout.Column = 1;

            % Create ParamTab
            app.ParamTab = uitab(app.RightTabs);
            app.ParamTab.Title = '参数';

            % Create KnowledgeTab
            app.KnowledgeTab = uitab(app.RightTabs);
            app.KnowledgeTab.Title = '知识点';

            % Create LogTab
            app.LogTab = uitab(app.RightTabs);
            app.LogTab.Title = '日志';

            % Show the figure after all components are created
            app.ElectriSimUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MainApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ElectriSimUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ElectriSimUIFigure)
        end
    end
end
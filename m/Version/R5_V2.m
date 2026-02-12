classdef R5_V2 < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        paramGrid                   matlab.ui.container.GridLayout
        ConductorSettingsPanel      matlab.ui.container.Panel
        ConductorSettingsPanelGrid  matlab.ui.container.GridLayout
        restitutionCoeffLabel       matlab.ui.control.Label
        restitutionCoeffField       matlab.ui.control.NumericEditField
        conductorSelectorLabel      matlab.ui.control.Label
        conductorSelectorDropDown   matlab.ui.control.DropDown
        ResultsPanel                matlab.ui.container.Panel
        ResultsGrid                 matlab.ui.container.GridLayout
        vcenterLabel                matlab.ui.control.Label
        xcenterLabel                matlab.ui.control.Label
        QLabel                      matlab.ui.control.Label
        FmagLabel                   matlab.ui.control.Label
        ILabel                      matlab.ui.control.Label
        epsilonLabel                matlab.ui.control.Label
        vcenterField                matlab.ui.control.NumericEditField
        xcenterField                matlab.ui.control.NumericEditField
        QField                      matlab.ui.control.NumericEditField
        FmagField                   matlab.ui.control.NumericEditField
        IField                      matlab.ui.control.NumericEditField
        epsilonField                matlab.ui.control.NumericEditField
        FieldPanel                  matlab.ui.container.Panel
        fGrid                       matlab.ui.container.GridLayout
        lblB                        matlab.ui.control.Label
        lblBdir                     matlab.ui.control.Label
        BField                      matlab.ui.control.NumericEditField
        BdirDropDown                matlab.ui.control.DropDown
        ConductorPanel              matlab.ui.container.Panel
        ConductorGrid               matlab.ui.container.GridLayout
        FLabel                      matlab.ui.control.Label
        mLabel                      matlab.ui.control.Label
        RLabel                      matlab.ui.control.Label
        vLabel                      matlab.ui.control.Label
        xLabel                      matlab.ui.control.Label
        LLabel                      matlab.ui.control.Label
        FField                      matlab.ui.control.NumericEditField
        mField                      matlab.ui.control.NumericEditField
        RField                      matlab.ui.control.NumericEditField
        vField                      matlab.ui.control.NumericEditField
        xField                      matlab.ui.control.NumericEditField
        LField                      matlab.ui.control.NumericEditField
        BoundsPanel                 matlab.ui.container.Panel
        bGrid                       matlab.ui.container.GridLayout
        BoundedCheck                matlab.ui.control.CheckBox
        XminLabel                   matlab.ui.control.Label
        XmaxLabel                   matlab.ui.control.Label
        YminLabel                   matlab.ui.control.Label
        YmaxLabel                   matlab.ui.control.Label
        XminField                   matlab.ui.control.NumericEditField
        XmaxField                   matlab.ui.control.NumericEditField
        YminField                   matlab.ui.control.NumericEditField
        YmaxField                   matlab.ui.control.NumericEditField
        ViewPanel                   matlab.ui.container.Panel
        vGrid                       matlab.ui.container.GridLayout
        ShowCurrentCheck            matlab.ui.control.CheckBox
        ShowAmpereForceCheck        matlab.ui.control.CheckBox
        ShowTrailCheck              matlab.ui.control.CheckBox
        ShowVCheck                  matlab.ui.control.CheckBox
        ShowDriveForceCheck         matlab.ui.control.CheckBox
        ShowGridCheck               matlab.ui.control.CheckBox
        ShowBMarksCheck             matlab.ui.control.CheckBox
    end

    methods (Access = protected)
        
        % 属性值发生更改时执行的代码
        function update(comp)
            % 使用此函数更新底层组件
            
        end

        % 创建底层组件
        function setup(comp)

            comp.Position = [1 1 320 240];

            % Create paramGrid
            comp.paramGrid = uigridlayout(comp);
            comp.paramGrid.ColumnWidth = {'1x'};
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.paramGrid.RowSpacing = 8;
            comp.paramGrid.Padding = [6 6 6 6];

            % Create ViewPanel
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 5;
            comp.ViewPanel.Layout.Column = 1;

            % Create vGrid
            comp.vGrid = uigridlayout(comp.ViewPanel);
            comp.vGrid.ColumnWidth = {'1x', '1x', '1x'};
            comp.vGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.vGrid.ColumnSpacing = 8;
            comp.vGrid.RowSpacing = 6;
            comp.vGrid.Padding = [8 8 8 8];

            % Create ShowBMarksCheck
            comp.ShowBMarksCheck = uicheckbox(comp.vGrid);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 3;
            comp.ShowBMarksCheck.Value = true;

            % Create ShowGridCheck
            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 2;
            comp.ShowGridCheck.Value = true;

            % Create ShowDriveForceCheck
            comp.ShowDriveForceCheck = uicheckbox(comp.vGrid);
            comp.ShowDriveForceCheck.Text = '牵引力箭头';
            comp.ShowDriveForceCheck.Layout.Row = 1;
            comp.ShowDriveForceCheck.Layout.Column = 3;
            comp.ShowDriveForceCheck.Value = true;

            % Create ShowVCheck
            comp.ShowVCheck = uicheckbox(comp.vGrid);
            comp.ShowVCheck.Text = '速度箭头';
            comp.ShowVCheck.Layout.Row = 1;
            comp.ShowVCheck.Layout.Column = 2;
            comp.ShowVCheck.Value = true;

            % Create ShowTrailCheck
            comp.ShowTrailCheck = uicheckbox(comp.vGrid);
            comp.ShowTrailCheck.Text = '轨迹';
            comp.ShowTrailCheck.Layout.Row = 1;
            comp.ShowTrailCheck.Layout.Column = 1;
            comp.ShowTrailCheck.Value = true;

            % Create ShowAmpereForceCheck
            comp.ShowAmpereForceCheck = uicheckbox(comp.vGrid);
            comp.ShowAmpereForceCheck.Text = '安培力箭头';
            comp.ShowAmpereForceCheck.Layout.Row = 2;
            comp.ShowAmpereForceCheck.Layout.Column = 1;
            comp.ShowAmpereForceCheck.Value = true;

            % Create ShowCurrentCheck
            comp.ShowCurrentCheck = uicheckbox(comp.vGrid);
            comp.ShowCurrentCheck.Text = '电流方向';
            comp.ShowCurrentCheck.Layout.Row = 3;
            comp.ShowCurrentCheck.Layout.Column = 1;
            comp.ShowCurrentCheck.Value = true;

            % Create BoundsPanel
            comp.BoundsPanel = uipanel(comp.paramGrid);
            comp.BoundsPanel.Title = '边界';
            comp.BoundsPanel.Layout.Row = 4;
            comp.BoundsPanel.Layout.Column = 1;

            % Create bGrid
            comp.bGrid = uigridlayout(comp.BoundsPanel);
            comp.bGrid.ColumnWidth = {60, '1x', 60, '1x'};
            comp.bGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.bGrid.ColumnSpacing = 8;
            comp.bGrid.RowSpacing = 6;
            comp.bGrid.Padding = [8 8 8 8];

            % Create YmaxField
            comp.YmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.YmaxField.Layout.Row = 3;
            comp.YmaxField.Layout.Column = 4;

            % Create YminField
            comp.YminField = uieditfield(comp.bGrid, 'numeric');
            comp.YminField.Layout.Row = 2;
            comp.YminField.Layout.Column = 4;

            % Create XmaxField
            comp.XmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.XmaxField.Layout.Row = 3;
            comp.XmaxField.Layout.Column = 2;

            % Create XminField
            comp.XminField = uieditfield(comp.bGrid, 'numeric');
            comp.XminField.Layout.Row = 2;
            comp.XminField.Layout.Column = 2;

            % Create YmaxLabel
            comp.YmaxLabel = uilabel(comp.bGrid);
            comp.YmaxLabel.Layout.Row = 3;
            comp.YmaxLabel.Layout.Column = 3;
            comp.YmaxLabel.Interpreter = 'tex';
            comp.YmaxLabel.Text = 'y_{max}';

            % Create YminLabel
            comp.YminLabel = uilabel(comp.bGrid);
            comp.YminLabel.Layout.Row = 2;
            comp.YminLabel.Layout.Column = 3;
            comp.YminLabel.Interpreter = 'tex';
            comp.YminLabel.Text = 'y_{min}';

            % Create XmaxLabel
            comp.XmaxLabel = uilabel(comp.bGrid);
            comp.XmaxLabel.Layout.Row = 3;
            comp.XmaxLabel.Layout.Column = 1;
            comp.XmaxLabel.Interpreter = 'tex';
            comp.XmaxLabel.Text = 'x_{max}';

            % Create XminLabel
            comp.XminLabel = uilabel(comp.bGrid);
            comp.XminLabel.Layout.Row = 2;
            comp.XminLabel.Layout.Column = 1;
            comp.XminLabel.Interpreter = 'tex';
            comp.XminLabel.Text = 'x_{min}';

            % Create BoundedCheck
            comp.BoundedCheck = uicheckbox(comp.bGrid);
            comp.BoundedCheck.Text = '有界';
            comp.BoundedCheck.Layout.Row = 1;
            comp.BoundedCheck.Layout.Column = 1;

            % Create ConductorPanel
            comp.ConductorPanel = uipanel(comp.paramGrid);
            comp.ConductorPanel.Title = '导体';
            comp.ConductorPanel.Layout.Row = 2;
            comp.ConductorPanel.Layout.Column = 1;

            % Create ConductorGrid
            comp.ConductorGrid = uigridlayout(comp.ConductorPanel);
            comp.ConductorGrid.ColumnWidth = {90, '1x'};
            comp.ConductorGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.ConductorGrid.ColumnSpacing = 8;
            comp.ConductorGrid.RowSpacing = 6;
            comp.ConductorGrid.Padding = [8 8 8 8];

            % Create LField
            comp.LField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.LField.Layout.Row = 1;
            comp.LField.Layout.Column = 2;

            % Create xField
            comp.xField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.xField.Layout.Row = 2;
            comp.xField.Layout.Column = 2;

            % Create vField
            comp.vField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.vField.Layout.Row = 3;
            comp.vField.Layout.Column = 2;

            % Create RField
            comp.RField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.RField.Layout.Row = 4;
            comp.RField.Layout.Column = 2;

            % Create mField
            comp.mField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.mField.Layout.Row = 5;
            comp.mField.Layout.Column = 2;

            % Create FField
            comp.FField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.FField.Layout.Row = 6;
            comp.FField.Layout.Column = 2;

            % Create LLabel
            comp.LLabel = uilabel(comp.ConductorGrid);
            comp.LLabel.Layout.Row = 1;
            comp.LLabel.Layout.Column = 1;
            comp.LLabel.Interpreter = 'tex';
            comp.LLabel.Text = 'L(m)';

            % Create xLabel
            comp.xLabel = uilabel(comp.ConductorGrid);
            comp.xLabel.Layout.Row = 2;
            comp.xLabel.Layout.Column = 1;
            comp.xLabel.Interpreter = 'tex';
            comp.xLabel.Text = 'x_0(m)';

            % Create vLabel
            comp.vLabel = uilabel(comp.ConductorGrid);
            comp.vLabel.Layout.Row = 3;
            comp.vLabel.Layout.Column = 1;
            comp.vLabel.Interpreter = 'tex';
            comp.vLabel.Text = 'v_0(m/s)';

            % Create RLabel
            comp.RLabel = uilabel(comp.ConductorGrid);
            comp.RLabel.Layout.Row = 4;
            comp.RLabel.Layout.Column = 1;
            comp.RLabel.Interpreter = 'tex';
            comp.RLabel.Text = 'R(\Omega)';

            % Create mLabel
            comp.mLabel = uilabel(comp.ConductorGrid);
            comp.mLabel.Layout.Row = 5;
            comp.mLabel.Layout.Column = 1;
            comp.mLabel.Interpreter = 'tex';
            comp.mLabel.Text = 'm(kg)';

            % Create FLabel
            comp.FLabel = uilabel(comp.ConductorGrid);
            comp.FLabel.Layout.Row = 6;
            comp.FLabel.Layout.Column = 1;
            comp.FLabel.Interpreter = 'tex';
            comp.FLabel.Text = 'F_{drive}';

            % Create FieldPanel
            comp.FieldPanel = uipanel(comp.paramGrid);
            comp.FieldPanel.Title = '磁场';
            comp.FieldPanel.Layout.Row = 3;
            comp.FieldPanel.Layout.Column = 1;

            % Create fGrid
            comp.fGrid = uigridlayout(comp.FieldPanel);
            comp.fGrid.ColumnWidth = {90, '1x'};
            comp.fGrid.RowHeight = {'fit', 'fit'};
            comp.fGrid.ColumnSpacing = 8;
            comp.fGrid.RowSpacing = 6;
            comp.fGrid.Padding = [8 8 8 8];

            % Create BdirDropDown
            comp.BdirDropDown = uidropdown(comp.fGrid);
            comp.BdirDropDown.Items = {'出屏', '入屏'};
            comp.BdirDropDown.Layout.Row = 2;
            comp.BdirDropDown.Layout.Column = 2;
            comp.BdirDropDown.Value = '出屏';

            % Create BField
            comp.BField = uieditfield(comp.fGrid, 'numeric');
            comp.BField.Layout.Row = 1;
            comp.BField.Layout.Column = 2;

            % Create lblBdir
            comp.lblBdir = uilabel(comp.fGrid);
            comp.lblBdir.Layout.Row = 2;
            comp.lblBdir.Layout.Column = 1;
            comp.lblBdir.Text = 'B 方向';

            % Create lblB
            comp.lblB = uilabel(comp.fGrid);
            comp.lblB.Layout.Row = 1;
            comp.lblB.Layout.Column = 1;
            comp.lblB.Interpreter = 'tex';
            comp.lblB.Text = 'B(T)';

            % Create ResultsPanel
            comp.ResultsPanel = uipanel(comp.paramGrid);
            comp.ResultsPanel.Title = '输出结果';
            comp.ResultsPanel.Layout.Row = 6;
            comp.ResultsPanel.Layout.Column = 1;

            % Create ResultsGrid
            comp.ResultsGrid = uigridlayout(comp.ResultsPanel);
            comp.ResultsGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            comp.ResultsGrid.RowHeight = {'1x', '1x', '1x'};
            comp.ResultsGrid.ColumnSpacing = 8;
            comp.ResultsGrid.RowSpacing = 6;
            comp.ResultsGrid.Padding = [8 8 8 8];

            % Create epsilonField
            comp.epsilonField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.epsilonField.Editable = 'off';
            comp.epsilonField.Layout.Row = 1;
            comp.epsilonField.Layout.Column = 2;

            % Create IField
            comp.IField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.IField.Editable = 'off';
            comp.IField.Layout.Row = 1;
            comp.IField.Layout.Column = 4;

            % Create FmagField
            comp.FmagField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.FmagField.Editable = 'off';
            comp.FmagField.Layout.Row = 3;
            comp.FmagField.Layout.Column = 2;

            % Create QField
            comp.QField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.QField.Editable = 'off';
            comp.QField.Layout.Row = 3;
            comp.QField.Layout.Column = 4;

            % Create xcenterField
            comp.xcenterField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.xcenterField.Editable = 'off';
            comp.xcenterField.Layout.Row = 2;
            comp.xcenterField.Layout.Column = 2;

            % Create vcenterField
            comp.vcenterField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.vcenterField.Editable = 'off';
            comp.vcenterField.Layout.Row = 2;
            comp.vcenterField.Layout.Column = 4;

            % Create epsilonLabel
            comp.epsilonLabel = uilabel(comp.ResultsGrid);
            comp.epsilonLabel.Layout.Row = 1;
            comp.epsilonLabel.Layout.Column = 1;
            comp.epsilonLabel.Interpreter = 'tex';
            comp.epsilonLabel.Text = '\epsilon';

            % Create ILabel
            comp.ILabel = uilabel(comp.ResultsGrid);
            comp.ILabel.Layout.Row = 1;
            comp.ILabel.Layout.Column = 3;
            comp.ILabel.Interpreter = 'tex';
            comp.ILabel.Text = 'I';

            % Create FmagLabel
            comp.FmagLabel = uilabel(comp.ResultsGrid);
            comp.FmagLabel.Layout.Row = 3;
            comp.FmagLabel.Layout.Column = 1;
            comp.FmagLabel.Interpreter = 'tex';
            comp.FmagLabel.Text = 'F_{mag}';

            % Create QLabel
            comp.QLabel = uilabel(comp.ResultsGrid);
            comp.QLabel.Layout.Row = 3;
            comp.QLabel.Layout.Column = 3;
            comp.QLabel.Interpreter = 'tex';
            comp.QLabel.Text = 'Q';

            % Create xcenterLabel
            comp.xcenterLabel = uilabel(comp.ResultsGrid);
            comp.xcenterLabel.Layout.Row = 2;
            comp.xcenterLabel.Layout.Column = 1;
            comp.xcenterLabel.Interpreter = 'tex';
            comp.xcenterLabel.Text = 'x_{center}';

            % Create vcenterLabel
            comp.vcenterLabel = uilabel(comp.ResultsGrid);
            comp.vcenterLabel.Layout.Row = 2;
            comp.vcenterLabel.Layout.Column = 3;
            comp.vcenterLabel.Interpreter = 'tex';
            comp.vcenterLabel.Text = 'v_{center}';

            % Create ConductorSettingsPanel
            comp.ConductorSettingsPanel = uipanel(comp.paramGrid);
            comp.ConductorSettingsPanel.Title = '模式';
            comp.ConductorSettingsPanel.Layout.Row = 1;
            comp.ConductorSettingsPanel.Layout.Column = 1;

            % Create ConductorSettingsPanelGrid
            comp.ConductorSettingsPanelGrid = uigridlayout(comp.ConductorSettingsPanel);
            comp.ConductorSettingsPanelGrid.ColumnWidth = {90, '1x'};
            comp.ConductorSettingsPanelGrid.RowHeight = {'fit', 'fit'};
            comp.ConductorSettingsPanelGrid.ColumnSpacing = 8;
            comp.ConductorSettingsPanelGrid.RowSpacing = 6;
            comp.ConductorSettingsPanelGrid.Padding = [8 8 8 8];

            % Create conductorSelectorDropDown
            comp.conductorSelectorDropDown = uidropdown(comp.ConductorSettingsPanelGrid);
            comp.conductorSelectorDropDown.Items = {'左边导体', '右边导体'};
            comp.conductorSelectorDropDown.Layout.Row = 1;
            comp.conductorSelectorDropDown.Layout.Column = 2;
            comp.conductorSelectorDropDown.Value = '左边导体';

            % Create conductorSelectorLabel
            comp.conductorSelectorLabel = uilabel(comp.ConductorSettingsPanelGrid);
            comp.conductorSelectorLabel.Layout.Row = 1;
            comp.conductorSelectorLabel.Layout.Column = 1;
            comp.conductorSelectorLabel.Text = '导体选择';

            % Create restitutionCoeffField
            comp.restitutionCoeffField = uieditfield(comp.ConductorSettingsPanelGrid, 'numeric');
            comp.restitutionCoeffField.Limits = [0 1];
            comp.restitutionCoeffField.Layout.Row = 2;
            comp.restitutionCoeffField.Layout.Column = 2;
            comp.restitutionCoeffField.Value = 1;

            % Create restitutionCoeffLabel
            comp.restitutionCoeffLabel = uilabel(comp.ConductorSettingsPanelGrid);
            comp.restitutionCoeffLabel.Layout.Row = 2;
            comp.restitutionCoeffLabel.Layout.Column = 1;
            comp.restitutionCoeffLabel.Text = '恢复系数';
        end
    end
end
classdef R8_v1 < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        paramGrid             matlab.ui.container.GridLayout
        ModeSwitchPanel       matlab.ui.container.Panel
        ModeSwitchGrid        matlab.ui.container.GridLayout
        ModeLabel             matlab.ui.control.Label
        ModeDropDown          matlab.ui.control.DropDown
        FieldPanel            matlab.ui.container.Panel
        fGrid                 matlab.ui.container.GridLayout
        lblB                  matlab.ui.control.Label
        lblBdir               matlab.ui.control.Label
        BField                matlab.ui.control.NumericEditField
        BdirDropDown          matlab.ui.control.DropDown
        WireLoopPanel         matlab.ui.container.Panel
        WireLoopGrid          matlab.ui.container.GridLayout
        xConterLabel          matlab.ui.control.Label
        YconterLabel          matlab.ui.control.Label
        YconterField          matlab.ui.control.NumericEditField
        xConterField          matlab.ui.control.NumericEditField
        FLabel                matlab.ui.control.Label
        mLabel                matlab.ui.control.Label
        RLabel                matlab.ui.control.Label
        vLabel                matlab.ui.control.Label
        HLabel                matlab.ui.control.Label
        WLabel                matlab.ui.control.Label
        FField                matlab.ui.control.NumericEditField
        mField                matlab.ui.control.NumericEditField
        RField                matlab.ui.control.NumericEditField
        vField                matlab.ui.control.NumericEditField
        HField                matlab.ui.control.NumericEditField
        WField                matlab.ui.control.NumericEditField
        BoundsPanel           matlab.ui.container.Panel
        bGrid                 matlab.ui.container.GridLayout
        XminLabel             matlab.ui.control.Label
        XmaxLabel             matlab.ui.control.Label
        XminField             matlab.ui.control.NumericEditField
        XmaxField             matlab.ui.control.NumericEditField
        ViewPanel             matlab.ui.container.Panel
        vGrid                 matlab.ui.container.GridLayout
        ShowCurrentCheck      matlab.ui.control.CheckBox
        ShowAmpereForceCheck  matlab.ui.control.CheckBox
        ShowTrailCheck        matlab.ui.control.CheckBox
        ShowVCheck            matlab.ui.control.CheckBox
        ShowDriveForceCheck   matlab.ui.control.CheckBox
        ShowGridCheck         matlab.ui.control.CheckBox
        ShowBMarksCheck       matlab.ui.control.CheckBox
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
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
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
            comp.bGrid.ColumnWidth = {90, '1x'};
            comp.bGrid.RowHeight = {'fit', 'fit'};
            comp.bGrid.ColumnSpacing = 8;
            comp.bGrid.RowSpacing = 6;
            comp.bGrid.Padding = [8 8 8 8];

            % Create XmaxField
            comp.XmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.XmaxField.Layout.Row = 2;
            comp.XmaxField.Layout.Column = 2;

            % Create XminField
            comp.XminField = uieditfield(comp.bGrid, 'numeric');
            comp.XminField.Layout.Row = 1;
            comp.XminField.Layout.Column = 2;

            % Create XmaxLabel
            comp.XmaxLabel = uilabel(comp.bGrid);
            comp.XmaxLabel.Layout.Row = 2;
            comp.XmaxLabel.Layout.Column = 1;
            comp.XmaxLabel.Interpreter = 'tex';
            comp.XmaxLabel.Text = 'x_{max}';

            % Create XminLabel
            comp.XminLabel = uilabel(comp.bGrid);
            comp.XminLabel.Layout.Row = 1;
            comp.XminLabel.Layout.Column = 1;
            comp.XminLabel.Interpreter = 'tex';
            comp.XminLabel.Text = 'x_{min}';

            % Create WireLoopPanel
            comp.WireLoopPanel = uipanel(comp.paramGrid);
            comp.WireLoopPanel.Title = '线框';
            comp.WireLoopPanel.Layout.Row = 2;
            comp.WireLoopPanel.Layout.Column = 1;

            % Create WireLoopGrid
            comp.WireLoopGrid = uigridlayout(comp.WireLoopPanel);
            comp.WireLoopGrid.ColumnWidth = {90, '1x'};
            comp.WireLoopGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.WireLoopGrid.ColumnSpacing = 8;
            comp.WireLoopGrid.RowSpacing = 6;
            comp.WireLoopGrid.Padding = [8 8 8 8];

            % Create WField
            comp.WField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.WField.Layout.Row = 1;
            comp.WField.Layout.Column = 2;

            % Create HField
            comp.HField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.HField.Layout.Row = 2;
            comp.HField.Layout.Column = 2;

            % Create vField
            comp.vField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.vField.Layout.Row = 7;
            comp.vField.Layout.Column = 2;

            % Create RField
            comp.RField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.RField.Layout.Row = 8;
            comp.RField.Layout.Column = 2;

            % Create mField
            comp.mField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.mField.Layout.Row = 5;
            comp.mField.Layout.Column = 2;

            % Create FField
            comp.FField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.FField.Layout.Row = 6;
            comp.FField.Layout.Column = 2;

            % Create WLabel
            comp.WLabel = uilabel(comp.WireLoopGrid);
            comp.WLabel.Layout.Row = 1;
            comp.WLabel.Layout.Column = 1;
            comp.WLabel.Text = '宽(m)';

            % Create HLabel
            comp.HLabel = uilabel(comp.WireLoopGrid);
            comp.HLabel.Layout.Row = 2;
            comp.HLabel.Layout.Column = 1;
            comp.HLabel.Text = '高(m)';

            % Create vLabel
            comp.vLabel = uilabel(comp.WireLoopGrid);
            comp.vLabel.Layout.Row = 7;
            comp.vLabel.Layout.Column = 1;
            comp.vLabel.Interpreter = 'tex';
            comp.vLabel.Text = 'v_0(m/s)';

            % Create RLabel
            comp.RLabel = uilabel(comp.WireLoopGrid);
            comp.RLabel.Layout.Row = 8;
            comp.RLabel.Layout.Column = 1;
            comp.RLabel.Interpreter = 'tex';
            comp.RLabel.Text = 'R(\Omega)';

            % Create mLabel
            comp.mLabel = uilabel(comp.WireLoopGrid);
            comp.mLabel.Layout.Row = 5;
            comp.mLabel.Layout.Column = 1;
            comp.mLabel.Interpreter = 'tex';
            comp.mLabel.Text = 'm(kg)';

            % Create FLabel
            comp.FLabel = uilabel(comp.WireLoopGrid);
            comp.FLabel.Layout.Row = 6;
            comp.FLabel.Layout.Column = 1;
            comp.FLabel.Interpreter = 'tex';
            comp.FLabel.Text = 'F_{drive}';

            % Create xConterField
            comp.xConterField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.xConterField.Layout.Row = 3;
            comp.xConterField.Layout.Column = 2;

            % Create YconterField
            comp.YconterField = uieditfield(comp.WireLoopGrid, 'numeric');
            comp.YconterField.Layout.Row = 4;
            comp.YconterField.Layout.Column = 2;

            % Create YconterLabel
            comp.YconterLabel = uilabel(comp.WireLoopGrid);
            comp.YconterLabel.Layout.Row = 4;
            comp.YconterLabel.Layout.Column = 1;
            comp.YconterLabel.Text = '中心位置X(m)';

            % Create xConterLabel
            comp.xConterLabel = uilabel(comp.WireLoopGrid);
            comp.xConterLabel.Layout.Row = 3;
            comp.xConterLabel.Layout.Column = 1;
            comp.xConterLabel.Text = '中心位置Y(m)';

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

            % Create ModeSwitchPanel
            comp.ModeSwitchPanel = uipanel(comp.paramGrid);
            comp.ModeSwitchPanel.Title = '模式';
            comp.ModeSwitchPanel.Layout.Row = 1;
            comp.ModeSwitchPanel.Layout.Column = 1;

            % Create ModeSwitchGrid
            comp.ModeSwitchGrid = uigridlayout(comp.ModeSwitchPanel);
            comp.ModeSwitchGrid.ColumnWidth = {90, '1x'};
            comp.ModeSwitchGrid.RowHeight = {'fit'};
            comp.ModeSwitchGrid.ColumnSpacing = 8;
            comp.ModeSwitchGrid.RowSpacing = 6;
            comp.ModeSwitchGrid.Padding = [8 8 8 8];

            % Create ModeDropDown
            comp.ModeDropDown = uidropdown(comp.ModeSwitchGrid);
            comp.ModeDropDown.Items = {'匀速运动', '启用阻尼'};
            comp.ModeDropDown.Layout.Row = 1;
            comp.ModeDropDown.Layout.Column = 2;
            comp.ModeDropDown.Value = '匀速运动';

            % Create ModeLabel
            comp.ModeLabel = uilabel(comp.ModeSwitchGrid);
            comp.ModeLabel.Layout.Row = 1;
            comp.ModeLabel.Layout.Column = 1;
            comp.ModeLabel.Text = '模式';
        end
    end
end
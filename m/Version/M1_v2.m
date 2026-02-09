classdef M1_v2 < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        paramGrid             matlab.ui.container.GridLayout
        FieldPanel            matlab.ui.container.Panel
        fGrid                 matlab.ui.container.GridLayout
        lblB                  matlab.ui.control.Label
        lblBdir               matlab.ui.control.Label
        BField                matlab.ui.control.NumericEditField
        BdirDropDown          matlab.ui.control.DropDown
        ParticlePanel         matlab.ui.container.Panel
        pGrid                 matlab.ui.container.GridLayout
        ThetaField            matlab.ui.control.NumericEditField
        lblTheta              matlab.ui.control.Label
        V0Field               matlab.ui.control.NumericEditField
        lblV0                 matlab.ui.control.Label
        UnitModeLabel         matlab.ui.control.Label
        lblParticleType       matlab.ui.control.Label
        QLabel                matlab.ui.control.Label
        MLabel                matlab.ui.control.Label
        XLabel                matlab.ui.control.Label
        YLabel                matlab.ui.control.Label
        UnitModeDropDown      matlab.ui.control.DropDown
        ParticleTypeDropDown  matlab.ui.control.DropDown
        QField                matlab.ui.control.NumericEditField
        MField                matlab.ui.control.NumericEditField
        XParticleField        matlab.ui.control.NumericEditField
        YParticleField        matlab.ui.control.NumericEditField
        BoundsPanel           matlab.ui.container.Panel
        bGrid                 matlab.ui.container.GridLayout
        BoundedCheck          matlab.ui.control.CheckBox
        XminLabel             matlab.ui.control.Label
        XmaxLabel             matlab.ui.control.Label
        YminLabel             matlab.ui.control.Label
        YmaxLabel             matlab.ui.control.Label
        XminField             matlab.ui.control.NumericEditField
        XmaxField             matlab.ui.control.NumericEditField
        YminField             matlab.ui.control.NumericEditField
        YmaxField             matlab.ui.control.NumericEditField
        ViewPanel             matlab.ui.container.Panel
        vGrid                 matlab.ui.container.GridLayout
        ShowTrailCheck        matlab.ui.control.CheckBox
        ShowVCheck            matlab.ui.control.CheckBox
        ShowFCheck            matlab.ui.control.CheckBox
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
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            comp.paramGrid.RowSpacing = 8;
            comp.paramGrid.Padding = [6 6 6 6];

            % Create ViewPanel
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 4;
            comp.ViewPanel.Layout.Column = 1;

            % Create vGrid
            comp.vGrid = uigridlayout(comp.ViewPanel);
            comp.vGrid.ColumnWidth = {'1x', '1x', '1x'};
            comp.vGrid.RowHeight = {'fit', 'fit'};

            % Create ShowBMarksCheck
            comp.ShowBMarksCheck = uicheckbox(comp.vGrid);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 2;

            % Create ShowGridCheck
            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 1;
            comp.ShowGridCheck.Value = true;

            % Create ShowFCheck
            comp.ShowFCheck = uicheckbox(comp.vGrid);
            comp.ShowFCheck.Text = '受力箭头';
            comp.ShowFCheck.Layout.Row = 1;
            comp.ShowFCheck.Layout.Column = 3;

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

            % Create BoundsPanel
            comp.BoundsPanel = uipanel(comp.paramGrid);
            comp.BoundsPanel.Title = '边界';
            comp.BoundsPanel.Layout.Row = 3;
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

            % Create ParticlePanel
            comp.ParticlePanel = uipanel(comp.paramGrid);
            comp.ParticlePanel.Title = '粒子';
            comp.ParticlePanel.Layout.Row = 1;
            comp.ParticlePanel.Layout.Column = 1;

            % Create pGrid
            comp.pGrid = uigridlayout(comp.ParticlePanel);
            comp.pGrid.ColumnWidth = {90, '1x'};
            comp.pGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.pGrid.ColumnSpacing = 8;
            comp.pGrid.RowSpacing = 6;
            comp.pGrid.Padding = [8 8 8 8];

            % Create YParticleField
            comp.YParticleField = uieditfield(comp.pGrid, 'numeric');
            comp.YParticleField.Layout.Row = 6;
            comp.YParticleField.Layout.Column = 2;

            % Create XParticleField
            comp.XParticleField = uieditfield(comp.pGrid, 'numeric');
            comp.XParticleField.Layout.Row = 5;
            comp.XParticleField.Layout.Column = 2;

            % Create MField
            comp.MField = uieditfield(comp.pGrid, 'numeric');
            comp.MField.Layout.Row = 4;
            comp.MField.Layout.Column = 2;

            % Create QField
            comp.QField = uieditfield(comp.pGrid, 'numeric');
            comp.QField.Layout.Row = 3;
            comp.QField.Layout.Column = 2;

            % Create ParticleTypeDropDown
            comp.ParticleTypeDropDown = uidropdown(comp.pGrid);
            comp.ParticleTypeDropDown.Items = {'自定义', '电子', '质子'};
            comp.ParticleTypeDropDown.Layout.Row = 2;
            comp.ParticleTypeDropDown.Layout.Column = 2;
            comp.ParticleTypeDropDown.Value = '自定义';

            % Create UnitModeDropDown
            comp.UnitModeDropDown = uidropdown(comp.pGrid);
            comp.UnitModeDropDown.Items = {'SI单位(C, kg)', '粒子单位(e, me)'};
            comp.UnitModeDropDown.Layout.Row = 1;
            comp.UnitModeDropDown.Layout.Column = 2;
            comp.UnitModeDropDown.Value = 'SI单位(C, kg)';

            % Create YLabel
            comp.YLabel = uilabel(comp.pGrid);
            comp.YLabel.Layout.Row = 6;
            comp.YLabel.Layout.Column = 1;
            comp.YLabel.Interpreter = 'tex';
            comp.YLabel.Text = 'Y(m)';

            % Create XLabel
            comp.XLabel = uilabel(comp.pGrid);
            comp.XLabel.Layout.Row = 5;
            comp.XLabel.Layout.Column = 1;
            comp.XLabel.Interpreter = 'tex';
            comp.XLabel.Text = 'X(m)';

            % Create MLabel
            comp.MLabel = uilabel(comp.pGrid);
            comp.MLabel.Layout.Row = 4;
            comp.MLabel.Layout.Column = 1;
            comp.MLabel.Interpreter = 'tex';
            comp.MLabel.Text = 'm(kg)';

            % Create QLabel
            comp.QLabel = uilabel(comp.pGrid);
            comp.QLabel.Layout.Row = 3;
            comp.QLabel.Layout.Column = 1;
            comp.QLabel.Interpreter = 'tex';
            comp.QLabel.Text = 'q(C)';

            % Create lblParticleType
            comp.lblParticleType = uilabel(comp.pGrid);
            comp.lblParticleType.Layout.Row = 2;
            comp.lblParticleType.Layout.Column = 1;
            comp.lblParticleType.Text = '粒子类型';

            % Create UnitModeLabel
            comp.UnitModeLabel = uilabel(comp.pGrid);
            comp.UnitModeLabel.Layout.Row = 1;
            comp.UnitModeLabel.Layout.Column = 1;
            comp.UnitModeLabel.Text = '单位模式';

            % Create lblV0
            comp.lblV0 = uilabel(comp.pGrid);
            comp.lblV0.Layout.Row = 7;
            comp.lblV0.Layout.Column = 1;
            comp.lblV0.Interpreter = 'tex';
            comp.lblV0.Text = 'v_0(m/s)';

            % Create V0Field
            comp.V0Field = uieditfield(comp.pGrid, 'numeric');
            comp.V0Field.Layout.Row = 7;
            comp.V0Field.Layout.Column = 2;

            % Create lblTheta
            comp.lblTheta = uilabel(comp.pGrid);
            comp.lblTheta.Layout.Row = 8;
            comp.lblTheta.Layout.Column = 1;
            comp.lblTheta.Interpreter = 'tex';
            comp.lblTheta.Text = '\theta(deg)';

            % Create ThetaField
            comp.ThetaField = uieditfield(comp.pGrid, 'numeric');
            comp.ThetaField.Layout.Row = 8;
            comp.ThetaField.Layout.Column = 2;

            % Create FieldPanel
            comp.FieldPanel = uipanel(comp.paramGrid);
            comp.FieldPanel.Title = '磁场';
            comp.FieldPanel.Layout.Row = 2;
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
        end
    end
end
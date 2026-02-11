classdef M4_V1 < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        paramGrid             matlab.ui.container.GridLayout
        ViewPanel             matlab.ui.container.Panel
        vGrid                 matlab.ui.container.GridLayout
        ShowFelcCheck         matlab.ui.control.CheckBox
        ShowTrailCheck        matlab.ui.control.CheckBox
        ShowVCheck            matlab.ui.control.CheckBox
        ShowFmagCheck         matlab.ui.control.CheckBox
        ShowGridCheck         matlab.ui.control.CheckBox
        ShowBMarksCheck       matlab.ui.control.CheckBox
        FieldPanel            matlab.ui.container.Panel
        fGrid                 matlab.ui.container.GridLayout
        lblB                  matlab.ui.control.Label
        lblBdir               matlab.ui.control.Label
        BField                matlab.ui.control.NumericEditField
        BdirDropDown          matlab.ui.control.DropDown
        ParticlePanel         matlab.ui.container.Panel
        pGrid                 matlab.ui.container.GridLayout
        DField                matlab.ui.control.NumericEditField
        Dlabel                matlab.ui.control.Label
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
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.paramGrid.RowSpacing = 8;
            comp.paramGrid.Padding = [6 6 6 6];

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

            % Create Dlabel
            comp.Dlabel = uilabel(comp.pGrid);
            comp.Dlabel.Layout.Row = 8;
            comp.Dlabel.Layout.Column = 1;
            comp.Dlabel.Interpreter = 'tex';
            comp.Dlabel.Text = 'd(m)';

            % Create DField
            comp.DField = uieditfield(comp.pGrid, 'numeric');
            comp.DField.Layout.Row = 8;
            comp.DField.Layout.Column = 2;

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

            % Create ViewPanel
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 3;
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
            comp.ShowBMarksCheck.Value = true;

            % Create ShowGridCheck
            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 1;
            comp.ShowGridCheck.Value = true;

            % Create ShowFmagCheck
            comp.ShowFmagCheck = uicheckbox(comp.vGrid);
            comp.ShowFmagCheck.Text = '磁场力箭头';
            comp.ShowFmagCheck.Layout.Row = 1;
            comp.ShowFmagCheck.Layout.Column = 3;

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

            % Create ShowFelcCheck
            comp.ShowFelcCheck = uicheckbox(comp.vGrid);
            comp.ShowFelcCheck.Text = '电场力箭头';
            comp.ShowFelcCheck.Layout.Row = 2;
            comp.ShowFelcCheck.Layout.Column = 3;
        end
    end
end
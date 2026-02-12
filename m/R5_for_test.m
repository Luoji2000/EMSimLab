classdef R5_for_test < matlab.ui.componentcontainer.ComponentContainer

    properties (Access = public)
        % Value - 对外统一参数载荷
        Value struct = struct()
    end

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        paramGrid                  matlab.ui.container.GridLayout
        ConductorSettingsPanel     matlab.ui.container.Panel
        ConductorSettingsPanelGrid matlab.ui.container.GridLayout
        restitutionCoeffLabel      matlab.ui.control.Label
        restitutionCoeffField      matlab.ui.control.NumericEditField
        conductorSelectorLabel     matlab.ui.control.Label
        conductorSelectorDropDown  matlab.ui.control.DropDown
        ResultsPanel               matlab.ui.container.Panel
        ResultsGrid                matlab.ui.container.GridLayout
        vcenterLabel               matlab.ui.control.Label
        xcenterLabel               matlab.ui.control.Label
        QLabel                     matlab.ui.control.Label
        FmagLabel                  matlab.ui.control.Label
        ILabel                     matlab.ui.control.Label
        epsilonLabel               matlab.ui.control.Label
        vcenterField               matlab.ui.control.NumericEditField
        xcenterField               matlab.ui.control.NumericEditField
        QField                     matlab.ui.control.NumericEditField
        FmagField                  matlab.ui.control.NumericEditField
        IField                     matlab.ui.control.NumericEditField
        epsilonField               matlab.ui.control.NumericEditField
        FieldPanel                 matlab.ui.container.Panel
        fGrid                      matlab.ui.container.GridLayout
        lblB                       matlab.ui.control.Label
        lblBdir                    matlab.ui.control.Label
        BField                     matlab.ui.control.NumericEditField
        BdirDropDown               matlab.ui.control.DropDown
        ConductorPanel             matlab.ui.container.Panel
        ConductorGrid              matlab.ui.container.GridLayout
        FLabel                     matlab.ui.control.Label
        mLabel                     matlab.ui.control.Label
        RLabel                     matlab.ui.control.Label
        vLabel                     matlab.ui.control.Label
        xLabel                     matlab.ui.control.Label
        LLabel                     matlab.ui.control.Label
        FField                     matlab.ui.control.NumericEditField
        mField                     matlab.ui.control.NumericEditField
        RField                     matlab.ui.control.NumericEditField
        vField                     matlab.ui.control.NumericEditField
        xField                     matlab.ui.control.NumericEditField
        LField                     matlab.ui.control.NumericEditField
        BoundsPanel                matlab.ui.container.Panel
        bGrid                      matlab.ui.container.GridLayout
        BoundedCheck               matlab.ui.control.CheckBox
        XminLabel                  matlab.ui.control.Label
        XmaxLabel                  matlab.ui.control.Label
        YminLabel                  matlab.ui.control.Label
        YmaxLabel                  matlab.ui.control.Label
        XminField                  matlab.ui.control.NumericEditField
        XmaxField                  matlab.ui.control.NumericEditField
        YminField                  matlab.ui.control.NumericEditField
        YmaxField                  matlab.ui.control.NumericEditField
        ViewPanel                  matlab.ui.container.Panel
        vGrid                      matlab.ui.container.GridLayout
        ShowCurrentCheck           matlab.ui.control.CheckBox
        ShowAmpereForceCheck       matlab.ui.control.CheckBox
        ShowTrailCheck             matlab.ui.control.CheckBox
        ShowVCheck                 matlab.ui.control.CheckBox
        ShowDriveForceCheck        matlab.ui.control.CheckBox
        ShowGridCheck              matlab.ui.control.CheckBox
        ShowBMarksCheck            matlab.ui.control.CheckBox
        IsApplyingPayload          logical = false
    end

    events
        % PayloadChanged - 任意参数控件变化后触发
        PayloadChanged
    end

    methods
        function payload = getPayload(comp)
            %GETPAYLOAD  读取当前参数（已归一化）
            if comp.isUiReady()
                payload = comp.collectPayloadFromUi(comp.Value);
            else
                payload = comp.normalizePayload(comp.Value, comp.Value);
            end
        end

        function setPayload(comp, payload)
            %SETPAYLOAD  外部写入参数并同步 UI
            if nargin < 2 || ~isstruct(payload)
                return;
            end
            payload = comp.normalizePayload(payload, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end

        function setOutputs(comp, outputs)
            %SETOUTPUTS  仅更新输出区字段，不触发参数重置链路
            if nargin < 2 || ~isstruct(outputs)
                return;
            end
            payload = comp.Value;
            if ~isstruct(payload)
                payload = comp.defaultPayload();
            end
            names = fieldnames(outputs);
            for i = 1:numel(names)
                key = names{i};
                payload.(key) = outputs.(key);
            end
            payload = comp.normalizePayload(payload, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyOutputsToUi(payload);
            end
        end
    end

    methods (Access = protected)
        
        % 属性值发生更改时执行的代码
        function update(comp)
            % 使用此函数更新底层组件
            payload = comp.normalizePayload(comp.Value, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
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

            % 默认参数写入与回调绑定
            payload = comp.defaultPayload();
            comp.Value = payload;
            comp.applyPayloadToUi(payload);
            comp.bindControlCallbacks();
        end
    end

    methods (Access = private)
        function tf = isUiReady(comp)
            %ISUIREADY  判断关键控件是否已创建
            tf = ~isempty(comp.restitutionCoeffField) && isvalid(comp.restitutionCoeffField) ...
                && ~isempty(comp.conductorSelectorDropDown) && isvalid(comp.conductorSelectorDropDown) ...
                && ~isempty(comp.BField) && isvalid(comp.BField);
        end

        function bindControlCallbacks(comp)
            %BINDCONTROLCALLBACKS  绑定统一回调入口
            controls = { ...
                comp.restitutionCoeffField, ...
                comp.LField, comp.xField, comp.vField, comp.RField, comp.mField, comp.FField, ...
                comp.BField, comp.BdirDropDown, ...
                comp.BoundedCheck, comp.XminField, comp.XmaxField, comp.YminField, comp.YmaxField, ...
                comp.ShowTrailCheck, comp.ShowVCheck, comp.ShowDriveForceCheck, ...
                comp.ShowAmpereForceCheck, comp.ShowCurrentCheck, comp.ShowGridCheck, comp.ShowBMarksCheck ...
            };
            for i = 1:numel(controls)
                h = controls{i};
                if isempty(h) || ~isvalid(h)
                    continue;
                end
                h.ValueChangedFcn = @(~,~)comp.onAnyControlChanged();
            end

            if ~isempty(comp.conductorSelectorDropDown) && isvalid(comp.conductorSelectorDropDown)
                comp.conductorSelectorDropDown.ValueChangedFcn = @(~,~)comp.onConductorSelectorChanged();
            end
        end

        function onAnyControlChanged(comp)
            %ONANYCONTROLCHANGED  任意可编辑控件变化时统一入口
            if comp.IsApplyingPayload
                return;
            end
            previousPayload = comp.Value;
            payload = comp.collectPayloadFromUi(previousPayload);
            payload = comp.normalizePayload(payload, previousPayload);
            comp.Value = payload;
            comp.applyPayloadToUi(payload);
            notify(comp, 'PayloadChanged');
        end

        function onConductorSelectorChanged(comp)
            %ONCONDUCTORSELECTORCHANGED  A/B 导体切换（仅切换编辑上下文）
            if comp.IsApplyingPayload
                return;
            end

            previousPayload = comp.Value;
            if ~isstruct(previousPayload)
                previousPayload = comp.defaultPayload();
            end

            oldKey = comp.normalizeConductorKey(pickField(previousPayload, 'editingConductor', "A"));
            payload = comp.writeConductorUiToPayload(previousPayload, oldKey);
            payload.editingConductor = comp.conductorFromUiValue(comp.conductorSelectorDropDown.Value);
            payload = comp.normalizePayload(payload, previousPayload);
            comp.Value = payload;
            comp.applyPayloadToUi(payload);
        end

        function payload = collectPayloadFromUi(comp, previousPayload)
            %COLLECTPAYLOADFROMUI  从控件采集 payload（含 A/B 双棒）
            if nargin < 2 || ~isstruct(previousPayload)
                previousPayload = comp.defaultPayload();
            end

            payload = previousPayload;
            activeKey = comp.conductorFromUiValue(comp.conductorSelectorDropDown.Value);
            payload = comp.writeConductorUiToPayload(payload, activeKey);
            payload.editingConductor = activeKey;

            payload.modelType = "rail";
            payload.templateId = "R5";
            payload.elementType = "R";
            payload.loopClosed = true;
            % R5_V2 取消“匀速/阻尼”模式切换：R5 始终按动力学链路推进
            payload.driveEnabled = true;
            payload.rho = comp.restitutionCoeffField.Value;
            payload.B = comp.BField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.bounded = logical(comp.BoundedCheck.Value);
            payload.xMin = comp.XminField.Value;
            payload.xMax = comp.XmaxField.Value;
            payload.yMin = comp.YminField.Value;
            payload.yMax = comp.YmaxField.Value;

            payload.showTrail = comp.ShowTrailCheck.Value;
            payload.showV = comp.ShowVCheck.Value;
            payload.showDriveForce = comp.ShowDriveForceCheck.Value;
            payload.showAmpereForce = comp.ShowAmpereForceCheck.Value;
            payload.showCurrent = comp.ShowCurrentCheck.Value;
            payload.showGrid = comp.ShowGridCheck.Value;
            payload.showBMarks = comp.ShowBMarksCheck.Value;

            % 当前组件未提供单独输入控件的字段沿用旧值
            payload.autoFollow = pickField(previousPayload, 'autoFollow', false);
            payload.followSpan = pickField(previousPayload, 'followSpan', 12.0);
            payload.maxSpan = pickField(previousPayload, 'maxSpan', 120.0);
            payload.speedScale = pickField(previousPayload, 'speedScale', 1.0);
            payload.qCollOut = pickField(previousPayload, 'qCollOut', 0.0);
            payload.xAOut = pickField(previousPayload, 'xAOut', payload.xA0);
            payload.xBOut = pickField(previousPayload, 'xBOut', payload.xB0);
            payload.vAOut = pickField(previousPayload, 'vAOut', payload.vA0);
            payload.vBOut = pickField(previousPayload, 'vBOut', payload.vB0);
            payload.modeOut = pickField(previousPayload, 'modeOut', "r5_s0");
            payload.epsilonOut = pickField(previousPayload, 'epsilonOut', 0.0);
            payload.currentOut = pickField(previousPayload, 'currentOut', 0.0);
            payload.xOut = pickField(previousPayload, 'xOut', 0.5 * (payload.xA0 + payload.xB0));
            payload.vOut = pickField(previousPayload, 'vOut', 0.5 * (payload.vA0 + payload.vB0));
            payload.fMagOut = pickField(previousPayload, 'fMagOut', 0.0);
            payload.qHeatOut = pickField(previousPayload, 'qHeatOut', 0.0);
            payload.pElecOut = pickField(previousPayload, 'pElecOut', 0.0);
        end

        function payload = writeConductorUiToPayload(comp, payloadIn, key)
            %WRITECONDUCTORUITOPAYLOAD  把当前单组输入框写入 A/B 对应字段
            payload = payloadIn;
            token = comp.normalizeConductorKey(key);
            switch token
                case "B"
                    payload.LB = comp.LField.Value;
                    payload.xB0 = comp.xField.Value;
                    payload.vB0 = comp.vField.Value;
                    payload.RB = comp.RField.Value;
                    payload.mB = comp.mField.Value;
                    payload.FdriveB = comp.FField.Value;
                otherwise
                    payload.LA = comp.LField.Value;
                    payload.xA0 = comp.xField.Value;
                    payload.vA0 = comp.vField.Value;
                    payload.RA = comp.RField.Value;
                    payload.mA = comp.mField.Value;
                    payload.FdriveA = comp.FField.Value;
            end
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将 payload 分发写入各个控件
            payload = comp.normalizePayload(payload, comp.Value);
            comp.IsApplyingPayload = true;
            try
                comp.restitutionCoeffField.Value = payload.rho;
                comp.BField.Value = payload.B;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.BoundedCheck.Value = payload.bounded;
                comp.XminField.Value = payload.xMin;
                comp.XmaxField.Value = payload.xMax;
                comp.YminField.Value = payload.yMin;
                comp.YmaxField.Value = payload.yMax;

                comp.ShowTrailCheck.Value = payload.showTrail;
                comp.ShowVCheck.Value = payload.showV;
                comp.ShowDriveForceCheck.Value = payload.showDriveForce;
                comp.ShowAmpereForceCheck.Value = payload.showAmpereForce;
                comp.ShowCurrentCheck.Value = payload.showCurrent;
                comp.ShowGridCheck.Value = payload.showGrid;
                comp.ShowBMarksCheck.Value = payload.showBMarks;

                key = comp.normalizeConductorKey(pickField(payload, 'editingConductor', "A"));
                comp.conductorSelectorDropDown.Value = comp.conductorToUiValue(key);
                if key == "B"
                    comp.LField.Value = payload.LB;
                    comp.xField.Value = payload.xB0;
                    comp.vField.Value = payload.vB0;
                    comp.RField.Value = payload.RB;
                    comp.mField.Value = payload.mB;
                    comp.FField.Value = payload.FdriveB;
                else
                    comp.LField.Value = payload.LA;
                    comp.xField.Value = payload.xA0;
                    comp.vField.Value = payload.vA0;
                    comp.RField.Value = payload.RA;
                    comp.mField.Value = payload.mA;
                    comp.FField.Value = payload.FdriveA;
                end

                comp.applyOutputsToUi(payload);
                comp.updateBoundsEnable(payload.bounded);
            catch err
                comp.IsApplyingPayload = false;
                rethrow(err);
            end
            comp.IsApplyingPayload = false;
        end

        function applyOutputsToUi(comp, payload)
            %APPLYOUTPUTSTOUI  仅把输出字段写到输出控件
            comp.epsilonField.Value = payload.epsilonOut;
            comp.IField.Value = payload.currentOut;
            comp.FmagField.Value = payload.fMagOut;
            comp.QField.Value = payload.qHeatOut;
            comp.xcenterField.Value = payload.xOut;
            comp.vcenterField.Value = payload.vOut;
        end

        function updateBoundsEnable(comp, isOn)
            %UPDATEBOUNDSENABLE  R5_V2 规则：除输出区外，所有输入控件均保持可编辑
            %#ok<INUSD>
            comp.XminField.Enable = 'on';
            comp.XmaxField.Enable = 'on';
            comp.YminField.Enable = 'on';
            comp.YmaxField.Enable = 'on';
        end

        function payload = normalizePayload(comp, in, previousPayload)
            %NORMALIZEPAYLOAD  参数合并与类型归一化
            if nargin < 3 || ~isstruct(previousPayload)
                previousPayload = struct();
            end

            base = comp.defaultPayload();
            payload = base;

            if isstruct(previousPayload)
                names = fieldnames(base);
                for i = 1:numel(names)
                    name = names{i};
                    if isfield(previousPayload, name)
                        payload.(name) = previousPayload.(name);
                    end
                end
            end
            if isstruct(in)
                names = fieldnames(base);
                for i = 1:numel(names)
                    name = names{i};
                    if isfield(in, name)
                        payload.(name) = in.(name);
                    end
                end
            end

            payload.modelType = "rail";
            payload.templateId = "R5";
            payload.elementType = "R";
            payload.loopClosed = true;
            % R5_V2 设计口径：不再暴露“匀速/阻尼”切换，统一走动力学推进
            payload.driveEnabled = true;
            payload.B = max(comp.toDouble(payload.B, base.B), 0.0);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], base.Bdir);
            payload.bounded = comp.toLogical(payload.bounded, base.bounded);

            payload.LA = max(comp.toDouble(payload.LA, base.LA), 1e-6);
            payload.LB = max(comp.toDouble(payload.LB, base.LB), 1e-6);
            payload.xA0 = comp.toDouble(payload.xA0, base.xA0);
            payload.xB0 = comp.toDouble(payload.xB0, base.xB0);
            if payload.xB0 < payload.xA0
                payload.xB0 = payload.xA0;
            end
            payload.vA0 = comp.toDouble(payload.vA0, base.vA0);
            payload.vB0 = comp.toDouble(payload.vB0, base.vB0);
            payload.RA = max(comp.toDouble(payload.RA, base.RA), 1e-12);
            payload.RB = max(comp.toDouble(payload.RB, base.RB), 1e-12);
            payload.mA = max(comp.toDouble(payload.mA, base.mA), 1e-12);
            payload.mB = max(comp.toDouble(payload.mB, base.mB), 1e-12);
            payload.FdriveA = comp.toDouble(payload.FdriveA, base.FdriveA);
            payload.FdriveB = comp.toDouble(payload.FdriveB, base.FdriveB);
            payload.rho = min(max(comp.toDouble(payload.rho, base.rho), 0.0), 1.0);

            payload.xMin = comp.toDouble(payload.xMin, base.xMin);
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            payload.yMin = comp.toDouble(payload.yMin, base.yMin);
            payload.yMax = comp.toDouble(payload.yMax, base.yMax);
            if payload.xMin > payload.xMax
                t = payload.xMin;
                payload.xMin = payload.xMax;
                payload.xMax = t;
            end
            if payload.yMin > payload.yMax
                t = payload.yMin;
                payload.yMin = payload.yMax;
                payload.yMax = t;
            end

            payload.showTrail = comp.toLogical(payload.showTrail, base.showTrail);
            payload.showV = comp.toLogical(payload.showV, base.showV);
            payload.showDriveForce = comp.toLogical(payload.showDriveForce, base.showDriveForce);
            payload.showAmpereForce = comp.toLogical(payload.showAmpereForce, base.showAmpereForce);
            payload.showCurrent = comp.toLogical(payload.showCurrent, base.showCurrent);
            payload.showGrid = comp.toLogical(payload.showGrid, base.showGrid);
            payload.showBMarks = comp.toLogical(payload.showBMarks, base.showBMarks);
            payload.autoFollow = comp.toLogical(payload.autoFollow, base.autoFollow);
            payload.followSpan = max(2.0, min(200.0, comp.toDouble(payload.followSpan, base.followSpan)));
            payload.maxSpan = max(4.0, min(400.0, comp.toDouble(payload.maxSpan, base.maxSpan)));
            payload.speedScale = max(0.25, min(4.0, comp.toDouble(payload.speedScale, base.speedScale)));

            payload.editingConductor = comp.normalizeConductorKey(payload.editingConductor);
            payload.epsilonOut = comp.toDouble(payload.epsilonOut, base.epsilonOut);
            payload.currentOut = comp.toDouble(payload.currentOut, base.currentOut);
            payload.fMagOut = comp.toDouble(payload.fMagOut, base.fMagOut);
            payload.qHeatOut = max(comp.toDouble(payload.qHeatOut, base.qHeatOut), 0.0);
            payload.pElecOut = comp.toDouble(payload.pElecOut, base.pElecOut);
            payload.qCollOut = max(comp.toDouble(payload.qCollOut, base.qCollOut), 0.0);
            payload.xAOut = comp.toDouble(payload.xAOut, payload.xA0);
            payload.xBOut = comp.toDouble(payload.xBOut, payload.xB0);
            payload.vAOut = comp.toDouble(payload.vAOut, payload.vA0);
            payload.vBOut = comp.toDouble(payload.vBOut, payload.vB0);
            payload.modeOut = string(pickField(payload, 'modeOut', "r5_s0"));

            % 兼容单棒链路字段（用于通用渲染/输出接口）
            payload.L = min(payload.LA, payload.LB);
            payload.R = payload.RA + payload.RB;
            payload.m = 0.5 * (payload.mA + payload.mB);
            payload.x0 = 0.5 * (payload.xA0 + payload.xB0);
            payload.y0 = 0.0;
            payload.v0 = 0.5 * (payload.vA0 + payload.vB0);
            payload.Fdrive = payload.FdriveA + payload.FdriveB;
            payload.xOut = comp.toDouble(payload.xOut, payload.x0);
            payload.vOut = comp.toDouble(payload.vOut, payload.v0);
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  R5 默认参数
            payload = struct( ...
                'modelType', "rail", ...
                'templateId', "R5", ...
                'elementType', "R", ...
                'loopClosed', true, ...
                'driveEnabled', true, ...
                'B', 1.0, ...
                'Bdir', "out", ...
                'bounded', false, ...
                'xMin', 0.0, ...
                'xMax', 4.0, ...
                'yMin', -1.0, ...
                'yMax', 1.0, ...
                'LA', 2.0, ...
                'LB', 2.0, ...
                'xA0', 0.0, ...
                'xB0', 2.0, ...
                'vA0', 0.0, ...
                'vB0', 1.0, ...
                'RA', 1.0, ...
                'RB', 1.0, ...
                'mA', 1.0, ...
                'mB', 1.0, ...
                'FdriveA', 0.0, ...
                'FdriveB', 0.0, ...
                'rho', 1.0, ...
                'editingConductor', "A", ...
                'showTrail', true, ...
                'showV', true, ...
                'showDriveForce', false, ...
                'showAmpereForce', false, ...
                'showCurrent', true, ...
                'showGrid', true, ...
                'showBMarks', true, ...
                'autoFollow', false, ...
                'followSpan', 12.0, ...
                'maxSpan', 120.0, ...
                'speedScale', 1.0, ...
                'L', 2.0, ...
                'R', 2.0, ...
                'm', 1.0, ...
                'x0', 1.0, ...
                'y0', 0.0, ...
                'v0', 0.5, ...
                'Fdrive', 0.0, ...
                'epsilonOut', 0.0, ...
                'currentOut', 0.0, ...
                'xOut', 1.0, ...
                'vOut', 0.5, ...
                'fMagOut', 0.0, ...
                'qHeatOut', 0.0, ...
                'pElecOut', 0.0, ...
                'qCollOut', 0.0, ...
                'xAOut', 0.0, ...
                'xBOut', 2.0, ...
                'vAOut', 0.0, ...
                'vBOut', 1.0, ...
                'modeOut', "r5_s0" ...
            );
        end

        function key = conductorFromUiValue(~, uiVal)
            %CONDUCTORFROMUIVALUE  UI 文案映射为内部导体键
            token = strtrim(string(uiVal));
            if token == "右边导体"
                key = "B";
            else
                key = "A";
            end
        end

        function uiVal = conductorToUiValue(~, key)
            %CONDUCTORTOUIVALUE  内部导体键映射为 UI 文案
            if strcmpi(string(key), "B")
                uiVal = '右边导体';
            else
                uiVal = '左边导体';
            end
        end

        function key = normalizeConductorKey(~, keyRaw)
            %NORMALIZECONDUCTORKEY  导体键归一化为 A/B
            if strcmpi(string(keyRaw), "B")
                key = "B";
            else
                key = "A";
            end
        end

        function key = bdirFromUiValue(~, uiVal)
            %BDIRFROMUIVALUE  UI 文案 -> 内部方向键（out/in）
            s = strtrim(string(uiVal));
            if s == "入屏"
                key = "in";
            else
                key = "out";
            end
        end

        function uiVal = bdirToUiValue(~, key)
            %BDIRTOUIVALUE  内部方向键（out/in）-> UI 文案
            if strtrim(string(key)) == "in"
                uiVal = '入屏';
            else
                uiVal = '出屏';
            end
        end

        function state = boolToOnOff(~, tf)
            %BOOLTOONOFF  布尔值转 MATLAB UI 的 Enable 状态字符串
            if tf
                state = 'on';
            else
                state = 'off';
            end
        end

        function v = normalizeEnum(~, vRaw, options, defaultValue)
            %NORMALIZEENUM  枚举值归一化，不匹配时回退默认值
            token = strtrim(string(vRaw));
            idx = find(strcmpi(string(options), token), 1, 'first');
            if isempty(idx)
                v = string(defaultValue);
            else
                v = string(options(idx));
            end
        end

        function v = toDouble(~, vRaw, defaultValue)
            %TODOUBLE  转换为有限 double，失败则回退默认值
            if isnumeric(vRaw) && isscalar(vRaw) && isfinite(vRaw)
                v = double(vRaw);
                return;
            end
            if isstring(vRaw) || ischar(vRaw)
                tmp = str2double(string(vRaw));
                if isfinite(tmp)
                    v = double(tmp);
                    return;
                end
            end
            v = double(defaultValue);
        end

        function v = toLogical(~, vRaw, defaultValue)
            %TOLOGICAL  转换为 logical，失败则回退默认值
            if islogical(vRaw) && isscalar(vRaw)
                v = logical(vRaw);
                return;
            end
            if isnumeric(vRaw) && isscalar(vRaw) && isfinite(vRaw)
                v = logical(vRaw ~= 0);
                return;
            end
            if isstring(vRaw) || ischar(vRaw)
                token = lower(strtrim(string(vRaw)));
                if any(token == ["true","1","on","yes"])
                    v = true;
                    return;
                end
                if any(token == ["false","0","off","no"])
                    v = false;
                    return;
                end
            end
            v = logical(defaultValue);
        end
    end
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

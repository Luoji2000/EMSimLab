classdef R8_for_test < matlab.ui.componentcontainer.ComponentContainer

    properties (Access = public)
        % Value - 对外统一参数载荷
        Value struct = struct()
    end

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
        IsApplyingPayload     logical = false
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

            % 修正中心坐标标签文案（导出文件中 X/Y 顺序互换）
            comp.xConterLabel.Text = '中心位置X(m)';
            comp.YconterLabel.Text = '中心位置Y(m)';

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
            tf = ~isempty(comp.ModeDropDown) && isvalid(comp.ModeDropDown) ...
                && ~isempty(comp.BField) && isvalid(comp.BField);
        end

        function bindControlCallbacks(comp)
            %BINDCONTROLCALLBACKS  绑定统一回调入口
            controls = { ...
                comp.ModeDropDown, comp.BField, comp.BdirDropDown, ...
                comp.WField, comp.HField, comp.xConterField, comp.YconterField, ...
                comp.mField, comp.FField, comp.vField, comp.RField, ...
                comp.XminField, comp.XmaxField, ...
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
        end

        function onAnyControlChanged(comp)
            %ONANYCONTROLCHANGED  任意参数变化后的统一入口
            if comp.IsApplyingPayload
                return;
            end
            previous = comp.Value;
            payload = comp.collectPayloadFromUi(previous);
            payload = comp.normalizePayload(payload, previous);
            comp.Value = payload;
            comp.applyPayloadToUi(payload);
            notify(comp, 'PayloadChanged');
        end

        function payload = collectPayloadFromUi(comp, previousPayload)
            %COLLECTPAYLOADFROMUI  从控件读取当前参数
            if nargin < 2 || ~isstruct(previousPayload)
                previousPayload = comp.defaultPayload();
            end

            driveEnabled = comp.modeToDriveEnabled(comp.ModeDropDown.Value);
            payload = struct();
            payload.modelType = "rail";
            payload.templateId = "R8";
            payload.elementType = "R";
            payload.B = comp.BField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.w = comp.WField.Value;
            payload.W = payload.w;
            payload.h = comp.HField.Value;
            payload.H = payload.h;
            payload.xCenter = comp.xConterField.Value;
            payload.yCenter = comp.YconterField.Value;
            payload.v0 = comp.vField.Value;
            payload.m = comp.mField.Value;
            payload.R = comp.RField.Value;
            payload.loopClosed = true;
            payload.driveEnabled = driveEnabled;
            if driveEnabled
                payload.Fdrive = comp.FField.Value;
            else
                payload.Fdrive = 0.0;
            end
            payload.bounded = true;
            payload.xMin = comp.XminField.Value;
            payload.xMax = comp.XmaxField.Value;
            payload.yMin = -1000.0;
            payload.yMax = 1000.0;
            payload.showTrail = comp.ShowTrailCheck.Value;
            payload.showV = comp.ShowVCheck.Value;
            payload.showCurrent = comp.ShowCurrentCheck.Value;
            payload.showGrid = comp.ShowGridCheck.Value;
            payload.showBMarks = comp.ShowBMarksCheck.Value;
            payload.showDriveForce = driveEnabled && comp.ShowDriveForceCheck.Value;
            payload.showAmpereForce = driveEnabled && comp.ShowAmpereForceCheck.Value;

            % 其余运行字段沿用旧值
            payload.C = comp.pickField(previousPayload, 'C', 1.0);
            payload.Ls = comp.pickField(previousPayload, 'Ls', 1.0);
            payload.autoFollow = comp.pickField(previousPayload, 'autoFollow', false);
            payload.followSpan = comp.pickField(previousPayload, 'followSpan', 12.0);
            payload.maxSpan = comp.pickField(previousPayload, 'maxSpan', 120.0);
            payload.speedScale = comp.pickField(previousPayload, 'speedScale', 1.0);
            payload.epsilonOut = comp.pickField(previousPayload, 'epsilonOut', 0.0);
            payload.currentOut = comp.pickField(previousPayload, 'currentOut', 0.0);
            payload.xOut = comp.pickField(previousPayload, 'xOut', 0.0);
            payload.vOut = comp.pickField(previousPayload, 'vOut', 0.0);
            payload.fMagOut = comp.pickField(previousPayload, 'fMagOut', 0.0);
            payload.qHeatOut = comp.pickField(previousPayload, 'qHeatOut', 0.0);
            payload.pElecOut = comp.pickField(previousPayload, 'pElecOut', 0.0);
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将参数写回到控件并更新联动状态
            payload = comp.normalizePayload(payload, comp.Value);
            comp.IsApplyingPayload = true;
            try
                comp.ModeDropDown.Value = comp.boolToMode(payload.driveEnabled);
                comp.BField.Value = payload.B;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.WField.Value = payload.w;
                comp.HField.Value = payload.h;
                comp.xConterField.Value = payload.xCenter;
                comp.YconterField.Value = payload.yCenter;
                comp.vField.Value = payload.v0;
                comp.mField.Value = payload.m;
                comp.RField.Value = payload.R;
                comp.FField.Value = payload.Fdrive;
                comp.XminField.Value = payload.xMin;
                comp.XmaxField.Value = payload.xMax;
                comp.ShowTrailCheck.Value = payload.showTrail;
                comp.ShowVCheck.Value = payload.showV;
                comp.ShowCurrentCheck.Value = payload.showCurrent;
                comp.ShowGridCheck.Value = payload.showGrid;
                comp.ShowBMarksCheck.Value = payload.showBMarks;
                comp.ShowDriveForceCheck.Value = payload.showDriveForce;
                comp.ShowAmpereForceCheck.Value = payload.showAmpereForce;
                comp.updateModeUi(payload.driveEnabled);
            catch err
                comp.IsApplyingPayload = false;
                rethrow(err);
            end
            comp.IsApplyingPayload = false;
        end

        function updateModeUi(comp, driveEnabled)
            %UPDATEMODEUI  “匀速/阻尼”联动：外力编辑与受力箭头开关
            state = comp.boolToOnOff(driveEnabled);
            comp.FField.Enable = state;
            comp.ShowDriveForceCheck.Enable = state;
            comp.ShowAmpereForceCheck.Enable = state;
            if ~driveEnabled
                comp.FField.Value = 0.0;
                comp.ShowDriveForceCheck.Value = false;
                comp.ShowAmpereForceCheck.Value = false;
            end
        end

        function payload = normalizePayload(comp, in, previousPayload)
            %NORMALIZEPAYLOAD  合并默认值并执行 R8 规则约束
            if nargin < 3 || ~isstruct(previousPayload)
                previousPayload = comp.defaultPayload();
            end
            base = comp.defaultPayload();
            payload = base;

            if isstruct(previousPayload)
                names = fieldnames(base);
                for i = 1:numel(names)
                    k = names{i};
                    if isfield(previousPayload, k)
                        payload.(k) = previousPayload.(k);
                    end
                end
            end
            if isstruct(in)
                names = fieldnames(base);
                for i = 1:numel(names)
                    k = names{i};
                    if isfield(in, k)
                        payload.(k) = in.(k);
                    end
                end
                if isfield(in, 'xCenter')
                    payload.xCenter = comp.toDouble(in.xCenter, payload.xCenter);
                end
                if isfield(in, 'yCenter')
                    payload.yCenter = comp.toDouble(in.yCenter, payload.yCenter);
                end
            end

            payload.modelType = "rail";
            payload.templateId = "R8";
            payload.elementType = "R";
            payload.loopClosed = true;
            payload.bounded = true;
            payload.autoFollow = false;

            payload.B = max(comp.toDouble(payload.B, base.B), 0.0);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], "out");
            payload.w = max(comp.toDouble(payload.w, base.w), 1e-3);
            payload.W = payload.w;
            payload.h = max(comp.toDouble(payload.h, base.h), 1e-3);
            payload.H = payload.h;
            payload.xCenter = comp.toDouble(payload.xCenter, base.xCenter);
            payload.yCenter = comp.toDouble(payload.yCenter, base.yCenter);
            payload.v0 = abs(comp.toDouble(payload.v0, base.v0));
            payload.m = max(comp.toDouble(payload.m, base.m), 1e-6);
            payload.R = max(comp.toDouble(payload.R, base.R), 1e-6);
            payload.Fdrive = comp.toDouble(payload.Fdrive, base.Fdrive);
            payload.driveEnabled = comp.toLogical(payload.driveEnabled, base.driveEnabled);
            payload.xMin = comp.toDouble(payload.xMin, base.xMin);
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            if payload.xMin > payload.xMax
                t = payload.xMin;
                payload.xMin = payload.xMax;
                payload.xMax = t;
            end
            payload.yMin = -1000.0;
            payload.yMax = 1000.0;

            payload.showTrail = comp.toLogical(payload.showTrail, base.showTrail);
            payload.showV = comp.toLogical(payload.showV, base.showV);
            payload.showCurrent = comp.toLogical(payload.showCurrent, base.showCurrent);
            payload.showGrid = comp.toLogical(payload.showGrid, base.showGrid);
            payload.showBMarks = comp.toLogical(payload.showBMarks, base.showBMarks);
            payload.showDriveForce = comp.toLogical(payload.showDriveForce, base.showDriveForce);
            payload.showAmpereForce = comp.toLogical(payload.showAmpereForce, base.showAmpereForce);

            if ~payload.driveEnabled
                payload.Fdrive = 0.0;
                payload.showDriveForce = false;
                payload.showAmpereForce = false;
            end

            % R8 主坐标采用“线框中心坐标”
            payload.x0 = payload.xCenter;
            payload.y0 = payload.yCenter;
            payload.L = payload.h;
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  R8 默认参数（按教学约定）
            payload = struct( ...
                'modelType', "rail", ...
                'templateId', "R8", ...
                'elementType', "R", ...
                'B', 1.0, ...
                'Bdir', "out", ...
                'w', 4.0, ...
                'W', 4.0, ...
                'h', 3.0, ...
                'H', 3.0, ...
                'xCenter', -3.0, ...
                'yCenter', 0.0, ...
                'x0', -3.0, ...
                'y0', 0.0, ...
                'L', 3.0, ...
                'v0', 1.0, ...
                'm', 1.0, ...
                'R', 1.0, ...
                'C', 1.0, ...
                'Ls', 1.0, ...
                'loopClosed', true, ...
                'driveEnabled', false, ...
                'Fdrive', 0.0, ...
                'bounded', true, ...
                'xMin', 0.0, ...
                'xMax', 4.0, ...
                'yMin', -1000.0, ...
                'yMax', 1000.0, ...
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
                'epsilonOut', 0.0, ...
                'currentOut', 0.0, ...
                'xOut', 0.0, ...
                'vOut', 0.0, ...
                'fMagOut', 0.0, ...
                'qHeatOut', 0.0, ...
                'pElecOut', 0.0 ...
            );
        end

        function enabled = modeToDriveEnabled(~, modeText)
            %MODETODRIVEENABLED  模式文本映射为驱动开关
            enabled = strtrim(string(modeText)) == "启用阻尼";
        end

        function modeText = boolToMode(~, enabled)
            %BOOLTOMODE  驱动开关映射为模式文本
            if enabled
                modeText = '启用阻尼';
            else
                modeText = '匀速运动';
            end
        end

        function key = bdirFromUiValue(~, uiVal)
            s = strtrim(string(uiVal));
            if s == "入屏"
                key = "in";
            else
                key = "out";
            end
        end

        function uiVal = bdirToUiValue(~, key)
            if strtrim(string(key)) == "in"
                uiVal = '入屏';
            else
                uiVal = '出屏';
            end
        end

        function state = boolToOnOff(~, tf)
            if tf
                state = 'on';
            else
                state = 'off';
            end
        end

        function v = normalizeEnum(~, vRaw, options, defaultValue)
            token = strtrim(string(vRaw));
            idx = find(strcmpi(string(options), token), 1, 'first');
            if isempty(idx)
                v = string(defaultValue);
            else
                v = string(options(idx));
            end
        end

        function v = toDouble(~, vRaw, defaultValue)
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
            if islogical(vRaw) && isscalar(vRaw)
                v = logical(vRaw);
                return;
            end
            if isnumeric(vRaw) && isscalar(vRaw) && isfinite(vRaw)
                v = logical(vRaw ~= 0);
                return;
            end
            v = logical(defaultValue);
        end

        function v = pickField(~, s, name, fallback)
            if isstruct(s) && isfield(s, name)
                v = s.(name);
            else
                v = fallback;
            end
        end
    end
end

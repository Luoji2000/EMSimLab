classdef R2_for_test < matlab.ui.componentcontainer.ComponentContainer
    %R2_FOR_TEST  R 系列导轨参数组件（R1/R2/R3 统一模板）
    %
    % 组件职责
    %   1) 创建并维护导轨模型参数 UI
    %   2) 对外提供统一参数接口：Value / getPayload / setPayload
    %   3) 用户改参时抛出 PayloadChanged 事件
    %
    % 分层约束
    %   - 不做物理计算，不直接调用引擎
    %   - 只负责“UI <-> payload”映射、归一化与联动

    properties (Access = public)
        % Value - 组件公开参数载荷
        Value struct = struct()
    end

    properties (Access = private, Transient, NonCopyable)
        % 布局容器
        paramGrid            matlab.ui.container.GridLayout
        ConductorPanel       matlab.ui.container.Panel
        ConductorGrid        matlab.ui.container.GridLayout
        FieldPanel           matlab.ui.container.Panel
        fGrid                matlab.ui.container.GridLayout
        BoundsPanel          matlab.ui.container.Panel
        bGrid                matlab.ui.container.GridLayout
        ViewPanel            matlab.ui.container.Panel
        vGrid                matlab.ui.container.GridLayout
        ResultsPanel         matlab.ui.container.Panel
        ResultsGrid          matlab.ui.container.GridLayout

        % 导体与回路参数
        LLabel               matlab.ui.control.Label
        xLabel               matlab.ui.control.Label
        vLabel               matlab.ui.control.Label
        RLabel               matlab.ui.control.Label
        mLabel               matlab.ui.control.Label
        driveForceLabel      matlab.ui.control.Label
        FLabel               matlab.ui.control.Label
        LField               matlab.ui.control.NumericEditField
        xField               matlab.ui.control.NumericEditField
        vField               matlab.ui.control.NumericEditField
        RField               matlab.ui.control.NumericEditField
        mField               matlab.ui.control.NumericEditField
        driveForceDropDown   matlab.ui.control.DropDown
        FField               matlab.ui.control.NumericEditField

        % 磁场参数
        lblB                 matlab.ui.control.Label
        lblBdir              matlab.ui.control.Label
        BField               matlab.ui.control.NumericEditField
        BdirDropDown         matlab.ui.control.DropDown

        % 有界参数
        BoundedCheck         matlab.ui.control.CheckBox
        XminLabel            matlab.ui.control.Label
        XmaxLabel            matlab.ui.control.Label
        YminLabel            matlab.ui.control.Label
        YmaxLabel            matlab.ui.control.Label
        XminField            matlab.ui.control.NumericEditField
        XmaxField            matlab.ui.control.NumericEditField
        YminField            matlab.ui.control.NumericEditField
        YmaxField            matlab.ui.control.NumericEditField

        % 可视化开关
        ShowTrailCheck       matlab.ui.control.CheckBox
        ShowVCheck           matlab.ui.control.CheckBox
        ShowDriveForceCheck  matlab.ui.control.CheckBox
        ShowAmpereForceCheck matlab.ui.control.CheckBox
        ShowCurrentCheck     matlab.ui.control.CheckBox
        ShowGridCheck        matlab.ui.control.CheckBox
        ShowBMarksCheck      matlab.ui.control.CheckBox

        % 输出区（只读）
        epsilonLabel         matlab.ui.control.Label
        ILabel               matlab.ui.control.Label
        xtLabel              matlab.ui.control.Label
        vtLabel              matlab.ui.control.Label
        FmagLabel            matlab.ui.control.Label
        pElecLabel           matlab.ui.control.Label
        epsilonField         matlab.ui.control.NumericEditField
        IField               matlab.ui.control.NumericEditField
        xtField              matlab.ui.control.NumericEditField
        vtField              matlab.ui.control.NumericEditField
        FmagField            matlab.ui.control.NumericEditField
        pElecField           matlab.ui.control.NumericEditField

        % 写回 UI 时的重入保护
        IsApplyingPayload    logical = false
    end

    events
        % PayloadChanged - 组件内部参数变化事件
        PayloadChanged
    end

    methods
        function payload = getPayload(comp)
            %GETPAYLOAD  读取当前 UI 参数（已归一化）
            if comp.isUiReady()
                payload = comp.collectPayloadFromUi(comp.Value);
            else
                payload = comp.normalizePayload(comp.Value, comp.Value);
            end
        end

        function setPayload(comp, payload)
            %SETPAYLOAD  外部写入参数并刷新 UI
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
        function update(comp)
            %UPDATE  当公开属性变化时，同步到底层 UI
            payload = comp.normalizePayload(comp.Value, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end

        function setup(comp)
            %SETUP  创建底层 UI 并绑定默认行为
            comp.Position = [1 1 340 260];

            comp.paramGrid = uigridlayout(comp);
            comp.paramGrid.ColumnWidth = {'1x'};
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.paramGrid.RowSpacing = 8;
            comp.paramGrid.Padding = [6 6 6 6];

            % 导体参数
            comp.ConductorPanel = uipanel(comp.paramGrid);
            comp.ConductorPanel.Title = '导体与回路';
            comp.ConductorPanel.Layout.Row = 1;
            comp.ConductorPanel.Layout.Column = 1;

            comp.ConductorGrid = uigridlayout(comp.ConductorPanel);
            comp.ConductorGrid.ColumnWidth = {90, '1x'};
            comp.ConductorGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.ConductorGrid.ColumnSpacing = 8;
            comp.ConductorGrid.RowSpacing = 6;
            comp.ConductorGrid.Padding = [8 8 8 8];

            comp.LLabel = uilabel(comp.ConductorGrid);
            comp.LLabel.Layout.Row = 1;
            comp.LLabel.Layout.Column = 1;
            comp.LLabel.Interpreter = 'tex';
            comp.LLabel.Text = 'L(m)';

            comp.LField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.LField.Layout.Row = 1;
            comp.LField.Layout.Column = 2;

            comp.xLabel = uilabel(comp.ConductorGrid);
            comp.xLabel.Layout.Row = 2;
            comp.xLabel.Layout.Column = 1;
            comp.xLabel.Interpreter = 'tex';
            comp.xLabel.Text = 'x_0(m)';

            comp.xField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.xField.Layout.Row = 2;
            comp.xField.Layout.Column = 2;

            comp.vLabel = uilabel(comp.ConductorGrid);
            comp.vLabel.Layout.Row = 3;
            comp.vLabel.Layout.Column = 1;
            comp.vLabel.Interpreter = 'tex';
            comp.vLabel.Text = 'v_0(m/s)';

            comp.vField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.vField.Layout.Row = 3;
            comp.vField.Layout.Column = 2;

            comp.RLabel = uilabel(comp.ConductorGrid);
            comp.RLabel.Layout.Row = 4;
            comp.RLabel.Layout.Column = 1;
            comp.RLabel.Interpreter = 'tex';
            comp.RLabel.Text = 'R(\Omega)';

            comp.RField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.RField.Layout.Row = 4;
            comp.RField.Layout.Column = 2;

            comp.mLabel = uilabel(comp.ConductorGrid);
            comp.mLabel.Layout.Row = 5;
            comp.mLabel.Layout.Column = 1;
            comp.mLabel.Interpreter = 'tex';
            comp.mLabel.Text = 'm(kg)';

            comp.mField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.mField.Layout.Row = 5;
            comp.mField.Layout.Column = 2;

            comp.driveForceLabel = uilabel(comp.ConductorGrid);
            comp.driveForceLabel.Layout.Row = 6;
            comp.driveForceLabel.Layout.Column = 1;
            comp.driveForceLabel.Text = '外力驱动';

            comp.driveForceDropDown = uidropdown(comp.ConductorGrid);
            comp.driveForceDropDown.Items = {'无', '有'};
            comp.driveForceDropDown.Layout.Row = 6;
            comp.driveForceDropDown.Layout.Column = 2;
            comp.driveForceDropDown.Value = '无';

            comp.FLabel = uilabel(comp.ConductorGrid);
            comp.FLabel.Layout.Row = 7;
            comp.FLabel.Layout.Column = 1;
            comp.FLabel.Interpreter = 'tex';
            comp.FLabel.Text = 'F_{drive}(N)';

            comp.FField = uieditfield(comp.ConductorGrid, 'numeric');
            comp.FField.Layout.Row = 7;
            comp.FField.Layout.Column = 2;

            % 磁场参数
            comp.FieldPanel = uipanel(comp.paramGrid);
            comp.FieldPanel.Title = '磁场';
            comp.FieldPanel.Layout.Row = 2;
            comp.FieldPanel.Layout.Column = 1;

            comp.fGrid = uigridlayout(comp.FieldPanel);
            comp.fGrid.ColumnWidth = {90, '1x'};
            comp.fGrid.RowHeight = {'fit', 'fit'};
            comp.fGrid.ColumnSpacing = 8;
            comp.fGrid.RowSpacing = 6;
            comp.fGrid.Padding = [8 8 8 8];

            comp.lblB = uilabel(comp.fGrid);
            comp.lblB.Layout.Row = 1;
            comp.lblB.Layout.Column = 1;
            comp.lblB.Interpreter = 'tex';
            comp.lblB.Text = 'B(T)';

            comp.BField = uieditfield(comp.fGrid, 'numeric');
            comp.BField.Layout.Row = 1;
            comp.BField.Layout.Column = 2;

            comp.lblBdir = uilabel(comp.fGrid);
            comp.lblBdir.Layout.Row = 2;
            comp.lblBdir.Layout.Column = 1;
            comp.lblBdir.Text = 'B 方向';

            comp.BdirDropDown = uidropdown(comp.fGrid);
            comp.BdirDropDown.Items = {'出屏', '入屏'};
            comp.BdirDropDown.Layout.Row = 2;
            comp.BdirDropDown.Layout.Column = 2;
            comp.BdirDropDown.Value = '出屏';

            % 有界参数
            comp.BoundsPanel = uipanel(comp.paramGrid);
            comp.BoundsPanel.Title = '边界';
            comp.BoundsPanel.Layout.Row = 3;
            comp.BoundsPanel.Layout.Column = 1;

            comp.bGrid = uigridlayout(comp.BoundsPanel);
            comp.bGrid.ColumnWidth = {60, '1x', 60, '1x'};
            comp.bGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.bGrid.ColumnSpacing = 8;
            comp.bGrid.RowSpacing = 6;
            comp.bGrid.Padding = [8 8 8 8];

            comp.BoundedCheck = uicheckbox(comp.bGrid);
            comp.BoundedCheck.Text = '有界';
            comp.BoundedCheck.Layout.Row = 1;
            comp.BoundedCheck.Layout.Column = 1;

            comp.XminLabel = uilabel(comp.bGrid);
            comp.XminLabel.Layout.Row = 2;
            comp.XminLabel.Layout.Column = 1;
            comp.XminLabel.Interpreter = 'tex';
            comp.XminLabel.Text = 'x_{min}';

            comp.XminField = uieditfield(comp.bGrid, 'numeric');
            comp.XminField.Layout.Row = 2;
            comp.XminField.Layout.Column = 2;

            comp.XmaxLabel = uilabel(comp.bGrid);
            comp.XmaxLabel.Layout.Row = 3;
            comp.XmaxLabel.Layout.Column = 1;
            comp.XmaxLabel.Interpreter = 'tex';
            comp.XmaxLabel.Text = 'x_{max}';

            comp.XmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.XmaxField.Layout.Row = 3;
            comp.XmaxField.Layout.Column = 2;

            comp.YminLabel = uilabel(comp.bGrid);
            comp.YminLabel.Layout.Row = 2;
            comp.YminLabel.Layout.Column = 3;
            comp.YminLabel.Interpreter = 'tex';
            comp.YminLabel.Text = 'y_{min}';

            comp.YminField = uieditfield(comp.bGrid, 'numeric');
            comp.YminField.Layout.Row = 2;
            comp.YminField.Layout.Column = 4;

            comp.YmaxLabel = uilabel(comp.bGrid);
            comp.YmaxLabel.Layout.Row = 3;
            comp.YmaxLabel.Layout.Column = 3;
            comp.YmaxLabel.Interpreter = 'tex';
            comp.YmaxLabel.Text = 'y_{max}';

            comp.YmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.YmaxField.Layout.Row = 3;
            comp.YmaxField.Layout.Column = 4;

            % 显示开关
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 4;
            comp.ViewPanel.Layout.Column = 1;

            comp.vGrid = uigridlayout(comp.ViewPanel);
            comp.vGrid.ColumnWidth = {'1x', '1x', '1x'};
            comp.vGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.vGrid.ColumnSpacing = 8;
            comp.vGrid.RowSpacing = 6;
            comp.vGrid.Padding = [8 8 8 8];

            comp.ShowTrailCheck = uicheckbox(comp.vGrid);
            comp.ShowTrailCheck.Text = '轨迹';
            comp.ShowTrailCheck.Layout.Row = 1;
            comp.ShowTrailCheck.Layout.Column = 1;

            comp.ShowVCheck = uicheckbox(comp.vGrid);
            comp.ShowVCheck.Text = '速度箭头';
            comp.ShowVCheck.Layout.Row = 1;
            comp.ShowVCheck.Layout.Column = 2;

            comp.ShowDriveForceCheck = uicheckbox(comp.vGrid);
            comp.ShowDriveForceCheck.Text = '外力箭头';
            comp.ShowDriveForceCheck.Layout.Row = 1;
            comp.ShowDriveForceCheck.Layout.Column = 3;

            comp.ShowAmpereForceCheck = uicheckbox(comp.vGrid);
            comp.ShowAmpereForceCheck.Text = '安培力箭头';
            comp.ShowAmpereForceCheck.Layout.Row = 2;
            comp.ShowAmpereForceCheck.Layout.Column = 1;

            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 2;

            comp.ShowBMarksCheck = uicheckbox(comp.vGrid);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 3;

            comp.ShowCurrentCheck = uicheckbox(comp.vGrid);
            comp.ShowCurrentCheck.Text = '电流方向';
            comp.ShowCurrentCheck.Layout.Row = 3;
            comp.ShowCurrentCheck.Layout.Column = 1;

            % 输出区（只读）
            comp.ResultsPanel = uipanel(comp.paramGrid);
            comp.ResultsPanel.Title = '输出结果';
            comp.ResultsPanel.Layout.Row = 5;
            comp.ResultsPanel.Layout.Column = 1;

            comp.ResultsGrid = uigridlayout(comp.ResultsPanel);
            comp.ResultsGrid.ColumnWidth = {'fit', '1x', 'fit', '1x'};
            comp.ResultsGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.ResultsGrid.ColumnSpacing = 8;
            comp.ResultsGrid.RowSpacing = 6;
            comp.ResultsGrid.Padding = [8 8 8 8];

            comp.epsilonLabel = uilabel(comp.ResultsGrid);
            comp.epsilonLabel.Layout.Row = 1;
            comp.epsilonLabel.Layout.Column = 1;
            comp.epsilonLabel.Interpreter = 'tex';
            comp.epsilonLabel.Text = '\epsilon(V)';

            comp.epsilonField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.epsilonField.Layout.Row = 1;
            comp.epsilonField.Layout.Column = 2;
            comp.epsilonField.Editable = 'off';

            comp.ILabel = uilabel(comp.ResultsGrid);
            comp.ILabel.Layout.Row = 1;
            comp.ILabel.Layout.Column = 3;
            comp.ILabel.Interpreter = 'tex';
            comp.ILabel.Text = 'I(A)';

            comp.IField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.IField.Layout.Row = 1;
            comp.IField.Layout.Column = 4;
            comp.IField.Editable = 'off';

            comp.xtLabel = uilabel(comp.ResultsGrid);
            comp.xtLabel.Layout.Row = 2;
            comp.xtLabel.Layout.Column = 1;
            comp.xtLabel.Interpreter = 'tex';
            comp.xtLabel.Text = 'x_t(m)';

            comp.xtField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.xtField.Layout.Row = 2;
            comp.xtField.Layout.Column = 2;
            comp.xtField.Editable = 'off';

            comp.vtLabel = uilabel(comp.ResultsGrid);
            comp.vtLabel.Layout.Row = 2;
            comp.vtLabel.Layout.Column = 3;
            comp.vtLabel.Interpreter = 'tex';
            comp.vtLabel.Text = 'v_t(m/s)';

            comp.vtField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.vtField.Layout.Row = 2;
            comp.vtField.Layout.Column = 4;
            comp.vtField.Editable = 'off';

            comp.FmagLabel = uilabel(comp.ResultsGrid);
            comp.FmagLabel.Layout.Row = 3;
            comp.FmagLabel.Layout.Column = 1;
            comp.FmagLabel.Interpreter = 'tex';
            comp.FmagLabel.Text = 'F_{mag}(N)';

            comp.FmagField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.FmagField.Layout.Row = 3;
            comp.FmagField.Layout.Column = 2;
            comp.FmagField.Editable = 'off';

            comp.pElecLabel = uilabel(comp.ResultsGrid);
            comp.pElecLabel.Layout.Row = 3;
            comp.pElecLabel.Layout.Column = 3;
            comp.pElecLabel.Interpreter = 'tex';
            comp.pElecLabel.Text = 'Q(J)';

            comp.pElecField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.pElecField.Layout.Row = 3;
            comp.pElecField.Layout.Column = 4;
            comp.pElecField.Editable = 'off';

            % 初始化默认值并绑定回调
            comp.Value = comp.defaultPayload();
            comp.applyPayloadToUi(comp.Value);
            comp.bindCallbacks();
        end
    end

    methods (Access = private)
        function tf = isUiReady(comp)
            %ISUIREADY  判断底层 UI 是否已经创建完成
            tf = ~isempty(comp.paramGrid) && isvalid(comp.paramGrid);
        end

        function bindCallbacks(comp)
            %BINDCALLBACKS  统一绑定全部可编辑控件的 ValueChanged 回调
            controls = {
                comp.LField, comp.xField, comp.vField, comp.RField, comp.mField, ...
                comp.driveForceDropDown, comp.FField, ...
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
        end

        function onAnyControlChanged(comp)
            %ONANYCONTROLCHANGED  任意可编辑控件变化时的统一入口
            if comp.IsApplyingPayload
                return;
            end

            previousPayload = comp.Value;
            comp.Value = comp.collectPayloadFromUi(previousPayload);
            comp.applyPayloadToUi(comp.Value);
            notify(comp, 'PayloadChanged');
        end

        function payload = collectPayloadFromUi(comp, previousPayload)
            %COLLECTPAYLOADFROMUI  采集控件值并组装为 payload
            if nargin < 2 || ~isstruct(previousPayload)
                previousPayload = comp.Value;
            end

            payload = struct();
            payload.modelType = "rail";
            payload.templateId = string(pickField(previousPayload, 'templateId', "R"));
            payload.B = comp.BField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.L = comp.LField.Value;
            payload.x0 = comp.xField.Value;
            payload.y0 = 0.0;
            payload.v0 = comp.vField.Value;
            payload.loopClosed = logical(pickField(previousPayload, 'loopClosed', false));
            payload.R = comp.RField.Value;
            payload.m = comp.mField.Value;
            payload.driveEnabled = comp.driveFromUiValue(comp.driveForceDropDown.Value);
            payload.Fdrive = comp.FField.Value;
            payload.bounded = comp.BoundedCheck.Value;
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

            % 以下字段当前组件无独立输入控件，先沿用旧值
            payload.autoFollow = pickField(previousPayload, 'autoFollow', true);
            payload.followSpan = pickField(previousPayload, 'followSpan', 8.0);
            payload.maxSpan = pickField(previousPayload, 'maxSpan', 120.0);
            payload.speedScale = pickField(previousPayload, 'speedScale', 1.0);
            payload.epsilonOut = pickField(previousPayload, 'epsilonOut', 0.0);
            payload.currentOut = pickField(previousPayload, 'currentOut', 0.0);
            payload.xOut = pickField(previousPayload, 'xOut', payload.x0);
            payload.vOut = pickField(previousPayload, 'vOut', payload.v0);
            payload.fMagOut = pickField(previousPayload, 'fMagOut', 0.0);
            payload.qHeatOut = pickField(previousPayload, 'qHeatOut', 0.0);
            payload.pElecOut = pickField(previousPayload, 'pElecOut', 0.0);

            payload = comp.normalizePayload(payload, previousPayload);
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将 payload 分发写入各个控件
            payload = comp.normalizePayload(payload, comp.Value);
            comp.IsApplyingPayload = true;
            try
                comp.BField.Value = payload.B;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.LField.Value = payload.L;
                comp.xField.Value = payload.x0;
                comp.vField.Value = payload.v0;
                comp.RField.Value = payload.R;
                comp.mField.Value = payload.m;
                comp.driveForceDropDown.Value = comp.driveToUiValue(payload.driveEnabled);
                comp.FField.Value = payload.Fdrive;

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

                comp.epsilonField.Value = payload.epsilonOut;
                comp.IField.Value = payload.currentOut;
                comp.xtField.Value = payload.xOut;
                comp.vtField.Value = payload.vOut;
                comp.FmagField.Value = payload.fMagOut;
                comp.pElecField.Value = payload.qHeatOut;

                comp.updateBoundsEnable(payload.bounded);
                comp.updateDriveForceEnable(payload.driveEnabled);
                comp.updateTemplateLocks(payload);
            catch err
                comp.IsApplyingPayload = false;
                rethrow(err);
            end
            comp.IsApplyingPayload = false;
        end

        function updateBoundsEnable(comp, isOn)
            %UPDATEBOUNDSENABLE  根据 bounded 开关启用/禁用边界输入
            state = comp.boolToOnOff(isOn);
            comp.XminField.Enable = state;
            comp.XmaxField.Enable = state;
            comp.YminField.Enable = state;
            comp.YmaxField.Enable = state;
        end

        function updateDriveForceEnable(comp, isOn)
            %UPDATEDRIVEFORCEENABLE  根据外力驱动开关启用/禁用 Fdrive 输入
            comp.FField.Enable = comp.boolToOnOff(isOn);
            comp.ShowDriveForceCheck.Enable = comp.boolToOnOff(isOn);
        end

        function updateTemplateLocks(comp, payload)
            %UPDATETEMPLATELOCKS  按模板约束启用/禁用相关控件
            %
            % 统一 R 模板：不按子编号锁死控件，交由参数开关控制
            comp.driveForceDropDown.Enable = 'on';
            comp.ShowAmpereForceCheck.Enable = comp.boolToOnOff(payload.loopClosed);
            comp.updateDriveForceEnable(payload.driveEnabled);
        end

        function payload = normalizePayload(comp, in, previousPayload)
            %NORMALIZEPAYLOAD  参数合并与类型归一化
            if nargin < 3 || ~isstruct(previousPayload)
                previousPayload = struct();
            end

            base = comp.defaultPayload();
            payload = base;
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
            payload.templateId = upper(comp.normalizeEnum(pickField(payload, 'templateId', "R"), ["R","R1","R2","R3","R4"], "R"));
            payload.B = max(comp.toDouble(payload.B, base.B), 0.0);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], base.Bdir);
            payload.L = max(comp.toDouble(payload.L, base.L), 1e-3);
            payload.x0 = comp.toDouble(payload.x0, base.x0);
            payload.y0 = comp.toDouble(payload.y0, base.y0);
            payload.v0 = comp.toDouble(payload.v0, base.v0);
            payload.loopClosed = comp.toLogical(payload.loopClosed, base.loopClosed);
            payload.R = max(comp.toDouble(payload.R, base.R), 1e-6);
            payload.m = max(comp.toDouble(payload.m, base.m), 1e-6);
            payload.driveEnabled = comp.toLogical(payload.driveEnabled, base.driveEnabled);
            payload.Fdrive = comp.toDouble(payload.Fdrive, base.Fdrive);
            % 统一 R 模板下：当前用“外力驱动”联动闭合回路，方便在单模板内切 R1/R2
            payload.loopClosed = payload.loopClosed || payload.driveEnabled;
            payload.bounded = comp.toLogical(payload.bounded, base.bounded);
            payload.xMin = comp.toDouble(payload.xMin, base.xMin);
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            payload.yMin = comp.toDouble(payload.yMin, base.yMin);
            payload.yMax = comp.toDouble(payload.yMax, base.yMax);
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
            payload.epsilonOut = comp.toDouble(payload.epsilonOut, base.epsilonOut);
            payload.currentOut = comp.toDouble(payload.currentOut, base.currentOut);
            payload.xOut = comp.toDouble(payload.xOut, base.xOut);
            payload.vOut = comp.toDouble(payload.vOut, base.vOut);
            payload.fMagOut = comp.toDouble(payload.fMagOut, base.fMagOut);
            payload.qHeatOut = comp.toDouble(payload.qHeatOut, base.qHeatOut);
            payload.pElecOut = comp.toDouble(payload.pElecOut, base.pElecOut);

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

            if ~payload.loopClosed
                payload.showAmpereForce = false;
            end

            if ~payload.driveEnabled
                payload.Fdrive = 0.0;
            end

            % 防止前后切换时把强制字段丢失
            if isstruct(previousPayload)
                payload.modelType = "rail";
            end
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  导轨模板默认参数
            payload = struct( ...
                'modelType', "rail", ...
                'templateId', "R", ...
                'B', 1.0, ...
                'Bdir', "out", ...
                'L', 1.0, ...
                'x0', 0.0, ...
                'y0', 0.0, ...
                'v0', 1.0, ...
                'loopClosed', false, ...
                'R', 1.0, ...
                'm', 1.0, ...
                'driveEnabled', false, ...
                'Fdrive', 0.0, ...
                'bounded', false, ...
                'xMin', -2.0, ...
                'xMax', 2.0, ...
                'yMin', -1.0, ...
                'yMax', 1.0, ...
                'showTrail', true, ...
                'showV', true, ...
                'showDriveForce', false, ...
                'showAmpereForce', false, ...
                'showCurrent', false, ...
                'showGrid', true, ...
                'showBMarks', true, ...
                'autoFollow', true, ...
                'followSpan', 8.0, ...
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

        function v = normalizeEnum(~, vRaw, options, defaultValue)
            %NORMALIZEENUM  枚举值归一化，不匹配时回退默认值
            s = strtrim(string(vRaw));
            idx = find(strcmpi(string(options), s), 1, 'first');
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

        function state = boolToOnOff(~, tf)
            %BOOLTOONOFF  布尔值转 MATLAB UI 的 Enable 状态字符串
            if tf
                state = 'on';
            else
                state = 'off';
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
            if strcmpi(string(key), "in")
                uiVal = '入屏';
            else
                uiVal = '出屏';
            end
        end

        function tf = driveFromUiValue(~, uiVal)
            %DRIVEFROMUIVALUE  UI 文案 -> 外力驱动开关
            tf = strtrim(string(uiVal)) == "有";
        end

        function uiVal = driveToUiValue(~, tf)
            %DRIVETOUIVALUE  外力驱动开关 -> UI 文案
            if tf
                uiVal = '有';
            else
                uiVal = '无';
            end
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


classdef M5_for_test < matlab.ui.componentcontainer.ComponentContainer
    %M5_FOR_TEST  M5 质谱仪参数组件（右半有界磁场）
    %
    % 组件职责
    %   1) 提供 M5 模板参数 UI（磁场、入射速度、边界、显示开关）
    %   2) 维护统一 payload 接口：Value / getPayload / setPayload
    %   3) 将 UI 输入归一化为粒子引擎可直接使用的参数结构
    %
    % 设计约束
    %   - M5 场景固定为“右半磁场”：xMin 始终锁定在 specWallX
    %   - UI 中 T 与 B 用于推导 q/m：q/m = 2*pi / (B*T)
    %   - 本组件只做参数映射与约束，不做仿真计算

    properties (Access = public)
        % Value - 对外统一参数结构
        Value struct = struct()
    end

    properties (Access = private, Transient, NonCopyable)
        % 布局与控件句柄
        paramGrid        matlab.ui.container.GridLayout
        ResultsPanel     matlab.ui.container.Panel
        ResultsGrid      matlab.ui.container.GridLayout
        qmLabel          matlab.ui.control.Label
        qmField          matlab.ui.control.NumericEditField
        FieldPanel       matlab.ui.container.Panel
        fGrid            matlab.ui.container.GridLayout
        lblB             matlab.ui.control.Label
        lblBdir          matlab.ui.control.Label
        BField           matlab.ui.control.NumericEditField
        BdirDropDown     matlab.ui.control.DropDown
        ParticlePanel    matlab.ui.container.Panel
        pGrid            matlab.ui.container.GridLayout
        TField           matlab.ui.control.NumericEditField
        TLabel           matlab.ui.control.Label
        ThetaField       matlab.ui.control.NumericEditField
        lblTheta         matlab.ui.control.Label
        V0Field          matlab.ui.control.NumericEditField
        lblV0            matlab.ui.control.Label
        BoundsPanel      matlab.ui.container.Panel
        bGrid            matlab.ui.container.GridLayout
        BoundedCheck     matlab.ui.control.CheckBox
        XminLabel        matlab.ui.control.Label
        XmaxLabel        matlab.ui.control.Label
        YminLabel        matlab.ui.control.Label
        YmaxLabel        matlab.ui.control.Label
        XminField        matlab.ui.control.NumericEditField
        XmaxField        matlab.ui.control.NumericEditField
        YminField        matlab.ui.control.NumericEditField
        YmaxField        matlab.ui.control.NumericEditField
        ViewPanel        matlab.ui.container.Panel
        vGrid            matlab.ui.container.GridLayout
        ShowTrailCheck   matlab.ui.control.CheckBox
        ShowVCheck       matlab.ui.control.CheckBox
        ShowFCheck       matlab.ui.control.CheckBox
        ShowGridCheck    matlab.ui.control.CheckBox
        ShowBMarksCheck  matlab.ui.control.CheckBox

        % 写回 UI 防重入
        IsApplyingPayload logical = false
    end

    events
        % PayloadChanged - 任意参数变更后触发
        PayloadChanged
    end

    methods
        function payload = getPayload(comp)
            %GETPAYLOAD  返回当前参数（已归一化）
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
            %UPDATE  公开属性 Value 更新后的同步入口
            payload = comp.normalizePayload(comp.Value, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end

        function setup(comp)
            %SETUP  创建底层 UI 并绑定回调
            comp.Position = [1 1 320 240];

            % 外层布局
            comp.paramGrid = uigridlayout(comp);
            comp.paramGrid.ColumnWidth = {'1x'};
            comp.paramGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
            comp.paramGrid.RowSpacing = 8;
            comp.paramGrid.Padding = [6 6 6 6];

            % 显示开关面板
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 4;
            comp.ViewPanel.Layout.Column = 1;

            comp.vGrid = uigridlayout(comp.ViewPanel);
            comp.vGrid.ColumnWidth = {'1x', '1x', '1x'};
            comp.vGrid.RowHeight = {'fit', 'fit'};

            comp.ShowBMarksCheck = uicheckbox(comp.vGrid);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 2;

            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 1;
            comp.ShowGridCheck.Value = true;

            comp.ShowFCheck = uicheckbox(comp.vGrid);
            comp.ShowFCheck.Text = '受力箭头';
            comp.ShowFCheck.Layout.Row = 1;
            comp.ShowFCheck.Layout.Column = 3;

            comp.ShowVCheck = uicheckbox(comp.vGrid);
            comp.ShowVCheck.Text = '速度箭头';
            comp.ShowVCheck.Layout.Row = 1;
            comp.ShowVCheck.Layout.Column = 2;
            comp.ShowVCheck.Value = true;

            comp.ShowTrailCheck = uicheckbox(comp.vGrid);
            comp.ShowTrailCheck.Text = '轨迹';
            comp.ShowTrailCheck.Layout.Row = 1;
            comp.ShowTrailCheck.Layout.Column = 1;
            comp.ShowTrailCheck.Value = true;

            % 边界面板
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

            comp.YmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.YmaxField.Layout.Row = 3;
            comp.YmaxField.Layout.Column = 4;

            comp.YminField = uieditfield(comp.bGrid, 'numeric');
            comp.YminField.Layout.Row = 2;
            comp.YminField.Layout.Column = 4;

            comp.XmaxField = uieditfield(comp.bGrid, 'numeric');
            comp.XmaxField.Layout.Row = 3;
            comp.XmaxField.Layout.Column = 2;

            comp.XminField = uieditfield(comp.bGrid, 'numeric');
            comp.XminField.Layout.Row = 2;
            comp.XminField.Layout.Column = 2;

            comp.YmaxLabel = uilabel(comp.bGrid);
            comp.YmaxLabel.Layout.Row = 3;
            comp.YmaxLabel.Layout.Column = 3;
            comp.YmaxLabel.Interpreter = 'tex';
            comp.YmaxLabel.Text = 'y_{max}';

            comp.YminLabel = uilabel(comp.bGrid);
            comp.YminLabel.Layout.Row = 2;
            comp.YminLabel.Layout.Column = 3;
            comp.YminLabel.Interpreter = 'tex';
            comp.YminLabel.Text = 'y_{min}';

            comp.XmaxLabel = uilabel(comp.bGrid);
            comp.XmaxLabel.Layout.Row = 3;
            comp.XmaxLabel.Layout.Column = 1;
            comp.XmaxLabel.Interpreter = 'tex';
            comp.XmaxLabel.Text = 'x_{max}';

            comp.XminLabel = uilabel(comp.bGrid);
            comp.XminLabel.Layout.Row = 2;
            comp.XminLabel.Layout.Column = 1;
            comp.XminLabel.Interpreter = 'tex';
            comp.XminLabel.Text = 'x_{min}';

            comp.BoundedCheck = uicheckbox(comp.bGrid);
            comp.BoundedCheck.Text = '有界';
            comp.BoundedCheck.Layout.Row = 1;
            comp.BoundedCheck.Layout.Column = 1;

            % 粒子参数面板
            comp.ParticlePanel = uipanel(comp.paramGrid);
            comp.ParticlePanel.Title = '粒子';
            comp.ParticlePanel.Layout.Row = 1;
            comp.ParticlePanel.Layout.Column = 1;

            comp.pGrid = uigridlayout(comp.ParticlePanel);
            comp.pGrid.ColumnWidth = {90, '1x'};
            comp.pGrid.RowHeight = {'fit', 'fit', 'fit'};
            comp.pGrid.ColumnSpacing = 8;
            comp.pGrid.RowSpacing = 6;
            comp.pGrid.Padding = [8 8 8 8];

            comp.lblV0 = uilabel(comp.pGrid);
            comp.lblV0.Layout.Row = 2;
            comp.lblV0.Layout.Column = 1;
            comp.lblV0.Interpreter = 'tex';
            comp.lblV0.Text = 'v_0(m/s)';

            comp.V0Field = uieditfield(comp.pGrid, 'numeric');
            comp.V0Field.Layout.Row = 2;
            comp.V0Field.Layout.Column = 2;

            comp.lblTheta = uilabel(comp.pGrid);
            comp.lblTheta.Layout.Row = 3;
            comp.lblTheta.Layout.Column = 1;
            comp.lblTheta.Interpreter = 'tex';
            comp.lblTheta.Text = '\theta(deg)';

            comp.ThetaField = uieditfield(comp.pGrid, 'numeric');
            comp.ThetaField.Layout.Row = 3;
            comp.ThetaField.Layout.Column = 2;

            comp.TLabel = uilabel(comp.pGrid);
            comp.TLabel.Layout.Row = 1;
            comp.TLabel.Layout.Column = 1;
            comp.TLabel.Interpreter = 'tex';
            comp.TLabel.Text = 'T(s)';

            comp.TField = uieditfield(comp.pGrid, 'numeric');
            comp.TField.Layout.Row = 1;
            comp.TField.Layout.Column = 2;

            % 磁场参数面板
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

            comp.BdirDropDown = uidropdown(comp.fGrid);
            comp.BdirDropDown.Items = {'出屏', '入屏'};
            comp.BdirDropDown.Layout.Row = 2;
            comp.BdirDropDown.Layout.Column = 2;
            comp.BdirDropDown.Value = '出屏';

            comp.BField = uieditfield(comp.fGrid, 'numeric');
            comp.BField.Layout.Row = 1;
            comp.BField.Layout.Column = 2;

            comp.lblBdir = uilabel(comp.fGrid);
            comp.lblBdir.Layout.Row = 2;
            comp.lblBdir.Layout.Column = 1;
            comp.lblBdir.Text = 'B 方向';

            comp.lblB = uilabel(comp.fGrid);
            comp.lblB.Layout.Row = 1;
            comp.lblB.Layout.Column = 1;
            comp.lblB.Interpreter = 'tex';
            comp.lblB.Text = 'B(T)';

            % 输出面板
            comp.ResultsPanel = uipanel(comp.paramGrid);
            comp.ResultsPanel.Title = '输出结果';
            comp.ResultsPanel.Layout.Row = 5;
            comp.ResultsPanel.Layout.Column = 1;

            comp.ResultsGrid = uigridlayout(comp.ResultsPanel);
            comp.ResultsGrid.ColumnWidth = {90, '1x'};
            comp.ResultsGrid.RowHeight = {'1x'};
            comp.ResultsGrid.ColumnSpacing = 8;
            comp.ResultsGrid.RowSpacing = 6;
            comp.ResultsGrid.Padding = [8 8 8 8];

            comp.qmField = uieditfield(comp.ResultsGrid, 'numeric');
            comp.qmField.Editable = 'off';
            comp.qmField.Layout.Row = 1;
            comp.qmField.Layout.Column = 2;

            comp.qmLabel = uilabel(comp.ResultsGrid);
            comp.qmLabel.Layout.Row = 1;
            comp.qmLabel.Layout.Column = 1;
            comp.qmLabel.Interpreter = 'latex';
            comp.qmLabel.Text = '\frac{q}{m}';

            % 默认值 + 回调绑定
            comp.Value = comp.defaultPayload();
            comp.applyPayloadToUi(comp.Value);
            comp.bindCallbacks();
        end
    end

    methods (Access = private)
        function tf = isUiReady(comp)
            %ISUIREADY  底层 UI 是否已完成创建
            tf = ~isempty(comp.paramGrid) && isvalid(comp.paramGrid);
        end

        function bindCallbacks(comp)
            %BINDCALLBACKS  统一绑定控件回调
            controls = {
                comp.BField, comp.BdirDropDown, comp.V0Field, comp.ThetaField, comp.TField, ...
                comp.BoundedCheck, comp.XminField, comp.XmaxField, comp.YminField, comp.YmaxField, ...
                comp.ShowTrailCheck, comp.ShowVCheck, comp.ShowFCheck, comp.ShowGridCheck, comp.ShowBMarksCheck ...
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
            %ONANYCONTROLCHANGED  任意控件改值后的统一处理入口
            if comp.IsApplyingPayload
                return;
            end

            oldPayload = comp.Value;
            comp.Value = comp.collectPayloadFromUi(oldPayload);
            comp.applyPayloadToUi(comp.Value);
            notify(comp, 'PayloadChanged');
        end

        function payload = collectPayloadFromUi(comp, oldPayload)
            %COLLECTPAYLOADFROMUI  从 UI 读取当前参数
            if nargin < 2 || ~isstruct(oldPayload)
                oldPayload = comp.Value;
            end

            payload = struct();
            payload.templateId = "M5";
            payload.modelType = "particle";
            payload.B = comp.BField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.v0 = comp.V0Field.Value;
            payload.thetaDeg = comp.ThetaField.Value;
            payload.T = comp.TField.Value;

            payload.bounded = comp.BoundedCheck.Value;
            payload.xMin = comp.XminField.Value;
            payload.xMax = comp.XmaxField.Value;
            payload.yMin = comp.YminField.Value;
            payload.yMax = comp.YmaxField.Value;

            payload.showTrail = comp.ShowTrailCheck.Value;
            payload.showV = comp.ShowVCheck.Value;
            payload.showF = comp.ShowFCheck.Value;
            payload.showGrid = comp.ShowGridCheck.Value;
            payload.showBMarks = comp.ShowBMarksCheck.Value;

            % 继承非 UI 字段
            payload.x0 = pickField(oldPayload, 'x0', -1.2);
            payload.y0 = pickField(oldPayload, 'y0', 0.0);
            payload.q = pickField(oldPayload, 'q', 1.0);
            payload.m = pickField(oldPayload, 'm', 1.0);
            payload.autoFollow = pickField(oldPayload, 'autoFollow', false);
            payload.followSpan = pickField(oldPayload, 'followSpan', 6.0);
            payload.maxSpan = pickField(oldPayload, 'maxSpan', 20.0);
            payload.speedScale = pickField(oldPayload, 'speedScale', 1.0);
            payload.specWallX = pickField(oldPayload, 'specWallX', 0.0);
            payload.slitCenterY = pickField(oldPayload, 'slitCenterY', 0.0);
            payload.slitHeight = pickField(oldPayload, 'slitHeight', 0.40);

            payload = comp.normalizePayload(payload, oldPayload);
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将 payload 写回 UI 控件
            payload = comp.normalizePayload(payload, comp.Value);
            comp.IsApplyingPayload = true;
            try
                comp.BField.Value = payload.B;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.V0Field.Value = payload.v0;
                comp.ThetaField.Value = payload.thetaDeg;
                comp.TField.Value = payload.T;

                comp.BoundedCheck.Value = payload.bounded;
                comp.XminField.Value = payload.xMin;
                comp.XmaxField.Value = payload.xMax;
                comp.YminField.Value = payload.yMin;
                comp.YmaxField.Value = payload.yMax;

                comp.ShowTrailCheck.Value = payload.showTrail;
                comp.ShowVCheck.Value = payload.showV;
                comp.ShowFCheck.Value = payload.showF;
                comp.ShowGridCheck.Value = payload.showGrid;
                comp.ShowBMarksCheck.Value = payload.showBMarks;

                comp.qmField.Value = payload.qOverMOut;
                comp.updateBoundsEnable(payload.bounded);
            catch err
                comp.IsApplyingPayload = false;
                rethrow(err);
            end
            comp.IsApplyingPayload = false;
        end

        function updateBoundsEnable(comp, boundedOn)
            %UPDATEBOUNDSENABLE  更新边界控件启用状态
            %
            % 说明
            %   - M5 的 xMin 与狭缝粗线绑定，固定不可编辑
            %   - BoundedCheck 仅保留显示意义，固定启用有界逻辑
            state = comp.boolToOnOff(boundedOn);
            comp.XminField.Enable = 'off';
            comp.XmaxField.Enable = state;
            comp.YminField.Enable = state;
            comp.YmaxField.Enable = state;
            comp.BoundedCheck.Enable = 'off';
        end

        function payload = normalizePayload(comp, in, previousPayload)
            %NORMALIZEPAYLOAD  参数归一化与场景约束
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

            payload.templateId = "M5";
            payload.modelType = "particle";
            payload.B = max(comp.toDouble(payload.B, base.B), 0);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], base.Bdir);
            payload.v0 = max(comp.toDouble(payload.v0, base.v0), 0);
            payload.thetaDeg = comp.toDouble(payload.thetaDeg, base.thetaDeg);
            payload.T = max(comp.toDouble(payload.T, base.T), 1e-6);

            payload.bounded = true;
            payload.specWallX = comp.toDouble(payload.specWallX, base.specWallX);
            payload.slitCenterY = comp.toDouble(payload.slitCenterY, base.slitCenterY);
            payload.slitHeight = max(0.05, comp.toDouble(payload.slitHeight, base.slitHeight));

            payload.xMin = payload.specWallX;
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            payload.yMin = comp.toDouble(payload.yMin, base.yMin);
            payload.yMax = comp.toDouble(payload.yMax, base.yMax);

            if payload.xMax <= payload.xMin
                payload.xMax = payload.xMin + 0.5;
            end
            if payload.yMin > payload.yMax
                tmp = payload.yMin;
                payload.yMin = payload.yMax;
                payload.yMax = tmp;
            end

            payload.showTrail = comp.toLogical(payload.showTrail, base.showTrail);
            payload.showV = comp.toLogical(payload.showV, base.showV);
            payload.showF = comp.toLogical(payload.showF, base.showF);
            payload.showGrid = comp.toLogical(payload.showGrid, base.showGrid);
            payload.showBMarks = comp.toLogical(payload.showBMarks, base.showBMarks);
            payload.autoFollow = comp.toLogical(payload.autoFollow, base.autoFollow);
            payload.followSpan = max(0.5, min(40.0, comp.toDouble(payload.followSpan, base.followSpan)));
            payload.maxSpan = max(2.0, min(200.0, comp.toDouble(payload.maxSpan, base.maxSpan)));
            payload.speedScale = max(0.25, min(4.0, comp.toDouble(payload.speedScale, base.speedScale)));

            % 根据 B 和 T 反推 q/m，并映射到引擎所需 q/m
            qOverM = base.qOverMOut;
            if payload.B > 1e-12 && payload.T > 1e-12
                qOverM = 2.0 * pi / (payload.B * payload.T);
            end
            payload.qOverMOut = qOverM;
            payload.q = 1.0;
            payload.m = max(1.0 / max(qOverM, 1e-9), 1e-9);

            % 初始点默认放在狭缝左侧，便于进入右半磁场
            payload.x0 = comp.toDouble(payload.x0, pickField(previousPayload, 'x0', base.x0));
            payload.y0 = comp.toDouble(payload.y0, pickField(previousPayload, 'y0', payload.slitCenterY));

            thetaRad = deg2rad(payload.thetaDeg);
            payload.vx0 = payload.v0 * cos(thetaRad);
            payload.vy0 = payload.v0 * sin(thetaRad);
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  M5 参数默认值
            payload = struct( ...
                'templateId', "M5", ...
                'modelType', "particle", ...
                'q', 1.0, ...
                'm', 1.0, ...
                'qOverMOut', 1.0, ...
                'B', 1.0, ...
                'Bdir', "out", ...
                'v0', 1.2, ...
                'thetaDeg', 0.0, ...
                'T', 2*pi, ...
                'x0', -1.2, ...
                'y0', 0.0, ...
                'bounded', true, ...
                'xMin', 0.0, ...
                'xMax', 4.0, ...
                'yMin', -2.0, ...
                'yMax', 2.0, ...
                'showTrail', true, ...
                'showV', true, ...
                'showF', false, ...
                'showGrid', true, ...
                'showBMarks', true, ...
                'autoFollow', false, ...
                'followSpan', 6.0, ...
                'maxSpan', 20.0, ...
                'speedScale', 1.0, ...
                'specWallX', 0.0, ...
                'slitCenterY', 0.0, ...
                'slitHeight', 0.40, ...
                'vx0', 1.2, ...
                'vy0', 0.0 ...
            );
        end

        function v = normalizeEnum(~, vRaw, options, defaultValue)
            %NORMALIZEENUM  枚举归一化
            s = strtrim(string(vRaw));
            idx = find(strcmpi(string(options), s), 1, 'first');
            if isempty(idx)
                v = string(defaultValue);
            else
                v = string(options(idx));
            end
        end

        function v = toDouble(~, vRaw, defaultValue)
            %TODOUBLE  转有限标量 double
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
            %TOLOGICAL  转 logical
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
            %BOOLTOONOFF  logical -> on/off
            if tf
                state = 'on';
            else
                state = 'off';
            end
        end

        function key = bdirFromUiValue(~, uiVal)
            %BDIRFROMUIVALUE  UI 文案 -> out/in
            if strtrim(string(uiVal)) == "入屏"
                key = "in";
            else
                key = "out";
            end
        end

        function uiVal = bdirToUiValue(~, key)
            %BDIRTOUIVALUE  out/in -> UI 文案
            if strcmpi(string(key), "in")
                uiVal = '入屏';
            else
                uiVal = '出屏';
            end
        end
    end
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失时返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

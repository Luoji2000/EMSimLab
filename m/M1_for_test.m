classdef M1_for_test < matlab.ui.componentcontainer.ComponentContainer
    %M1_FOR_TEST  M1 参数面板自定义组件（UI + 参数桥接）
    %
    % 职责定位
    %   1) 负责创建/维护 M1 参数相关控件
    %   2) 对外提供统一参数接口：Value / getPayload / setPayload
    %   3) 在用户修改控件时抛出 PayloadChanged 事件
    %
    % 分层约束
    %   - 本组件不做物理计算与仿真推进
    %   - 本组件只处理“UI <-> payload”映射与归一化
    %   - 参数合法性最终以 params.validate 为准

    properties (Access = public)
        % Value - 组件公开参数载荷（与 app/ui 层交互的统一结构）
        Value struct = struct()
    end

    properties (Access = private, Transient, NonCopyable)
        paramGrid             matlab.ui.container.GridLayout
        FieldPanel            matlab.ui.container.Panel
        fGrid                 matlab.ui.container.GridLayout
        lblB                  matlab.ui.control.Label
        lblV0                 matlab.ui.control.Label
        lblTheta              matlab.ui.control.Label
        lblBdir               matlab.ui.control.Label
        BField                matlab.ui.control.NumericEditField
        V0Field               matlab.ui.control.NumericEditField
        ThetaField            matlab.ui.control.NumericEditField
        BdirDropDown          matlab.ui.control.DropDown
        ParticlePanel         matlab.ui.container.Panel
        pGrid                 matlab.ui.container.GridLayout
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
        GridLayout            matlab.ui.container.GridLayout
        ShowTrailCheck        matlab.ui.control.CheckBox
        ShowVCheck            matlab.ui.control.CheckBox
        ShowFCheck            matlab.ui.control.CheckBox
        ShowGridCheck         matlab.ui.control.CheckBox
        ShowBMarksCheck       matlab.ui.control.CheckBox

        % IsApplyingPayload - 写回 UI 时的重入保护标记
        IsApplyingPayload     logical = false
    end

    events
        % PayloadChanged - 控件内部参数变化事件（由 UI 操作触发）
        PayloadChanged
    end

    methods
        function payload = getPayload(comp)
            %GETPAYLOAD  读取当前 UI 参数（已归一化）
            %
            % 输出
            %   payload (1,1) struct : 当前参数快照
            %
            % 说明
            %   - UI 已就绪：从控件采集并归一化
            %   - UI 未就绪：从 Value 归一化后返回
            if comp.isUiReady()
                payload = comp.collectPayloadFromUi();
            else
                payload = comp.normalizePayload(comp.Value);
            end
        end

        function setPayload(comp, payload)
            %SETPAYLOAD  外部写入参数并刷新 UI
            %
            % 输入
            %   payload (1,1) struct : 待写入参数
            %
            % 说明
            %   - 非 struct 输入将被忽略
            %   - 写入前统一执行 normalizePayload
            if nargin < 2 || ~isstruct(payload)
                return;
            end
            payload = comp.normalizePayload(payload);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end
    end

    methods (Access = protected)

        function update(comp)
            %UPDATE  当公开属性变化时，同步到底层 UI
            % 触发时机：外部直接赋值 comp.Value 后由框架调用
            payload = comp.normalizePayload(comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end

        function setup(comp)
            %SETUP  创建底层组件并绑定默认行为
            %
            % 执行顺序
            %   1) 创建全部 UI 控件
            %   2) 写入默认 payload
            %   3) 绑定 ValueChanged 回调
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

            % Create GridLayout
            comp.GridLayout = uigridlayout(comp.ViewPanel);
            comp.GridLayout.ColumnWidth = {'1x', '1x', '1x'};
            comp.GridLayout.RowHeight = {'fit', 'fit'};

            % Create ShowBMarksCheck
            comp.ShowBMarksCheck = uicheckbox(comp.GridLayout);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 2;

            % Create ShowGridCheck
            comp.ShowGridCheck = uicheckbox(comp.GridLayout);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 1;
            comp.ShowGridCheck.Value = true;

            % Create ShowFCheck
            comp.ShowFCheck = uicheckbox(comp.GridLayout);
            comp.ShowFCheck.Text = '受力箭头';
            comp.ShowFCheck.Layout.Row = 1;
            comp.ShowFCheck.Layout.Column = 3;

            % Create ShowVCheck
            comp.ShowVCheck = uicheckbox(comp.GridLayout);
            comp.ShowVCheck.Text = '速度箭头';
            comp.ShowVCheck.Layout.Row = 1;
            comp.ShowVCheck.Layout.Column = 2;
            comp.ShowVCheck.Value = true;

            % Create ShowTrailCheck
            comp.ShowTrailCheck = uicheckbox(comp.GridLayout);
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
            comp.pGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
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

            % Create FieldPanel
            comp.FieldPanel = uipanel(comp.paramGrid);
            comp.FieldPanel.Title = '磁场';
            comp.FieldPanel.Layout.Row = 2;
            comp.FieldPanel.Layout.Column = 1;

            % Create fGrid
            comp.fGrid = uigridlayout(comp.FieldPanel);
            comp.fGrid.ColumnWidth = {90, '1x'};
            comp.fGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            comp.fGrid.ColumnSpacing = 8;
            comp.fGrid.RowSpacing = 6;
            comp.fGrid.Padding = [8 8 8 8];

            % Create BdirDropDown
            comp.BdirDropDown = uidropdown(comp.fGrid);
            comp.BdirDropDown.Items = {'出屏', '入屏'};
            comp.BdirDropDown.Layout.Row = 4;
            comp.BdirDropDown.Layout.Column = 2;
            comp.BdirDropDown.Value = '出屏';

            % Create ThetaField
            comp.ThetaField = uieditfield(comp.fGrid, 'numeric');
            comp.ThetaField.Layout.Row = 3;
            comp.ThetaField.Layout.Column = 2;

            % Create V0Field
            comp.V0Field = uieditfield(comp.fGrid, 'numeric');
            comp.V0Field.Layout.Row = 2;
            comp.V0Field.Layout.Column = 2;

            % Create BField
            comp.BField = uieditfield(comp.fGrid, 'numeric');
            comp.BField.Layout.Row = 1;
            comp.BField.Layout.Column = 2;

            % Create lblBdir
            comp.lblBdir = uilabel(comp.fGrid);
            comp.lblBdir.Layout.Row = 4;
            comp.lblBdir.Layout.Column = 1;
            comp.lblBdir.Text = 'B 方向';

            % Create lblTheta
            comp.lblTheta = uilabel(comp.fGrid);
            comp.lblTheta.Layout.Row = 3;
            comp.lblTheta.Layout.Column = 1;
            comp.lblTheta.Interpreter = 'tex';
            comp.lblTheta.Text = '\theta(deg)';

            % Create lblV0
            comp.lblV0 = uilabel(comp.fGrid);
            comp.lblV0.Layout.Row = 2;
            comp.lblV0.Layout.Column = 1;
            comp.lblV0.Interpreter = 'tex';
            comp.lblV0.Text = 'v_0(m/s)';

            % Create lblB
            comp.lblB = uilabel(comp.fGrid);
            comp.lblB.Layout.Row = 1;
            comp.lblB.Layout.Column = 1;
            comp.lblB.Interpreter = 'tex';
            comp.lblB.Text = 'B(T)';

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
            %BINDCALLBACKS  统一绑定全部控件的 ValueChanged 回调
            % 设计意图：
            %   - 通过单入口 onAnyControlChanged 收敛所有参数变更逻辑
            %   - 便于后续新增控件时保持一致行为
            controls = {
                comp.BField, comp.V0Field, comp.ThetaField, comp.BdirDropDown, ...
                comp.QField, comp.MField, comp.XParticleField, comp.YParticleField, ...
                comp.UnitModeDropDown, comp.ParticleTypeDropDown, ...
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
            %ONANYCONTROLCHANGED  任意控件变化时的统一入口
            % 流程：
            %   1) 若当前处于 setPayload 写回期，直接返回（防重入）
            %   2) 从 UI 采集并归一化 payload
            %   3) 同步边界输入启用状态并派发 PayloadChanged 事件
            if comp.IsApplyingPayload
                return;
            end
            comp.Value = comp.collectPayloadFromUi();
            comp.updateBoundsEnable(comp.Value.bounded);
            notify(comp, 'PayloadChanged');
        end

        function payload = collectPayloadFromUi(comp)
            %COLLECTPAYLOADFROMUI  采集控件值并组装为 payload
            % 说明：
            %   - 仅做“读取+映射”；合法性修正交给 normalizePayload
            %   - speedScale 当前无独立 UI 控件，先固定为 1.0
            payload = struct();
            payload.q = comp.QField.Value;
            payload.m = comp.MField.Value;
            payload.B = comp.BField.Value;
            payload.v0 = comp.V0Field.Value;
            payload.thetaDeg = comp.ThetaField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.x0 = comp.XParticleField.Value;
            payload.y0 = comp.YParticleField.Value;
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
            payload.unitMode = comp.unitModeFromUiValue(comp.UnitModeDropDown.Value);
            payload.particleType = comp.particleTypeFromUiValue(comp.ParticleTypeDropDown.Value);
            payload.speedScale = 1.0;
            payload = comp.normalizePayload(payload);
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将 payload 分发写入各个控件
            % 实现细节：
            %   - 先 normalize，确保写回值始终合法
            %   - 使用 IsApplyingPayload 防止写回触发回调形成循环
            payload = comp.normalizePayload(payload);
            comp.IsApplyingPayload = true;
            try
                comp.QField.Value = payload.q;
                comp.MField.Value = payload.m;
                comp.BField.Value = payload.B;
                comp.V0Field.Value = payload.v0;
                comp.ThetaField.Value = payload.thetaDeg;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.XParticleField.Value = payload.x0;
                comp.YParticleField.Value = payload.y0;
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
                comp.UnitModeDropDown.Value = comp.unitModeToUiValue(payload.unitMode);
                comp.ParticleTypeDropDown.Value = comp.particleTypeToUiValue(payload.particleType);

                comp.updateBoundsEnable(payload.bounded);
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

        function payload = normalizePayload(comp, in)
            %NORMALIZEPAYLOAD  参数合并与类型归一化（组件内防御层）
            % 规则：
            %   1) 先与 defaultPayload 合并，补齐缺失字段
            %   2) 按字段类型做转换与裁剪
            %   3) 自动修正边界顺序并派生 vx0/vy0
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

            payload.q = comp.toDouble(payload.q, base.q);
            payload.m = max(comp.toDouble(payload.m, base.m), 1e-9);
            payload.B = max(comp.toDouble(payload.B, base.B), 0);
            payload.v0 = max(comp.toDouble(payload.v0, base.v0), 0);
            payload.thetaDeg = comp.toDouble(payload.thetaDeg, base.thetaDeg);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], base.Bdir);
            payload.x0 = comp.toDouble(payload.x0, base.x0);
            payload.y0 = comp.toDouble(payload.y0, base.y0);
            payload.bounded = comp.toLogical(payload.bounded, base.bounded);
            payload.xMin = comp.toDouble(payload.xMin, base.xMin);
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            payload.yMin = comp.toDouble(payload.yMin, base.yMin);
            payload.yMax = comp.toDouble(payload.yMax, base.yMax);
            payload.showTrail = comp.toLogical(payload.showTrail, base.showTrail);
            payload.showV = comp.toLogical(payload.showV, base.showV);
            payload.showF = comp.toLogical(payload.showF, base.showF);
            payload.showGrid = comp.toLogical(payload.showGrid, base.showGrid);
            payload.showBMarks = comp.toLogical(payload.showBMarks, base.showBMarks);
            payload.unitMode = comp.normalizeEnum(payload.unitMode, ["SI","particle"], base.unitMode);
            payload.particleType = comp.normalizeEnum(payload.particleType, ["custom","electron","proton"], base.particleType);
            payload.speedScale = max(0.25, min(4, comp.toDouble(payload.speedScale, base.speedScale)));

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

            thetaRad = deg2rad(payload.thetaDeg);
            payload.vx0 = payload.v0 * cos(thetaRad);
            payload.vy0 = payload.v0 * sin(thetaRad);
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  组件默认参数（与 M1 最小闭环保持一致）
            payload = struct( ...
                'q', 1.0, ...
                'm', 1.0, ...
                'B', 1.0, ...
                'v0', 0.8, ...
                'thetaDeg', 0.0, ...
                'Bdir', "out", ...
                'x0', 0.0, ...
                'y0', 0.8, ...
                'bounded', false, ...
                'xMin', -1.0, ...
                'xMax', 1.0, ...
                'yMin', -1.0, ...
                'yMax', 1.0, ...
                'showTrail', true, ...
                'showV', true, ...
                'showF', false, ...
                'showGrid', true, ...
                'showBMarks', true, ...
                'unitMode', "SI", ...
                'particleType', "custom", ...
                'speedScale', 1.0, ...
                'vx0', 0.8, ...
                'vy0', 0.0 ...
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

        function v = boolToOnOff(~, tf)
            %BOOLTOONOFF  布尔值转 MATLAB UI 的 Enable 状态字符串
            if tf
                v = 'on';
            else
                v = 'off';
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

        function key = unitModeFromUiValue(~, uiVal)
            %UNITMODEFROMUIVALUE  UI 文案 -> 单位模式键（SI/particle）
            s = strtrim(string(uiVal));
            if s == "粒子单位(e, me)"
                key = "particle";
            else
                key = "SI";
            end
        end

        function uiVal = unitModeToUiValue(~, key)
            %UNITMODETOUIVALUE  单位模式键（SI/particle）-> UI 文案
            if strcmpi(string(key), "particle")
                uiVal = '粒子单位(e, me)';
            else
                uiVal = 'SI单位(C, kg)';
            end
        end

        function key = particleTypeFromUiValue(~, uiVal)
            %PARTICLETYPEFROMUIVALUE  UI 文案 -> 粒子类型键
            s = strtrim(string(uiVal));
            switch s
                case "电子"
                    key = "electron";
                case "质子"
                    key = "proton";
                otherwise
                    key = "custom";
            end
        end

        function uiVal = particleTypeToUiValue(~, key)
            %PARTICLETYPETOUIVALUE  粒子类型键 -> UI 文案
            switch lower(string(key))
                case "electron"
                    uiVal = '电子';
                case "proton"
                    uiVal = '质子';
                otherwise
                    uiVal = '自定义';
            end
        end
    end
end



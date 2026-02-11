classdef M4_for_test < matlab.ui.componentcontainer.ComponentContainer
    %M4_FOR_TEST  M4 速度选择器参数组件（交叉场）
    %
    % 组件职责
    %   1) 提供 M4 参数 UI，并维护统一 payload 接口
    %   2) 对外暴露 Value/getPayload/setPayload/PayloadChanged
    %   3) 仅处理 UI 与参数映射，不承载物理推进
    %
    % 设计说明
    %   - 当前 UI 里保留 DField 命名，但语义映射为 Ey（电场强度）
    %   - 极板间距 plateGap 由 payload 保留，可后续在 mlapp 中补独立输入

    properties (Access = public)
        % Value - 对外统一参数结构
        Value struct = struct()
    end

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

        IsApplyingPayload     logical = false
    end

    events
        % PayloadChanged - 参数变更事件
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
            %SETPAYLOAD  写入参数并刷新 UI
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
            %SETOUTPUTS  输出区增量接口（当前组件无独立输出控件）
            if nargin < 2 || ~isstruct(outputs)
                return;
            end
            payload = comp.Value;
            if ~isstruct(payload) || isempty(fieldnames(payload))
                payload = comp.defaultPayload();
            end
            if isfield(outputs, 'qOverMOut')
                payload.qOverMOut = outputs.qOverMOut;
            end
            comp.Value = comp.normalizePayload(payload, comp.Value);
        end
    end

    methods (Access = protected)
        function update(comp)
            %UPDATE  公开属性 Value 改变时同步到底层控件
            payload = comp.normalizePayload(comp.Value, comp.Value);
            comp.Value = payload;
            if comp.isUiReady()
                comp.applyPayloadToUi(payload);
            end
        end

        function setup(comp)
            %SETUP  创建底层 UI，并绑定统一回调
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

            comp.YParticleField = uieditfield(comp.pGrid, 'numeric');
            comp.YParticleField.Layout.Row = 6;
            comp.YParticleField.Layout.Column = 2;

            comp.XParticleField = uieditfield(comp.pGrid, 'numeric');
            comp.XParticleField.Layout.Row = 5;
            comp.XParticleField.Layout.Column = 2;

            comp.MField = uieditfield(comp.pGrid, 'numeric');
            comp.MField.Layout.Row = 4;
            comp.MField.Layout.Column = 2;

            comp.QField = uieditfield(comp.pGrid, 'numeric');
            comp.QField.Layout.Row = 3;
            comp.QField.Layout.Column = 2;

            comp.ParticleTypeDropDown = uidropdown(comp.pGrid);
            comp.ParticleTypeDropDown.Items = {'自定义', '电子', '质子'};
            comp.ParticleTypeDropDown.Layout.Row = 2;
            comp.ParticleTypeDropDown.Layout.Column = 2;
            comp.ParticleTypeDropDown.Value = '自定义';

            comp.UnitModeDropDown = uidropdown(comp.pGrid);
            comp.UnitModeDropDown.Items = {'SI单位(C, kg)', '粒子单位(e, me)'};
            comp.UnitModeDropDown.Layout.Row = 1;
            comp.UnitModeDropDown.Layout.Column = 2;
            comp.UnitModeDropDown.Value = 'SI单位(C, kg)';

            comp.YLabel = uilabel(comp.pGrid);
            comp.YLabel.Layout.Row = 6;
            comp.YLabel.Layout.Column = 1;
            comp.YLabel.Interpreter = 'tex';
            comp.YLabel.Text = 'Y(m)';

            comp.XLabel = uilabel(comp.pGrid);
            comp.XLabel.Layout.Row = 5;
            comp.XLabel.Layout.Column = 1;
            comp.XLabel.Interpreter = 'tex';
            comp.XLabel.Text = 'X(m)';

            comp.MLabel = uilabel(comp.pGrid);
            comp.MLabel.Layout.Row = 4;
            comp.MLabel.Layout.Column = 1;
            comp.MLabel.Interpreter = 'tex';
            comp.MLabel.Text = 'm(kg)';

            comp.QLabel = uilabel(comp.pGrid);
            comp.QLabel.Layout.Row = 3;
            comp.QLabel.Layout.Column = 1;
            comp.QLabel.Interpreter = 'tex';
            comp.QLabel.Text = 'q(C)';

            comp.lblParticleType = uilabel(comp.pGrid);
            comp.lblParticleType.Layout.Row = 2;
            comp.lblParticleType.Layout.Column = 1;
            comp.lblParticleType.Text = '粒子类型';

            comp.UnitModeLabel = uilabel(comp.pGrid);
            comp.UnitModeLabel.Layout.Row = 1;
            comp.UnitModeLabel.Layout.Column = 1;
            comp.UnitModeLabel.Text = '单位模式';

            comp.lblV0 = uilabel(comp.pGrid);
            comp.lblV0.Layout.Row = 7;
            comp.lblV0.Layout.Column = 1;
            comp.lblV0.Interpreter = 'tex';
            comp.lblV0.Text = 'v_0(m/s)';

            comp.V0Field = uieditfield(comp.pGrid, 'numeric');
            comp.V0Field.Layout.Row = 7;
            comp.V0Field.Layout.Column = 2;

            comp.Dlabel = uilabel(comp.pGrid);
            comp.Dlabel.Layout.Row = 8;
            comp.Dlabel.Layout.Column = 1;
            comp.Dlabel.Interpreter = 'tex';
            comp.Dlabel.Text = 'E_y(V/m)';

            comp.DField = uieditfield(comp.pGrid, 'numeric');
            comp.DField.Layout.Row = 8;
            comp.DField.Layout.Column = 2;

            % Create FieldPanel
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

            % Create ViewPanel
            comp.ViewPanel = uipanel(comp.paramGrid);
            comp.ViewPanel.Title = '显示';
            comp.ViewPanel.Layout.Row = 3;
            comp.ViewPanel.Layout.Column = 1;

            comp.vGrid = uigridlayout(comp.ViewPanel);
            comp.vGrid.ColumnWidth = {'1x', '1x', '1x'};
            comp.vGrid.RowHeight = {'fit', 'fit'};

            comp.ShowBMarksCheck = uicheckbox(comp.vGrid);
            comp.ShowBMarksCheck.Text = 'B 标记';
            comp.ShowBMarksCheck.Layout.Row = 2;
            comp.ShowBMarksCheck.Layout.Column = 2;
            comp.ShowBMarksCheck.Value = true;

            comp.ShowGridCheck = uicheckbox(comp.vGrid);
            comp.ShowGridCheck.Text = '网格';
            comp.ShowGridCheck.Layout.Row = 2;
            comp.ShowGridCheck.Layout.Column = 1;
            comp.ShowGridCheck.Value = true;

            comp.ShowFmagCheck = uicheckbox(comp.vGrid);
            comp.ShowFmagCheck.Text = '磁场力箭头';
            comp.ShowFmagCheck.Layout.Row = 1;
            comp.ShowFmagCheck.Layout.Column = 3;

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

            comp.ShowFelcCheck = uicheckbox(comp.vGrid);
            comp.ShowFelcCheck.Text = '电场力箭头';
            comp.ShowFelcCheck.Layout.Row = 2;
            comp.ShowFelcCheck.Layout.Column = 3;

            comp.Value = comp.defaultPayload();
            comp.applyPayloadToUi(comp.Value);
            comp.bindCallbacks();
        end
    end

    methods (Access = private)
        function tf = isUiReady(comp)
            %ISUIREADY  判断底层控件是否已创建
            tf = ~isempty(comp.paramGrid) && isvalid(comp.paramGrid);
        end

        function bindCallbacks(comp)
            %BINDCALLBACKS  统一绑定 ValueChanged 回调
            controls = {
                comp.BField, comp.BdirDropDown, ...
                comp.QField, comp.MField, comp.XParticleField, comp.YParticleField, ...
                comp.UnitModeDropDown, comp.ParticleTypeDropDown, ...
                comp.V0Field, comp.DField, ...
                comp.ShowTrailCheck, comp.ShowVCheck, comp.ShowFmagCheck, ...
                comp.ShowFelcCheck, comp.ShowGridCheck, comp.ShowBMarksCheck ...
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
            %ONANYCONTROLCHANGED  任意参数变化统一入口
            if comp.IsApplyingPayload
                return;
            end
            prev = comp.Value;
            comp.Value = comp.collectPayloadFromUi(prev);
            comp.applyPayloadToUi(comp.Value);
            notify(comp, 'PayloadChanged');
        end

        function payload = collectPayloadFromUi(comp, previousPayload)
            %COLLECTPAYLOADFROMUI  从控件读取参数并归一化
            if nargin < 2 || ~isstruct(previousPayload)
                previousPayload = comp.Value;
            end

            payload = struct();
            payload.templateId = "M4";
            payload.modelType = "selector";
            payload.q = comp.QField.Value;
            payload.m = comp.MField.Value;
            payload.B = comp.BField.Value;
            payload.Bdir = comp.bdirFromUiValue(comp.BdirDropDown.Value);
            payload.v0 = comp.V0Field.Value;
            payload.thetaDeg = 0.0;
            payload.Ey = comp.DField.Value;
            payload.x0 = comp.XParticleField.Value;
            payload.y0 = comp.YParticleField.Value;
            payload.showTrail = comp.ShowTrailCheck.Value;
            payload.showV = comp.ShowVCheck.Value;
            payload.showFMag = comp.ShowFmagCheck.Value;
            payload.showFElec = comp.ShowFelcCheck.Value;
            payload.showGrid = comp.ShowGridCheck.Value;
            payload.showBMarks = comp.ShowBMarksCheck.Value;
            payload.showEField = true;
            payload.showF = payload.showFMag || payload.showFElec;
            payload.unitMode = comp.unitModeFromUiValue(comp.UnitModeDropDown.Value);
            payload.particleType = comp.particleTypeFromUiValue(comp.ParticleTypeDropDown.Value);

            % 无独立控件字段沿用旧值
            payload.plateGap = pickField(previousPayload, 'plateGap', 1.2);
            payload.bounded = pickField(previousPayload, 'bounded', true);
            payload.xMin = pickField(previousPayload, 'xMin', -1.0);
            payload.xMax = pickField(previousPayload, 'xMax', 1.0);
            payload.yMin = pickField(previousPayload, 'yMin', -0.6);
            payload.yMax = pickField(previousPayload, 'yMax', 0.6);
            payload.autoFollow = pickField(previousPayload, 'autoFollow', false);
            payload.followSpan = pickField(previousPayload, 'followSpan', 6.0);
            payload.maxSpan = pickField(previousPayload, 'maxSpan', 30.0);
            payload.speedScale = pickField(previousPayload, 'speedScale', 1.0);
            payload.qOverMOut = pickField(previousPayload, 'qOverMOut', 1.0);

            payload = comp.normalizePayload(payload, previousPayload);
        end

        function applyPayloadToUi(comp, payload)
            %APPLYPAYLOADTOUI  将 payload 写回到控件
            payload = comp.normalizePayload(payload, comp.Value);
            comp.IsApplyingPayload = true;
            try
                comp.QField.Value = payload.q;
                comp.MField.Value = payload.m;
                comp.BField.Value = payload.B;
                comp.BdirDropDown.Value = comp.bdirToUiValue(payload.Bdir);
                comp.V0Field.Value = payload.v0;
                comp.DField.Value = payload.Ey;
                comp.XParticleField.Value = payload.x0;
                comp.YParticleField.Value = payload.y0;
                comp.ShowTrailCheck.Value = payload.showTrail;
                comp.ShowVCheck.Value = payload.showV;
                comp.ShowFmagCheck.Value = payload.showFMag;
                comp.ShowFelcCheck.Value = payload.showFElec;
                comp.ShowGridCheck.Value = payload.showGrid;
                comp.ShowBMarksCheck.Value = payload.showBMarks;
                comp.UnitModeDropDown.Value = comp.unitModeToUiValue(payload.unitMode);
                comp.ParticleTypeDropDown.Value = comp.particleTypeToUiValue(payload.particleType);
                comp.updateChargeMassLabels(payload.unitMode);
            catch err
                comp.IsApplyingPayload = false;
                rethrow(err);
            end
            comp.IsApplyingPayload = false;
        end

        function payload = normalizePayload(comp, in, previousPayload)
            %NORMALIZEPAYLOAD  参数类型修正、联动与派生
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

            prevUnitMode = base.unitMode;
            prevParticleType = base.particleType;
            if isfield(previousPayload, 'unitMode')
                prevUnitMode = comp.normalizeEnum(previousPayload.unitMode, ["SI","particle"], base.unitMode);
            end
            if isfield(previousPayload, 'particleType')
                prevParticleType = comp.normalizeEnum(previousPayload.particleType, ["custom","electron","proton"], base.particleType);
            end

            payload.templateId = "M4";
            payload.modelType = "selector";
            payload.unitMode = comp.normalizeEnum(payload.unitMode, ["SI","particle"], base.unitMode);
            payload.particleType = comp.normalizeEnum(payload.particleType, ["custom","electron","proton"], base.particleType);
            payload.q = comp.toDouble(payload.q, base.q);
            payload.m = max(comp.toDouble(payload.m, base.m), 1e-9);
            payload.B = max(comp.toDouble(payload.B, base.B), 0.0);
            payload.Bdir = comp.normalizeEnum(payload.Bdir, ["out","in"], base.Bdir);
            payload.Ey = comp.toDouble(payload.Ey, base.Ey);
            payload.v0 = max(comp.toDouble(payload.v0, base.v0), 0.0);
            payload.thetaDeg = 0.0;
            payload.x0 = comp.toDouble(payload.x0, base.x0);
            payload.y0 = comp.toDouble(payload.y0, base.y0);
            payload.plateGap = max(comp.toDouble(payload.plateGap, base.plateGap), 0.05);
            payload.bounded = true;
            payload.xMin = comp.toDouble(payload.xMin, base.xMin);
            payload.xMax = comp.toDouble(payload.xMax, base.xMax);
            payload.showTrail = comp.toLogical(payload.showTrail, base.showTrail);
            payload.showV = comp.toLogical(payload.showV, base.showV);
            payload.showFMag = comp.toLogical(payload.showFMag, base.showFMag);
            payload.showFElec = comp.toLogical(payload.showFElec, base.showFElec);
            payload.showF = comp.toLogical(payload.showF, base.showF) || payload.showFMag || payload.showFElec;
            payload.showGrid = comp.toLogical(payload.showGrid, base.showGrid);
            payload.showBMarks = comp.toLogical(payload.showBMarks, base.showBMarks);
            payload.showEField = comp.toLogical(payload.showEField, base.showEField);
            payload.autoFollow = comp.toLogical(payload.autoFollow, base.autoFollow);
            payload.followSpan = max(0.5, min(40.0, comp.toDouble(payload.followSpan, base.followSpan)));
            payload.maxSpan = max(2.0, min(200.0, comp.toDouble(payload.maxSpan, base.maxSpan)));
            payload.speedScale = max(0.25, min(4.0, comp.toDouble(payload.speedScale, base.speedScale)));

            payload = comp.applyUnitParticleRules(payload, prevUnitMode, prevParticleType);
            payload.m = max(payload.m, 1e-9);

            if payload.xMin > payload.xMax
                t = payload.xMin;
                payload.xMin = payload.xMax;
                payload.xMax = t;
            end
            if payload.xMax <= payload.xMin + 1e-6
                payload.xMax = payload.xMin + 1.0;
            end

            halfGap = 0.5 * payload.plateGap;
            payload.yMin = payload.y0 - halfGap;
            payload.yMax = payload.y0 + halfGap;

            thetaRad = deg2rad(payload.thetaDeg);
            payload.vx0 = payload.v0 * cos(thetaRad);
            payload.vy0 = payload.v0 * sin(thetaRad);
            payload.qOverMOut = payload.q / payload.m;
        end

        function payload = applyUnitParticleRules(comp, payload, prevUnitMode, prevParticleType)
            %APPLYUNITPARTICLERULES  与 M1 保持一致的单位/粒子联动
            if payload.particleType ~= "custom"
                payload.unitMode = "particle";
            end

            unitModeChanged = payload.unitMode ~= prevUnitMode;
            particleTypeChanged = payload.particleType ~= prevParticleType;

            if payload.unitMode ~= "particle"
                return;
            end

            switch payload.particleType
                case "electron"
                    [payload.q, payload.m] = comp.particlePreset("electron");
                case "proton"
                    [payload.q, payload.m] = comp.particlePreset("proton");
                otherwise
                    if unitModeChanged || (particleTypeChanged && prevParticleType ~= "custom")
                        [payload.q, payload.m] = comp.particlePreset("custom");
                    end
            end
        end

        function [qVal, mVal] = particlePreset(~, particleType)
            %PARTICLEPRESET  粒子单位下的 q/m 预设
            switch lower(string(particleType))
                case "electron"
                    qVal = -1.0;
                    mVal = 1.0;
                case "proton"
                    qVal = 1.0;
                    mVal = 1836.15267343;
                otherwise
                    qVal = 1.0;
                    mVal = 1.0;
            end
        end

        function payload = defaultPayload(~)
            %DEFAULTPAYLOAD  M4 默认参数
            payload = struct( ...
                'templateId', "M4", ...
                'modelType', "selector", ...
                'q', 1.0, ...
                'm', 1.0, ...
                'B', 1.0, ...
                'Bdir', "out", ...
                'Ey', 1.0, ...
                'plateGap', 1.2, ...
                'v0', 1.2, ...
                'thetaDeg', 0.0, ...
                'x0', -1.2, ...
                'y0', 0.0, ...
                'bounded', true, ...
                'xMin', -1.0, ...
                'xMax', 1.0, ...
                'yMin', -0.6, ...
                'yMax', 0.6, ...
                'showTrail', true, ...
                'showV', true, ...
                'showF', false, ...
                'showGrid', true, ...
                'showBMarks', true, ...
                'showEField', true, ...
                'showFElec', false, ...
                'showFMag', false, ...
                'autoFollow', false, ...
                'followSpan', 6.0, ...
                'maxSpan', 30.0, ...
                'unitMode', "SI", ...
                'particleType', "custom", ...
                'speedScale', 1.0, ...
                'vx0', 1.2, ...
                'vy0', 0.0, ...
                'qOverMOut', 1.0 ...
            );
        end

        function v = normalizeEnum(~, vRaw, options, defaultValue)
            %NORMALIZEENUM  枚举值归一化
            s = strtrim(string(vRaw));
            idx = find(strcmpi(string(options), s), 1, 'first');
            if isempty(idx)
                v = string(defaultValue);
            else
                v = string(options(idx));
            end
        end

        function v = toDouble(~, vRaw, defaultValue)
            %TODOUBLE  转换为有限 double
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
            %TOLOGICAL  转换为 logical
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

        function updateChargeMassLabels(comp, unitMode)
            %UPDATECHARGEMASSLABELS  单位模式切换时更新 q/m 标签
            if strcmpi(string(unitMode), "particle")
                qText = 'q(e)';
                mText = 'm(me)';
            else
                qText = 'q(C)';
                mText = 'm(kg)';
            end
            if ~isempty(comp.QLabel) && isvalid(comp.QLabel)
                comp.QLabel.Text = qText;
            end
            if ~isempty(comp.MLabel) && isvalid(comp.MLabel)
                comp.MLabel.Text = mText;
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

        function key = unitModeFromUiValue(~, uiVal)
            %UNITMODEFROMUIVALUE  UI 文案 -> SI/particle
            if strtrim(string(uiVal)) == "粒子单位(e, me)"
                key = "particle";
            else
                key = "SI";
            end
        end

        function uiVal = unitModeToUiValue(~, key)
            %UNITMODETOUIVALUE  SI/particle -> UI 文案
            if strcmpi(string(key), "particle")
                uiVal = '粒子单位(e, me)';
            else
                uiVal = 'SI单位(C, kg)';
            end
        end

        function key = particleTypeFromUiValue(~, uiVal)
            %PARTICLETYPEFROMUIVALUE  UI 文案 -> 粒子类型键
            switch strtrim(string(uiVal))
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

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

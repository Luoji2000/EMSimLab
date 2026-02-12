function renderPlots(app, state)
%% 入口：曲线渲染主流程
%RENDERPLOTS  曲线渲染入口（R 系列兼容 + R8/R5 专用子图）
%
% 渲染策略
%   1) 非导轨模型：显示占位提示
%   2) R8：2x2 子图，绘制 v / I / Phi / Fmag
%   3) R5：3x2 子图，绘制 A/B/中心量、电学量与热量量
%   4) 其余 R 模型：沿用 v / I / Fmag（三子图）
%   4) 曲线历史在 UI 层缓存，检测到时间回退自动清空
%
% 说明
%   - 按用户要求，不在标题显示实时数值
%   - 每个子图保留 y=0 参考线，便于观察正负切换

if ~(isprop(app, 'plotsGrid') && isLiveHandle(app.plotsGrid))
    return;
end

params = readParams(app);
modelType = resolveModelType(params, state);

if modelType ~= "rail"
    [handles, cache] = ensurePlotHandles(app, "rail");
    msg = "当前模板暂不绘制导轨曲线";
    if modelType == "selector"
        msg = "M4 曲线待接入（可后续启用 y(t)/F_y(t)）";
    end
    cache = clearHistoryAndShowMessage(handles, cache, msg);
    writePlotCache(app, cache);
    return;
end

isR8 = isR8Template(params, state);
if isR8
    [handles, cache] = ensurePlotHandles(app, "r8");
    sample = buildHistorySample(params, state, true);
    cache = appendHistory(cache, sample);
    cache = drawCurves(handles, cache, "r8");
    writePlotCache(app, cache);
    return;
end

isR5 = isR5Template(params, state);
if isR5
    [handles, cache] = ensurePlotHandles(app, "r5");
    sample = buildR5HistorySample(params, state);
    cache = appendR5History(cache, sample);
    cache = drawR5Curves(handles, cache);
    writePlotCache(app, cache);
    return;
end

% R2 场景判定：只要“有外力驱动开关”为真，就按非 R1 场景处理
isDriveScene = logicalField(params, 'driveEnabled', false);
if ~isDriveScene
    [handles, cache] = ensurePlotHandles(app, "rail");
    cache = clearHistoryAndShowMessage(handles, cache, "R1 场景暂不绘制曲线");
    writePlotCache(app, cache);
    return;
end

[handles, cache] = ensurePlotHandles(app, "rail");
sample = buildHistorySample(params, state, false);
cache = appendHistory(cache, sample);
cache = drawCurves(handles, cache, "rail");
writePlotCache(app, cache);
end

%% 参数读取与模型判定
function params = readParams(app)
%READPARAMS  安全读取 app.Params
params = struct();
if isprop(app, 'Params') && isstruct(app.Params)
    params = app.Params;
end
end

function modelType = resolveModelType(params, state)
%RESOLVEMODELTYPE  解析模型类型（particle/selector/rail）
modelType = lower(strtrim(string(pickField(params, 'modelType', pickField(state, 'modelType', "particle")))));
if startsWith(modelType, "rail")
    modelType = "rail";
elseif startsWith(modelType, "selector")
    modelType = "selector";
else
    modelType = "particle";
end
end

function tf = isR8Template(params, state)
%ISR8TEMPLATE  判断当前模板是否 R8（线框模型）
token = upper(strtrim(string(pickField(params, 'templateId', pickField(state, 'templateId', "")))));
tf = token == "R8";
end

function tf = isR5Template(params, state)
%ISR5TEMPLATE  判断当前模板是否 R5（双导体棒）
token = upper(strtrim(string(pickField(params, 'templateId', pickField(state, 'templateId', "")))));
tf = token == "R5";
end

%% 曲线句柄与缓存管理
function [handles, cache] = ensurePlotHandles(app, layoutKind)
%ENSUREPLOTHANDLES  确保目标布局的曲线坐标轴与句柄已创建
%
% 输入
%   layoutKind : "rail"（三子图）或 "r8"（2x2 子图）

cache = readPlotCache(app);

if isprop(app, 'PlotsAxes') && isLiveHandle(app.PlotsAxes)
    app.PlotsAxes.Visible = 'off';
end

if isempty(cache) || ~isstruct(cache)
    cache = defaultPlotCache();
end
cache = fillMissingCacheFields(cache);

needCreate = true;
if isfield(cache, 'layoutKind') && string(cache.layoutKind) == string(layoutKind)
    needCreate = ~requiredHandlesAlive(cache, layoutKind);
end

if needCreate
    delete(app.plotsGrid.Children);
    cache = defaultPlotCache();
    cache.layoutKind = string(layoutKind);

    switch layoutKind
        case "r5"
            app.plotsGrid.RowHeight = {'1x', '1x', '1x'};
            app.plotsGrid.ColumnWidth = {'1x', '1x'};

            cache.hAxXA = uiaxes(app.plotsGrid);
            cache.hAxXA.Layout.Row = 1;
            cache.hAxXA.Layout.Column = 1;

            cache.hAxVA = uiaxes(app.plotsGrid);
            cache.hAxVA.Layout.Row = 1;
            cache.hAxVA.Layout.Column = 2;

            cache.hAxI = uiaxes(app.plotsGrid);
            cache.hAxI.Layout.Row = 2;
            cache.hAxI.Layout.Column = 1;

            cache.hAxPhi = uiaxes(app.plotsGrid);
            cache.hAxPhi.Layout.Row = 2;
            cache.hAxPhi.Layout.Column = 2;

            cache.hAxF = uiaxes(app.plotsGrid);
            cache.hAxF.Layout.Row = 3;
            cache.hAxF.Layout.Column = 1;

            cache.hAxQ = uiaxes(app.plotsGrid);
            cache.hAxQ.Layout.Row = 3;
            cache.hAxQ.Layout.Column = 2;

            styleAxis(cache.hAxXA, 'x(t)', '位置 x (m)', '');
            styleAxis(cache.hAxVA, 'v(t)', '速度 v (m/s)', '');
            styleAxis(cache.hAxI, 'I(t)', '电流 I (A)', '时间 t (s)');
            styleAxis(cache.hAxPhi, '\epsilon(t)', '电动势 \epsilon (V)', '时间 t (s)');
            styleAxis(cache.hAxF, 'F_{mag}(t)', '安培力 F_{mag} (N)', '时间 t (s)');
            styleAxis(cache.hAxQ, 'Q(t)', '热量 Q (J)', '时间 t (s)');

            cache.hLineXA = line('Parent', cache.hAxXA, 'XData', NaN, 'YData', NaN, 'Color', [0.92, 0.25, 0.18], 'LineWidth', 1.8);
            cache.hLineXB = line('Parent', cache.hAxXA, 'XData', NaN, 'YData', NaN, 'Color', [0.15, 0.55, 0.92], 'LineWidth', 1.8);
            cache.hLineXC = line('Parent', cache.hAxXA, 'XData', NaN, 'YData', NaN, 'Color', [0.35, 0.35, 0.35], 'LineStyle', '--', 'LineWidth', 1.4);

            cache.hLineVA = line('Parent', cache.hAxVA, 'XData', NaN, 'YData', NaN, 'Color', [0.92, 0.25, 0.18], 'LineWidth', 1.8);
            cache.hLineVB = line('Parent', cache.hAxVA, 'XData', NaN, 'YData', NaN, 'Color', [0.15, 0.55, 0.92], 'LineWidth', 1.8);
            cache.hLineVC = line('Parent', cache.hAxVA, 'XData', NaN, 'YData', NaN, 'Color', [0.35, 0.35, 0.35], 'LineStyle', '--', 'LineWidth', 1.4);

            cache.hLineI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.16, 0.53, 0.92], 'LineWidth', 1.8);
            cache.hLinePhi = line('Parent', cache.hAxPhi, 'XData', NaN, 'YData', NaN, 'Color', [0.11, 0.64, 0.52], 'LineWidth', 1.8);

            cache.hLineFA = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.88, 0.30, 0.20], 'LineWidth', 1.6);
            cache.hLineFB = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.22, 0.56, 0.92], 'LineWidth', 1.6);
            cache.hLineF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.42, 0.24, 0.80], 'LineWidth', 2.0);

            cache.hLineQR = line('Parent', cache.hAxQ, 'XData', NaN, 'YData', NaN, 'Color', [0.95, 0.56, 0.16], 'LineWidth', 1.6);
            cache.hLineQColl = line('Parent', cache.hAxQ, 'XData', NaN, 'YData', NaN, 'Color', [0.12, 0.63, 0.35], 'LineWidth', 1.6);
            cache.hLineQ = line('Parent', cache.hAxQ, 'XData', NaN, 'YData', NaN, 'Color', [0.20, 0.20, 0.20], 'LineWidth', 2.0);

            cache.hZeroV = line('Parent', cache.hAxVA, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroPhi = line('Parent', cache.hAxPhi, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);

            cache.hMsgV = text(cache.hAxVA, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgI = text(cache.hAxI, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgPhi = text(cache.hAxPhi, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgF = text(cache.hAxF, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgQ = text(cache.hAxQ, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');

        case "r8"
            app.plotsGrid.RowHeight = {'1x', '1x'};
            app.plotsGrid.ColumnWidth = {'1x', '1x'};

            cache.hAxV = uiaxes(app.plotsGrid);
            cache.hAxV.Layout.Row = 1;
            cache.hAxV.Layout.Column = 1;

            cache.hAxI = uiaxes(app.plotsGrid);
            cache.hAxI.Layout.Row = 1;
            cache.hAxI.Layout.Column = 2;

            cache.hAxPhi = uiaxes(app.plotsGrid);
            cache.hAxPhi.Layout.Row = 2;
            cache.hAxPhi.Layout.Column = 1;

            cache.hAxF = uiaxes(app.plotsGrid);
            cache.hAxF.Layout.Row = 2;
            cache.hAxF.Layout.Column = 2;

            styleAxis(cache.hAxV, 'v(t)', '速度 v (m/s)', '');
            styleAxis(cache.hAxI, 'I(t)', '电流 I (A)', '');
            styleAxis(cache.hAxPhi, '\Phi(t)', '磁通量 \Phi (Wb)', '时间 t (s)');
            styleAxis(cache.hAxF, 'F_{mag}(t)', '安培力 F_{mag} (N)', '时间 t (s)');

            cache.hLineV = line('Parent', cache.hAxV, 'XData', NaN, 'YData', NaN, 'Color', [0.90, 0.26, 0.18], 'LineWidth', 1.8);
            cache.hLineI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.16, 0.53, 0.92], 'LineWidth', 1.8);
            cache.hLinePhi = line('Parent', cache.hAxPhi, 'XData', NaN, 'YData', NaN, 'Color', [0.11, 0.64, 0.52], 'LineWidth', 1.8);
            cache.hLineF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.42, 0.24, 0.80], 'LineWidth', 1.8);

            cache.hZeroV = line('Parent', cache.hAxV, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroPhi = line('Parent', cache.hAxPhi, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);

            cache.hMsgV = text(cache.hAxV, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgI = text(cache.hAxI, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgPhi = text(cache.hAxPhi, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgF = text(cache.hAxF, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
        otherwise
            app.plotsGrid.RowHeight = {'1x', '1x', '1x'};
            app.plotsGrid.ColumnWidth = {'1x'};

            cache.hAxV = uiaxes(app.plotsGrid);
            cache.hAxV.Layout.Row = 1;
            cache.hAxV.Layout.Column = 1;

            cache.hAxI = uiaxes(app.plotsGrid);
            cache.hAxI.Layout.Row = 2;
            cache.hAxI.Layout.Column = 1;

            cache.hAxF = uiaxes(app.plotsGrid);
            cache.hAxF.Layout.Row = 3;
            cache.hAxF.Layout.Column = 1;

            styleAxis(cache.hAxV, 'v(t)', '速度 v (m/s)', '');
            styleAxis(cache.hAxI, 'I(t)', '电流 I (A)', '');
            styleAxis(cache.hAxF, 'F_{mag}(t)', '安培力 F_{mag} (N)', '时间 t (s)');

            cache.hLineV = line('Parent', cache.hAxV, 'XData', NaN, 'YData', NaN, 'Color', [0.90, 0.26, 0.18], 'LineWidth', 1.8);
            cache.hLineI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.16, 0.53, 0.92], 'LineWidth', 1.8);
            cache.hLineF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.42, 0.24, 0.80], 'LineWidth', 1.8);

            cache.hZeroV = line('Parent', cache.hAxV, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroI = line('Parent', cache.hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);
            cache.hZeroF = line('Parent', cache.hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--', 'LineWidth', 1.0);

            cache.hMsgV = text(cache.hAxV, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgI = text(cache.hAxI, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
            cache.hMsgF = text(cache.hAxF, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
    end
end

handles = struct( ...
    'axXA', cache.hAxXA, ...
    'axVA', cache.hAxVA, ...
    'axQ', cache.hAxQ, ...
    'axV', cache.hAxV, ...
    'axI', cache.hAxI, ...
    'axPhi', cache.hAxPhi, ...
    'axF', cache.hAxF, ...
    'lineXA', cache.hLineXA, ...
    'lineXB', cache.hLineXB, ...
    'lineXC', cache.hLineXC, ...
    'lineVA', cache.hLineVA, ...
    'lineVB', cache.hLineVB, ...
    'lineVC', cache.hLineVC, ...
    'lineFA', cache.hLineFA, ...
    'lineFB', cache.hLineFB, ...
    'lineQR', cache.hLineQR, ...
    'lineQColl', cache.hLineQColl, ...
    'lineQ', cache.hLineQ, ...
    'lineV', cache.hLineV, ...
    'lineI', cache.hLineI, ...
    'linePhi', cache.hLinePhi, ...
    'lineF', cache.hLineF, ...
    'zeroV', cache.hZeroV, ...
    'zeroI', cache.hZeroI, ...
    'zeroPhi', cache.hZeroPhi, ...
    'zeroF', cache.hZeroF, ...
    'msgV', cache.hMsgV, ...
    'msgI', cache.hMsgI, ...
    'msgPhi', cache.hMsgPhi, ...
    'msgF', cache.hMsgF, ...
    'msgQ', cache.hMsgQ ...
);
end

function tf = requiredHandlesAlive(cache, layoutKind)
%REQUIREDHANDLESALIVE  判断当前缓存是否满足目标布局的句柄需求
switch layoutKind
    case "r5"
        tf = isLiveHandle(cache.hAxXA) && isLiveHandle(cache.hAxVA) && ...
             isLiveHandle(cache.hAxI) && isLiveHandle(cache.hAxPhi) && ...
             isLiveHandle(cache.hAxF) && isLiveHandle(cache.hAxQ) && ...
             isLiveHandle(cache.hLineXA) && isLiveHandle(cache.hLineXB) && isLiveHandle(cache.hLineXC) && ...
             isLiveHandle(cache.hLineVA) && isLiveHandle(cache.hLineVB) && isLiveHandle(cache.hLineVC) && ...
             isLiveHandle(cache.hLineI) && isLiveHandle(cache.hLinePhi) && ...
             isLiveHandle(cache.hLineFA) && isLiveHandle(cache.hLineFB) && isLiveHandle(cache.hLineF) && ...
             isLiveHandle(cache.hLineQR) && isLiveHandle(cache.hLineQColl) && isLiveHandle(cache.hLineQ) && ...
             isLiveHandle(cache.hMsgV) && isLiveHandle(cache.hMsgI) && ...
             isLiveHandle(cache.hMsgPhi) && isLiveHandle(cache.hMsgF) && isLiveHandle(cache.hMsgQ);
    case "r8"
        tf = isLiveHandle(cache.hAxV) && isLiveHandle(cache.hAxI) && ...
             isLiveHandle(cache.hAxPhi) && isLiveHandle(cache.hAxF) && ...
             isLiveHandle(cache.hLineV) && isLiveHandle(cache.hLineI) && ...
             isLiveHandle(cache.hLinePhi) && isLiveHandle(cache.hLineF) && ...
             isLiveHandle(cache.hMsgV) && isLiveHandle(cache.hMsgI) && ...
             isLiveHandle(cache.hMsgPhi) && isLiveHandle(cache.hMsgF);
    otherwise
        tf = isLiveHandle(cache.hAxV) && isLiveHandle(cache.hAxI) && isLiveHandle(cache.hAxF) && ...
             isLiveHandle(cache.hLineV) && isLiveHandle(cache.hLineI) && isLiveHandle(cache.hLineF) && ...
             isLiveHandle(cache.hMsgV) && isLiveHandle(cache.hMsgI) && isLiveHandle(cache.hMsgF);
end
end

function styleAxis(ax, ttl, yLabelText, xLabelText)
%STYLEAXIS  统一子图样式
cla(ax);
title(ax, ttl);
ylabel(ax, yLabelText);
xlabel(ax, xLabelText);
ax.XGrid = 'on';
ax.YGrid = 'on';
end

%% 历史追加与曲线绘制
function sample = buildHistorySample(params, state, needPhi)
%BUILDHISTORYSAMPLE  组装单个采样点
sample = struct();
sample.t = double(pickField(state, 't', NaN));
sample.step = double(pickField(state, 'stepCount', NaN));
sample.v = double(pickField(state, 'vx', 0.0));
sample.i = double(pickField(state, 'current', 0.0));
sample.f = double(pickField(state, 'fMag', 0.0));
if needPhi
    sample.phi = computeFrameFlux(params, state);
else
    sample.phi = NaN;
end
end

function sample = buildR5HistorySample(~, state)
%BUILDR5HISTORYSAMPLE  组装 R5 双棒曲线采样点
sample = struct();
sample.t = double(pickField(state, 't', NaN));
sample.step = double(pickField(state, 'stepCount', NaN));
sample.xA = double(pickField(state, 'xA', pickField(state, 'x', 0.0)));
sample.xB = double(pickField(state, 'xB', pickField(state, 'x', 0.0)));
sample.xC = double(pickField(state, 'xCenter', 0.5 * (sample.xA + sample.xB)));
sample.vA = double(pickField(state, 'vA', pickField(state, 'vx', 0.0)));
sample.vB = double(pickField(state, 'vB', pickField(state, 'vx', 0.0)));
sample.vC = double(pickField(state, 'vCenter', 0.5 * (sample.vA + sample.vB)));
sample.i = double(pickField(state, 'current', 0.0));
sample.eps = double(pickField(state, 'epsilon', 0.0));
sample.fA = double(pickField(state, 'fMagA', 0.0));
sample.fB = double(pickField(state, 'fMagB', 0.0));
sample.fS = double(pickField(state, 'fMag', 0.0));
sample.qR = double(pickField(state, 'qHeatR', pickField(state, 'qHeat', 0.0)));
sample.qColl = double(pickField(state, 'qHeatColl', pickField(state, 'qColl', 0.0)));
sample.qTotal = double(pickField(state, 'qHeat', sample.qR + sample.qColl));
end

function cache = appendHistory(cache, sample)
%APPENDHISTORY  追加单步数据到曲线历史
%
% 清空规则
%   - t 回退：视为重置
%   - stepCount 回退：视为重置
tNow = double(pickField(sample, 't', NaN));
if ~isScalarFinite(tNow)
    return;
end

stepNow = double(pickField(sample, 'step', NaN));
lastT = scalarOrNaN(pickField(cache, 'lastT', NaN));
lastStep = scalarOrNaN(pickField(cache, 'lastStep', NaN));
if (isScalarFinite(lastT) && tNow < lastT - 1e-12) || ...
   (isScalarFinite(lastStep) && isScalarFinite(stepNow) && stepNow < lastStep)
    cache.t = [];
    cache.v = [];
    cache.i = [];
    cache.f = [];
    cache.phi = [];
end

vNow = double(pickField(sample, 'v', 0.0));
iNow = double(pickField(sample, 'i', 0.0));
fNow = double(pickField(sample, 'f', 0.0));
phiNow = double(pickField(sample, 'phi', NaN));

if ~isempty(cache.t) && abs(tNow - cache.t(end)) <= 1e-12
    cache.v(end) = vNow;
    cache.i(end) = iNow;
    cache.f(end) = fNow;
    cache.phi(end) = phiNow;
else
    cache.t(end+1, 1) = tNow;
    cache.v(end+1, 1) = vNow;
    cache.i(end+1, 1) = iNow;
    cache.f(end+1, 1) = fNow;
    cache.phi(end+1, 1) = phiNow;
end

cache.lastT = tNow;
if isScalarFinite(stepNow)
    cache.lastStep = stepNow;
end

maxPoints = 5000;
if numel(cache.t) > maxPoints
    keepIdx = (numel(cache.t)-maxPoints+1):numel(cache.t);
    cache.t = cache.t(keepIdx);
    cache.v = cache.v(keepIdx);
    cache.i = cache.i(keepIdx);
    cache.f = cache.f(keepIdx);
    cache.phi = cache.phi(keepIdx);
end
end

function cache = appendR5History(cache, sample)
%APPENDR5HISTORY  追加 R5 双棒历史数据
tNow = double(pickField(sample, 't', NaN));
if ~isScalarFinite(tNow)
    return;
end

stepNow = double(pickField(sample, 'step', NaN));
lastT = scalarOrNaN(pickField(cache, 'lastT', NaN));
lastStep = scalarOrNaN(pickField(cache, 'lastStep', NaN));
if (isScalarFinite(lastT) && tNow < lastT - 1e-12) || ...
   (isScalarFinite(lastStep) && isScalarFinite(stepNow) && stepNow < lastStep)
    cache.t = [];
    cache.xA = [];
    cache.xB = [];
    cache.xC = [];
    cache.vA = [];
    cache.vB = [];
    cache.vC = [];
    cache.i = [];
    cache.eps = [];
    cache.fA = [];
    cache.fB = [];
    cache.f = [];
    cache.qR = [];
    cache.qColl = [];
    cache.qTotal = [];
end

if ~isempty(cache.t) && abs(tNow - cache.t(end)) <= 1e-12
    cache.xA(end) = double(pickField(sample, 'xA', 0.0));
    cache.xB(end) = double(pickField(sample, 'xB', 0.0));
    cache.xC(end) = double(pickField(sample, 'xC', 0.0));
    cache.vA(end) = double(pickField(sample, 'vA', 0.0));
    cache.vB(end) = double(pickField(sample, 'vB', 0.0));
    cache.vC(end) = double(pickField(sample, 'vC', 0.0));
    cache.i(end) = double(pickField(sample, 'i', 0.0));
    cache.eps(end) = double(pickField(sample, 'eps', 0.0));
    cache.fA(end) = double(pickField(sample, 'fA', 0.0));
    cache.fB(end) = double(pickField(sample, 'fB', 0.0));
    cache.f(end) = double(pickField(sample, 'fS', 0.0));
    cache.qR(end) = double(pickField(sample, 'qR', 0.0));
    cache.qColl(end) = double(pickField(sample, 'qColl', 0.0));
    cache.qTotal(end) = double(pickField(sample, 'qTotal', 0.0));
else
    cache.t(end+1, 1) = tNow;
    cache.xA(end+1, 1) = double(pickField(sample, 'xA', 0.0));
    cache.xB(end+1, 1) = double(pickField(sample, 'xB', 0.0));
    cache.xC(end+1, 1) = double(pickField(sample, 'xC', 0.0));
    cache.vA(end+1, 1) = double(pickField(sample, 'vA', 0.0));
    cache.vB(end+1, 1) = double(pickField(sample, 'vB', 0.0));
    cache.vC(end+1, 1) = double(pickField(sample, 'vC', 0.0));
    cache.i(end+1, 1) = double(pickField(sample, 'i', 0.0));
    cache.eps(end+1, 1) = double(pickField(sample, 'eps', 0.0));
    cache.fA(end+1, 1) = double(pickField(sample, 'fA', 0.0));
    cache.fB(end+1, 1) = double(pickField(sample, 'fB', 0.0));
    cache.f(end+1, 1) = double(pickField(sample, 'fS', 0.0));
    cache.qR(end+1, 1) = double(pickField(sample, 'qR', 0.0));
    cache.qColl(end+1, 1) = double(pickField(sample, 'qColl', 0.0));
    cache.qTotal(end+1, 1) = double(pickField(sample, 'qTotal', 0.0));
end

cache.lastT = tNow;
if isScalarFinite(stepNow)
    cache.lastStep = stepNow;
end

maxPoints = 5000;
if numel(cache.t) > maxPoints
    keepIdx = (numel(cache.t)-maxPoints+1):numel(cache.t);
    cache.t = cache.t(keepIdx);
    cache.xA = cache.xA(keepIdx);
    cache.xB = cache.xB(keepIdx);
    cache.xC = cache.xC(keepIdx);
    cache.vA = cache.vA(keepIdx);
    cache.vB = cache.vB(keepIdx);
    cache.vC = cache.vC(keepIdx);
    cache.i = cache.i(keepIdx);
    cache.eps = cache.eps(keepIdx);
    cache.fA = cache.fA(keepIdx);
    cache.fB = cache.fB(keepIdx);
    cache.f = cache.f(keepIdx);
    cache.qR = cache.qR(keepIdx);
    cache.qColl = cache.qColl(keepIdx);
    cache.qTotal = cache.qTotal(keepIdx);
end
end

function cache = drawCurves(handles, cache, layoutKind)
%DRAWCURVES  按布局绘制曲线
setIfLive(handles.msgV, 'Visible', 'off');
setIfLive(handles.msgI, 'Visible', 'off');
setIfLive(handles.msgF, 'Visible', 'off');
setIfLive(handles.msgPhi, 'Visible', 'off');

if isempty(cache.t)
    return;
end

maxDrawPoints = 1600;
[tDraw, vDraw, iDraw, fDraw, phiDraw] = tailHistory(cache.t, cache.v, cache.i, cache.f, cache.phi, maxDrawPoints);

setIfLive(handles.lineV, 'XData', tDraw, 'YData', vDraw, 'Visible', 'on');
setIfLive(handles.lineI, 'XData', tDraw, 'YData', iDraw, 'Visible', 'on');
setIfLive(handles.lineF, 'XData', tDraw, 'YData', fDraw, 'Visible', 'on');

if layoutKind == "r8"
    setIfLive(handles.linePhi, 'XData', tDraw, 'YData', phiDraw, 'Visible', 'on');
else
    setIfLive(handles.linePhi, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
end

xMin = tDraw(1);
xMax = tDraw(end);
if xMax <= xMin
    xMax = xMin + 1e-3;
end
xLim = [xMin, xMax];

if ~(isnumeric(cache.lastXLim) && numel(cache.lastXLim) == 2 && all(isfinite(cache.lastXLim)) ...
        && all(abs(cache.lastXLim - xLim) <= 1e-12))
    setIfLive(handles.axV, 'XLim', xLim);
    setIfLive(handles.axI, 'XLim', xLim);
    setIfLive(handles.axF, 'XLim', xLim);
    if layoutKind == "r8"
        setIfLive(handles.axPhi, 'XLim', xLim);
    end
    cache.lastXLim = xLim;
end

updateZeroLine(handles.zeroV, xLim);
updateZeroLine(handles.zeroI, xLim);
updateZeroLine(handles.zeroF, xLim);
if layoutKind == "r8"
    updateZeroLine(handles.zeroPhi, xLim);
else
    setIfLive(handles.zeroPhi, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
end
end

function cache = drawR5Curves(handles, cache)
%DRAWR5CURVES  绘制 R5 双棒 3x2 曲线
setIfLive(handles.msgV, 'Visible', 'off');
setIfLive(handles.msgI, 'Visible', 'off');
setIfLive(handles.msgPhi, 'Visible', 'off');
setIfLive(handles.msgF, 'Visible', 'off');
setIfLive(handles.msgQ, 'Visible', 'off');

if isempty(cache.t)
    return;
end

maxDrawPoints = 1600;
if numel(cache.t) > maxDrawPoints
    idx = (numel(cache.t)-maxDrawPoints+1):numel(cache.t);
else
    idx = 1:numel(cache.t);
end

tDraw = cache.t(idx);
xADraw = cache.xA(idx);
xBDraw = cache.xB(idx);
xCDraw = cache.xC(idx);
vADraw = cache.vA(idx);
vBDraw = cache.vB(idx);
vCDraw = cache.vC(idx);
iDraw = cache.i(idx);
epsDraw = cache.eps(idx);
fADraw = cache.fA(idx);
fBDraw = cache.fB(idx);
fSumDraw = cache.f(idx);
qRDraw = cache.qR(idx);
qCollDraw = cache.qColl(idx);
qTotDraw = cache.qTotal(idx);

setIfLive(handles.lineXA, 'XData', tDraw, 'YData', xADraw, 'Visible', 'on');
setIfLive(handles.lineXB, 'XData', tDraw, 'YData', xBDraw, 'Visible', 'on');
setIfLive(handles.lineXC, 'XData', tDraw, 'YData', xCDraw, 'Visible', 'on');

setIfLive(handles.lineVA, 'XData', tDraw, 'YData', vADraw, 'Visible', 'on');
setIfLive(handles.lineVB, 'XData', tDraw, 'YData', vBDraw, 'Visible', 'on');
setIfLive(handles.lineVC, 'XData', tDraw, 'YData', vCDraw, 'Visible', 'on');

setIfLive(handles.lineI, 'XData', tDraw, 'YData', iDraw, 'Visible', 'on');
setIfLive(handles.linePhi, 'XData', tDraw, 'YData', epsDraw, 'Visible', 'on');

setIfLive(handles.lineFA, 'XData', tDraw, 'YData', fADraw, 'Visible', 'on');
setIfLive(handles.lineFB, 'XData', tDraw, 'YData', fBDraw, 'Visible', 'on');
setIfLive(handles.lineF, 'XData', tDraw, 'YData', fSumDraw, 'Visible', 'on');

setIfLive(handles.lineQR, 'XData', tDraw, 'YData', qRDraw, 'Visible', 'on');
setIfLive(handles.lineQColl, 'XData', tDraw, 'YData', qCollDraw, 'Visible', 'on');
setIfLive(handles.lineQ, 'XData', tDraw, 'YData', qTotDraw, 'Visible', 'on');

xMin = tDraw(1);
xMax = tDraw(end);
if xMax <= xMin
    xMax = xMin + 1e-3;
end
xLim = [xMin, xMax];

if ~(isnumeric(cache.lastXLim) && numel(cache.lastXLim) == 2 && all(isfinite(cache.lastXLim)) ...
        && all(abs(cache.lastXLim - xLim) <= 1e-12))
    setIfLive(handles.axXA, 'XLim', xLim);
    setIfLive(handles.axVA, 'XLim', xLim);
    setIfLive(handles.axI, 'XLim', xLim);
    setIfLive(handles.axPhi, 'XLim', xLim);
    setIfLive(handles.axF, 'XLim', xLim);
    setIfLive(handles.axQ, 'XLim', xLim);
    cache.lastXLim = xLim;
end

updateZeroLine(handles.zeroV, xLim);
updateZeroLine(handles.zeroI, xLim);
updateZeroLine(handles.zeroPhi, xLim);
updateZeroLine(handles.zeroF, xLim);
end

function updateZeroLine(hLine, xLim)
%UPDATEZEROLINE  更新 y=0 参考线
if ~isLiveHandle(hLine)
    return;
end
set(hLine, 'XData', xLim, 'YData', [0, 0], 'Visible', 'on');
end

%% R8 线框磁通量计算
function phi = computeFrameFlux(params, state)
%COMPUTEFRAMEFLUX  复用 R8 公式真源计算线框磁通量 Phi
%
% 用途
%   - 为曲线区提供当前时刻的磁通量采样值。
%
% 输入
%   params (1,1) struct
%     当前参数结构（R8 场景下包含几何与磁场参数）。
%   state  (1,1) struct
%     当前状态结构（用于解析线框中心坐标）。
%
% 输出
%   phi (1,1) double
%     当前时刻磁通量 Phi。
%
% 说明
%   - 历史版本曾在渲染层内重复实现 overlap/Bz/h 公式。
%   - 为避免“渲染层公式”与“物理真源”漂移，这里统一调用
%     physics.frameStripOutputs，并直接读取 out.phi。
xCenter = resolveFrameCenterX(params, state);
out = physics.frameStripOutputs(double(xCenter), 0.0, params);
phi = double(out.phi);
end

function xCenter = resolveFrameCenterX(params, state)
%RESOLVEFRAMECENTERX  解析线框中心坐标 x_c（R8 主状态变量）
%
% 优先级
%   1) state.xCenter（若引擎提供）
%   2) state.x（R8 当前实现中即中心坐标）
%   3) params.xCenter（参数兜底）
%   4) params.x0（旧字段兼容）
xCenter = toDouble( ...
    pickField(state, 'xCenter', ...
    pickField(state, 'x', ...
    pickField(params, 'xCenter', ...
    pickField(params, 'x0', 0.0)))), 0.0);
end

%% 占位提示与默认缓存
function cache = clearHistoryAndShowMessage(handles, cache, messageText)
%CLEARHISTORYANDSHOWMESSAGE  清空曲线并显示占位提示
cache.t = [];
cache.xA = [];
cache.xB = [];
cache.xC = [];
cache.vA = [];
cache.vB = [];
cache.vC = [];
cache.v = [];
cache.i = [];
cache.eps = [];
cache.fA = [];
cache.fB = [];
cache.qR = [];
cache.qColl = [];
cache.qTotal = [];
cache.f = [];
cache.phi = [];
cache.lastT = NaN;
cache.lastStep = NaN;
cache.lastXLim = [NaN, NaN];

setIfLive(handles.lineV, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineI, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineF, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.linePhi, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineXA, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineXB, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineXC, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineVA, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineVB, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineVC, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineFA, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineFB, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineQR, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineQColl, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.lineQ, 'XData', NaN, 'YData', NaN, 'Visible', 'off');

setIfLive(handles.zeroV, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.zeroI, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.zeroF, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
setIfLive(handles.zeroPhi, 'XData', NaN, 'YData', NaN, 'Visible', 'off');

setIfLive(handles.msgV, 'String', messageText, 'Visible', 'on');
setIfLive(handles.msgI, 'String', messageText, 'Visible', 'on');
setIfLive(handles.msgF, 'String', messageText, 'Visible', 'on');
setIfLive(handles.msgPhi, 'String', messageText, 'Visible', 'on');
setIfLive(handles.msgQ, 'String', messageText, 'Visible', 'on');
end

function cache = defaultPlotCache()
%DEFAULTPLOTCACHE  曲线缓存默认结构
cache = struct( ...
    'layoutKind', "rail", ...
    'hAxXA', [], ...
    'hAxVA', [], ...
    'hAxV', [], ...
    'hAxI', [], ...
    'hAxPhi', [], ...
    'hAxF', [], ...
    'hAxQ', [], ...
    'hLineXA', [], ...
    'hLineXB', [], ...
    'hLineXC', [], ...
    'hLineVA', [], ...
    'hLineVB', [], ...
    'hLineVC', [], ...
    'hLineV', [], ...
    'hLineI', [], ...
    'hLinePhi', [], ...
    'hLineF', [], ...
    'hLineFA', [], ...
    'hLineFB', [], ...
    'hLineQR', [], ...
    'hLineQColl', [], ...
    'hLineQ', [], ...
    'hZeroV', [], ...
    'hZeroI', [], ...
    'hZeroPhi', [], ...
    'hZeroF', [], ...
    'hMsgV', [], ...
    'hMsgI', [], ...
    'hMsgPhi', [], ...
    'hMsgF', [], ...
    'hMsgQ', [], ...
    't', zeros(0, 1), ...
    'xA', zeros(0, 1), ...
    'xB', zeros(0, 1), ...
    'xC', zeros(0, 1), ...
    'vA', zeros(0, 1), ...
    'vB', zeros(0, 1), ...
    'vC', zeros(0, 1), ...
    'v', zeros(0, 1), ...
    'i', zeros(0, 1), ...
    'eps', zeros(0, 1), ...
    'fA', zeros(0, 1), ...
    'fB', zeros(0, 1), ...
    'qR', zeros(0, 1), ...
    'qColl', zeros(0, 1), ...
    'qTotal', zeros(0, 1), ...
    'f', zeros(0, 1), ...
    'phi', zeros(0, 1), ...
    'lastT', NaN, ...
    'lastStep', NaN, ...
    'lastXLim', [NaN, NaN] ...
);
end

function cache = fillMissingCacheFields(cache)
%FILLMISSINGCACHEFIELDS  为旧版缓存补齐新增字段，避免字段缺失报错
defaults = defaultPlotCache();
names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(cache, name)
        cache.(name) = defaults.(name);
    end
end
end

function [tOut, vOut, iOut, fOut, phiOut] = tailHistory(t, v, i, f, phi, maxPoints)
%TAILHISTORY  仅取历史尾部窗口用于绘制
if numel(t) <= maxPoints
    tOut = t;
    vOut = v;
    iOut = i;
    fOut = f;
    phiOut = phi;
    return;
end
idx = (numel(t)-maxPoints+1):numel(t);
tOut = t(idx);
vOut = v(idx);
iOut = i(idx);
fOut = f(idx);
phiOut = phi(idx);
end

function cache = readPlotCache(app)
%READPLOTCACHE  从 plotsGrid.UserData 读取缓存
cache = [];
if ~isprop(app, 'plotsGrid') || ~isLiveHandle(app.plotsGrid)
    return;
end
ud = app.plotsGrid.UserData;
if isstruct(ud) && isfield(ud, 'plotCache') && isstruct(ud.plotCache)
    cache = ud.plotCache;
end
end

function writePlotCache(app, cache)
%WRITEPLOTCACHE  回写缓存到 plotsGrid.UserData
if ~isprop(app, 'plotsGrid') || ~isLiveHandle(app.plotsGrid)
    return;
end
ud = app.plotsGrid.UserData;
if ~isstruct(ud)
    ud = struct();
end
if nargin >= 2 && isstruct(cache)
    ud.plotCache = cache;
end
app.plotsGrid.UserData = ud;
end

%% 通用工具
function v = logicalField(s, name, fallback)
%LOGICALFIELD  安全读取 logical 字段
raw = pickField(s, name, fallback);
if islogical(raw) && isscalar(raw)
    v = raw;
elseif isnumeric(raw) && isscalar(raw)
    v = raw ~= 0;
else
    v = logical(fallback);
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

function setIfLive(h, varargin)
%SETIFLIVE  安全 set 封装（句柄失效时忽略）
if isLiveHandle(h)
    set(h, varargin{:});
end
end

function tf = isLiveHandle(h)
%ISLIVEHANDLE  安全判断图形句柄是否有效（返回标量 logical）
tf = false;
if isempty(h)
    return;
end
try
    tf = isscalar(h) && isgraphics(h);
catch
    tf = false;
end
end

function v = scalarOrNaN(x)
%SCALARORNAN  将输入压缩为标量数值；失败返回 NaN
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = NaN;
end
end

function v = toDouble(x, fallback)
%TODOUBLE  安全转换为有限标量 double
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = double(fallback);
end
end

function tf = isScalarFinite(x)
%ISSCALARFINITE  判断是否为有限标量数值
tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

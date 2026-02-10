function renderPlots(app, state)
%RENDERPLOTS  曲线渲染入口（R 模板三子图：v / I / Fmag）
%
% 渲染策略
%   1) 仅在导轨模型且“外力场景”下绘制三子图
%   2) R1（开路/无外力）阶段暂不绘制，显示提示文本
%   3) 曲线历史在 UI 层缓存，检测到时间回退自动清空
%
% 三子图定义
%   - 图1：v(t)
%   - 图2：I(t)
%   - 图3：F_mag(t)

if ~(isprop(app, 'plotsGrid') && isLiveHandle(app.plotsGrid))
    return;
end

params = readParams(app);
modelType = resolveModelType(params, state);

% 仅在导轨模型下处理
if modelType ~= "rail"
    [handles, cache] = ensurePlotHandles(app);
    cache = clearHistoryAndShowMessage(handles, cache, "当前模板暂不绘制导轨曲线");
    writePlotCache(app, cache);
    return;
end

% R2 场景判定：只要“有外力驱动开关”为真，就按非 R1 场景处理
% 说明
%   - 这里不再用 |Fdrive|>0 作为判定条件，避免“已选择有外力”却被当成 R1。
isDriveScene = logicalField(params, 'driveEnabled', false);
if ~isDriveScene
    [handles, cache] = ensurePlotHandles(app);
    cache = clearHistoryAndShowMessage(handles, cache, "R1 场景暂不绘制曲线");
    writePlotCache(app, cache);
    return;
end

[handles, cache] = ensurePlotHandles(app);
cache = appendHistory(cache, state);
cache = drawRailCurves(handles, cache);
writePlotCache(app, cache);
end

function params = readParams(app)
%READPARAMS  安全读取 app.Params
params = struct();
if isprop(app, 'Params') && isstruct(app.Params)
    params = app.Params;
end
end

function modelType = resolveModelType(params, state)
%RESOLVEMODELTYPE  解析模型类型（particle/rail）
modelType = lower(strtrim(string(pickField(params, 'modelType', pickField(state, 'modelType', "particle")))));
if startsWith(modelType, "rail")
    modelType = "rail";
else
    modelType = "particle";
end
end

function [handles, cache] = ensurePlotHandles(app)
%ENSUREPLOTHANDLES  确保三子图与缓存结构已创建
cache = readPlotCache(app);

% 若旧单轴存在，先隐藏，避免和三子图叠加
if isprop(app, 'PlotsAxes') && isLiveHandle(app.PlotsAxes)
    app.PlotsAxes.Visible = 'off';
end

if isempty(cache) || ~isstruct(cache)
    cache = defaultPlotCache();
end

needCreate = true;
if isfield(cache, 'hAxV') && isLiveHandle(cache.hAxV) && ...
   isfield(cache, 'hAxI') && isLiveHandle(cache.hAxI) && ...
   isfield(cache, 'hAxF') && isLiveHandle(cache.hAxF)
    needCreate = false;
end

if needCreate
    % 先清空旧子对象（仅清 plotsGrid）
    delete(app.plotsGrid.Children);

    % 三行一列布局
    app.plotsGrid.RowHeight = {'1x', '1x', '1x'};
    app.plotsGrid.ColumnWidth = {'1x'};

    hAxV = uiaxes(app.plotsGrid);
    hAxV.Layout.Row = 1;
    hAxV.Layout.Column = 1;

    hAxI = uiaxes(app.plotsGrid);
    hAxI.Layout.Row = 2;
    hAxI.Layout.Column = 1;

    hAxF = uiaxes(app.plotsGrid);
    hAxF.Layout.Row = 3;
    hAxF.Layout.Column = 1;

    styleAxis(hAxV, 'v(t)', '速度 v (m/s)');
    styleAxis(hAxI, 'I(t)', '电流 I (A)');
    styleAxis(hAxF, 'F_{mag}(t)', '安培力 F_{mag} (N)');
    xlabel(hAxF, '时间 t (s)');

    % 初始化曲线句柄
    cache.hAxV = hAxV;
    cache.hAxI = hAxI;
    cache.hAxF = hAxF;
    cache.hLineV = line('Parent', hAxV, 'XData', NaN, 'YData', NaN, 'Color', [0.90, 0.26, 0.18], 'LineWidth', 1.8);
    cache.hLineI = line('Parent', hAxI, 'XData', NaN, 'YData', NaN, 'Color', [0.16, 0.53, 0.92], 'LineWidth', 1.8);
    cache.hLineF = line('Parent', hAxF, 'XData', NaN, 'YData', NaN, 'Color', [0.42, 0.24, 0.80], 'LineWidth', 1.8);
    cache.hMsgV = text(hAxV, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
    cache.hMsgI = text(hAxI, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
    cache.hMsgF = text(hAxF, 0.5, 0.5, '', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Visible', 'off');
end

handles = struct('axV', cache.hAxV, 'axI', cache.hAxI, 'axF', cache.hAxF, ...
                 'lineV', cache.hLineV, 'lineI', cache.hLineI, 'lineF', cache.hLineF, ...
                 'msgV', cache.hMsgV, 'msgI', cache.hMsgI, 'msgF', cache.hMsgF);
end

function styleAxis(ax, ttl, ylab)
%STYLEAXIS  统一子图样式
cla(ax);
title(ax, ttl);
ylabel(ax, ylab);
ax.XGrid = 'on';
ax.YGrid = 'on';
end

function cache = appendHistory(cache, state)
%APPENDHISTORY  追加单步数据到曲线历史
%
% 清空规则
%   - t 回退：视为重置
%   - stepCount 回退：视为重置

tNow = double(pickField(state, 't', NaN));
if ~isScalarFinite(tNow)
    return;
end

stepNow = double(pickField(state, 'stepCount', NaN));
lastT = scalarOrNaN(pickField(cache, 'lastT', NaN));
lastStep = scalarOrNaN(pickField(cache, 'lastStep', NaN));
if (isScalarFinite(lastT) && tNow < lastT - 1e-12) || ...
   (isScalarFinite(lastStep) && isScalarFinite(stepNow) && stepNow < lastStep)
    cache.t = [];
    cache.v = [];
    cache.i = [];
    cache.f = [];
end

vNow = double(pickField(state, 'vx', 0.0));
iNow = double(pickField(state, 'current', 0.0));
fNow = double(pickField(state, 'fMag', 0.0));

% 同一帧重复渲染：覆盖最后一个点，避免重复堆叠
if ~isempty(cache.t) && abs(tNow - cache.t(end)) <= 1e-12
    cache.v(end) = vNow;
    cache.i(end) = iNow;
    cache.f(end) = fNow;
else
    cache.t(end+1, 1) = tNow;
    cache.v(end+1, 1) = vNow;
    cache.i(end+1, 1) = iNow;
    cache.f(end+1, 1) = fNow;
end

cache.lastT = tNow;
if isScalarFinite(stepNow)
    cache.lastStep = stepNow;
end

% 历史长度保护
maxPoints = 5000;
if numel(cache.t) > maxPoints
    keepIdx = (numel(cache.t)-maxPoints+1):numel(cache.t);
    cache.t = cache.t(keepIdx);
    cache.v = cache.v(keepIdx);
    cache.i = cache.i(keepIdx);
    cache.f = cache.f(keepIdx);
end
end

function cache = drawRailCurves(handles, cache)
%DRAWRAILCURVES  绘制 v/I/Fmag 三条曲线
set(handles.msgV, 'Visible', 'off');
set(handles.msgI, 'Visible', 'off');
set(handles.msgF, 'Visible', 'off');

if isempty(cache.t)
    return;
end

set(handles.lineV, 'XData', cache.t, 'YData', cache.v, 'Visible', 'on');
set(handles.lineI, 'XData', cache.t, 'YData', cache.i, 'Visible', 'on');
set(handles.lineF, 'XData', cache.t, 'YData', cache.f, 'Visible', 'on');

% 三图统一时间窗
xMin = cache.t(1);
xMax = cache.t(end);
if xMax <= xMin
    xMax = xMin + 1e-3;
end
set(handles.axV, 'XLim', [xMin, xMax]);
set(handles.axI, 'XLim', [xMin, xMax]);
set(handles.axF, 'XLim', [xMin, xMax]);
end

function cache = clearHistoryAndShowMessage(handles, cache, messageText)
%CLEARHISTORYANDSHOWMESSAGE  清空曲线并显示占位提示
cache.t = [];
cache.v = [];
cache.i = [];
cache.f = [];
cache.lastT = NaN;
cache.lastStep = NaN;

set(handles.lineV, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
set(handles.lineI, 'XData', NaN, 'YData', NaN, 'Visible', 'off');
set(handles.lineF, 'XData', NaN, 'YData', NaN, 'Visible', 'off');

set(handles.msgV, 'String', messageText, 'Visible', 'on');
set(handles.msgI, 'String', messageText, 'Visible', 'on');
set(handles.msgF, 'String', messageText, 'Visible', 'on');
end

function cache = defaultPlotCache()
%DEFAULTPLOTCACHE  曲线缓存默认结构
cache = struct( ...
    'hAxV', [], ...
    'hAxI', [], ...
    'hAxF', [], ...
    'hLineV', [], ...
    'hLineI', [], ...
    'hLineF', [], ...
    'hMsgV', [], ...
    'hMsgI', [], ...
    'hMsgF', [], ...
    't', zeros(0, 1), ...
    'v', zeros(0, 1), ...
    'i', zeros(0, 1), ...
    'f', zeros(0, 1), ...
    'lastT', NaN, ...
    'lastStep', NaN ...
);
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

function tf = isScalarFinite(x)
%ISSCALARFINITE  判断是否为有限标量数值
tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

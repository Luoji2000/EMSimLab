function renderScene(app, state)
%RENDERSCENE  场景渲染（M1 有界/无界统一版本）
%
% 渲染内容
%   1) 粒子轨迹
%   2) 粒子当前位置
%   3) 速度箭头（按速度+回旋半径对数放大）
%   4) 磁场标记（无界覆盖全视窗；有界仅覆盖磁场区域）
%   5) 有界磁场粗黑边框

if ~(isprop(app, 'SceneAxes') && isgraphics(app.SceneAxes))
    return;
end

ax = app.SceneAxes;
p = readParams(app);
state = normalizeState(state);
doLog = shouldLogRender(state);

cache = getRenderCache(ax);
[xLim, yLim, viewSpan] = computeViewWindow(ax, state, p);
modelType = resolveModelType(p, state);
isMassSpec = isMassSpecTemplate(p, state);
tNow = pickField(state, 't', 0.0);

% 坐标轴设置（按需更新，减少每帧重复 set 的渲染开销）
cache = updateAxesPresentation(ax, cache, xLim, yLim, p, modelType, isMassSpec, tNow, state);

if doLog
    logger.logEvent(app, '调试', '渲染-坐标轴', struct( ...
        't', double(tNow), ...
        'x', double(state.x), ...
        'y', double(state.y), ...
        'vx', double(state.vx), ...
        'vy', double(state.vy), ...
        'model_type', modelType, ...
        'traj_points', size(state.traj, 1), ...
        'auto_follow', logicalField(p, 'autoFollow', true), ...
        'follow_span', double(pickField(p, 'followSpan', 2.4)), ...
        'x_lim_text', sprintf('[%.3f, %.3f]', xLim(1), xLim(2)), ...
        'y_lim_text', sprintf('[%.3f, %.3f]', yLim(1), yLim(2)), ...
        'view_span', double(viewSpan) ...
    ));
end

% 磁场标记
[cache, bInfo] = updateBMarks(ax, cache, p, xLim, yLim, viewSpan, modelType);
if doLog
    logger.logEvent(app, '调试', '渲染-磁场标记', bInfo);
end

if modelType == "rail"
    [cache, railInfo] = renderRailSceneBody(ax, cache, state, p, viewSpan);
    if doLog
        logger.logEvent(app, '调试', '渲染-导轨', railInfo);
    end

    % 关闭调试探针：避免在导轨附近出现额外标记干扰观察
    hideHandle(cache.hDebugText);
    hideHandle(cache.hParticle);
    hideHandle(cache.hForce);
    hideHandle(cache.hForceElec);
    hideHandle(cache.hForceMag);
    cache = hideMassSpecHandles(cache);
    cache = hideSelectorHandles(cache);

    setRenderCache(ax, cache);
    if doLog
        logAxesChildren(app, ax);
    end
    % 不使用 limitrate，避免 MATLAB 内部限帧造成“明显顿感”
    drawnow nocallbacks;
    if doLog
        logRenderFinalState(app, ax, cache, state);
    end
    return;
end

cache = hideRailOnlyHandles(cache);
[cache, msInfo] = renderMassSpecOverlay(ax, cache, p, yLim, isMassSpec);
if doLog && isMassSpec
    logger.logEvent(app, '调试', '渲染-质谱仪', msInfo);
end

if modelType == "selector"
    [cache, selectorInfo] = renderSelectorOverlay(ax, cache, p);
    if doLog
        logger.logEvent(app, '调试', '渲染-速度选择器', selectorInfo);
    end
else
    cache = hideSelectorHandles(cache);
end

% 轨迹
showTrail = logicalField(p, 'showTrail', true);
traj = state.traj;
if showTrail && size(traj, 1) >= 1
    trajDraw = trimTrailForRender(traj, 1600);
    if ~isLiveHandle(cache.hTrail)
        cache.hTrail = line('Parent', ax, ...
            'XData', trajDraw(:, 1), ...
            'YData', trajDraw(:, 2), ...
            'LineStyle', '-', ...
            'Color', [0.05, 0.75, 0.25], ...
            'LineWidth', 2.2);
    else
        set(cache.hTrail, 'XData', trajDraw(:, 1), 'YData', trajDraw(:, 2), 'Visible', 'on');
    end
else
    hideHandle(cache.hTrail);
end
if doLog
    logger.logEvent(app, '调试', '渲染-轨迹', struct( ...
        'visible', showTrail && size(traj, 1) >= 1, ...
        'point_count', size(traj, 1) ...
    ));
end

% 粒子当前位置
if ~isLiveHandle(cache.hParticle)
    cache.hParticle = line('Parent', ax, ...
        'XData', state.x, ...
        'YData', state.y, ...
        'LineStyle', 'none', ...
        'Marker', 'o', ...
        'MarkerSize', 14, ...
        'MarkerFaceColor', [1.00, 0.15, 0.05], ...
        'MarkerEdgeColor', [1.00, 1.00, 1.00], ...
        'LineWidth', 1.2);
else
    set(cache.hParticle, 'XData', state.x, 'YData', state.y, 'Visible', 'on');
end
if doLog
    logger.logEvent(app, '调试', '渲染-粒子', struct( ...
        'x', double(state.x), ...
        'y', double(state.y), ...
        'finite_xy', isfinite(state.x) && isfinite(state.y) ...
    ));
end

% 速度箭头
[cache, vInfo] = updateVelocityArrow(ax, cache, state, p, viewSpan);
if doLog
    logger.logEvent(app, '调试', '渲染-速度箭头', vInfo);
end

% 受力箭头（可选）
if modelType == "selector"
    [cache, fInfo] = updateSelectorForceArrows(ax, cache, state, p, viewSpan);
else
    [cache, fInfo] = updateForceArrow(ax, cache, state, p, viewSpan);
    hideHandle(cache.hForceElec);
    hideHandle(cache.hForceMag);
end
if doLog
    logger.logEvent(app, '调试', '渲染-受力箭头', fInfo);
end

% 关闭调试探针：避免在粒子旁出现粉色标记干扰观察
hideHandle(cache.hDebugText);

setRenderCache(ax, cache);
if doLog
    logAxesChildren(app, ax);
end
% 不使用 limitrate，避免 MATLAB 内部限帧造成“明显顿感”
drawnow nocallbacks;
if doLog
    logRenderFinalState(app, ax, cache, state);
end
end

function p = readParams(app)
%READPARAMS  安全读取 app.Params
p = struct();
if isprop(app, 'Params') && isstruct(app.Params)
    p = app.Params;
end
end

function state = normalizeState(state)
%NORMALIZESTATE  统一状态字段，避免渲染层分支过多
if ~isstruct(state)
    state = struct();
end
state.x = pickField(state, 'x', 0.0);
state.y = pickField(state, 'y', 0.0);
state.vx = pickField(state, 'vx', 0.0);
state.vy = pickField(state, 'vy', 0.0);
state.t = pickField(state, 't', 0.0);

if ~isfield(state, 'traj') || ~isnumeric(state.traj) || size(state.traj, 2) ~= 2
    state.traj = [state.x, state.y];
elseif isempty(state.traj)
    state.traj = [state.x, state.y];
end
end

function modelType = resolveModelType(p, state)
%RESOLVEMODELTYPE  解析当前渲染模型类型（particle/rail）
modelType = string(pickField(p, 'modelType', pickField(state, 'modelType', "particle")));
modelType = lower(strtrim(modelType));
if startsWith(modelType, "rail")
    modelType = "rail";
elseif startsWith(modelType, "selector")
    modelType = "selector";
else
    modelType = "particle";
end
end

function tf = isMassSpecTemplate(p, state)
%ISMASSSPECTEMPLATE  判断当前是否 M5 质谱仪模板
token = upper(strtrim(string(pickField(p, 'templateId', pickField(state, 'templateId', "")))));
tf = token == "M5";
end

function cache = hideRailOnlyHandles(cache)
%HIDERAILONLYHANDLES  在粒子模型下隐藏导轨专用图元
hideHandle(cache.hRailTop);
hideHandle(cache.hRailBottom);
hideHandle(cache.hRod);
hideHandle(cache.hResistor);
hideHandle(cache.hCurrentArrow);
hideHandle(cache.hDriveArrow);
hideHandle(cache.hAmpereArrow);
end

function cache = hideMassSpecHandles(cache)
%HIDEMASSSPECHANDLES  隐藏质谱仪专用图元
hideHandle(cache.hSpecWallLower);
hideHandle(cache.hSpecWallUpper);
end

function cache = hideSelectorHandles(cache)
%HIDESELECTORHANDLES  隐藏速度选择器专用图元
hideHandle(cache.hSelectorPlateTop);
hideHandle(cache.hSelectorPlateBottom);
hideHandle(cache.hSelectorEArrow);
hideHandle(cache.hForceElec);
hideHandle(cache.hForceMag);
end

function cache = getRenderCache(ax)
%GETRENDERCACHE  获取/初始化渲染句柄缓存
cache = struct( ...
    'hTrail', [], ...
    'hParticle', [], ...
    'hVel', [], ...
    'hForce', [], ...
    'hBMarks', [], ...
    'hFieldBox', [], ...
    'hDebugText', [], ...
    'hRailTop', [], ...
    'hRailBottom', [], ...
    'hRod', [], ...
    'hResistor', [], ...
    'hCurrentArrow', [], ...
    'hDriveArrow', [], ...
    'hAmpereArrow', [], ...
    'hForceElec', [], ...
    'hForceMag', [], ...
    'hSelectorPlateTop', [], ...
    'hSelectorPlateBottom', [], ...
    'hSelectorEArrow', [], ...
    'hSpecWallLower', [], ...
    'hSpecWallUpper', [], ...
    'lastBMarkKey', "", ...
    'lastBMarkCount', 0, ...
    'axisStaticReady', false, ...
    'lastXLim', [NaN, NaN], ...
    'lastYLim', [NaN, NaN], ...
    'lastShowGrid', true, ...
    'lastTitleText', "", ...
    'lastTitleModel', "", ...
    'lastTitleStep', -inf ...
);

ud = ax.UserData;
if isstruct(ud) && isfield(ud, 'renderCache') && isstruct(ud.renderCache)
    cache = mergeCache(cache, ud.renderCache);
end

hold(ax, 'on');
end

function cache = updateAxesPresentation(ax, cache, xLim, yLim, p, modelType, isMassSpec, tNow, state)
%UPDATEAXESPRESENTATION  仅在必要时更新坐标轴属性
if ~cache.axisStaticReady
    % 这些是静态属性，只需设置一次
    ax.DataAspectRatio = [1 1 1];
    ax.DataAspectRatioMode = 'manual';
    xlabel(ax, 'x (m)');
    ylabel(ax, 'y (m)');
    cache.axisStaticReady = true;
end

if needUpdateRange(cache.lastXLim, xLim)
    ax.XLim = xLim;
    cache.lastXLim = reshape(double(xLim), 1, 2);
end
if needUpdateRange(cache.lastYLim, yLim)
    ax.YLim = yLim;
    cache.lastYLim = reshape(double(yLim), 1, 2);
end

showGrid = logicalField(p, 'showGrid', true);
if cache.lastShowGrid ~= showGrid
    if showGrid
        ax.XGrid = 'on';
        ax.YGrid = 'on';
    else
        ax.XGrid = 'off';
        ax.YGrid = 'off';
    end
    cache.lastShowGrid = showGrid;
end

% 标题是动态文本，降频更新可显著降低 UI 重排开销
stepNow = double(pickField(state, 'stepCount', 0.0));
if ~isfinite(stepNow)
    stepNow = 0.0;
end
needTitle = (stepNow <= 1) || (cache.lastTitleModel ~= modelType) || (mod(round(stepNow), 5) == 0);
if ~needTitle
    return;
end

if modelType == "rail"
    titleText = string(sprintf('导轨滑杆场景（t = %.3f s）', double(tNow)));
elseif modelType == "selector"
    titleText = string(sprintf('速度选择器场景（t = %.3f s）', double(tNow)));
elseif isMassSpec
    titleText = string(sprintf('质谱仪场景（t = %.3f s）', double(tNow)));
else
    titleText = string(sprintf('粒子运动场景（t = %.3f s）', double(tNow)));
end
if cache.lastTitleText ~= titleText
    title(ax, char(titleText));
    cache.lastTitleText = titleText;
end
cache.lastTitleModel = modelType;
cache.lastTitleStep = stepNow;
end

function tf = needUpdateRange(oldLim, newLim)
%NEEDUPDATERANGE  判断坐标范围是否需要更新（带容差）
tf = true;
if isnumeric(oldLim) && isnumeric(newLim) && numel(oldLim) == 2 && numel(newLim) == 2 ...
        && all(isfinite(oldLim)) && all(isfinite(newLim))
    tf = any(abs(double(oldLim(:) - newLim(:))) > 1e-10);
end
end

function trajDraw = trimTrailForRender(traj, maxPoints)
%TRIMTRAILFORRENDER  仅渲染末尾轨迹，减少每帧大数组写入开销
trajDraw = traj;
if ~isnumeric(traj) || size(traj, 2) ~= 2
    return;
end
n = size(traj, 1);
if n <= maxPoints
    return;
end
trajDraw = traj(n-maxPoints+1:n, :);
end

function setRenderCache(ax, cache)
%SETRENDERCACHE  写回渲染句柄缓存
ud = ax.UserData;
if ~isstruct(ud)
    ud = struct();
end
ud.renderCache = cache;
ax.UserData = ud;
end

function out = mergeCache(base, in)
%MERGECACHE  合并缓存结构（只复制同名字段）
out = base;
fields = fieldnames(base);
for i = 1:numel(fields)
    k = fields{i};
    if isfield(in, k)
        out.(k) = in.(k);
    end
end
end

function [xLim, yLim, span] = computeViewWindow(ax, state, p)
%COMPUTEVIEWWINDOW  计算视口范围（窗口锁定，越界再平移）
%
% 视角策略
%   1) autoFollow=true ：窗口默认锁定，粒子越界时才平移窗口
%   2) autoFollow=false：按轨迹包围盒/半径估计给出全局视角
traj = state.traj;
xMin = min(traj(:, 1));
xMax = max(traj(:, 1));
yMin = min(traj(:, 2));
yMax = max(traj(:, 2));

% 轨迹跨度
sx = max(xMax - xMin, 0);
sy = max(yMax - yMin, 0);

% 回旋半径估计：用于给初期画面留更大空间
speed = hypot(double(state.vx), double(state.vy));
omega = cyclotronOmega(p);
if abs(omega) > 1e-12
    radius = speed / abs(omega);
else
    radius = 0;
end

autoFollow = logicalField(p, 'autoFollow', true);
followSpan = pickField(p, 'followSpan', 2.4);
maxSpan = pickField(p, 'maxSpan', 40.0);
modelType = resolveModelType(p, state);

% M4 速度选择器：视窗以选择器方框为主，不跟随粒子抖动
if modelType == "selector"
    box = geom.readBoundsFromParams(p);
    boxW = max(1e-6, double(box.xMax - box.xMin));
    boxH = max(1e-6, double(box.yMax - box.yMin));
    % 目标：方框占视窗约 62%（接近黄金比例）
    selectorSpan = max(boxW, boxH) / 0.62;
    span = max([double(followSpan), selectorSpan, 1.2]);
    span = min(span, double(maxSpan));

    cx = 0.5 * (double(box.xMin) + double(box.xMax));
    cy = 0.5 * (double(box.yMin) + double(box.yMax));
    [xLim, yLim] = makeCenteredWindow(cx, cy, span);

    % 若粒子跑出视窗，才平移窗口，避免完全丢失粒子
    if pointOutsideWindow(double(state.x), double(state.y), xLim, yLim)
        pad = 0.06 * span;
        [xLim, yLim] = shiftWindowToIncludePoint(xLim, yLim, double(state.x), double(state.y), pad);
    end
    storeViewWindow(ax, xLim, yLim);
    span = xLim(2) - xLim(1);
    return;
end

if autoFollow
    % 跟随模式：优先复用已有窗口，避免“坐标系跟着每帧抖动”
    span = max([double(followSpan), 1.8 * radius, 1.0]);
    span = min(span, double(maxSpan));

    resetView = shouldResetViewWindow(state);
    [hasWindow, xOld, yOld] = getStoredViewWindow(ax);
    if ~hasWindow || resetView
        [xLim, yLim] = makeCenteredWindow(double(state.x), double(state.y), span);
        storeViewWindow(ax, xLim, yLim);
        return;
    end

    % 使用已有窗口跨度，保证播放期间坐标系固定
    span = max(1e-6, xOld(2) - xOld(1));
    xLim = xOld;
    yLim = yOld;

    % 仅当粒子跑到窗口外，才整体平移窗口把粒子拉回视野
    if pointOutsideWindow(double(state.x), double(state.y), xLim, yLim)
        pad = 0.06 * span;
        [xLim, yLim] = shiftWindowToIncludePoint(xLim, yLim, double(state.x), double(state.y), pad);
    end
    storeViewWindow(ax, xLim, yLim);
    span = xLim(2) - xLim(1);
    return;
else
    % 全局模式：优先覆盖已有轨迹与半径尺度
    span = max([8.0, 1.5 * max(sx, sy), 6.0 * radius, 4.0 * speed, 2.0]);
    span = min(span, double(maxSpan));
    cx = 0.5 * (xMin + xMax);
    cy = 0.5 * (yMin + yMax);
    if ~isfinite(cx)
        cx = double(state.x);
    end
    if ~isfinite(cy)
        cy = double(state.y);
    end
end

xLim = [cx - 0.5 * span, cx + 0.5 * span];
yLim = [cy - 0.5 * span, cy + 0.5 * span];
storeViewWindow(ax, xLim, yLim);
end

function tf = shouldResetViewWindow(state)
%SHOULDRESETVIEWWINDOW  是否应重建视窗（重置/首帧时）
tf = false;
if isfield(state, 'stepCount') && double(state.stepCount) <= 1
    tf = true;
    return;
end
if isfield(state, 't') && abs(double(state.t)) < 1e-12
    tf = true;
end
end

function [ok, xLim, yLim] = getStoredViewWindow(ax)
%GETSTOREDVIEWWINDOW  读取已缓存的视窗范围
ok = false;
xLim = [0, 1];
yLim = [0, 1];

ud = ax.UserData;
if ~isstruct(ud) || ~isfield(ud, 'viewWindow') || ~isstruct(ud.viewWindow)
    return;
end
if ~isfield(ud.viewWindow, 'xLim') || ~isfield(ud.viewWindow, 'yLim')
    return;
end

xTmp = ud.viewWindow.xLim;
yTmp = ud.viewWindow.yLim;
if isnumeric(xTmp) && isnumeric(yTmp) && numel(xTmp) == 2 && numel(yTmp) == 2 ...
        && all(isfinite(xTmp)) && all(isfinite(yTmp))
    xLim = reshape(double(xTmp), 1, 2);
    yLim = reshape(double(yTmp), 1, 2);
    ok = true;
end
end

function storeViewWindow(ax, xLim, yLim)
%STOREVIEWWINDOW  缓存当前视窗范围到 ax.UserData
ud = ax.UserData;
if ~isstruct(ud)
    ud = struct();
end
ud.viewWindow = struct('xLim', reshape(double(xLim), 1, 2), 'yLim', reshape(double(yLim), 1, 2));
ax.UserData = ud;
end

function [xLim, yLim] = makeCenteredWindow(cx, cy, span)
%MAKECENTEREDWINDOW  按中心与跨度构造窗口
xLim = [cx - 0.5 * span, cx + 0.5 * span];
yLim = [cy - 0.5 * span, cy + 0.5 * span];
end

function tf = pointOutsideWindow(x, y, xLim, yLim)
%POINTOUTSIDEWINDOW  点是否在窗口外部
tf = (x < xLim(1)) || (x > xLim(2)) || (y < yLim(1)) || (y > yLim(2));
end

function [xLimNew, yLimNew] = shiftWindowToIncludePoint(xLim, yLim, x, y, pad)
%SHIFTWINDOWTOINCLUDEPOINT  平移窗口以包含越界点
%
% 说明
%   - 仅做平移，不改变窗口大小
%   - pad 用于让点回到边界内侧，避免刚好贴边反复触发
pad = max(0, double(pad));
dx = 0.0;
dy = 0.0;

if x < xLim(1)
    dx = (x - pad) - xLim(1);
elseif x > xLim(2)
    dx = (x + pad) - xLim(2);
end

if y < yLim(1)
    dy = (y - pad) - yLim(1);
elseif y > yLim(2)
    dy = (y + pad) - yLim(2);
end

xLimNew = xLim + dx;
yLimNew = yLim + dy;
end

function [cache, info] = updateBMarks(ax, cache, p, xLim, yLim, viewSpan, modelType)
%UPDATEBMARKS  更新磁场标记与有界磁场边框
%
% 渲染规则
%   - bounded=false：磁场标记覆盖当前可视范围
%   - bounded=true ：磁场标记仅在有界磁场区域内绘制，并显示黑色粗边框
%   - 例外（M4 selector）：不绘制矩形边框，仅由速度选择器上下极板表示边界
info = struct( ...
    'visible', false, ...
    'mark_count', 0, ...
    'marker', "-", ...
    'bdir', "-", ...
    'bounded', false, ...
    'box_visible', false, ...
    'cache_hit', false ...
);

bounded = logicalField(p, 'bounded', false);
info.bounded = bounded;

% 边框显示独立于 showBMarks：有界模式下始终显示边界位置
[cache, boxVisible] = updateFieldBox(ax, cache, p, bounded, modelType);
info.box_visible = boxVisible;

showB = logicalField(p, 'showBMarks', true);
if ~showB
    hideHandle(cache.hBMarks);
    cache.lastBMarkKey = "";
    cache.lastBMarkCount = 0;
    return;
end

Bdir = lower(strtrim(string(pickField(p, 'Bdir', "out"))));
if Bdir == "in"
    marker = 'x';
    markColor = [0.20, 0.45, 0.95];
    markFace = 'none';
else
    marker = 'o';
    markColor = [0.16, 0.42, 0.90];
    markFace = [0.75, 0.86, 1.00];
end

% 生成“磁场标记缓存键”，用于跳过重复点阵重建与重复 set(XData/YData)
if bounded
    box = geom.readBoundsFromParams(p);
    key = composeBMarkKeyBounded(box, marker);
    if isLiveHandle(cache.hBMarks) && cache.lastBMarkKey == key
        % 点阵未变化时仅保持可见，避免高频 set 带来的渲染抖动
        set(cache.hBMarks, 'Visible', 'on');
        info.visible = true;
        info.mark_count = cache.lastBMarkCount;
        info.marker = marker;
        info.bdir = Bdir;
        info.cache_hit = true;
        return;
    end
    [xx, yy] = buildBMarkGridInBox(box);
else
    key = composeBMarkKeyView(xLim, yLim, viewSpan, marker);
    if isLiveHandle(cache.hBMarks) && cache.lastBMarkKey == key
        set(cache.hBMarks, 'Visible', 'on');
        info.visible = true;
        info.mark_count = cache.lastBMarkCount;
        info.marker = marker;
        info.bdir = Bdir;
        info.cache_hit = true;
        return;
    end
    [xx, yy] = buildBMarkGrid(xLim, yLim, viewSpan);
end

if ~isLiveHandle(cache.hBMarks)
    cache.hBMarks = line('Parent', ax, ...
        'XData', xx, ...
        'YData', yy, ...
        'LineStyle', 'none', ...
        'Marker', marker, ...
        'Color', markColor, ...
        'MarkerSize', 8, ...
        'LineWidth', 1.2);
else
    set(cache.hBMarks, ...
        'XData', xx, ...
        'YData', yy, ...
        'Marker', marker, ...
        'Color', markColor, ...
        'Visible', 'on');
end

if marker == 'o'
    set(cache.hBMarks, 'MarkerFaceColor', markFace);
else
    set(cache.hBMarks, 'MarkerFaceColor', 'none');
end

cache.lastBMarkKey = key;
cache.lastBMarkCount = numel(xx);
info.visible = true;
info.mark_count = cache.lastBMarkCount;
info.marker = marker;
info.bdir = Bdir;
end

function key = composeBMarkKeyBounded(box, marker)
%COMPOSEBMARKKEYBOUNDED  生成有界磁场标记缓存键
key = string(sprintf( ...
    'bounded|%.6f|%.6f|%.6f|%.6f|%s', ...
    box.xMin, box.xMax, box.yMin, box.yMax, char(marker)));
end

function key = composeBMarkKeyView(xLim, yLim, viewSpan, marker)
%COMPOSEBMARKKEYVIEW  生成无界磁场标记缓存键（按视窗量化）
%
% 说明
%   - 这里对视窗值做小数位量化，减少浮点噪声导致的频繁缓存失效
key = string(sprintf( ...
    'view|%.3f|%.3f|%.3f|%.3f|%.3f|%s', ...
    xLim(1), xLim(2), yLim(1), yLim(2), viewSpan, char(marker)));
end

function [xx, yy] = buildBMarkGrid(xLim, yLim, viewSpan)
%BUILDBMARKGRID  在可视区内生成磁场标记点阵
n = max(10, min(24, round(viewSpan * 1.2)));
xv = linspace(xLim(1), xLim(2), n);
yv = linspace(yLim(1), yLim(2), n);
[X, Y] = meshgrid(xv, yv);
xx = X(:);
yy = Y(:);
end

function [xx, yy] = buildBMarkGridInBox(box)
%BUILDBMARKGRIDINBOX  在有界磁场区域内生成均匀标记点阵
span = max(box.xMax - box.xMin, box.yMax - box.yMin);
n = max(10, min(28, round(max(span, 1.0) * 2.0)));
xv = linspace(box.xMin, box.xMax, n);
yv = linspace(box.yMin, box.yMax, n);
[X, Y] = meshgrid(xv, yv);
xx = X(:);
yy = Y(:);
end

function [cache, visible] = updateFieldBox(ax, cache, p, bounded, modelType)
%UPDATEFIELDBOX  更新有界磁场黑色边框
visible = false;
if ~bounded || modelType == "selector"
    hideHandle(cache.hFieldBox);
    return;
end

box = geom.readBoundsFromParams(p);
xData = [box.xMin, box.xMax, box.xMax, box.xMin, box.xMin];
yData = [box.yMin, box.yMin, box.yMax, box.yMax, box.yMin];

if ~isLiveHandle(cache.hFieldBox)
    cache.hFieldBox = line('Parent', ax, ...
        'XData', xData, ...
        'YData', yData, ...
        'LineStyle', '-', ...
        'Color', [0.00, 0.00, 0.00], ...
        'LineWidth', 2.8);
else
    set(cache.hFieldBox, ...
        'XData', xData, ...
        'YData', yData, ...
        'Visible', 'on');
end

visible = true;
end

function [cache, info] = renderMassSpecOverlay(ax, cache, p, yLim, isMassSpec)
%RENDERMASSSPECOVERLAY  绘制 M5 质谱仪左侧粗线与狭缝
%
% 场景语义
%   - 左侧粗线：质谱仪入口屏蔽板
%   - 中间留孔：允许粒子从狭缝进入右半磁场
%   - 磁场区域本体仍由 bounded+xMin/xMax/yMin/yMax 控制
info = struct( ...
    'visible', false, ...
    'wall_x', 0.0, ...
    'slit_center_y', 0.0, ...
    'slit_height', 0.0 ...
);

if ~isMassSpec
    cache = hideMassSpecHandles(cache);
    return;
end

wallX = double(pickField(p, 'specWallX', pickField(p, 'xMin', 0.0)));
slitCenterY = double(pickField(p, 'slitCenterY', pickField(p, 'y0', 0.0)));
slitHeight = max(double(pickField(p, 'slitHeight', 0.40)), 0.05);
slitYMin = slitCenterY - 0.5 * slitHeight;
slitYMax = slitCenterY + 0.5 * slitHeight;
lineWidth = 6.0;
lineColor = [0.05, 0.05, 0.05];

% 下半段粗线
if yLim(1) < slitYMin
    if ~isLiveHandle(cache.hSpecWallLower)
        cache.hSpecWallLower = line('Parent', ax, ...
            'XData', [wallX, wallX], ...
            'YData', [yLim(1), min(slitYMin, yLim(2))], ...
            'Color', lineColor, ...
            'LineWidth', lineWidth);
    else
        set(cache.hSpecWallLower, ...
            'XData', [wallX, wallX], ...
            'YData', [yLim(1), min(slitYMin, yLim(2))], ...
            'Visible', 'on');
    end
else
    hideHandle(cache.hSpecWallLower);
end

% 上半段粗线
if yLim(2) > slitYMax
    if ~isLiveHandle(cache.hSpecWallUpper)
        cache.hSpecWallUpper = line('Parent', ax, ...
            'XData', [wallX, wallX], ...
            'YData', [max(slitYMax, yLim(1)), yLim(2)], ...
            'Color', lineColor, ...
            'LineWidth', lineWidth);
    else
        set(cache.hSpecWallUpper, ...
            'XData', [wallX, wallX], ...
            'YData', [max(slitYMax, yLim(1)), yLim(2)], ...
            'Visible', 'on');
    end
else
    hideHandle(cache.hSpecWallUpper);
end

info.visible = handleVisible(cache.hSpecWallLower) || handleVisible(cache.hSpecWallUpper);
info.wall_x = wallX;
info.slit_center_y = slitCenterY;
info.slit_height = slitHeight;
end

function [cache, info] = renderSelectorOverlay(ax, cache, p)
%RENDERSELECTOROVERLAY  绘制 M4 速度选择器极板与电场方向
%
% 场景语义
%   - 极板区域默认由有界磁场边界控制（xMin/xMax/yMin/yMax）
%   - 中央电场箭头用 Ey 正负表示方向（向上/向下）
info = struct( ...
    'visible', false, ...
    'show_efield', false, ...
    'x_min', 0.0, ...
    'x_max', 0.0, ...
    'y_top', 0.0, ...
    'y_bottom', 0.0, ...
    'ey', 0.0 ...
);

if ~logicalField(p, 'bounded', true)
    cache = hideSelectorHandles(cache);
    return;
end

box = geom.readBoundsFromParams(p);
x1 = box.xMin;
x2 = box.xMax;
yBottom = box.yMin;
yTop = box.yMax;
lineColor = [0.12, 0.12, 0.12];

if ~isLiveHandle(cache.hSelectorPlateTop)
    cache.hSelectorPlateTop = line('Parent', ax, ...
        'XData', [x1, x2], ...
        'YData', [yTop, yTop], ...
        'Color', lineColor, ...
        'LineWidth', 3.0);
else
    set(cache.hSelectorPlateTop, ...
        'XData', [x1, x2], ...
        'YData', [yTop, yTop], ...
        'Visible', 'on');
end

if ~isLiveHandle(cache.hSelectorPlateBottom)
    cache.hSelectorPlateBottom = line('Parent', ax, ...
        'XData', [x1, x2], ...
        'YData', [yBottom, yBottom], ...
        'Color', lineColor, ...
        'LineWidth', 3.0);
else
    set(cache.hSelectorPlateBottom, ...
        'XData', [x1, x2], ...
        'YData', [yBottom, yBottom], ...
        'Visible', 'on');
end

showEField = logicalField(p, 'showEField', true);
if showEField
    ey = double(pickField(p, 'Ey', 0.0));
    dirY = sign(ey);
    if dirY == 0
        dirY = 1;
    end
    yMid = 0.5 * (yTop + yBottom);
    xMid = 0.5 * (x1 + x2);
    arrLen = 0.32 * max(yTop - yBottom, 1e-6);
    if ~isLiveHandle(cache.hSelectorEArrow)
        cache.hSelectorEArrow = quiver(ax, xMid, yMid, 0, dirY * arrLen, 0, ...
            'AutoScale', 'off', ...
            'Color', [0.95, 0.55, 0.12], ...
            'LineWidth', 2.2, ...
            'MaxHeadSize', 1.2);
    else
        set(cache.hSelectorEArrow, ...
            'XData', xMid, ...
            'YData', yMid, ...
            'UData', 0, ...
            'VData', dirY * arrLen, ...
            'Visible', 'on');
    end
    info.show_efield = true;
    info.ey = ey;
else
    hideHandle(cache.hSelectorEArrow);
end

info.visible = true;
info.x_min = x1;
info.x_max = x2;
info.y_top = yTop;
info.y_bottom = yBottom;
end

function [cache, info] = renderRailSceneBody(ax, cache, state, p, viewSpan)
%RENDERRAILSCENEBODY  渲染导轨场景主体（R1）
%
% 渲染元素
%   1) 上下导轨（两条平行线）
%   2) 导体棒（竖直线段）
%   3) 中心轨迹（可选）
%   4) 速度/电流/外力/安培力箭头（按开关显示）

info = struct( ...
    'rail_visible', false, ...
    'rod_visible', false, ...
    'resistor_visible', false, ...
    'trail_visible', false, ...
    'show_current', false, ...
    'current_source', "none", ...
    'show_drive_force', false, ...
    'show_ampere_force', false, ...
    'epsilon', double(pickField(state, 'epsilon', 0.0)), ...
    'current', double(pickField(state, 'current', 0.0)), ...
    'fmag', double(pickField(state, 'fMag', 0.0)), ...
    'in_field', logical(pickField(state, 'inField', true)) ...
);

L = max(1e-3, double(pickField(p, 'L', 1.0)));
yCenter = double(pickField(state, 'y', 0.0));
halfL = 0.5 * L;
yTop = yCenter + halfL;
yBottom = yCenter - halfL;
xRod = double(pickField(state, 'x', 0.0));
xLim = ax.XLim;

% 上导轨
if ~isLiveHandle(cache.hRailTop)
    cache.hRailTop = line('Parent', ax, ...
        'XData', xLim, ...
        'YData', [yTop, yTop], ...
        'Color', [0.10, 0.10, 0.10], ...
        'LineWidth', 2.4);
else
    set(cache.hRailTop, 'XData', xLim, 'YData', [yTop, yTop], 'Visible', 'on');
end

% 下导轨
if ~isLiveHandle(cache.hRailBottom)
    cache.hRailBottom = line('Parent', ax, ...
        'XData', xLim, ...
        'YData', [yBottom, yBottom], ...
        'Color', [0.10, 0.10, 0.10], ...
        'LineWidth', 2.4);
else
    set(cache.hRailBottom, 'XData', xLim, 'YData', [yBottom, yBottom], 'Visible', 'on');
end

% 导体棒
if ~isLiveHandle(cache.hRod)
    cache.hRod = line('Parent', ax, ...
        'XData', [xRod, xRod], ...
        'YData', [yBottom, yTop], ...
        'Color', [0.95, 0.20, 0.15], ...
        'LineWidth', 4.0);
else
    set(cache.hRod, 'XData', [xRod, xRod], 'YData', [yBottom, yTop], 'Visible', 'on');
end

info.rail_visible = true;
info.rod_visible = true;

% 左侧电阻（固定在初始位置附近，不随导体棒移动）
[cache, resistorVisible] = updateRailResistor(ax, cache, p, yBottom, yTop);
info.resistor_visible = logical(resistorVisible);

% 中心轨迹
showTrail = logicalField(p, 'showTrail', true);
traj = pickField(state, 'traj', [xRod, yCenter]);
if showTrail && isnumeric(traj) && size(traj, 2) == 2 && size(traj, 1) >= 1
    trajDraw = trimTrailForRender(traj, 1600);
    if ~isLiveHandle(cache.hTrail)
        cache.hTrail = line('Parent', ax, ...
            'XData', trajDraw(:, 1), ...
            'YData', trajDraw(:, 2), ...
            'LineStyle', '-', ...
            'Color', [0.05, 0.75, 0.25], ...
            'LineWidth', 2.0);
    else
        set(cache.hTrail, 'XData', trajDraw(:, 1), 'YData', trajDraw(:, 2), 'Visible', 'on');
    end
    info.trail_visible = true;
else
    hideHandle(cache.hTrail);
end

% 速度箭头（沿导轨方向，放在上导轨上方，避免与外力箭头重叠）
[cache, ~] = updateRailVelocityArrow(ax, cache, state, p, viewSpan, xRod, yTop, L);

% 电流方向箭头（沿导体棒方向）
%
% 方向来源
%   1) 闭路/有电流：按 I 符号
%   2) 开路（R1）：按感应电动势 epsilon 符号
showCurrent = logicalField(p, 'showCurrent', false);
currentVal = double(pickField(state, 'current', 0.0));
epsilonVal = double(pickField(state, 'epsilon', 0.0));
currentSource = "none";
dirY = 0;
if abs(currentVal) > 1e-12
    dirY = sign(currentVal);
    currentSource = "current";
elseif abs(epsilonVal) > 1e-12
    dirY = sign(epsilonVal);
    currentSource = "epsilon";
end

if showCurrent && dirY ~= 0
    arrLen = 0.55 * L;
    if ~isLiveHandle(cache.hCurrentArrow)
        cache.hCurrentArrow = quiver(ax, xRod, yCenter, 0, dirY * arrLen, 0, ...
            'AutoScale', 'off', ...
            'Color', [0.20, 0.55, 0.98], ...
            'LineWidth', 2.0, ...
            'MaxHeadSize', 1.2);
    else
        set(cache.hCurrentArrow, ...
            'XData', xRod, ...
            'YData', yCenter, ...
            'UData', 0, ...
            'VData', dirY * arrLen, ...
            'Visible', 'on');
    end
    info.show_current = true;
    info.current_source = currentSource;
else
    hideHandle(cache.hCurrentArrow);
end

% 外力箭头（沿 x 轴）
showDrive = logicalField(p, 'showDriveForce', false) && logicalField(p, 'driveEnabled', false);
Fdrive = double(pickField(p, 'Fdrive', 0.0));
if showDrive && abs(Fdrive) > 1e-12
    dirX = sign(Fdrive);
    arrLen = min(max(0.12 * viewSpan, 0.25 * L), 0.40 * viewSpan);
    if ~isLiveHandle(cache.hDriveArrow)
        cache.hDriveArrow = quiver(ax, xRod, yCenter, dirX * arrLen, 0, 0, ...
            'AutoScale', 'off', ...
            'Color', [0.96, 0.56, 0.16], ...
            'LineWidth', 2.0, ...
            'MaxHeadSize', 1.2);
    else
        set(cache.hDriveArrow, ...
            'XData', xRod, ...
            'YData', yCenter, ...
            'UData', dirX * arrLen, ...
            'VData', 0, ...
            'Visible', 'on');
    end
    info.show_drive_force = true;
else
    hideHandle(cache.hDriveArrow);
end

% 安培力箭头（沿 x 轴，方向与 Fmag 符号一致）
showAmpere = logicalField(p, 'showAmpereForce', false);
fMag = double(pickField(state, 'fMag', 0.0));
if showAmpere && abs(fMag) > 1e-12
    dirX = sign(fMag);
    arrLen = min(max(0.10 * viewSpan, 0.20 * L), 0.35 * viewSpan);
    if ~isLiveHandle(cache.hAmpereArrow)
        cache.hAmpereArrow = quiver(ax, xRod, yCenter, dirX * arrLen, 0, 0, ...
            'AutoScale', 'off', ...
            'Color', [0.70, 0.28, 0.95], ...
            'LineWidth', 2.0, ...
            'MaxHeadSize', 1.2);
    else
        set(cache.hAmpereArrow, ...
            'XData', xRod, ...
            'YData', yCenter, ...
            'UData', dirX * arrLen, ...
            'VData', 0, ...
            'Visible', 'on');
    end
    info.show_ampere_force = true;
else
    hideHandle(cache.hAmpereArrow);
end
end

function [cache, visible] = updateRailResistor(ax, cache, p, yBottom, yTop)
%UPDATERAILRESISTOR  在导轨左侧绘制等效电阻（矩形符号）
%
% 说明
%   - 该电阻用于表现“导轨中间串联电阻”的场景元素
%   - 默认位置：x0 左侧约 2.2L，可通过 p.xRes 覆盖
visible = false;

L = max(1e-3, double(pickField(p, 'L', 1.0)));
x0 = double(pickField(p, 'x0', 0.0));
xRes = double(pickField(p, 'xRes', x0 - 2.2 * L));

% 用“矩形 + 上下引线”表示电阻
yCenter = 0.5 * (yTop + yBottom);
rectH = 0.48 * max(1e-3, (yTop - yBottom));
rectW = min(max(0.16 * L, 0.06), 0.35 * L);
yRectTop = yCenter + 0.5 * rectH;
yRectBottom = yCenter - 0.5 * rectH;
xLeft = xRes - 0.5 * rectW;
xRight = xRes + 0.5 * rectW;

% 通过 NaN 分段一次画出：上引线 + 矩形边框 + 下引线
xPts = [ ...
    xRes, xRes, NaN, ...
    xLeft, xRight, xRight, xLeft, xLeft, NaN, ...
    xRes, xRes ...
];
yPts = [ ...
    yTop, yRectTop, NaN, ...
    yRectTop, yRectTop, yRectBottom, yRectBottom, yRectTop, NaN, ...
    yRectBottom, yBottom ...
];

if ~isLiveHandle(cache.hResistor)
    cache.hResistor = line('Parent', ax, ...
        'XData', xPts, ...
        'YData', yPts, ...
        'Color', [0.45, 0.22, 0.08], ...
        'LineWidth', 3.0);
else
    set(cache.hResistor, ...
        'XData', xPts, ...
        'YData', yPts, ...
        'Visible', 'on');
end

visible = true;
end

function [cache, info] = updateVelocityArrow(ax, cache, state, p, viewSpan)
%UPDATEVELOCITYARROW  更新速度箭头（显著放大）
info = struct('visible', false, 'show_switch', false, 'speed', 0.0, 'radius', 0.0, 'arrow_len', 0.0);
showV = logicalField(p, 'showV', true);
speed = hypot(double(state.vx), double(state.vy));
info.show_switch = showV;
info.speed = speed;
if ~showV || speed <= 1e-12
    hideHandle(cache.hVel);
    return;
end

radius = estimateRadius(state, p);
arrowLen = velocityArrowLength(speed, radius, viewSpan);
ux = double(state.vx) / speed;
uy = double(state.vy) / speed;

if ~isLiveHandle(cache.hVel)
    cache.hVel = quiver(ax, state.x, state.y, ux * arrowLen, uy * arrowLen, 0, ...
        'AutoScale', 'off', ...
        'Color', [0.95, 0.25, 0.20], 'LineWidth', 2.3, 'MaxHeadSize', 1.5);
else
    set(cache.hVel, ...
        'XData', state.x, ...
        'YData', state.y, ...
        'UData', ux * arrowLen, ...
        'VData', uy * arrowLen, ...
        'Visible', 'on');
end

info.visible = true;
info.radius = radius;
info.arrow_len = arrowLen;
end

function [cache, info] = updateRailVelocityArrow(ax, cache, state, p, viewSpan, xRod, yTop, L)
%UPDATERAILVELOCITYARROW  更新导轨模型速度箭头（上方偏移显示）
%
% 设计说明
%   - 速度箭头放在上导轨外侧，避免和外力/安培力箭头重叠
%   - 箭头方向仍由 vx 符号决定，长度按视野与导体棒尺寸裁剪
info = struct('visible', false, 'show_switch', false, 'speed', 0.0, 'arrow_len', 0.0);
showV = logicalField(p, 'showV', true);
vx = double(pickField(state, 'vx', 0.0));
speed = abs(vx);
info.show_switch = showV;
info.speed = speed;
if ~showV || speed <= 1e-12
    hideHandle(cache.hVel);
    return;
end

dirX = sign(vx);
arrowLen = min(max(0.12 * viewSpan, 0.45 * L), 0.55 * viewSpan);
anchorY = yTop + 0.16 * L;

if ~isLiveHandle(cache.hVel)
    cache.hVel = quiver(ax, xRod, anchorY, dirX * arrowLen, 0, 0, ...
        'AutoScale', 'off', ...
        'Color', [0.95, 0.25, 0.20], ...
        'LineWidth', 2.3, ...
        'MaxHeadSize', 1.5);
else
    set(cache.hVel, ...
        'XData', xRod, ...
        'YData', anchorY, ...
        'UData', dirX * arrowLen, ...
        'VData', 0, ...
        'Visible', 'on');
end

info.visible = true;
info.arrow_len = arrowLen;
end

function [cache, info] = updateForceArrow(ax, cache, state, p, viewSpan)
%UPDATEFORCEARROW  更新受力箭头（可选显示）
info = struct('visible', false, 'show_switch', false, 'omega', 0.0, 'arrow_len', 0.0);
showF = logicalField(p, 'showF', false);
info.show_switch = showF;
if ~showF
    hideHandle(cache.hForce);
    return;
end

speed = hypot(double(state.vx), double(state.vy));
omega = cyclotronOmega(p);
info.omega = omega;
if speed <= 1e-12 || abs(omega) <= 1e-12
    hideHandle(cache.hForce);
    return;
end

fDir = sign(omega) * [double(state.vy); -double(state.vx)];
fNorm = norm(fDir);
if fNorm <= 1e-12
    hideHandle(cache.hForce);
    return;
end
fDir = fDir / fNorm;

baseLen = velocityArrowLength(speed, estimateRadius(state, p), viewSpan);
fLen = 0.75 * baseLen;

if ~isLiveHandle(cache.hForce)
    cache.hForce = quiver(ax, state.x, state.y, fDir(1) * fLen, fDir(2) * fLen, 0, ...
        'AutoScale', 'off', ...
        'Color', [0.25, 0.70, 0.95], 'LineWidth', 2.0, 'MaxHeadSize', 1.3);
else
    set(cache.hForce, ...
        'XData', state.x, ...
        'YData', state.y, ...
        'UData', fDir(1) * fLen, ...
        'VData', fDir(2) * fLen, ...
        'Visible', 'on');
end
info.visible = true;
info.arrow_len = fLen;
end

function [cache, info] = updateSelectorForceArrows(ax, cache, state, p, viewSpan)
%UPDATESELECTORFORCEARROWS  M4 受力箭头更新（合力/电场力/磁场力）
info = struct( ...
    'visible', false, ...
    'show_switch', false, ...
    'show_felec', false, ...
    'show_fmag', false, ...
    'f_total', 0.0, ...
    'f_elec', 0.0, ...
    'f_mag', 0.0 ...
);

showTotal = logicalField(p, 'showF', false);
showFElec = logicalField(p, 'showFElec', false);
showFMag = logicalField(p, 'showFMag', false);
info.show_switch = showTotal;
info.show_felec = showFElec;
info.show_fmag = showFMag;

x = double(state.x);
y = double(state.y);
fTotal = [double(pickField(state, 'fTotalX', 0.0)); double(pickField(state, 'fTotalY', 0.0))];
fElec = [double(pickField(state, 'fElecX', 0.0)); double(pickField(state, 'fElecY', 0.0))];
fMag = [double(pickField(state, 'fMagX', 0.0)); double(pickField(state, 'fMagY', 0.0))];
info.f_total = norm(fTotal);
info.f_elec = norm(fElec);
info.f_mag = norm(fMag);

if showTotal
    [cache.hForce, totalVisible] = upsertVectorArrow(ax, cache.hForce, x, y, fTotal, [0.22, 0.70, 0.95], 2.1, viewSpan);
else
    totalVisible = false;
    hideHandle(cache.hForce);
end

if showFElec
    [cache.hForceElec, elecVisible] = upsertVectorArrow(ax, cache.hForceElec, x, y, fElec, [0.95, 0.52, 0.18], 1.9, viewSpan);
else
    elecVisible = false;
    hideHandle(cache.hForceElec);
end

if showFMag
    [cache.hForceMag, magVisible] = upsertVectorArrow(ax, cache.hForceMag, x, y, fMag, [0.62, 0.34, 0.95], 1.9, viewSpan);
else
    magVisible = false;
    hideHandle(cache.hForceMag);
end

info.visible = totalVisible || elecVisible || magVisible;
end

function [h, visible] = upsertVectorArrow(ax, h, x, y, vec, color, lineWidth, viewSpan)
%UPSERTVECTORARROW  按向量方向更新/创建 quiver 箭头
visible = false;
if norm(vec) <= 1e-12
    hideHandle(h);
    return;
end

dir = vec / norm(vec);
baseLen = 0.10 * max(viewSpan, 1e-6);
gain = 1.0 + 0.55 * log10(1.0 + norm(vec));
len = min(max(baseLen * gain, 0.08 * viewSpan), 0.35 * viewSpan);

if ~isLiveHandle(h)
    h = quiver(ax, x, y, dir(1) * len, dir(2) * len, 0, ...
        'AutoScale', 'off', ...
        'Color', color, ...
        'LineWidth', lineWidth, ...
        'MaxHeadSize', 1.3);
else
    set(h, ...
        'XData', x, ...
        'YData', y, ...
        'UData', dir(1) * len, ...
        'VData', dir(2) * len, ...
        'Color', color, ...
        'LineWidth', lineWidth, ...
        'Visible', 'on');
end
visible = true;
end

function len = velocityArrowLength(speed, radius, viewSpan)
%VELOCITYARROWLENGTH  速度箭头长度（速度+半径对数放大）
%
% 设计目标
%   - 箭头必须明显，不被粒子点淹没
%   - 速度变大/半径变大时，箭头也明显增大
speedTerm = log10(1.0 + max(speed, 0));
radiusTerm = log10(1.0 + max(radius, 0));

baseLen = 0.10 * viewSpan;
len = baseLen * (1.0 + 0.7 * speedTerm + 0.6 * radiusTerm);
len = min(max(len, 0.10 * viewSpan), 0.45 * viewSpan);
end

function r = estimateRadius(state, p)
%ESTIMATERADIUS  估计回旋半径 r = v / |omega|
speed = hypot(double(state.vx), double(state.vy));
omega = cyclotronOmega(p);
if abs(omega) <= 1e-12
    r = 0;
else
    r = speed / abs(omega);
end
end

function omega = cyclotronOmega(p)
%CYCLOTRONOMEGA  计算当前参数对应的角速度
q = pickField(p, 'q', 0.0);
m = max(pickField(p, 'm', 1.0), 1e-12);
B = pickField(p, 'B', 0.0);
Bdir = lower(strtrim(string(pickField(p, 'Bdir', "out"))));
if Bdir == "in"
    Bz = -double(B);
else
    Bz = double(B);
end
omega = double(q) * Bz / double(m);
end

function hideHandle(h)
%HIDEHANDLE  安全隐藏图元
if isLiveHandle(h)
    set(h, 'Visible', 'off');
end
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

function logAxesChildren(app, ax)
%LOGAXESCHILDREN  记录场景坐标轴子对象状态，用于排障
children = ax.Children;
count = numel(children);
allCount = numel(allchild(ax));
firstType = "";
firstVisible = "";
if count >= 1
    firstType = string(class(children(1)));
    try
        firstVisible = string(children(1).Visible);
    catch
        firstVisible = "unknown";
    end
end

logger.logEvent(app, '调试', '渲染-坐标轴对象', struct( ...
    'child_count', count, ...
    'allchild_count', allCount, ...
    'first_type', firstType, ...
    'first_visible', firstVisible, ...
    'axes_visible', string(ax.Visible), ...
    'axes_pos_text', sprintf('[%.1f, %.1f, %.1f, %.1f]', ax.Position(1), ax.Position(2), ax.Position(3), ax.Position(4)), ...
    'axes_inner_text', sprintf('[%.1f, %.1f, %.1f, %.1f]', ax.InnerPosition(1), ax.InnerPosition(2), ax.InnerPosition(3), ax.InnerPosition(4)) ...
));
end

function logRenderFinalState(app, ax, cache, state)
%LOGRENDERFINALSTATE  渲染后 UI 可见性与句柄状态诊断
figVisible = readUiVisible(readProp(app, 'ElectriSimUIFigure', []));
sceneTabVisible = readUiVisible(readProp(app, 'SceneTab', []));
axesVisible = readUiVisible(ax);

selectedTitle = "";
isSceneSelected = false;
centerTabs = readProp(app, 'CenterTabs', []);
sceneTab = readProp(app, 'SceneTab', []);
if ~isempty(centerTabs) && isgraphics(centerTabs) && isprop(centerTabs, 'SelectedTab')
    try
        sel = centerTabs.SelectedTab;
        if ~isempty(sel) && isgraphics(sel)
            if isprop(sel, 'Title')
                selectedTitle = string(sel.Title);
            else
                selectedTitle = string(class(sel));
            end
            if ~isempty(sceneTab) && isgraphics(sceneTab)
                isSceneSelected = isequal(sel, sceneTab);
            end
        end
    catch
        % 诊断日志不应中断渲染主流程
    end
end

trailVisible = handleVisible(cache.hTrail);
particleVisible = handleVisible(cache.hParticle);
velVisible = handleVisible(cache.hVel);
bMarkVisible = handleVisible(cache.hBMarks);
fieldBoxVisible = handleVisible(cache.hFieldBox);
childCount = numel(ax.Children);

logger.logEvent(app, '调试', '渲染-终态', struct( ...
    'figure_visible', figVisible, ...
    'scene_tab_visible', sceneTabVisible, ...
    'scene_selected', isSceneSelected, ...
    'selected_tab_title', selectedTitle, ...
    'axes_visible', axesVisible, ...
    'child_count', childCount, ...
    'trail_visible', trailVisible, ...
    'particle_visible', particleVisible, ...
    'vel_visible', velVisible, ...
    'bmark_visible', bMarkVisible, ...
    'field_box_visible', fieldBoxVisible, ...
    'x', double(state.x), ...
    'y', double(state.y) ...
));
end

function s = readUiVisible(h)
%READUIVISIBLE  读取 UI 组件 Visible 属性（兼容 on/off/true/false）
s = "unknown";
if ~isLiveHandle(h)
    return;
end
if isprop(h, 'Visible')
    try
        s = string(h.Visible);
    catch
        s = "unknown";
    end
end
end

function v = handleVisible(h)
%HANDLEVISIBLE  图元可见性读取
v = false;
if ~isLiveHandle(h)
    return;
end
if isprop(h, 'Visible')
    try
        vis = string(h.Visible);
        v = any(strcmpi(vis, ["on","true"]));
    catch
        v = false;
    end
end
end

function tf = isLiveHandle(h)
%ISLIVEHANDLE  宽容句柄有效性判断（兼容部分 UI 对象）
tf = false;
if isempty(h)
    return;
end
try
    tf = isvalid(h);
catch
    try
        tf = isgraphics(h);
    catch
        tf = false;
    end
end
end

function v = readProp(obj, name, fallback)
%READPROP  安全读取对象属性
v = fallback;
if isempty(obj)
    return;
end
if isprop(obj, name)
    try
        v = obj.(name);
    catch
        v = fallback;
    end
end
end

function tf = shouldLogRender(state)
%SHOULDLOGRENDER  渲染日志节流判定
%
% 规则
%   - stepCount 可用时：每 120 帧记录一次
%   - stepCount 缺失时：默认记录
if isstruct(state) && isfield(state, 'stepCount')
    tf = mod(double(state.stepCount), 120) == 0;
else
    tf = true;
end
end

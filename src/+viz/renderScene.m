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

% 坐标轴设置
ax.XLim = xLim;
ax.YLim = yLim;
% uiaxes 上用 DataAspectRatio 手动锁定更稳
ax.DataAspectRatio = [1 1 1];
ax.DataAspectRatioMode = 'manual';
if logicalField(p, 'showGrid', true)
    ax.XGrid = 'on';
    ax.YGrid = 'on';
else
    ax.XGrid = 'off';
    ax.YGrid = 'off';
end

tNow = pickField(state, 't', 0.0);
title(ax, sprintf('粒子运动场景（t = %.3f s）', double(tNow)));
xlabel(ax, 'x (m)');
ylabel(ax, 'y (m)');

if doLog
    logger.logEvent(app, '调试', '渲染-坐标轴', struct( ...
        't', double(tNow), ...
        'x', double(state.x), ...
        'y', double(state.y), ...
        'vx', double(state.vx), ...
        'vy', double(state.vy), ...
        'traj_points', size(state.traj, 1), ...
        'auto_follow', logicalField(p, 'autoFollow', true), ...
        'follow_span', double(pickField(p, 'followSpan', 2.4)), ...
        'x_lim_text', sprintf('[%.3f, %.3f]', xLim(1), xLim(2)), ...
        'y_lim_text', sprintf('[%.3f, %.3f]', yLim(1), yLim(2)), ...
        'view_span', double(viewSpan) ...
    ));
end

% 磁场标记
[cache, bInfo] = updateBMarks(ax, cache, p, xLim, yLim, viewSpan);
if doLog
    logger.logEvent(app, '调试', '渲染-磁场标记', bInfo);
end

% 轨迹
showTrail = logicalField(p, 'showTrail', true);
traj = state.traj;
if showTrail && size(traj, 1) >= 1
    if ~isLiveHandle(cache.hTrail)
        cache.hTrail = line('Parent', ax, ...
            'XData', traj(:, 1), ...
            'YData', traj(:, 2), ...
            'LineStyle', '-', ...
            'Color', [0.05, 0.75, 0.25], ...
            'LineWidth', 2.2);
    else
        set(cache.hTrail, 'XData', traj(:, 1), 'YData', traj(:, 2), 'Visible', 'on');
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
[cache, fInfo] = updateForceArrow(ax, cache, state, p, viewSpan);
if doLog
    logger.logEvent(app, '调试', '渲染-受力箭头', fInfo);
end

% 关闭调试探针：避免在粒子旁出现粉色标记干扰观察
hideHandle(cache.hDebugText);

setRenderCache(ax, cache);
if doLog
    logAxesChildren(app, ax);
end
drawnow limitrate nocallbacks;
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

function cache = getRenderCache(ax)
%GETRENDERCACHE  获取/初始化渲染句柄缓存
cache = struct( ...
    'hTrail', [], ...
    'hParticle', [], ...
    'hVel', [], ...
    'hForce', [], ...
    'hBMarks', [], ...
    'hFieldBox', [], ...
    'hDebugText', [] ...
);

ud = ax.UserData;
if isstruct(ud) && isfield(ud, 'renderCache') && isstruct(ud.renderCache)
    cache = mergeCache(cache, ud.renderCache);
end

hold(ax, 'on');
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

function [cache, info] = updateBMarks(ax, cache, p, xLim, yLim, viewSpan)
%UPDATEBMARKS  更新磁场标记与有界磁场边框
%
% 渲染规则
%   - bounded=false：磁场标记覆盖当前可视范围
%   - bounded=true ：磁场标记仅在有界磁场区域内绘制，并显示黑色粗边框
info = struct( ...
    'visible', false, ...
    'mark_count', 0, ...
    'marker', "-", ...
    'bdir', "-", ...
    'bounded', false, ...
    'box_visible', false ...
);

bounded = logicalField(p, 'bounded', false);
info.bounded = bounded;

% 边框显示独立于 showBMarks：有界模式下始终显示边界位置
[cache, boxVisible] = updateFieldBox(ax, cache, p, bounded);
info.box_visible = boxVisible;

showB = logicalField(p, 'showBMarks', true);
if ~showB
    hideHandle(cache.hBMarks);
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

if bounded
    % 有界模式固定按“整块磁场区域”铺设标记，不随当前视窗裁剪。
    % 这样在拖拽坐标轴或粒子远离后，磁场标记仍保持完整一致。
    box = readBoundaryBoxFromParams(p);
    [xx, yy] = buildBMarkGridInBox(box);
else
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

info.visible = true;
info.mark_count = numel(xx);
info.marker = marker;
info.bdir = Bdir;
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

function [cache, visible] = updateFieldBox(ax, cache, p, bounded)
%UPDATEFIELDBOX  更新有界磁场黑色边框
visible = false;
if ~bounded
    hideHandle(cache.hFieldBox);
    return;
end

box = readBoundaryBoxFromParams(p);
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

function box = readBoundaryBoxFromParams(p)
%READBOUNDARYBOXFROMPARAMS  从参数读取并规范化矩形边界
box = struct();
box.xMin = double(pickField(p, 'xMin', -1.0));
box.xMax = double(pickField(p, 'xMax', 1.0));
box.yMin = double(pickField(p, 'yMin', -1.0));
box.yMax = double(pickField(p, 'yMax', 1.0));

if box.xMin > box.xMax
    t = box.xMin;
    box.xMin = box.xMax;
    box.xMax = t;
end
if box.yMin > box.yMax
    t = box.yMin;
    box.yMin = box.yMax;
    box.yMax = t;
end
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
%   - stepCount 可用时：每 20 帧记录一次
%   - stepCount 缺失时：默认记录
if isstruct(state) && isfield(state, 'stepCount')
    tf = mod(double(state.stepCount), 20) == 0;
else
    tf = true;
end
end

function state = step(state, params, dt)
%STEP  推进一步（支持 M1 有界/无界匀强磁场）
%
% 输入
%   state (1,1) struct : 当前状态（至少包含 x/y/vx/vy）
%   params (1,1) struct : 参数结构（含 bounded 与边界范围）
%   dt    (1,1) double : 基础步长（秒）
%
% 输出
%   state (1,1) struct : 推进后的新状态
%
% 实现要点
%   1) 无界模式：全程使用旋转矩阵解析推进（与旧版本一致）
%   2) 有界模式：矩形区域内走磁场推进，区域外走匀速直线
%   3) 若单步内发生进/出边界：使用二分法定位穿越时刻，再分段推进
%
% 物理约束
%   - 磁场外: r_{n+1} = r_n + v_n * dt, a = 0
%   - 磁场内: 使用解析旋转矩阵，避免欧拉积分漂移

arguments
    state (1,1) struct
    params (1,1) struct
    dt (1,1) double {mustBePositive}
end

% 顶部速度倍率统一缩放仿真步长
if isfield(params, 'speedScale')
    dt = dt * max(0.01, double(params.speedScale));
end

% 缺字段兜底：允许外部直接调用 step
state = ensureBaseState(state, params);

omega = cyclotronOmega(params);
rOld = [double(state.x); double(state.y)];
vOld = [double(state.vx); double(state.vy)];

bounded = logicalField(params, 'bounded', false);
if ~bounded
    % 无界：全程都在磁场内
    [rNew, vNew] = propagateSegment(rOld, vOld, omega, true, dt);
    inField = true;
    modeText = "unbounded";
else
    % 有界：可能出现“外 -> 内 -> 外”链条
    box = readBoundaryBox(params);
    [rNew, vNew, inField] = propagateBoundedChain(rOld, vOld, omega, dt, box);
    if inField
        modeText = "bounded_inside";
    else
        modeText = "bounded_outside";
    end
end

state.t = state.t + dt;
state.x = rNew(1);
state.y = rNew(2);
state.vx = vNew(1);
state.vy = vNew(2);
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.inField = inField;
state.mode = modeText;
end

function state = ensureBaseState(state, params)
%ENSUREBASESTATE  统一补齐状态字段
if ~isfield(state, 'x') || ~isfield(state, 'y') || ~isfield(state, 'vx') || ~isfield(state, 'vy')
    state = engine.reset(state, params);
end
if ~isfield(state, 't')
    state.t = 0.0;
end
if ~isfield(state, 'traj') || ~isnumeric(state.traj) || size(state.traj, 2) ~= 2
    state.traj = [state.x, state.y];
end
if ~isfield(state, 'stepCount')
    state.stepCount = 0;
end
end

function [rNew, vNew, inField] = propagateBoundedChain(r0, v0, omega, dt, box)
%PROPAGATEBOUNDEDCHAIN  有界单步分段推进
%
% 规则
%   - 在当前区域假设下试走完整 dt
%   - 若区域属性未变化，直接接受
%   - 若发生跨界，用二分法定位穿越时刻 tau 并拆分子段

remaining = double(dt);
rNow = r0;
vNow = v0;
inNow = isInsideRect(rNow, box);

% 一步里最多处理若干次跨界，防止极端参数导致死循环
maxCrossEvents = 8;
crossCount = 0;

while remaining > 1e-12 && crossCount < maxCrossEvents
    [rTry, vTry] = propagateSegment(rNow, vNow, omega, inNow, remaining);
    inTry = isInsideRect(rTry, box);

    % 当前剩余时间内没有跨界，直接收敛
    if inTry == inNow
        rNow = rTry;
        vNow = vTry;
        remaining = 0;
        break;
    end

    % 发生跨界：用二分法找首次穿越时刻
    tau = findCrossingTimeByBisection(rNow, vNow, omega, remaining, inNow, box);
    tau = max(0.0, min(tau, remaining));

    % 数值保护：避免 tau=0 导致循环不前进
    if tau <= 1e-12
        tau = min(remaining, max(1e-9, 1e-6 * remaining));
    end

    [rNow, vNow] = propagateSegment(rNow, vNow, omega, inNow, tau);
    remaining = remaining - tau;

    % 穿越后按几何位置刷新区域属性
    inAfter = isInsideRect(rNow, box);
    if inAfter == inNow
        inNow = ~inNow;
    else
        inNow = inAfter;
    end

    crossCount = crossCount + 1;
end

% 兜底：若迭代次数用尽仍有剩余时间，按当前区域推进完
if remaining > 1e-12
    [rNow, vNow] = propagateSegment(rNow, vNow, omega, inNow, remaining);
    inNow = isInsideRect(rNow, box);
end

rNew = rNow;
vNew = vNow;
inField = inNow;
end

function tau = findCrossingTimeByBisection(r0, v0, omega, totalDt, inStart, box)
%FINDCROSSINGTIMEBYBISECTION  二分定位首次跨界时刻
%
% 输入
%   r0, v0   : 子段起点状态
%   omega    : 回旋角速度
%   totalDt  : 子段总时长
%   inStart  : 起点是否在磁场区域内
%   box      : 边界盒
%
% 输出
%   tau      : 首次跨界时刻（0 ~ totalDt）

lo = 0.0;
hi = double(totalDt);

for k = 1:32
    mid = 0.5 * (lo + hi);
    [rMid, ~] = propagateSegment(r0, v0, omega, inStart, mid);
    inMid = isInsideRect(rMid, box);

    if inMid == inStart
        lo = mid;
    else
        hi = mid;
    end
end

% hi 更接近“刚跨界后的时刻”
tau = hi;
end

function [rNew, vNew] = propagateSegment(rOld, vOld, omega, inField, dt)
%PROPAGATESEGMENT  在指定区域属性下推进一个子段
if inField
    [rNew, vNew] = propagateInField(rOld, vOld, omega, dt);
else
    [rNew, vNew] = propagateFree(rOld, vOld, dt);
end
end

function [rNew, vNew] = propagateFree(rOld, vOld, dt)
%PROPAGATEFREE  磁场外推进：匀速直线
rNew = rOld + double(dt) * vOld;
vNew = vOld;
end

function [rNew, vNew] = propagateInField(rOld, vOld, omega, dt)
%PROPAGATEINFIELD  磁场内推进：旋转矩阵解析法
%
% 公式
%   theta = omega * dt
%   v_{n+1} = R(theta) * v_n
%   r_{n+1} = r_n + (1/omega) * A(theta) * v_n
%
% 其中
%   R = [cos(theta),  sin(theta);
%       -sin(theta),  cos(theta)]
%   A = [sin(theta), 1-cos(theta);
%       -(1-cos(theta)), sin(theta)]

if abs(omega) < 1e-12
    [rNew, vNew] = propagateFree(rOld, vOld, dt);
    return;
end

theta = double(omega) * double(dt);
c = cos(theta);
s = sin(theta);

R = [c, s; -s, c];
A = [s, (1 - c); -(1 - c), s];

vNew = R * vOld;
rNew = rOld + (A * vOld) / double(omega);
end

function box = readBoundaryBox(params)
%READBOUNDARYBOX  读取并规范化矩形边界
xMin = double(pickField(params, 'xMin', -1.0));
xMax = double(pickField(params, 'xMax', 1.0));
yMin = double(pickField(params, 'yMin', -1.0));
yMax = double(pickField(params, 'yMax', 1.0));

if xMin > xMax
    t = xMin;
    xMin = xMax;
    xMax = t;
end
if yMin > yMax
    t = yMin;
    yMin = yMax;
    yMax = t;
end

box = struct('xMin', xMin, 'xMax', xMax, 'yMin', yMin, 'yMax', yMax);
end

function tf = isInsideRect(r, box)
%ISINSIDERECT  判断点是否位于边界盒内部（含边界）
%
% 数值说明
%   - 加入微小容差 tol，减少浮点误差引起的边界抖动
x = double(r(1));
y = double(r(2));
tol = 1e-12;

tf = (x >= box.xMin - tol) && (x <= box.xMax + tol) && ...
     (y >= box.yMin - tol) && (y <= box.yMax + tol);
end

function omega = cyclotronOmega(params)
%CYCLOTRONOMEGA  计算回旋角速度 omega = q*Bz/m
q = pickField(params, 'q', 0.0);
m = max(pickField(params, 'm', 1.0), 1e-12);
B = pickField(params, 'B', 0.0);
Bdir = lower(strtrim(string(pickField(params, 'Bdir', "out"))));

if Bdir == "in"
    Bz = -double(B);
else
    Bz = double(B);
end

omega = double(q) * Bz / double(m);
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

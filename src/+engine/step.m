function state = step(state, params, dt)
%STEP  推进一步（按 modelType 分发）
%
% 输入
%   state (1,1) struct : 当前状态
%   params (1,1) struct : 参数结构
%   dt    (1,1) double : 基础步长（秒）
%
% 输出
%   state (1,1) struct : 推进后的新状态
%
% 说明
%   - particle: 旋转矩阵解析推进（含有界跨界二分）
%   - rail    : 导轨模型推进（R 统一模板：开路匀速 + 闭路阻尼）

arguments
    state (1,1) struct
    params (1,1) struct
    dt (1,1) double {mustBePositive}
end

if isfield(params, 'speedScale')
    dt = dt * max(0.01, double(params.speedScale));
end

modelType = resolveModelType(params);
switch modelType
    case "rail"
        state = stepRailState(state, params, dt);
    otherwise
        state = stepParticleState(state, params, dt);
end

end

function state = stepParticleState(state, params, dt)
%STEPPARTICLESTATE  M 系列粒子推进
state = ensureParticleState(state, params);

omega = cyclotronOmega(params);
rOld = [double(state.x); double(state.y)];
vOld = [double(state.vx); double(state.vy)];

bounded = logicalField(params, 'bounded', false);
if ~bounded
    [rNew, vNew] = propagateSegment(rOld, vOld, omega, true, dt);
    inField = true;
    modeText = "unbounded";
else
    box = geom.readBoundsFromParams(params);
    [rNew, vNew, inField] = propagateBoundedChain(rOld, vOld, omega, dt, box);
    if inField
        modeText = "bounded_inside";
    else
        modeText = "bounded_outside";
    end
end

state.t = state.t + dt;
state.modelType = "particle";
state.x = rNew(1);
state.y = rNew(2);
state.vx = vNew(1);
state.vy = vNew(2);
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.inField = inField;
state.mode = modeText;
end

function state = ensureParticleState(state, params)
%ENSUREPARTICLESTATE  补齐粒子状态字段
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

function state = stepRailState(state, params, dt)
%STEPRAILSTATE  R 系列导轨推进
state = ensureRailState(state, params);
qHeatPrev = double(pickField(state, 'qHeat', 0.0));

x0 = double(state.x);
y0 = double(state.y);
v0 = double(state.vx);

m = max(double(pickField(params, 'm', 1.0)), 1e-9);
Fdrive = 0.0;
if logicalField(params, 'driveEnabled', false)
    Fdrive = double(pickField(params, 'Fdrive', 0.0));
end

inFieldStart = isRailInField([x0; y0], params);
loopClosed = logicalField(params, 'loopClosed', false);

if inFieldStart && loopClosed
    % 闭环导轨模型：dv/dt = (Fdrive/m) - (k/m) v
    k = railDampingK(params);
    alpha = k / m;
    b = Fdrive / m;
    if abs(alpha) > 1e-12
        vInf = b / alpha;
        expTerm = exp(-alpha * dt);
        v1 = vInf + (v0 - vInf) * expTerm;
        x1 = x0 + vInf * dt + ((v0 - vInf) / alpha) * (1 - expTerm);
    else
        a = b;
        v1 = v0 + a * dt;
        x1 = x0 + v0 * dt + 0.5 * a * dt^2;
    end
else
    % 开路主链：导体棒等效匀速（可选叠加外力）
    a = Fdrive / m;
    v1 = v0 + a * dt;
    x1 = x0 + v0 * dt + 0.5 * a * dt^2;
end

y1 = y0;
inFieldEnd = isRailInField([x1; y1], params);

state.t = state.t + dt;
state.modelType = "rail";
state.x = x1;
state.y = y1;
state.vx = v1;
state.vy = 0.0;
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.inField = inFieldEnd;

if logicalField(params, 'bounded', false)
    if inFieldEnd
        state.mode = "rail_bounded_inside";
    else
        state.mode = "rail_bounded_outside";
    end
else
    state.mode = "rail_unbounded";
end

state = attachRailOutputs(state, params, inFieldEnd);
state.qHeat = qHeatPrev + max(0.0, double(state.pElec)) * double(dt);
if isfield(state, 'rail') && isstruct(state.rail)
    state.rail.qHeat = double(state.qHeat);
end
end

function state = ensureRailState(state, params)
%ENSURERAILSTATE  补齐导轨状态字段
if ~isfield(state, 'x') || ~isfield(state, 'y') || ~isfield(state, 'vx')
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
if ~isfield(state, 'qHeat')
    state.qHeat = 0.0;
end
end

function state = attachRailOutputs(state, params, inField)
%ATTACHRAILOUTPUTS  计算导轨输出量
vx = double(pickField(state, 'vx', 0.0));
L = max(double(pickField(params, 'L', 1.0)), 1e-9);
R = max(double(pickField(params, 'R', 1.0)), 1e-12);
loopClosed = logicalField(params, 'loopClosed', false);

if inField
    epsilon = signedB(params) * L * vx;
else
    epsilon = 0.0;
end

if loopClosed
    current = epsilon / R;
    % 安培力方向必须阻碍导体棒当前速度（楞次定律）
    fMag = -signedB(params) * current * L;
    pElec = current^2 * R;
else
    current = 0.0;
    fMag = 0.0;
    pElec = 0.0;
end

state.epsilon = epsilon;
state.current = current;
state.fMag = fMag;
state.pElec = pElec;
state.pMech = double(pickField(params, 'Fdrive', 0.0)) * vx;
state.rail = struct( ...
    'L', L, ...
    'x', double(state.x), ...
    'yCenter', double(state.y), ...
    'inField', logical(inField), ...
    'epsilon', epsilon, ...
    'current', current, ...
    'fMag', fMag, ...
    'pElec', pElec ...
);
end

function inField = isRailInField(r, params)
%ISRAILINFIELD  计算导体棒中心是否位于磁场有效区域
if ~logicalField(params, 'bounded', false)
    inField = true;
    return;
end
box = geom.readBoundsFromParams(params);
inField = geom.isInsideBounds(r, box);
end

function k = railDampingK(params)
%RAILDAMPINGK  回路阻尼系数 k = B^2 L^2 / R
B = abs(double(pickField(params, 'B', 0.0)));
L = abs(double(pickField(params, 'L', 1.0)));
R = max(double(pickField(params, 'R', 1.0)), 1e-12);
k = (B * L)^2 / R;
end

function modelType = resolveModelType(params)
%RESOLVEMODELTYPE  解析当前参数对应模型类型
modelType = lower(strtrim(string(pickField(params, 'modelType', "particle"))));
if startsWith(modelType, "rail")
    modelType = "rail";
else
    modelType = "particle";
end
end

function [rNew, vNew, inField] = propagateBoundedChain(r0, v0, omega, dt, box)
%PROPAGATEBOUNDEDCHAIN  有界单步分段推进
remaining = double(dt);
rNow = r0;
vNow = v0;
inNow = geom.isInsideBounds(rNow, box);

maxCrossEvents = 8;
crossCount = 0;

while remaining > 1e-12 && crossCount < maxCrossEvents
    [rTry, vTry] = propagateSegment(rNow, vNow, omega, inNow, remaining);
    inTry = geom.isInsideBounds(rTry, box);

    if inTry == inNow
        rNow = rTry;
        vNow = vTry;
        remaining = 0;
        break;
    end

    tau = findCrossingTimeByBisection(rNow, vNow, omega, remaining, inNow, box);
    tau = max(0.0, min(tau, remaining));
    if tau <= 1e-12
        tau = min(remaining, max(1e-9, 1e-6 * remaining));
    end

    [rNow, vNow] = propagateSegment(rNow, vNow, omega, inNow, tau);
    remaining = remaining - tau;

    inAfter = geom.isInsideBounds(rNow, box);
    if inAfter == inNow
        inNow = ~inNow;
    else
        inNow = inAfter;
    end

    crossCount = crossCount + 1;
end

if remaining > 1e-12
    [rNow, vNow] = propagateSegment(rNow, vNow, omega, inNow, remaining);
    inNow = geom.isInsideBounds(rNow, box);
end

rNew = rNow;
vNew = vNow;
inField = inNow;
end

function tau = findCrossingTimeByBisection(r0, v0, omega, totalDt, inStart, box)
%FINDCROSSINGTIMEBYBISECTION  二分定位首次跨界时刻
lo = 0.0;
hi = double(totalDt);

for k = 1:32
    mid = 0.5 * (lo + hi);
    [rMid, ~] = propagateSegment(r0, v0, omega, inStart, mid);
    inMid = geom.isInsideBounds(rMid, box);

    if inMid == inStart
        lo = mid;
    else
        hi = mid;
    end
end

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

function omega = cyclotronOmega(params)
%CYCLOTRONOMEGA  计算回旋角速度 omega = q*Bz/m
q = pickField(params, 'q', 0.0);
m = max(pickField(params, 'm', 1.0), 1e-12);
Bz = signedB(params);
omega = double(q) * Bz / double(m);
end

function Bz = signedB(params)
%SIGNEDB  按方向得到带符号 Bz（出屏为正，入屏为负）
B = double(pickField(params, 'B', 0.0));
Bdir = lower(strtrim(string(pickField(params, 'Bdir', "out"))));
if Bdir == "in"
    Bz = -B;
else
    Bz = B;
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

function state = dualRodAdvance(stateIn, params, dt)
%DUALRODADVANCE  R5 双导体棒事件驱动推进（含碰撞与边界切换）
%
% 用途
%   - 在单个步长 dt 内，执行“解析段推进 + 事件定位 + 事件映射”循环。
%   - 支持两类事件：
%       1) 碰撞事件：xB-xA=0（含恢复系数 rho）
%       2) 边界事件：xA/xB 穿越 xMin/xMax（导致模式切换）
%
% 输入
%   stateIn (1,1) struct
%     输入状态，至少应包含 xA/xB/vA/vB（缺失时回退到 params 初值）。
%   params  (1,1) struct
%     参数结构，至少应包含 mA/mB、FdriveA/FdriveB、rho、边界等字段。
%   dt      (1,1) double
%     本次推进步长（秒）。
%
% 输出
%   state (1,1) struct
%     推进后的状态，至少包含：
%       - xA/xB/vA/vB
%       - qHeatR（焦耳热累计）
%       - qHeatColl（碰撞热累计）
%       - qHeat（总热量累计=qHeatR+qHeatColl）
%
% 说明
%   - 模式内采用解析推进（S0/S1/S2/S3），避免把核心动力学降级为欧拉近似。
%   - R5_V2 口径下统一按动力学链路推进：FdriveA/FdriveB 可为 0，自动退化。

arguments
    stateIn (1,1) struct
    params (1,1) struct
    dt (1,1) double {mustBeNonnegative}
end

state = ensureDualState(stateIn, params);
if dt <= 0
    state.qHeat = state.qHeatR + state.qHeatColl;
    return;
end

remaining = double(dt);
maxEvents = 32;
tolTime = 1e-12;

for k = 1:maxEvents
    if remaining <= tolTime
        break;
    end

    out0 = physics.dualRodOutputs(state, params);
    model = buildSegmentModel(state, params, out0);
    [tauEvent, eventType] = findEarliestEvent(model, params, remaining);

    tau = min(max(tauEvent, 0.0), remaining);
    stateSegEnd = evalSegment(model, tau);

    dQ = segmentHeatDelta(state, stateSegEnd, params, out0, tau, model.dynamicsEnabled);
    state.qHeatR = state.qHeatR + dQ;

    state.xA = stateSegEnd.xA;
    state.xB = stateSegEnd.xB;
    state.vA = stateSegEnd.vA;
    state.vB = stateSegEnd.vB;

    if eventType == "collision"
        [state, dQColl] = applyCollisionEvent(state, params);
        state.qHeatColl = state.qHeatColl + dQColl;
    elseif eventType == "boundary"
        state = clampBoundaryEvent(state, params);
    end

    remaining = remaining - tau;
    if eventType == "none"
        break;
    end
end

if remaining > tolTime
    out0 = physics.dualRodOutputs(state, params);
    model = buildSegmentModel(state, params, out0);
    stateSegEnd = evalSegment(model, remaining);
    dQ = segmentHeatDelta(state, stateSegEnd, params, out0, remaining, model.dynamicsEnabled);
    state.qHeatR = state.qHeatR + dQ;
    state.xA = stateSegEnd.xA;
    state.xB = stateSegEnd.xB;
    state.vA = stateSegEnd.vA;
    state.vB = stateSegEnd.vB;
end

if state.xB < state.xA
    xMid = 0.5 * (state.xA + state.xB);
    state.xA = xMid;
    state.xB = xMid;
end

state.qHeatR = max(0.0, double(state.qHeatR));
state.qHeatColl = max(0.0, double(state.qHeatColl));
state.qHeat = state.qHeatR + state.qHeatColl;
end

function state = ensureDualState(stateIn, params)
%ENSUREDUALSTATE  补齐双棒推进所需最小状态字段
state = stateIn;

if ~isfield(state, 'xA')
    state.xA = toDouble(pickField(params, 'xA0', 0.0), 0.0);
end
if ~isfield(state, 'xB')
    state.xB = toDouble(pickField(params, 'xB0', state.xA + 1.0), state.xA + 1.0);
end
if ~isfield(state, 'vA')
    state.vA = toDouble(pickField(params, 'vA0', 0.0), 0.0);
end
if ~isfield(state, 'vB')
    state.vB = toDouble(pickField(params, 'vB0', 0.0), 0.0);
end

if state.xB < state.xA
    xMid = 0.5 * (state.xA + state.xB);
    state.xA = xMid;
    state.xB = xMid;
end

if ~isfield(state, 'qHeatR')
    qHeatTotal = toDouble(pickField(state, 'qHeat', 0.0), 0.0);
    qHeatColl = toDouble(pickField(state, 'qHeatColl', 0.0), 0.0);
    state.qHeatR = max(qHeatTotal - qHeatColl, 0.0);
end
if ~isfield(state, 'qHeatColl')
    state.qHeatColl = toDouble(pickField(state, 'qColl', 0.0), 0.0);
end
if ~isfield(state, 'qHeat')
    state.qHeat = double(state.qHeatR) + double(state.qHeatColl);
end
end

function model = buildSegmentModel(state, params, out0)
%BUILDSEGMENTMODEL  构建当前模式下的解析段模型
fA = toDouble(pickField(params, 'FdriveA', pickField(params, 'Fdrive', 0.0)), 0.0);
fB = toDouble(pickField(params, 'FdriveB', pickField(params, 'Fdrive', 0.0)), 0.0);

mA = max(toDouble(pickField(params, 'mA', pickField(params, 'm', 1.0)), 1.0), 1e-12);
mB = max(toDouble(pickField(params, 'mB', pickField(params, 'm', 1.0)), 1.0), 1e-12);

model = struct();
model.xA0 = double(state.xA);
model.xB0 = double(state.xB);
model.vA0 = double(state.vA);
model.vB0 = double(state.vB);
model.mA = mA;
model.mB = mB;
model.fA = fA;
model.fB = fB;
model.k = max(toDouble(pickField(out0, 'kCoupling', 0.0), 0.0), 0.0);
model.mode = upper(strtrim(string(pickField(out0, 'mode', "S0"))));
model.dynamicsEnabled = true;
model.type = "uniform";

if model.k <= 1e-12 || model.mode == "S0"
    model.type = "s0";
    model.aA = model.fA / model.mA;
    model.aB = model.fB / model.mB;
    return;
end

switch model.mode
    case "S1"
        model.type = "s1";
        model.alphaA = model.k / model.mA;
        model.vInfA = model.fA / model.k;
        model.aB = model.fB / model.mB;
    case "S2"
        model.type = "s2";
        model.alphaB = model.k / model.mB;
        model.vInfB = model.fB / model.k;
        model.aA = model.fA / model.mA;
    case "S3"
        model.type = "s3";
        M = model.mA + model.mB;
        model.M = M;
        model.etaA = model.mA / M;
        model.etaB = model.mB / M;
        model.xCm0 = (model.mA * model.xA0 + model.mB * model.xB0) / M;
        model.vCm0 = (model.mA * model.vA0 + model.mB * model.vB0) / M;
        model.aCm = (model.fA + model.fB) / M;
        model.u0 = model.vB0 - model.vA0;
        model.xRel0 = model.xB0 - model.xA0;
        model.alpha = model.k * (1.0 / model.mA + 1.0 / model.mB);
        model.b = model.fB / model.mB - model.fA / model.mA;
        if model.alpha > 1e-12
            model.uInf = model.b / model.alpha;
        else
            model.uInf = 0.0;
        end
    otherwise
        model.type = "s0";
        model.aA = model.fA / model.mA;
        model.aB = model.fB / model.mB;
end
end

function state = evalSegment(model, tau)
%EVALSEGMENT  计算解析段在 tau 时刻的状态
t = max(0.0, double(tau));
state = struct('xA', model.xA0, 'xB', model.xB0, 'vA', model.vA0, 'vB', model.vB0);

switch model.type
    case "uniform"
        state.xA = model.xA0 + model.vA0 * t;
        state.xB = model.xB0 + model.vB0 * t;
        state.vA = model.vA0;
        state.vB = model.vB0;

    case "s0"
        state.vA = model.vA0 + model.aA * t;
        state.vB = model.vB0 + model.aB * t;
        state.xA = model.xA0 + model.vA0 * t + 0.5 * model.aA * t^2;
        state.xB = model.xB0 + model.vB0 * t + 0.5 * model.aB * t^2;

    case "s1"
        if model.alphaA > 1e-12
            e = exp(-model.alphaA * t);
            state.vA = model.vInfA + (model.vA0 - model.vInfA) * e;
            state.xA = model.xA0 + model.vInfA * t + ((model.vA0 - model.vInfA) / model.alphaA) * (1.0 - e);
        else
            aA = model.fA / model.mA;
            state.vA = model.vA0 + aA * t;
            state.xA = model.xA0 + model.vA0 * t + 0.5 * aA * t^2;
        end
        state.vB = model.vB0 + model.aB * t;
        state.xB = model.xB0 + model.vB0 * t + 0.5 * model.aB * t^2;

    case "s2"
        if model.alphaB > 1e-12
            e = exp(-model.alphaB * t);
            state.vB = model.vInfB + (model.vB0 - model.vInfB) * e;
            state.xB = model.xB0 + model.vInfB * t + ((model.vB0 - model.vInfB) / model.alphaB) * (1.0 - e);
        else
            aB = model.fB / model.mB;
            state.vB = model.vB0 + aB * t;
            state.xB = model.xB0 + model.vB0 * t + 0.5 * aB * t^2;
        end
        state.vA = model.vA0 + model.aA * t;
        state.xA = model.xA0 + model.vA0 * t + 0.5 * model.aA * t^2;

    case "s3"
        if model.alpha > 1e-12
            e = exp(-model.alpha * t);
            u = model.uInf + (model.u0 - model.uInf) * e;
            xRel = model.xRel0 + model.uInf * t + ((model.u0 - model.uInf) / model.alpha) * (1.0 - e);
        else
            u = model.u0 + model.b * t;
            xRel = model.xRel0 + model.u0 * t + 0.5 * model.b * t^2;
        end
        vCm = model.vCm0 + model.aCm * t;
        xCm = model.xCm0 + model.vCm0 * t + 0.5 * model.aCm * t^2;
        state.vA = vCm - model.etaB * u;
        state.vB = vCm + model.etaA * u;
        state.xA = xCm - model.etaB * xRel;
        state.xB = xCm + model.etaA * xRel;

    otherwise
        % 兜底分支：按匀速处理，避免异常模式导致崩溃
        state.xA = model.xA0 + model.vA0 * t;
        state.xB = model.xB0 + model.vB0 * t;
        state.vA = model.vA0;
        state.vB = model.vB0;
end
end

function [tau, eventType] = findEarliestEvent(model, params, totalDt)
%FINDEARLIESTEVENT  在 [0,totalDt] 内定位最早事件
tol = 1e-10;
tauMin = inf;
eventType = "none";
T = double(totalDt);
if T <= tol
    tau = T;
    return;
end

s0 = evalSegment(model, 0.0);
sT = evalSegment(model, T);

% ---------- 1) 碰撞事件 ----------
xRel0 = s0.xB - s0.xA;
xRelT = sT.xB - sT.xA;
if xRel0 > tol && xRelT <= 0.0
    f = @(t) (evalSegment(model, t).xB - evalSegment(model, t).xA);
    tHit = findRootBisection(f, 0.0, T);
    if isfinite(tHit) && tHit > tol
        tauMin = tHit;
        eventType = "collision";
    end
end

% ---------- 2) 边界事件 ----------
bounded = toLogical(pickField(params, 'bounded', true), true);
if bounded
    xMin = toDouble(pickField(params, 'xMin', 0.0), 0.0);
    xMax = toDouble(pickField(params, 'xMax', 4.0), 4.0);
    if xMax < xMin
        tmp = xMin;
        xMin = xMax;
        xMax = tmp;
    end

    candidates = { ...
        @(s) s.xA - xMin, ...
        @(s) s.xA - xMax, ...
        @(s) s.xB - xMin, ...
        @(s) s.xB - xMax ...
    };
    for i = 1:numel(candidates)
        g = candidates{i};
        g0 = g(s0);
        gT = g(sT);
        if ~isFiniteScalar(g0) || ~isFiniteScalar(gT)
            continue;
        end
        if abs(g0) <= tol
            % 起点就在边界上：不把 t=0 视为新事件，避免死循环
            continue;
        end
        if g0 * gT > 0
            continue;
        end
        f = @(t) g(evalSegment(model, t));
        tHit = findRootBisection(f, 0.0, T);
        if ~(isfinite(tHit) && tHit > tol)
            continue;
        end
        if tHit + tol < tauMin
            tauMin = tHit;
            eventType = "boundary";
        elseif abs(tHit - tauMin) <= tol && eventType ~= "collision"
            % 同时刻出现多个边界事件时维持“边界”标签
            eventType = "boundary";
        end
    end
end

if isfinite(tauMin)
    tau = tauMin;
else
    tau = T;
    eventType = "none";
end
end

function root = findRootBisection(fun, a, b)
%FINDROOTBISECTION  在 [a,b] 上用二分法求根（要求端点异号或端点为零）
fa = fun(a);
fb = fun(b);

if ~isFiniteScalar(fa) || ~isFiniteScalar(fb)
    root = inf;
    return;
end
if abs(fa) <= 1e-12
    root = a;
    return;
end
if abs(fb) <= 1e-12
    root = b;
    return;
end
if fa * fb > 0
    root = inf;
    return;
end

lo = a;
hi = b;
for k = 1:48
    mid = 0.5 * (lo + hi);
    fm = fun(mid);
    if ~isFiniteScalar(fm)
        root = inf;
        return;
    end
    if abs(fm) <= 1e-12
        lo = mid;
        hi = mid;
        break;
    end
    if fa * fm <= 0
        hi = mid;
        fb = fm; %#ok<NASGU>
    else
        lo = mid;
        fa = fm;
    end
end
root = 0.5 * (lo + hi);
end

function dQ = segmentHeatDelta(state0, state1, params, out0, tau, dynamicsEnabled)
%SEGMENTHEATDELTA  计算连续段内焦耳热增量
t = max(0.0, double(tau));
if t <= 0
    dQ = 0.0;
    return;
end

if ~dynamicsEnabled
    dQ = max(0.0, toDouble(pickField(out0, 'pElec', 0.0), 0.0) * t);
    return;
end

fA = toDouble(pickField(params, 'FdriveA', pickField(params, 'Fdrive', 0.0)), 0.0);
fB = toDouble(pickField(params, 'FdriveB', pickField(params, 'Fdrive', 0.0)), 0.0);
mA = max(toDouble(pickField(params, 'mA', pickField(params, 'm', 1.0)), 1.0), 1e-12);
mB = max(toDouble(pickField(params, 'mB', pickField(params, 'm', 1.0)), 1.0), 1e-12);

wExt = fA * (state1.xA - state0.xA) + fB * (state1.xB - state0.xB);
dK = 0.5 * mA * (state1.vA^2 - state0.vA^2) + 0.5 * mB * (state1.vB^2 - state0.vB^2);
dQ = wExt - dK;

if dQ < 0 && abs(dQ) <= 1e-9
    dQ = 0.0;
end
dQ = max(0.0, double(dQ));
end

function [state, dQColl] = applyCollisionEvent(stateIn, params)
%APPLYCOLLISIONEVENT  执行碰撞瞬时映射并返回碰撞热增量
state = stateIn;
mA = max(toDouble(pickField(params, 'mA', pickField(params, 'm', 1.0)), 1.0), 1e-12);
mB = max(toDouble(pickField(params, 'mB', pickField(params, 'm', 1.0)), 1.0), 1e-12);
rho = min(max(toDouble(pickField(params, 'rho', 1.0), 1.0), 0.0), 1.0);

uBefore = state.vB - state.vA;
if uBefore >= -1e-12
    dQColl = 0.0;
    state.xB = max(state.xB, state.xA);
    return;
end

M = mA + mB;
mu = (mA * mB) / M;
vCm = (mA * state.vA + mB * state.vB) / M;
uAfter = -rho * uBefore;

state.vA = vCm - (mB / M) * uAfter;
state.vB = vCm + (mA / M) * uAfter;
state.xB = max(state.xB, state.xA);

dQColl = 0.5 * mu * (1.0 - rho^2) * (uBefore^2);
dQColl = max(0.0, double(dQColl));
end

function state = clampBoundaryEvent(stateIn, params)
%CLAMPBOUNDARYEVENT  边界事件后的坐标夹紧（消除浮点漂移）
state = stateIn;
if ~toLogical(pickField(params, 'bounded', true), true)
    return;
end

xMin = toDouble(pickField(params, 'xMin', 0.0), 0.0);
xMax = toDouble(pickField(params, 'xMax', 4.0), 4.0);
if xMax < xMin
    t = xMin;
    xMin = xMax;
    xMax = t;
end

tol = 1e-9;
if abs(state.xA - xMin) <= tol
    state.xA = xMin;
elseif abs(state.xA - xMax) <= tol
    state.xA = xMax;
end
if abs(state.xB - xMin) <= tol
    state.xB = xMin;
elseif abs(state.xB - xMax) <= tol
    state.xB = xMax;
end
if state.xB < state.xA
    xMid = 0.5 * (state.xA + state.xB);
    state.xA = xMid;
    state.xB = xMid;
end
end

function tf = isFiniteScalar(x)
%ISFINITESCALAR  判断是否为有限标量
tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失时回退）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

function v = toDouble(x, fallback)
%TODOUBLE  安全转 double 标量
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = double(fallback);
end
end

function tf = toLogical(x, fallback)
%TOLOGICAL  安全转 logical 标量
if islogical(x) && isscalar(x)
    tf = logical(x);
elseif isnumeric(x) && isscalar(x) && isfinite(x)
    tf = logical(x ~= 0);
else
    tf = logical(fallback);
end
end

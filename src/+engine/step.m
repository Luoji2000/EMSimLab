function state = step(state, params, dt)
%% 入口：按模型分发步进
%STEP  推进一步（按 modelType 分发）
%
% 用途
%   - 统一作为引擎单步推进总入口，按模型类型分发到对应子推进函数。
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
%   - particle: 旋转矩阵解析推进（纯磁场，含有界跨界二分）
%   - selector: 交叉场解析推进（E+B，含有界跨界二分）
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
    case "selector"
        state = stepSelectorState(state, params, dt);
    otherwise
        state = stepParticleState(state, params, dt);
end

end

%% 粒子模型（M1/M2/M5）
function state = stepParticleState(state, params, dt)
%STEPPARTICLESTATE  M 系列粒子单步推进入口
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     当前粒子状态，至少包含 x/y/vx/vy（缺失时会在内部补齐）。
%   params (1,1) struct
%     当前参数结构，包含 q/m/B/bounded/bounds 等字段。
%   dt     (1,1) double
%     本次推进步长（秒）。
%
% 输出
%   state  (1,1) struct
%     推进后的粒子状态，含位置、速度、轨迹、模式与 inField 标记。
%
% 说明
%   - 无界模式：整段解析推进。
%   - 有界模式：使用“分段推进 + 跨界二分”保证进出场时刻稳定。
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
%ENSUREPARTICLESTATE  补齐粒子状态基础字段
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     可能不完整的粒子状态结构。
%   params (1,1) struct
%     参数结构，用于必要时触发 reset 回填默认状态。
%
% 输出
%   state  (1,1) struct
%     字段完整的粒子状态，保证后续 step 可安全运行。
%
% 说明
%   - 当核心字段缺失时，回退调用 engine.reset 统一补齐。
%   - 保证 traj 为 N×2 数值矩阵、stepCount 为标量计数。
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

%% 速度选择器模型（M4）
function state = stepSelectorState(state, params, dt)
%STEPSELECTORSTATE  M4 速度选择器单步推进（交叉场）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     当前速度选择器状态（x/y/vx/vy/traj 等）。
%   params (1,1) struct
%     速度选择器参数（Ey/B/q/m/bounds 等）。
%   dt     (1,1) double
%     本次推进步长（秒）。
%
% 输出
%   state  (1,1) struct
%     推进后的选择器状态，并附加 q/m 与受力分量输出字段。
%
% 说明
%   - 场内调用交叉场解析核。
%   - 场外保持匀速直线推进。
state = ensureSelectorState(state, params);

rOld = [double(state.x); double(state.y)];
vOld = [double(state.vx); double(state.vy)];

bounded = logicalField(params, 'bounded', true);
if ~bounded
    [rNew, vNew] = propagateSelectorSegment(rOld, vOld, params, true, dt);
    inField = true;
    modeText = "selector_unbounded";
else
    box = geom.readBoundsFromParams(params);
    [rNew, vNew, inField] = propagateSelectorBoundedChain(rOld, vOld, params, dt, box);
    if inField
        modeText = "selector_inside";
    else
        modeText = "selector_outside";
    end
end

state.t = state.t + dt;
state.modelType = "selector";
state.x = rNew(1);
state.y = rNew(2);
state.vx = vNew(1);
state.vy = vNew(2);
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.inField = inField;
state.mode = modeText;
state = attachSelectorOutputs(state, params, inField);
end

function state = ensureSelectorState(state, params)
%ENSURESELECTORSTATE  补齐速度选择器状态字段
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     可能缺字段的选择器状态。
%   params (1,1) struct
%     参数结构，用于 reset 和边界判定。
%
% 输出
%   state  (1,1) struct
%     可直接参与选择器推进的完整状态结构。
%
% 说明
%   - 若 inField 缺失，会基于 bounded 与几何边界即时补算。
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
if ~isfield(state, 'inField')
    bounded = logicalField(params, 'bounded', true);
    if bounded
        box = geom.readBoundsFromParams(params);
        state.inField = geom.isInsideBounds([state.x; state.y], box);
    else
        state.inField = true;
    end
end
end

%% 导轨模型（R 系列）
function state = stepRailState(state, params, dt)
%STEPRAILSTATE  R 系列导轨单步推进入口
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     当前导轨状态（含位置、速度、电路分支状态等）。
%   params (1,1) struct
%     导轨参数（R/C/L、drive、bounded、templateId 等）。
%   dt     (1,1) double
%     本次推进步长（秒）。
%
% 输出
%   state  (1,1) struct
%     推进后的导轨状态，附加当前输出量与模式标签。
%
% 说明
%   - R8 模板会转入专用推进函数 stepR8FrameState。
%   - 其它 R 系列统一在本函数按元件类型分支推进。
if isR8Template(params)
    state = stepR8FrameState(state, params, dt);
    return;
end

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
Bz = engine.helpers.signedBFromParams(params);
L = max(double(pickField(params, 'L', 1.0)), 1e-9);
R = max(double(pickField(params, 'R', 1.0)), 1e-12);
elementType = resolveRailElement(params);
K = Bz * L;

% 仅“场内+闭路”时启用电磁耦合
useCoupling = inFieldStart && loopClosed;
switch elementType
    case "C"
        Cval = max(double(pickField(params, 'C', 1.0)), 1e-12);
        [x1, v1, infoLC] = physics.railAdvanceCapacitor(x0, v0, m, Fdrive, K, Cval, dt, useCoupling);
        state.iBranch = double(infoLC.current);
        state.aBranch = double(infoLC.accel);
    case "L"
        LsVal = max(double(pickField(params, 'Ls', 1.0)), 1e-12);
        i0 = double(pickField(state, 'iBranch', 0.0));
        [x1, v1, i1, infoLC] = physics.railAdvanceInductor(x0, v0, i0, m, Fdrive, K, LsVal, dt, useCoupling);
        state.iBranch = double(i1);
        state.aBranch = double(infoLC.accel);
    otherwise
        k = engine.helpers.railDampingK(Bz, L, R);
        [x1, v1, ~] = physics.railAdvanceNoFriction(x0, v0, m, Fdrive, k, dt, useCoupling);
        if useCoupling
            state.aBranch = (Fdrive - k * v1) / max(m, 1e-12);
        else
            state.aBranch = Fdrive / max(m, 1e-12);
        end
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

% R2LC 教学口径：场外或开路时，电感分支电流归零
if elementType == "L" && ~(inFieldEnd && loopClosed)
    state.iBranch = 0.0;
end

state = attachRailOutputs(state, params, inFieldEnd);

if elementType == "R"
    % 电阻版累计焦耳热
    dQ = physics.railHeatDeltaNoFriction(x0, x1, v0, v1, m, Fdrive, useCoupling);
    state.qHeat = qHeatPrev + dQ;
    if isfield(state, 'rail') && isstruct(state.rail)
        state.rail.qHeat = double(state.qHeat);
    end
end
end

function state = stepR8FrameState(state, params, dt)
%STEPR8FRAMESTATE  R8 线框模型推进（中心坐标 + 重叠宽度公式）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     当前 R8 状态，主坐标语义为线框中心坐标。
%   params (1,1) struct
%     R8 参数结构（w/h/B/R/xMin/xMax/driveEnabled/Fdrive 等）。
%   dt     (1,1) double
%     本次推进步长（秒）。
%
% 输出
%   state  (1,1) struct
%     推进后的 R8 状态，包含电磁输出、几何输出与累计热量。
%
% 模式说明
%   - 匀速模式（driveEnabled=false）：
%       速度保持常量，仅做位置平移；但输出量仍按公式计算。
%   - 阻尼模式（driveEnabled=true）：
%       m*dv/dt = Fdrive - k_eff*v，k_eff = (B^2 h^2 / R) * (s'^2)。
state = ensureRailState(state, params);

x0 = double(state.x);
y0 = double(state.y);
v0 = max(0.0, double(state.vx));
m = max(double(pickField(params, 'm', 1.0)), 1e-9);
driveEnabled = logicalField(params, 'driveEnabled', false);
if driveEnabled
    Fdrive = double(pickField(params, 'Fdrive', 0.0));
else
    Fdrive = 0.0;
end

out0 = physics.frameStripOutputs(x0, v0, params);
if driveEnabled
    kEff = max(double(out0.dragCoeff), 0.0);
    if kEff > 1e-12
        alpha = kEff / m;
        vInf = Fdrive / kEff;
        e = exp(-alpha * dt);
        v1 = vInf + (v0 - vInf) * e;
        x1 = x0 + vInf * dt + ((v0 - vInf) / alpha) * (1 - e);
        aNow = (Fdrive - kEff * v0) / m;
    else
        aNow = Fdrive / m;
        v1 = v0 + aNow * dt;
        x1 = x0 + v0 * dt + 0.5 * aNow * dt^2;
    end
else
    % 匀速模式：默认存在未显式建模的外部平衡力，速度保持不变
    aNow = 0.0;
    v1 = v0;
    x1 = x0 + v0 * dt;
end

% R8 约束：只允许向右运动，不回退
v1 = max(0.0, v1);
x1 = max(x1, x0);

state.t = state.t + dt;
state.modelType = "rail";
state.x = x1;
state.y = y0;
state.xCenter = state.x;
state.yCenter = state.y;
state.vx = v1;
state.vy = 0.0;
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.aBranch = aNow;

out1 = physics.frameStripOutputs(state.x, state.vx, params);
state.iBranch = double(out1.current);
state.inField = logical(out1.inField);
state.xFront = double(out1.xFront);
state.xBack = double(out1.xBack);
state.qHeat = double(pickField(state, 'qHeat', 0.0)) + max(0.0, double(out1.pElec)) * double(dt);

if driveEnabled
    if state.inField
        state.mode = "r8_damped_infield";
    else
        state.mode = "r8_damped_free";
    end
else
    if state.inField
        state.mode = "r8_uniform_infield";
    else
        state.mode = "r8_uniform_free";
    end
end

state = attachR8Outputs(state, params, out1, Fdrive);
end

function state = attachR8Outputs(state, params, out, Fdrive)
%ATTACHR8OUTPUTS  R8 输出挂载兼容封装（step 内部）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%   params (1,1) struct
%   out    (1,1) struct
%   Fdrive (1,1) double
%
% 输出
%   state  (1,1) struct
%
% 说明
%   - 本地函数仅做委托，真实实现位于 engine.helpers.attachR8Outputs。
%   - 保留该封装是为了维持旧调用路径，降低重构风险。
state = engine.helpers.attachR8Outputs(state, params, out, Fdrive);
end

function state = ensureRailState(state, params)
%ENSURERAILSTATE  补齐导轨状态字段
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     可能不完整的导轨状态结构。
%   params (1,1) struct
%     参数结构，用于必要时 reset。
%
% 输出
%   state  (1,1) struct
%     可安全参与导轨推进的状态结构。
%
% 说明
%   - 同时补齐 qHeat/iBranch/aBranch 等导轨专有字段。
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
if ~isfield(state, 'iBranch')
    state.iBranch = 0.0;
end
if ~isfield(state, 'aBranch')
    state.aBranch = 0.0;
end
end

%% 输出挂载与模型判定
function state = attachRailOutputs(state, params, inField)
%ATTACHRAILOUTPUTS  计算并挂载 R 系列输出量（R/C/L）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state   (1,1) struct
%     当前导轨状态。
%   params  (1,1) struct
%     当前导轨参数。
%   inField (1,1) logical
%     当前时刻是否位于磁场有效区域。
%
% 输出
%   state   (1,1) struct
%     已写入 epsilon/current/fMag/pElec/pMech 及 state.rail 的状态。
%
% 说明
%   - R8 分支直接复用 frameStripOutputs 真源。
%   - R/C/L 分支按教学口径分别计算对应输出量。
if isR8Template(params)
    out = physics.frameStripOutputs(double(pickField(state, 'x', 0.0)), double(pickField(state, 'vx', 0.0)), params);
    state.iBranch = double(out.current);
    state.aBranch = double(pickField(state, 'aBranch', 0.0));
    state.inField = logical(out.inField);
    state.xFront = double(out.xFront);
    state.xBack = double(out.xBack);
    state = attachR8Outputs(state, params, out, double(pickField(params, 'Fdrive', 0.0)));
    return;
end

vx = double(pickField(state, 'vx', 0.0));
L = max(double(pickField(params, 'L', 1.0)), 1e-9);
R = max(double(pickField(params, 'R', 1.0)), 1e-12);
K = engine.helpers.signedBFromParams(params) * L;
elementType = resolveRailElement(params);
loopClosed = logicalField(params, 'loopClosed', false);
Fdrive = double(pickField(params, 'Fdrive', 0.0));

useCoupling = logical(inField) && loopClosed;
switch elementType
    case "C"
        Cval = max(double(pickField(params, 'C', 1.0)), 1e-12);
        if useCoupling
            m = max(double(pickField(params, 'm', 1.0)), 1e-12);
            mEff = m + Cval * (K^2);
            accel = Fdrive / max(mEff, 1e-12);
            current = Cval * K * accel;
            epsilon = K * vx;
            fMag = -K * current;
            pElec = epsilon * current;
            qHeat = 0.5 * Cval * epsilon^2;
        else
            accel = Fdrive / max(double(pickField(params, 'm', 1.0)), 1e-12);
            current = 0.0;
            epsilon = 0.0;
            fMag = 0.0;
            pElec = 0.0;
            qHeat = 0.0;
        end
        state.aBranch = accel;
        state.iBranch = current;
        state.qHeat = qHeat;
        out = struct('epsilon', epsilon, 'current', current, 'fMag', fMag, 'pElec', pElec, 'pMech', Fdrive * vx);
    case "L"
        LsVal = max(double(pickField(params, 'Ls', 1.0)), 1e-12);
        if useCoupling
            current = double(pickField(state, 'iBranch', 0.0));
            epsilon = K * vx;
            fMag = -K * current;
            pElec = epsilon * current;
            qHeat = 0.5 * LsVal * current^2;
            accel = (Fdrive - K * current) / max(double(pickField(params, 'm', 1.0)), 1e-12);
        else
            current = 0.0;
            epsilon = 0.0;
            fMag = 0.0;
            pElec = 0.0;
            qHeat = 0.0;
            accel = Fdrive / max(double(pickField(params, 'm', 1.0)), 1e-12);
        end
        state.aBranch = accel;
        state.iBranch = current;
        state.qHeat = qHeat;
        out = struct('epsilon', epsilon, 'current', current, 'fMag', fMag, 'pElec', pElec, 'pMech', Fdrive * vx);
    otherwise
        Bz = engine.helpers.signedBFromParams(params);
        out = physics.railOutputsNoFriction(vx, L, R, Bz, logical(inField), loopClosed, Fdrive);
        m = max(double(pickField(params, 'm', 1.0)), 1e-12);
        k = engine.helpers.railDampingK(Bz, L, R);
        if useCoupling
            state.aBranch = (Fdrive - k * vx) / m;
        else
            state.aBranch = Fdrive / m;
        end
end

state.epsilon = out.epsilon;
state.current = out.current;
state.fMag = out.fMag;
state.pElec = out.pElec;
state.pMech = out.pMech;
state.rail = struct( ...
    'elementType', elementType, ...
    'L', L, ...
    'x', double(state.x), ...
    'yCenter', double(state.y), ...
    'inField', logical(inField), ...
    'epsilon', out.epsilon, ...
    'current', out.current, ...
    'fMag', out.fMag, ...
    'pElec', out.pElec, ...
    'qHeat', double(pickField(state, 'qHeat', 0.0)) ...
);
end

function state = attachSelectorOutputs(state, params, inField)
%ATTACHSELECTOROUTPUTS  计算并挂载 M4 输出量（q/m 与受力分量）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state   (1,1) struct
%     当前选择器状态。
%   params  (1,1) struct
%     当前选择器参数。
%   inField (1,1) logical
%     当前是否在交叉场区域内。
%
% 输出
%   state   (1,1) struct
%     已写入 qOverM/vSelect 与电磁受力分量。
%
% 说明
%   - 具体计算委托给 engine.helpers.selectorOutputs，step 层只负责字段回填。
out = engine.helpers.selectorOutputs([double(state.vx); double(state.vy)], params, logical(inField));
state.qOverM = out.qOverM;
state.vSelect = out.vSelect;
state.fElecX = out.fElecX;
state.fElecY = out.fElecY;
state.fMagX = out.fMagX;
state.fMagY = out.fMagY;
state.fTotalX = out.fTotalX;
state.fTotalY = out.fTotalY;
state.selector = struct( ...
    'inField', logical(inField), ...
    'qOverM', out.qOverM, ...
    'vSelect', out.vSelect ...
);
end

function inField = isRailInField(r, params)
%ISRAILINFIELD  计算导体棒中心是否位于磁场有效区域
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   r      (2,1) double
%     当前位置向量 [x; y]。
%   params (1,1) struct
%     导轨参数。
%
% 输出
%   inField (1,1) logical
%     true 表示在场内（R8 语义下为 overlap>0）。
%
% 说明
%   - 普通导轨按中心点是否在 bounds 内判断。
%   - R8 按线框与条带场重叠语义判断。
if ~logicalField(params, 'bounded', false)
    inField = true;
    return;
end
if isR8Template(params)
    % R8 语义：是否“在场内”由重叠宽度 s(x) 决定，而非中心点位置
    out = physics.frameStripOutputs(double(r(1)), 0.0, params);
    inField = logical(out.inField);
    return;
end
box = geom.readBoundsFromParams(params);
inField = geom.isInsideBounds(r, box);
end

function elementType = resolveRailElement(params)
%RESOLVERAILELEMENT  解析 R 系列回路元件类型（兼容封装）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   params (1,1) struct
%
% 输出
%   elementType (1,1) string
%
% 说明
%   - 本地函数仅做委托，统一规则在 engine.helpers.resolveRailElement。
elementType = engine.helpers.resolveRailElement(params);
end

function tf = isR8Template(params)
%ISR8TEMPLATE  判断当前是否 R8 模板（兼容封装）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   params (1,1) struct
%
% 输出
%   tf (1,1) logical
%
% 说明
%   - 本地函数仅做委托，统一规则在 engine.helpers.isR8Template。
tf = engine.helpers.isR8Template(params);
end

function modelType = resolveModelType(params)
%RESOLVEMODELTYPE  解析当前参数对应模型类型（兼容封装）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   params (1,1) struct
%
% 输出
%   modelType (1,1) string
%
% 说明
%   - 本地函数仅做委托，统一规则在 engine.helpers.resolveModelType。
modelType = engine.helpers.resolveModelType(params);
end

%% 有界分段推进与跨界定位（粒子/M4）
function [rNew, vNew, inField] = propagateBoundedChain(r0, v0, omega, dt, box)
%PROPAGATEBOUNDEDCHAIN  粒子有界场单步分段推进
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   r0    (2,1) double : 起点位置
%   v0    (2,1) double : 起点速度
%   omega (1,1) double : 回旋角速度
%   dt    (1,1) double : 总推进时长
%   box   (1,1) struct : 有界场边界（xMin/xMax/yMin/yMax）
%
% 输出
%   rNew    (2,1) double : 子步链推进后的终点位置
%   vNew    (2,1) double : 子步链推进后的终点速度
%   inField (1,1) logical: 终点是否位于场内
%
% 说明
%   - 若一步内发生跨界，使用二分定位首次跨界时刻后继续推进剩余时长。
%   - 最大跨界事件数有限制，避免异常参数导致死循环。
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

function [rNew, vNew, inField] = propagateSelectorBoundedChain(r0, v0, params, dt, box)
%PROPAGATESELECTORBOUNDEDCHAIN  速度选择器有界场单步分段推进
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   r0     (2,1) double : 起点位置
%   v0     (2,1) double : 起点速度
%   params (1,1) struct : 选择器参数结构
%   dt     (1,1) double : 总推进时长
%   box    (1,1) struct : 有界场边界
%
% 输出
%   rNew    (2,1) double : 终点位置
%   vNew    (2,1) double : 终点速度
%   inField (1,1) logical: 终点是否在场内
%
% 说明
%   - 与粒子版逻辑一致，但场内子段使用交叉场解析推进核。
remaining = double(dt);
rNow = r0;
vNow = v0;
inNow = geom.isInsideBounds(rNow, box);

maxCrossEvents = 8;
crossCount = 0;

while remaining > 1e-12 && crossCount < maxCrossEvents
    [rTry, vTry] = propagateSelectorSegment(rNow, vNow, params, inNow, remaining);
    inTry = geom.isInsideBounds(rTry, box);

    if inTry == inNow
        rNow = rTry;
        vNow = vTry;
        remaining = 0;
        break;
    end

    tau = findSelectorCrossingTimeByBisection(rNow, vNow, params, remaining, inNow, box);
    tau = max(0.0, min(tau, remaining));
    if tau <= 1e-12
        tau = min(remaining, max(1e-9, 1e-6 * remaining));
    end

    [rNow, vNow] = propagateSelectorSegment(rNow, vNow, params, inNow, tau);
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
    [rNow, vNow] = propagateSelectorSegment(rNow, vNow, params, inNow, remaining);
    inNow = geom.isInsideBounds(rNow, box);
end

rNew = rNow;
vNew = vNow;
inField = inNow;
end

function tau = findCrossingTimeByBisection(r0, v0, omega, totalDt, inStart, box)
%FINDCROSSINGTIMEBYBISECTION  二分定位粒子首次跨界时刻
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   r0      (2,1) double : 段起点位置
%   v0      (2,1) double : 段起点速度
%   omega   (1,1) double : 回旋角速度
%   totalDt (1,1) double : 搜索区间上限
%   inStart (1,1) logical: 起点是否在场内
%   box     (1,1) struct : 边界结构
%
% 输出
%   tau (1,1) double
%     首次跨界时间估计（区间右端近似值）。
%
% 说明
%   - 使用固定 32 次二分迭代，平衡数值精度与实时性能。
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

function tau = findSelectorCrossingTimeByBisection(r0, v0, params, totalDt, inStart, box)
%FINDSELECTORCROSSINGTIMEBYBISECTION  二分定位选择器首次跨界时刻
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   r0      (2,1) double : 段起点位置
%   v0      (2,1) double : 段起点速度
%   params  (1,1) struct : 选择器参数
%   totalDt (1,1) double : 搜索区间上限
%   inStart (1,1) logical: 起点是否在场内
%   box     (1,1) struct : 边界结构
%
% 输出
%   tau (1,1) double
%     首次跨界时间估计（区间右端近似值）。
%
% 说明
%   - 与粒子跨界定位逻辑一致，仅场内推进核不同。
lo = 0.0;
hi = double(totalDt);

for k = 1:32
    mid = 0.5 * (lo + hi);
    [rMid, ~] = propagateSelectorSegment(r0, v0, params, inStart, mid);
    inMid = geom.isInsideBounds(rMid, box);

    if inMid == inStart
        lo = mid;
    else
        hi = mid;
    end
end

tau = hi;
end

%% 段内推进核（场内/场外）
function [rNew, vNew] = propagateSegment(rOld, vOld, omega, inField, dt)
%PROPAGATESEGMENT  粒子模型单子段推进
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   rOld    (2,1) double : 子段起点位置
%   vOld    (2,1) double : 子段起点速度
%   omega   (1,1) double : 回旋角速度
%   inField (1,1) logical: 子段是否位于场内
%   dt      (1,1) double : 子段时长
%
% 输出
%   rNew    (2,1) double : 子段终点位置
%   vNew    (2,1) double : 子段终点速度
%
% 说明
%   - 场内与场外推进核在此统一分发，避免上层重复判断。
if inField
    [rNew, vNew] = propagateInField(rOld, vOld, omega, dt);
else
    [rNew, vNew] = propagateFree(rOld, vOld, dt);
end
end

function [rNew, vNew] = propagateSelectorSegment(rOld, vOld, params, inField, dt)
%PROPAGATESELECTORSEGMENT  选择器模型单子段推进
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   rOld    (2,1) double : 子段起点位置
%   vOld    (2,1) double : 子段起点速度
%   params  (1,1) struct : 选择器参数
%   inField (1,1) logical: 子段是否位于场内
%   dt      (1,1) double : 子段时长
%
% 输出
%   rNew    (2,1) double : 子段终点位置
%   vNew    (2,1) double : 子段终点速度
%
% 说明
%   - 场内调用交叉场解析核，场外调用匀速推进核。
if inField
    [rNew, vNew] = propagateSelectorInField(rOld, vOld, params, dt);
else
    [rNew, vNew] = propagateFree(rOld, vOld, dt);
end
end

function [rNew, vNew] = propagateFree(rOld, vOld, dt)
%PROPAGATEFREE  场外匀速直线推进
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   rOld (2,1) double : 起点位置
%   vOld (2,1) double : 起点速度
%   dt   (1,1) double : 推进时长
%
% 输出
%   rNew (2,1) double : 终点位置
%   vNew (2,1) double : 终点速度（与输入相同）
%
% 说明
%   - 本函数不修改速度，仅做线性位移积分。
rNew = rOld + double(dt) * vOld;
vNew = vOld;
end

function [rNew, vNew] = propagateSelectorInField(rOld, vOld, params, dt)
%PROPAGATESELECTORINFIELD  选择器场内推进（交叉场解析解）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   rOld   (2,1) double : 起点位置
%   vOld   (2,1) double : 起点速度
%   params (1,1) struct : 选择器参数
%   dt     (1,1) double : 推进时长
%
% 输出
%   rNew   (2,1) double : 终点位置
%   vNew   (2,1) double : 终点速度
%
% 说明
%   - 从 params 读取 q/m/Ey/Bz 后统一调用 crossedFieldStep2D。
q = double(pickField(params, 'q', 0.0));
m = max(double(pickField(params, 'm', 1.0)), 1e-12);
Ey = double(pickField(params, 'Ey', 0.0));
Bz = engine.helpers.signedBFromParams(params);
[rNew, vNew] = physics.crossedFieldStep2D(rOld, vOld, q, m, Ey, Bz, dt);
end

function [rNew, vNew] = propagateInField(rOld, vOld, omega, dt)
%PROPAGATEINFIELD  磁场内推进：调用独立旋转矩阵算法
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   rOld  (2,1) double : 起点位置
%   vOld  (2,1) double : 起点速度
%   omega (1,1) double : 回旋角速度
%   dt    (1,1) double : 推进时长
%
% 输出
%   rNew  (2,1) double : 终点位置
%   vNew  (2,1) double : 终点速度
%
% 说明
%   - 这里不再内联旋转矩阵公式，改为调用 physics.rotmatStep2D
%   - 这样做的目的是把“核心公式”从流程控制中拆出来，便于：
%       1) 集中审阅物理公式
%       2) 单独编写测试
%       3) 后续在 M 系列多模板间复用
[rNew, vNew] = physics.rotmatStep2D(rOld, vOld, omega, dt);
end

%% 通用工具
function omega = cyclotronOmega(params)
%CYCLOTRONOMEGA  计算回旋角速度 omega = q*Bz/m
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   params (1,1) struct
%     至少应包含 q/m/Bdir/B 等字段。
%
% 输出
%   omega (1,1) double
%     回旋角速度（带符号）。
%
% 说明
%   - 对质量使用下限保护，避免出现除零。
q = pickField(params, 'q', 0.0);
m = max(pickField(params, 'm', 1.0), 1e-12);
Bz = engine.helpers.signedBFromParams(params);
omega = double(q) * Bz / double(m);
end

function v = logicalField(s, name, fallback)
%LOGICALFIELD  安全读取 logical 字段并归一化为标量逻辑值
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   s        (1,1) struct : 源结构体
%   name     (1,:) char/string : 字段名
%   fallback (1,1) logical/numeric : 缺失或非法时的回退值
%
% 输出
%   v (1,1) logical
%     归一化后的逻辑标量。
%
% 说明
%   - 支持 logical 与 numeric 标量输入，其余类型统一回退 fallback。
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
%PICKFIELD  安全读取结构体字段（缺失则返回 fallback）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   s        (1,1) struct : 源结构体
%   name     (1,:) char/string : 字段名
%   fallback 任意类型 : 回退值
%
% 输出
%   v 任意类型
%     字段存在时返回字段值，否则返回 fallback。
%
% 说明
%   - 该函数只做字段安全读取，不做类型转换。
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end


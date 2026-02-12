function state = reset(state, params)
%% 入口：按模型分发重置
%RESET  重置仿真状态（按 modelType 分发）
%
% 输入
%   state  (1,1) struct : 旧状态（可为空）
%   params (1,1) struct : 合法参数（来自 params.validate）
%
% 输出
%   state (1,1) struct : 新状态
%
% 说明
%   - particle: M1/M5 粒子状态（纯磁场）
%   - selector: M4 速度选择器状态（交叉场）
%   - rail    : R 系列导轨状态（R1/R2/R3 统一模板）

arguments
    state (1,1) struct
    params (1,1) struct
end

modelType = resolveModelType(params);
switch modelType
    case "rail"
        state = resetRailState(state, params);
    case "selector"
        state = resetSelectorState(state, params);
    otherwise
        state = resetParticleState(state, params);
end

end

%% 粒子模型（M1/M5）重置
function state = resetParticleState(state, params)
%RESETPARTICLESTATE  重置 M 系列粒子状态
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     历史状态（允许为空或不完整）。
%   params (1,1) struct
%     粒子参数结构（x0/y0/v0/thetaDeg 或 vx0/vy0 等）。
%
% 输出
%   state  (1,1) struct
%     完整的粒子初始状态，包含位置、速度、轨迹与模式字段。
%
% 说明
%   - 当 bounded=true 时会基于边界计算初始 inField 与 mode。
state.t = 0.0;
state.modelType = "particle";
state.x = pickField(params, 'x0', 0.0);
state.y = pickField(params, 'y0', 0.0);

if isfield(params, 'vx0') && isfield(params, 'vy0')
    state.vx = double(params.vx0);
    state.vy = double(params.vy0);
else
    v0 = pickField(params, 'v0', 0.0);
    thetaDeg = pickField(params, 'thetaDeg', 0.0);
    thetaRad = deg2rad(double(thetaDeg));
    state.vx = double(v0) * cos(thetaRad);
    state.vy = double(v0) * sin(thetaRad);
end

state.traj = [state.x, state.y];
state.stepCount = 0;

bounded = logicalField(params, 'bounded', false);
if bounded
    box = geom.readBoundsFromParams(params);
    inField = geom.isInsideBounds([state.x; state.y], box);
    state.inField = inField;
    if inField
        state.mode = "bounded_inside";
    else
        state.mode = "bounded_outside";
    end
else
    state.inField = true;
    state.mode = "unbounded";
end

end

%% 导轨模型（R 系列）重置
function state = resetRailState(state, params)
%RESETRAILSTATE  重置 R 系列导轨状态
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     历史状态（允许为空）。
%   params (1,1) struct
%     导轨参数（R/C/L、loopClosed、driveEnabled 等）。
%
% 输出
%   state  (1,1) struct
%     导轨初始状态，包含导轨专有字段（qHeat/iBranch/aBranch）。
%
% 说明
%   - R8 模板会转入 resetR8FrameState 专用分支。
if isR8Template(params)
    state = resetR8FrameState(state, params);
    return;
end

state.t = 0.0;
state.modelType = "rail";
state.x = pickField(params, 'x0', 0.0);
state.y = pickField(params, 'y0', 0.0);
% R 系列统一使用参数 v0 作为初速度（R2 也允许用户编辑）
state.vx = pickField(params, 'v0', 0.0);
state.vy = 0.0;
state.traj = [state.x, state.y];
state.stepCount = 0;
state.qHeat = 0.0;
state.iBranch = 0.0;
state.aBranch = 0.0;

inField = isRailInField([state.x; state.y], params);
state.inField = inField;

if logicalField(params, 'bounded', false)
    if inField
        state.mode = "rail_bounded_inside";
    else
        state.mode = "rail_bounded_outside";
    end
else
    state.mode = "rail_unbounded";
end

% R2LC 分支初值
elementType = resolveRailElement(params);
if elementType == "L" && inField && logicalField(params, 'loopClosed', false)
    state.iBranch = double(pickField(params, 'i0', 0.0));
end

state = attachRailOutputs(state, params, inField);

end

function state = resetR8FrameState(state, params)
%RESETR8FRAMESTATE  重置 R8 线框状态（中心坐标语义）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     历史状态（允许为空）。
%   params (1,1) struct
%     R8 参数结构（xCenter/yCenter/v0/w/h/xMin/xMax 等）。
%
% 输出
%   state  (1,1) struct
%     R8 初始状态，包含中心坐标、前后沿、电磁输出与模式。
%
% 说明
%   - 主状态坐标使用线框中心，不使用前沿坐标。
state.t = 0.0;
state.modelType = "rail";
state.x = double(pickField(params, 'xCenter', pickField(params, 'x0', 0.0)));
state.y = double(pickField(params, 'yCenter', pickField(params, 'y0', 0.0)));
state.xCenter = state.x;
state.yCenter = state.y;
state.vx = abs(double(pickField(params, 'v0', 0.0)));
state.vy = 0.0;
state.traj = [state.x, state.y];
state.stepCount = 0;
state.qHeat = 0.0;
state.iBranch = 0.0;
state.aBranch = 0.0;

out = physics.frameStripOutputs(state.x, state.vx, params);
state.inField = logical(out.inField);
state.xFront = double(out.xFront);
state.xBack = double(out.xBack);

if logicalField(params, 'driveEnabled', false)
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

state = attachR8Outputs(state, params, out, double(pickField(params, 'Fdrive', 0.0)));
end

%% 速度选择器模型（M4）重置
function state = resetSelectorState(state, params)
%RESETSELECTORSTATE  重置 M4 速度选择器状态
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state  (1,1) struct
%     历史状态（允许为空）。
%   params (1,1) struct
%     选择器参数（Ey/B/q/m/bounds 等）。
%
% 输出
%   state  (1,1) struct
%     选择器初始状态，并挂载 q/m 与受力分量输出。
%
% 说明
%   - 若 bounded=true，则重置时立即计算初始 inField 与 selector 模式标签。
state.t = 0.0;
state.modelType = "selector";
state.x = pickField(params, 'x0', 0.0);
state.y = pickField(params, 'y0', 0.0);

if isfield(params, 'vx0') && isfield(params, 'vy0')
    state.vx = double(params.vx0);
    state.vy = double(params.vy0);
else
    v0 = pickField(params, 'v0', 0.0);
    thetaDeg = pickField(params, 'thetaDeg', 0.0);
    thetaRad = deg2rad(double(thetaDeg));
    state.vx = double(v0) * cos(thetaRad);
    state.vy = double(v0) * sin(thetaRad);
end

state.traj = [state.x, state.y];
state.stepCount = 0;

bounded = logicalField(params, 'bounded', true);
if bounded
    box = geom.readBoundsFromParams(params);
    inField = geom.isInsideBounds([state.x; state.y], box);
    state.inField = inField;
    if inField
        state.mode = "selector_inside";
    else
        state.mode = "selector_outside";
    end
else
    state.inField = true;
    state.mode = "selector_unbounded";
end

state = attachSelectorOutputs(state, params, state.inField);
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
%     是否位于磁场有效区域。
%
% 输出
%   state   (1,1) struct
%     已写入电磁输出字段与 state.rail 子结构。
%
% 说明
%   - R8 分支直接复用 frameStripOutputs 真源并挂载 R8 输出。
%   - R/C/L 分支按教学口径计算各自输出。
if isR8Template(params)
    out = physics.frameStripOutputs(double(pickField(state, 'x', 0.0)), double(pickField(state, 'vx', 0.0)), params);
    state.iBranch = double(out.current);
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
if ~isfield(state, 'qHeat')
    state.qHeat = 0.0;
end

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
    'qHeat', double(state.qHeat) ...
);

end

function state = attachR8Outputs(state, params, out, Fdrive)
%ATTACHR8OUTPUTS  R8 输出挂载兼容封装（reset 内部）
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
state = engine.helpers.attachR8Outputs(state, params, out, Fdrive);
end

function state = attachSelectorOutputs(state, params, inField)
%ATTACHSELECTOROUTPUTS  计算并挂载 M4 输出量（q/m 与受力分量）
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   state   (1,1) struct
%   params  (1,1) struct
%   inField (1,1) logical
%
% 输出
%   state   (1,1) struct
%     已写入 qOverM/vSelect/fElec*/fMag*/fTotal* 字段。
%
% 说明
%   - 具体计算委托给 engine.helpers.selectorOutputs，reset 层只负责字段回填。
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
%     true 表示在场内；R8 模板下按 overlap>0 语义判断。
%
% 说明
%   - 普通导轨按中心点与 bounds 的几何关系判定。
%   - R8 由 frameStripOutputs 统一判定 inField。
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

%% 通用工具
function v = logicalField(s, name, fallback)
%LOGICALFIELD  安全读取 logical 字段并归一化为标量逻辑值
%
% 用途
%   - 见函数标题与下方输入/输出/说明小节。
%
% 输入
%   s        (1,1) struct : 源结构体
%   name     (1,:) char/string : 字段名
%   fallback (1,1) logical/numeric : 回退值
%
% 输出
%   v (1,1) logical
%     归一化后的逻辑标量。
%
% 说明
%   - 支持 logical 与 numeric 标量输入，其余类型回退 fallback。
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


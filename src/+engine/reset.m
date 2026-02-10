function state = reset(state, params)
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
%   - particle: M 系列粒子状态
%   - rail    : R 系列导轨状态（R1/R2/R3 统一模板）

arguments
    state (1,1) struct
    params (1,1) struct
end

modelType = resolveModelType(params);
switch modelType
    case "rail"
        state = resetRailState(state, params);
    otherwise
        state = resetParticleState(state, params);
end

end

function state = resetParticleState(state, params)
%RESETPARTICLESTATE  重置 M 系列粒子状态
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

function state = resetRailState(state, params)
%RESETRAILSTATE  重置 R 系列导轨状态
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

state = attachRailOutputs(state, params, inField);

end

function state = attachRailOutputs(state, params, inField)
%ATTACHRAILOUTPUTS  计算并挂载 R 系列输出量
vx = double(pickField(state, 'vx', 0.0));
L = max(double(pickField(params, 'L', 1.0)), 1e-9);
R = max(double(pickField(params, 'R', 1.0)), 1e-12);
loopClosed = logicalField(params, 'loopClosed', false);
Bz = engine.helpers.signedBFromParams(params);
Fdrive = double(pickField(params, 'Fdrive', 0.0));
out = physics.railOutputsNoFriction(vx, L, R, Bz, logical(inField), loopClosed, Fdrive);

state.epsilon = out.epsilon;
state.current = out.current;
state.fMag = out.fMag;
state.pElec = out.pElec;
state.pMech = out.pMech;
if ~isfield(state, 'qHeat')
    state.qHeat = 0.0;
end

state.rail = struct( ...
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

function inField = isRailInField(r, params)
%ISRAILINFIELD  计算导体棒中心是否位于磁场有效区域
if ~logicalField(params, 'bounded', false)
    inField = true;
    return;
end
box = geom.readBoundsFromParams(params);
inField = geom.isInsideBounds(r, box);
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

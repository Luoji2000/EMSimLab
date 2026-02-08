function state = reset(state, params)
%RESET  重置仿真状态（M1 无界版本）
%
% 输入
%   state  (1,1) struct : 旧状态（可为空）
%   params (1,1) struct : 合法参数（来自 params.validate）
%
% 输出
%   state (1,1) struct : 新状态（至少包含 t、x、y 等字段）
%
% 说明
%   当前阶段仅实现“无界匀强磁场”初始态，
%   有界逻辑后续再在 engine.step 中扩展。

arguments
    state (1,1) struct
    params (1,1) struct
end

state.t = 0.0;
state.x = pickField(params, 'x0', 0.0);
state.y = pickField(params, 'y0', 0.0);

% 优先使用 validate 已派生的速度分量；若缺失则由 v0/thetaDeg 反推
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

% 轨迹缓存（可选）
state.traj = [state.x, state.y];
state.stepCount = 0;
state.mode = "unbounded";

end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

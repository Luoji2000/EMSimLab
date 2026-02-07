function state = reset(state, params)
%RESET  重置仿真状态（占位实现）
%
% 输入
%   state  (1,1) struct : 旧状态（可为空）
%   params (1,1) struct : 合法参数（来自 params.validate）
%
% 输出
%   state (1,1) struct : 新状态（至少包含 t、x、y 等字段）
%
% 说明
%   目前为占位：只把初始位置/速度写入 state。
%   后续你可以按 engineKey 分发到不同引擎实现。

arguments
    state (1,1) struct
    params (1,1) struct
end

state.t = 0.0;
% 初始位置/速度（粒子示例）
state.x = params.x0;
state.y = params.y0;
state.vx = params.vx0;
state.vy = params.vy0;

% 轨迹缓存（可选）
state.traj = [state.x, state.y];

end

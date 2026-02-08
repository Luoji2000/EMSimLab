function state = step(state, params, dt)
%STEP  推进一步（M1 无界匀强磁场：旋转矩阵法）
%
% 物理模型
%   - 当前阶段只实现“无界匀强磁场”
%   - 使用解析旋转矩阵推进速度与位置，避免欧拉积分漂移
%
% 推进公式
%   omega = q * Bz / m
%   v_{n+1} = R(theta) * v_n, theta = omega*dt
%   r_{n+1} = r_n + (1/omega) * A(theta) * v_n
%
% 退化处理
%   - 当 |omega| 很小时，退化为匀速直线推进

arguments
    state (1,1) struct
    params (1,1) struct
    dt (1,1) double {mustBePositive}
end

if isfield(params, 'speedScale')
    dt = dt * max(0.01, double(params.speedScale));
end

% 缺字段时做兜底初始化，防止外部直接调用 step 崩溃
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

omega = cyclotronOmega(params);
vOld = [double(state.vx); double(state.vy)];
rOld = [double(state.x); double(state.y)];

if abs(omega) < 1e-12
    % B 很小或 q/m 很小：近似匀速直线
    rNew = rOld + dt * vOld;
    vNew = vOld;
else
    theta = omega * dt;
    c = cos(theta);
    s = sin(theta);

    % 速度旋转矩阵
    R = [c, s; -s, c];
    % 位置积分矩阵
    A = [s, (1 - c); -(1 - c), s];

    vNew = R * vOld;
    rNew = rOld + (A * vOld) / omega;
end

state.t = state.t + dt;
state.x = rNew(1);
state.y = rNew(2);
state.vx = vNew(1);
state.vy = vNew(2);
state.traj(end+1, :) = [state.x, state.y];
state.stepCount = state.stepCount + 1;
state.mode = "unbounded";
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

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

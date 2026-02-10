function [x1, v1, info] = railAdvanceNoFriction(x0, v0, m, Fdrive, k, dt, useDamping)
%RAILADVANCENOFRICTION  R 系列单步推进（默认无摩擦）
%
% 输入
%   x0         (1,1) double : 步起点位置
%   v0         (1,1) double : 步起点速度
%   m          (1,1) double : 质量（kg）
%   Fdrive     (1,1) double : 外力（N）
%   k          (1,1) double : 阻尼系数（B^2L^2/R）
%   dt         (1,1) double : 时间步长（s）
%   useDamping (1,1) logical: 是否启用闭路阻尼方程
%
% 输出
%   x1   (1,1) double : 步终点位置
%   v1   (1,1) double : 步终点速度
%   info (1,1) struct : 过程信息（alpha/vInf/method）
%
% 方程模型（无摩擦）
%   1) 阻尼闭路段：
%        m dv/dt = Fdrive - k v
%      解析解：
%        v1 = vInf + (v0-vInf)*exp(-alpha*dt)
%        x1 = x0 + vInf*dt + (v0-vInf)/alpha*(1-exp(-alpha*dt))
%      其中 alpha=k/m, vInf=Fdrive/k
%
%   2) 非阻尼段（开路或场外）：
%        m dv/dt = Fdrive
%        v1 = v0 + a*dt, x1 = x0 + v0*dt + 0.5*a*dt^2

arguments
    x0 (1,1) double
    v0 (1,1) double
    m (1,1) double
    Fdrive (1,1) double
    k (1,1) double
    dt (1,1) double {mustBeNonnegative}
    useDamping (1,1) logical
end

mSafe = max(double(m), 1e-12);
kSafe = max(double(k), 0.0);
dt = double(dt);
Fdrive = double(Fdrive);

info = struct( ...
    'alpha', 0.0, ...
    'vInf', 0.0, ...
    'method', "uniform_accel", ...
    'useDamping', logical(useDamping) ...
);

if useDamping && kSafe > 1e-12
    alpha = kSafe / mSafe;
    vInf = Fdrive / kSafe;
    e = exp(-alpha * dt);

    v1 = vInf + (v0 - vInf) * e;
    x1 = x0 + vInf * dt + ((v0 - vInf) / alpha) * (1 - e);

    info.alpha = alpha;
    info.vInf = vInf;
    info.method = "damped_exact";
    return;
end

a = Fdrive / mSafe;
v1 = v0 + a * dt;
x1 = x0 + v0 * dt + 0.5 * a * dt^2;
end


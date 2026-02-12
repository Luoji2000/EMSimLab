function [x1, v1, i1, info] = railAdvanceInductor(x0, v0, i0, m, Fdrive, K, Ls, dt, useCoupling)
%RAILADVANCEINDUCTOR  R2LC 电感支路单步推进（无摩擦）
%
% 输入
%   x0, v0      : 本步起点位置与速度
%   i0          : 本步起点电流
%   m           : 导体棒质量
%   Fdrive      : 外力
%   K           : 耦合常数，K = Bz * L（带符号）
%   Ls          : 电感
%   dt          : 时间步长
%   useCoupling : 是否启用“场内+闭路”耦合
%
% 输出
%   x1, v1, i1 : 本步终点位置/速度/电流
%   info       : 本步派生量（用于输出区与日志）
%
% 公式（耦合开启时）
%   m dv/dt = Fdrive - K*I
%   dI/dt   = (K/Ls)*v
%   用闭式旋转更新，避免 ODE 数值积分误差。

arguments
    x0 (1,1) double
    v0 (1,1) double
    i0 (1,1) double
    m (1,1) double
    Fdrive (1,1) double
    K (1,1) double
    Ls (1,1) double
    dt (1,1) double {mustBeNonnegative}
    useCoupling (1,1) logical
end

mSafe = max(double(m), 1e-12);
LsSafe = max(double(Ls), 1e-12);
K = double(K);
dt = double(dt);
Fdrive = double(Fdrive);
i0 = double(i0);

if ~useCoupling || abs(K) <= 1e-12
    a = Fdrive / mSafe;
    v1 = v0 + a * dt;
    x1 = x0 + v0 * dt + 0.5 * a * dt^2;
    i1 = 0.0;

    info = struct( ...
        'accel', a, ...
        'current', i1, ...
        'epsilon', 0.0, ...
        'fMag', 0.0, ...
        'pElec', 0.0, ...
        'energy', 0.0, ...
        'omega', 0.0 ...
    );
    return;
end

omega = abs(K) / sqrt(mSafe * LsSafe);
sgnK = sign(K);
if sgnK == 0
    sgnK = 1;
end

iEq = Fdrive / K;
iTilde0 = i0 - iEq;
c = cos(omega * dt);
s = sin(omega * dt);

v1 = v0 * c - sgnK * sqrt(LsSafe / mSafe) * iTilde0 * s;
i1 = iEq + iTilde0 * c + sgnK * sqrt(mSafe / LsSafe) * v0 * s;
x1 = x0 + (v0 / omega) * s - sgnK * sqrt(LsSafe / mSafe) * (iTilde0 / omega) * (1 - c);

epsilon = K * v1;
fMag = -K * i1;
pElec = epsilon * i1;
energy = 0.5 * LsSafe * i1^2;
a = (Fdrive - K * i1) / mSafe;

info = struct( ...
    'accel', a, ...
    'current', i1, ...
    'epsilon', epsilon, ...
    'fMag', fMag, ...
    'pElec', pElec, ...
    'energy', energy, ...
    'omega', omega ...
);
end


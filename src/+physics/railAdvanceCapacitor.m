function [x1, v1, info] = railAdvanceCapacitor(x0, v0, m, Fdrive, K, C, dt, useCoupling)
%RAILADVANCECAPACITOR  R2LC 电容支路单步推进（无摩擦）
%
% 输入
%   x0, v0      : 本步起点位置与速度
%   m           : 导体棒质量
%   Fdrive      : 外力
%   K           : 耦合常数，K = Bz * L（带符号）
%   C           : 电容
%   dt          : 时间步长
%   useCoupling : 是否启用“场内+闭路”耦合
%
% 输出
%   x1, v1 : 本步终点位置与速度
%   info   : 本步派生量（用于输出区与日志）
%
% 公式
%   电容版在耦合开启时满足：
%       m_eff = m + C*K^2
%       a     = Fdrive / m_eff
%       I     = C*K*a
%       Fmag  = -K*I
%   速度/位置按匀加速解析式推进。

arguments
    x0 (1,1) double
    v0 (1,1) double
    m (1,1) double
    Fdrive (1,1) double
    K (1,1) double
    C (1,1) double
    dt (1,1) double {mustBeNonnegative}
    useCoupling (1,1) logical
end

mSafe = max(double(m), 1e-12);
CSafe = max(double(C), 1e-12);
K = double(K);
dt = double(dt);
Fdrive = double(Fdrive);

if useCoupling
    mEff = mSafe + CSafe * (K^2);
    a = Fdrive / max(mEff, 1e-12);
    iNow = CSafe * K * a;
else
    mEff = mSafe;
    a = Fdrive / mSafe;
    iNow = 0.0;
end

v1 = v0 + a * dt;
x1 = x0 + v0 * dt + 0.5 * a * dt^2;

if useCoupling
    epsilon = K * v1;
    fMag = -K * iNow;
    pElec = epsilon * iNow;
    energy = 0.5 * CSafe * epsilon^2;
else
    epsilon = 0.0;
    fMag = 0.0;
    pElec = 0.0;
    energy = 0.0;
end

info = struct( ...
    'accel', a, ...
    'current', iNow, ...
    'epsilon', epsilon, ...
    'fMag', fMag, ...
    'pElec', pElec, ...
    'energy', energy, ...
    'mEff', mEff ...
);
end


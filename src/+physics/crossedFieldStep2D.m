function [rNew, vNew] = crossedFieldStep2D(rOld, vOld, q, m, Ey, Bz, dt)
%CROSSEDFIELDSTEP2D  交叉场（E_y + B_z）二维一步解析推进
%
% 输入
%   rOld (2,1) double : 旧位置 [x; y]
%   vOld (2,1) double : 旧速度 [vx; vy]
%   q    (1,1) double : 电荷量
%   m    (1,1) double : 质量（内部会做最小值保护）
%   Ey   (1,1) double : 电场 y 分量（V/m）
%   Bz   (1,1) double : 磁场 z 分量（T，带符号）
%   dt   (1,1) double : 时间步长（秒）
%
% 输出
%   rNew (2,1) double : 新位置 [x; y]
%   vNew (2,1) double : 新速度 [vx; vy]
%
% 公式（与你确认的一致）
%   1) 漂移速度：v_d = Ey / Bz
%   2) 相对速度：w = v - [v_d;0]
%   3) 旋转更新：w_{n+1} = R(theta) w_n, theta = omega*dt, omega=q*Bz/m
%   4) 位置积分：
%      r_{n+1}=r_n+[v_d;0]dt + (1/omega)A(theta)w_n
%      A(theta)=[sin(theta),1-cos(theta);-(1-cos(theta)),sin(theta)]
%
% 数值稳定性
%   - Bz≈0 时退化到纯电场显式解析（x 匀速，y 匀加速）
%   - theta≈0 时对 sin(theta)/omega 与 (1-cos(theta))/omega 使用泰勒近似

arguments
    rOld (2,1) double
    vOld (2,1) double
    q (1,1) double
    m (1,1) double
    Ey (1,1) double
    Bz (1,1) double
    dt (1,1) double {mustBeNonnegative}
end

qVal = double(q);
mVal = max(double(m), 1e-12);
EyVal = double(Ey);
BzVal = double(Bz);
dtVal = double(dt);

% Bz=0 时退化为纯电场：x 匀速，y 匀加速
if abs(BzVal) < 1e-12
    ay = qVal * EyVal / mVal;
    vNew = [vOld(1); vOld(2) + ay * dtVal];
    rNew = [ ...
        rOld(1) + vOld(1) * dtVal; ...
        rOld(2) + vOld(2) * dtVal + 0.5 * ay * dtVal^2 ...
    ];
    return;
end

omega = qVal * BzVal / mVal;
vDrift = EyVal / BzVal;
wOld = [vOld(1) - vDrift; vOld(2)];

theta = omega * dtVal;
c = cos(theta);
s = sin(theta);

% 速度更新：先旋转相对速度，再叠加漂移速度
R = [c, s; -s, c];
wNew = R * wOld;
vNew = [vDrift; 0.0] + wNew;

% 位置更新：对相对速度解析积分 + 漂移平移
if abs(theta) < 1e-7
    % sin(theta)/theta 与 (1-cos(theta))/theta 的泰勒近似
    sinOverTheta = 1.0 - theta^2 / 6.0 + theta^4 / 120.0;
    oneMinusCosOverTheta = 0.5 * theta - theta^3 / 24.0 + theta^5 / 720.0;
    sOverOmega = dtVal * sinOverTheta;
    oneMinusCosOverOmega = dtVal * oneMinusCosOverTheta;
else
    sOverOmega = s / omega;
    oneMinusCosOverOmega = (1.0 - c) / omega;
end

rStep = [ ...
    sOverOmega * wOld(1) + oneMinusCosOverOmega * wOld(2); ...
   -oneMinusCosOverOmega * wOld(1) + sOverOmega * wOld(2) ...
];

rNew = rOld + [vDrift * dtVal; 0.0] + rStep;
end

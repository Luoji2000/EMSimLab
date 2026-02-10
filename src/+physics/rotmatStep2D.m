function [rNew, vNew] = rotmatStep2D(rOld, vOld, omega, dt)
%ROTMATSTEP2D  匀强磁场二维一步解析推进（旋转矩阵法）
%
% 输入
%   rOld  (2,1) double : 旧位置列向量 [x; y]
%   vOld  (2,1) double : 旧速度列向量 [vx; vy]
%   omega (1,1) double : 回旋角速度，omega = q*Bz/m（可正可负）
%   dt    (1,1) double : 时间步长（秒）
%
% 输出
%   rNew  (2,1) double : 新位置列向量 [x; y]
%   vNew  (2,1) double : 新速度列向量 [vx; vy]
%
% 公式说明（二维、速度在平面内）
%   1) 速度解析解（旋转映射）
%      v(t+dt) = R(theta) * v(t),  theta = omega*dt
%      R(theta) = [ cos(theta),  sin(theta);
%                  -sin(theta),  cos(theta) ]
%
%   2) 位置解析解（对速度解析解积分）
%      r(t+dt) = r(t) + (A(theta) * v(t)) / omega
%      A(theta) = [ sin(theta),      1-cos(theta);
%                  -(1-cos(theta)),  sin(theta) ]
%
% 数值稳定性约定
%   - 当 |omega| 很小时，旋转公式会出现除以 omega 的放大误差。
%   - 这里统一退化为“匀速直线”：
%       rNew = rOld + vOld*dt,  vNew = vOld
%   - 这样与物理极限 omega -> 0 一致，也避免数值抖动。

arguments
    rOld (2,1) double
    vOld (2,1) double
    omega (1,1) double
    dt (1,1) double {mustBeNonnegative}
end

if abs(omega) < 1e-12
    rNew = rOld + double(dt) * vOld;
    vNew = vOld;
    return;
end

theta = double(omega) * double(dt);
c = cos(theta);
s = sin(theta);

R = [c, s; -s, c];
A = [s, (1 - c); -(1 - c), s];

vNew = R * vOld;
rNew = rOld + (A * vOld) / double(omega);
end


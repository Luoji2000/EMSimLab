function out = railOutputsNoFriction(vx, L, R, Bz, inField, loopClosed, Fdrive)
%RAILOUTPUTSNOFRICTION  计算 R 系列一步派生输出（无摩擦）
%
% 输入
%   vx         (1,1) double : 当前速度（导轨方向）
%   L          (1,1) double : 导体棒长度
%   R          (1,1) double : 回路电阻
%   Bz         (1,1) double : 带符号磁场
%   inField    (1,1) logical: 是否在磁场区域内
%   loopClosed (1,1) logical: 是否闭合回路
%   Fdrive     (1,1) double : 外力
%
% 输出
%   out (1,1) struct : 派生物理量
%       - epsilon : 感应电动势 ε
%       - current : 电流 I
%       - fMag    : 安培力（导轨方向分量）
%       - pElec   : 电阻发热功率 I^2R
%       - pMech   : 外力机械功率 Fdrive*vx
%
% 公式
%   epsilon = Bz*L*vx（仅场内）
%   current = epsilon/R（仅闭路）
%   fMag    = -Bz*current*L（方向按楞次定律阻碍运动）
%   pElec   = current^2 * R

arguments
    vx (1,1) double
    L (1,1) double
    R (1,1) double
    Bz (1,1) double
    inField (1,1) logical
    loopClosed (1,1) logical
    Fdrive (1,1) double
end

L = max(abs(double(L)), 1e-9);
R = max(double(R), 1e-12);
Bz = double(Bz);
vx = double(vx);

if inField
    epsilon = Bz * L * vx;
else
    epsilon = 0.0;
end

if loopClosed
    current = epsilon / R;
    fMag = -Bz * current * L;
    pElec = current^2 * R;
else
    current = 0.0;
    fMag = 0.0;
    pElec = 0.0;
end

out = struct( ...
    'epsilon', epsilon, ...
    'current', current, ...
    'fMag', fMag, ...
    'pElec', pElec, ...
    'pMech', double(Fdrive) * vx ...
);
end


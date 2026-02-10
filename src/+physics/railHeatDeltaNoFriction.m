function dQ = railHeatDeltaNoFriction(x0, x1, v0, v1, m, Fdrive, heatEnabled)
%RAILHEATDELTANOFRICTION  R 系列单步焦耳热增量（无摩擦能量法）
%
% 输入
%   x0, x1     (1,1) double : 步起点/终点位置
%   v0, v1     (1,1) double : 步起点/终点速度
%   m          (1,1) double : 质量
%   Fdrive     (1,1) double : 外力
%   heatEnabled(1,1) logical: 本步是否允许电阻发热
%                             建议条件：inFieldStart && loopClosed
%
% 输出
%   dQ (1,1) double : 本步电阻发热增量（J）
%
% 采用公式（默认无摩擦）
%   ΔQ_R = Fdrive*Δx - 1/2*m*(v1^2 - v0^2)
%
% 说明
%   - 该式来自机械功输入减去动能增量，等价于电阻耗散能量。
%   - 当本步不在“闭路且有磁感应”的链路中，直接返回 0。
%   - 数值上允许极小负零偏差（浮点误差），会被压到 0。

arguments
    x0 (1,1) double
    x1 (1,1) double
    v0 (1,1) double
    v1 (1,1) double
    m (1,1) double
    Fdrive (1,1) double
    heatEnabled (1,1) logical
end

if ~heatEnabled
    dQ = 0.0;
    return;
end

mSafe = max(double(m), 1e-12);
dx = double(x1) - double(x0);
dK = 0.5 * mSafe * (double(v1)^2 - double(v0)^2);
dQ = double(Fdrive) * dx - dK;

if dQ < 0 && abs(dQ) < 1e-10
    dQ = 0.0;
end
end

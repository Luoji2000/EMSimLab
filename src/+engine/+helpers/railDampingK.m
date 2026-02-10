function k = railDampingK(B, L, R)
%RAILDAMPINGK  计算导轨闭路模型阻尼系数 k = B^2*L^2/R
%
% 输入
%   B (1,1) double : 磁感应强度（可带符号；内部按绝对值计算）
%   L (1,1) double : 导体棒有效长度（米）
%   R (1,1) double : 回路等效电阻（欧姆）
%
% 输出
%   k (1,1) double : 阻尼系数，满足 F_mag = -k*v（无摩擦模型）
%
% 说明
%   - k 只由几何与回路参数决定，不依赖速度
%   - 使用 |B| 后可避免方向符号干扰 k 的正定性

arguments
    B (1,1) double
    L (1,1) double
    R (1,1) double
end

Babs = abs(double(B));
Labs = abs(double(L));
Rsafe = max(double(R), 1e-12);
k = (Babs * Labs)^2 / Rsafe;
end


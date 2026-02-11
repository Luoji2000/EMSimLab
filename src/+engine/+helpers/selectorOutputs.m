function out = selectorOutputs(v, params, inField)
%SELECTOROUTPUTS  计算速度选择器（M4）当前输出量与受力分量
%
% 输入
%   v       (2,1) double : 当前速度 [vx; vy]
%   params  (1,1) struct : 参数结构（至少包含 q/m/Ey/B/Bdir）
%   inField (1,1) logical: 当前是否位于交叉场区域内
%
% 输出
%   out (1,1) struct
%     - qOverM : 当前荷质比 q/m
%     - vSelect: 理想通过速度 Ey/Bz（Bz=0 时为 NaN）
%     - fElecX/fElecY : 电场力分量
%     - fMagX/fMagY   : 磁场力分量
%     - fTotalX/fTotalY : 合力分量

arguments
    v (2,1) double
    params (1,1) struct
    inField (1,1) logical
end

q = double(pickField(params, 'q', 0.0));
m = max(double(pickField(params, 'm', 1.0)), 1e-12);
Ey = double(pickField(params, 'Ey', 0.0));
Bz = engine.helpers.signedBFromParams(params);

if abs(Bz) > 1e-12
    vSelect = Ey / Bz;
else
    vSelect = NaN;
end

if inField
    fElec = [0.0; q * Ey];
    fMag = q * [v(2) * Bz; -v(1) * Bz];
else
    fElec = [0.0; 0.0];
    fMag = [0.0; 0.0];
end

fTotal = fElec + fMag;

out = struct( ...
    'qOverM', q / m, ...
    'vSelect', vSelect, ...
    'fElecX', fElec(1), ...
    'fElecY', fElec(2), ...
    'fMagX', fMag(1), ...
    'fMagY', fMag(2), ...
    'fTotalX', fTotal(1), ...
    'fTotalY', fTotal(2) ...
);
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

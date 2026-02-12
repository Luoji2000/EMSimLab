function out = frameStripOutputs(xCenter, vx, params)
%FRAMESTRIPOUTPUTS  线框-条带磁场模型输出（基于中心坐标与重叠宽度）
%
% 输入
%   xCenter (1,1) double
%     线框中心 x 坐标（状态主变量）。
%   vx      (1,1) double
%     线框中心速度（沿 +x 方向为正）。
%   params  (1,1) struct
%     模板参数，至少包含 w/h/B/Bdir/R/xMin/xMax/loopClosed。
%
% 输出
%   out (1,1) struct
%     - xCenter / xFront / xBack : 中心与前后沿坐标
%     - w / h                    : 线框宽高
%     - overlap                  : 与条带磁场的重叠宽度 s(x)
%     - sPrime                   : ds/dx_center（分段导数）
%     - phi                      : 磁通量 Phi = Bz * h * s
%     - epsilon                  : 感应电动势 ε = -Bz * h * s' * v
%     - current                  : 电流 I = ε / R（仅闭路）
%     - fMag                     : 安培力 F = -(B^2 h^2 / R) * (s'^2) * v（仅闭路）
%     - pElec                    : 电功率 P = I^2 R（仅闭路）
%     - dragCoeff                : 等效阻尼系数 k_eff = (B^2 h^2 / R) * (s'^2)
%     - inField                  : 是否有重叠（overlap > 0）
%
% 说明
%   - 本函数是线框条带模型的“公式真源”，用于 step/reset/render 统一口径。
%   - 坐标约定是“中心坐标”，不是前沿坐标。

arguments
    xCenter (1,1) double
    vx (1,1) double
    params (1,1) struct
end

w = max(toDouble(pickField(params, 'w', pickField(params, 'W', 4.0)), 4.0), 1e-9);
h = max(toDouble(pickField(params, 'h', pickField(params, 'H', pickField(params, 'L', 3.0))), 3.0), 1e-9);
xMin = toDouble(pickField(params, 'xMin', 0.0), 0.0);
xMax = toDouble(pickField(params, 'xMax', xMin + 4.0), xMin + 4.0);
if xMax < xMin
    t = xMin;
    xMin = xMax;
    xMax = t;
end

B = abs(toDouble(pickField(params, 'B', 0.0), 0.0));
Bdir = lower(strtrim(string(pickField(params, 'Bdir', "out"))));
if Bdir == "in"
    Bz = -B;
else
    Bz = B;
end

R = max(toDouble(pickField(params, 'R', 1.0), 1.0), 1e-12);
loopClosed = toLogical(pickField(params, 'loopClosed', true), true);

xFront = xCenter + 0.5 * w;
xBack = xCenter - 0.5 * w;
overlap = max(0.0, min(xFront, xMax) - max(xBack, xMin));

% 使用 clamp 导数得到 ds/dx_center 的分段值（典型取值：-1/0/+1）
dUpper = double(xFront > xMin && xFront < xMax);
dLower = double(xBack > xMin && xBack < xMax);
sPrime = dUpper - dLower;
if overlap <= 1e-12
    sPrime = 0.0;
end

phi = Bz * h * overlap;
epsilon = -Bz * h * sPrime * double(vx);

kBase = (B^2) * (h^2) / R;
dragCoeff = kBase * (sPrime^2);
if loopClosed
    current = epsilon / R;
    fMag = -dragCoeff * double(vx);
    pElec = current^2 * R;
else
    current = 0.0;
    fMag = 0.0;
    pElec = 0.0;
    dragCoeff = 0.0;
end

out = struct( ...
    'xCenter', double(xCenter), ...
    'xFront', double(xFront), ...
    'xBack', double(xBack), ...
    'w', double(w), ...
    'h', double(h), ...
    'overlap', double(overlap), ...
    'sPrime', double(sPrime), ...
    'phi', double(phi), ...
    'epsilon', double(epsilon), ...
    'current', double(current), ...
    'fMag', double(fMag), ...
    'pElec', double(pElec), ...
    'dragCoeff', double(dragCoeff), ...
    'inField', logical(overlap > 1e-12) ...
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

function v = toDouble(x, fallback)
%TODOUBLE  转换为有限标量 double；失败回退
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
elseif isstring(x) || ischar(x)
    tmp = str2double(string(x));
    if isfinite(tmp)
        v = double(tmp);
    else
        v = double(fallback);
    end
else
    v = double(fallback);
end
end

function v = toLogical(x, fallback)
%TOLOGICAL  转换为 logical 标量；失败回退
if islogical(x) && isscalar(x)
    v = logical(x);
elseif isnumeric(x) && isscalar(x) && isfinite(x)
    v = logical(x ~= 0);
elseif isstring(x) || ischar(x)
    token = lower(strtrim(string(x)));
    if any(token == ["true", "1", "on", "yes"])
        v = true;
    elseif any(token == ["false", "0", "off", "no"])
        v = false;
    else
        v = logical(fallback);
    end
else
    v = logical(fallback);
end
end

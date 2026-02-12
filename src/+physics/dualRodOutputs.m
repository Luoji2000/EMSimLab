function out = dualRodOutputs(state, params)
%DUALRODOUTPUTS  计算 R5 双导体棒当前时刻输出量（模式/电学/受力）
%
% 用途
%   - 作为 R5 公式真源的“输出层入口”，统一产出：
%       1) 模式信息（S0/S1/S2/S3）
%       2) 有效重叠与其导数（ell / dEll）
%       3) 合电动势、电流、电功率
%       4) A/B 安培力与合安培力
%
% 输入
%   state  (1,1) struct
%     当前状态，至少应包含 xA/xB/vA/vB（缺失时回退到 params 初值）。
%   params (1,1) struct
%     参数结构，至少应包含 B/Bdir、RA/RB（或 R）、LA/LB（或 L）、
%     bounded/xMin/xMax/yMin/yMax、loopClosed 等字段。
%
% 输出
%   out (1,1) struct
%     双棒输出结构，关键字段如下：
%       - mode/modeCode        : 当前模式（S0/S1/S2/S3）
%       - overlap/dOverlap     : ell 与 d(ell)/dt
%       - cA/cB                : dEll = cA*vA + cB*vB 的系数
%       - Lpair/Leff           : 两棒最短长度与 y 向裁剪后有效长度
%       - Bz/Rtotal            : 带符号磁场与总电阻
%       - epsilon/current/pElec: 合电动势、电流、电阻功率
%       - fMagA/fMagB/fMagSum  : A/B 安培力与合安培力
%       - kCoupling            : 电磁耦合系数 k=(B*Leff)^2/Rtotal
%       - xCenter/vCenter      : 几何中心位置与速度
%       - xCmMass/vCmMass      : 质量中心位置与速度
%       - inField              : overlap>0 语义下是否在场内
%
% 说明
%   - 该函数只做“当前时刻输出计算”，不修改状态。
%   - R5 的电磁耦合采用统一能量一致口径：
%       Fmag_i = -k * c_i * dEll
%     其机械功率恒满足：
%       FmagA*vA + FmagB*vB = -k * dEll^2

arguments
    state (1,1) struct
    params (1,1) struct
end

% ---------- 1) 状态读取 ----------
xA = toDouble(pickField(state, 'xA', pickField(params, 'xA0', pickField(params, 'x0', 0.0))), 0.0);
xB = toDouble(pickField(state, 'xB', pickField(params, 'xB0', xA + 1.0)), xA + 1.0);
vA = toDouble(pickField(state, 'vA', pickField(params, 'vA0', pickField(params, 'v0', 0.0))), 0.0);
vB = toDouble(pickField(state, 'vB', pickField(params, 'vB0', pickField(params, 'v0', 0.0))), 0.0);

if xB < xA
    xMid = 0.5 * (xA + xB);
    xA = xMid;
    xB = xMid;
end

mA = max(toDouble(pickField(params, 'mA', pickField(params, 'm', 1.0)), 1.0), 1e-12);
mB = max(toDouble(pickField(params, 'mB', pickField(params, 'm', 1.0)), 1.0), 1e-12);

% ---------- 2) 几何与模式 ----------
bounded = toLogical(pickField(params, 'bounded', true), true);
if bounded
    xMin = toDouble(pickField(params, 'xMin', 0.0), 0.0);
    xMax = toDouble(pickField(params, 'xMax', 4.0), 4.0);
    if xMax < xMin
        t = xMin;
        xMin = xMax;
        xMax = t;
    end
else
    xMin = -inf;
    xMax = inf;
end

[overlap, cA, cB, dEll, mode] = computeOverlapMode(xA, xB, vA, vB, xMin, xMax);

% ---------- 3) 有效长度与电参数 ----------
Bz = signedB(params);
Lpair = resolveLpair(params);
Leff = resolveLeff(params, Lpair);
Rtotal = resolveRtotal(params);
loopClosed = toLogical(pickField(params, 'loopClosed', true), true);

epsilon = -Bz * Leff * dEll;
if loopClosed
    current = epsilon / Rtotal;
    pElec = current^2 * Rtotal;
    kCoupling = (Bz^2) * (Leff^2) / Rtotal;
    fMagA = -kCoupling * cA * dEll;
    fMagB = -kCoupling * cB * dEll;
else
    current = 0.0;
    pElec = 0.0;
    kCoupling = 0.0;
    fMagA = 0.0;
    fMagB = 0.0;
end
fMagSum = fMagA + fMagB;

% ---------- 4) 中心量 ----------
xCenter = 0.5 * (xA + xB);
vCenter = 0.5 * (vA + vB);
M = mA + mB;
xCmMass = (mA * xA + mB * xB) / M;
vCmMass = (mA * vA + mB * vB) / M;

% ---------- 5) 外力功率（仅用于诊断） ----------
% R5_V2 口径：始终按动力学链路计算，Fdrive=0 时自然退化为无外力
fDriveA = toDouble(pickField(params, 'FdriveA', pickField(params, 'Fdrive', 0.0)), 0.0);
fDriveB = toDouble(pickField(params, 'FdriveB', pickField(params, 'Fdrive', 0.0)), 0.0);
pMech = fDriveA * vA + fDriveB * vB;

% ---------- 6) 输出 ----------
out = struct( ...
    'mode', string(mode), ...
    'modeCode', modeToCode(mode), ...
    'overlap', double(overlap), ...
    'dOverlap', double(dEll), ...
    'cA', double(cA), ...
    'cB', double(cB), ...
    'Lpair', double(Lpair), ...
    'Leff', double(Leff), ...
    'Bz', double(Bz), ...
    'Rtotal', double(Rtotal), ...
    'epsilon', double(epsilon), ...
    'current', double(current), ...
    'pElec', double(pElec), ...
    'pMech', double(pMech), ...
    'fMagA', double(fMagA), ...
    'fMagB', double(fMagB), ...
    'fMagSum', double(fMagSum), ...
    'kCoupling', double(kCoupling), ...
    'xCenter', double(xCenter), ...
    'vCenter', double(vCenter), ...
    'xCmMass', double(xCmMass), ...
    'vCmMass', double(vCmMass), ...
    'inField', logical(overlap > 1e-12) ...
);
end

function [overlap, cA, cB, dEll, mode] = computeOverlapMode(xA, xB, vA, vB, xMin, xMax)
%COMPUTEOVERLAPMODE  计算有效重叠长度、导数系数与模式标签
tol = 1e-12;
left = max(xA, xMin);
right = min(xB, xMax);
overlap = max(0.0, right - left);

if overlap <= tol
    cA = 0.0;
    cB = 0.0;
    dEll = 0.0;
    mode = "S0";
    return;
end

% 左端点贡献（left=max(xA,xMin)）
if xA > xMin + tol
    cA = -1.0;
elseif xA < xMin - tol
    cA = 0.0;
else
    % 位于边界处：若向右进入场内，则端点随 xA 运动
    if vA >= 0
        cA = -1.0;
    else
        cA = 0.0;
    end
end

% 右端点贡献（right=min(xB,xMax)）
if xB < xMax - tol
    cB = 1.0;
elseif xB > xMax + tol
    cB = 0.0;
else
    % 位于边界处：若向左进入场内，则端点随 xB 运动
    if vB <= 0
        cB = 1.0;
    else
        cB = 0.0;
    end
end

dEll = cA * vA + cB * vB;
if cA == -1.0 && cB == 0.0
    mode = "S1";
elseif cA == 0.0 && cB == 1.0
    mode = "S2";
elseif cA == -1.0 && cB == 1.0
    mode = "S3";
else
    mode = "S0";
end
end

function code = modeToCode(mode)
%MODETOCODE  模式字符串转整数代码，便于日志与测试
switch upper(strtrim(string(mode)))
    case "S1"
        code = 1;
    case "S2"
        code = 2;
    case "S3"
        code = 3;
    otherwise
        code = 0;
end
end

function Lpair = resolveLpair(params)
%RESOLVELPAIR  读取两棒长度并返回最小值
LA = max(toDouble(pickField(params, 'LA', pickField(params, 'L', 1.0)), 1.0), 1e-9);
LB = max(toDouble(pickField(params, 'LB', pickField(params, 'L', 1.0)), 1.0), 1e-9);
Lpair = min(LA, LB);
end

function Leff = resolveLeff(params, Lpair)
%RESOLVELEFF  计算 y 向截断后的有效导体长度 Leff
bounded = toLogical(pickField(params, 'bounded', true), true);
if ~bounded
    Leff = Lpair;
    return;
end
yMin = toDouble(pickField(params, 'yMin', -0.5 * Lpair), -0.5 * Lpair);
yMax = toDouble(pickField(params, 'yMax', 0.5 * Lpair), 0.5 * Lpair);
if yMax < yMin
    t = yMin;
    yMin = yMax;
    yMax = t;
end
y0 = toDouble(pickField(params, 'y0', 0.0), 0.0);
rodYMin = y0 - 0.5 * Lpair;
rodYMax = y0 + 0.5 * Lpair;
Leff = max(0.0, min(rodYMax, yMax) - max(rodYMin, yMin));
end

function Rtotal = resolveRtotal(params)
%RESOLVERTOTAL  读取双棒总电阻
RA = max(toDouble(pickField(params, 'RA', pickField(params, 'R', 1.0)), 1.0), 1e-12);
RB = max(toDouble(pickField(params, 'RB', pickField(params, 'R', 1.0)), 1.0), 1e-12);
Rtotal = max(RA + RB, 1e-12);
end

function Bz = signedB(params)
%SIGNEDB  读取带符号磁场 Bz
B = toDouble(pickField(params, 'B', 0.0), 0.0);
dirToken = lower(strtrim(string(pickField(params, 'Bdir', "out"))));
if dirToken == "in"
    Bz = -B;
else
    Bz = B;
end
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失时回退）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

function v = toDouble(x, fallback)
%TODOUBLE  安全转 double 标量
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = double(fallback);
end
end

function tf = toLogical(x, fallback)
%TOLOGICAL  安全转 logical 标量
if islogical(x) && isscalar(x)
    tf = logical(x);
elseif isnumeric(x) && isscalar(x) && isfinite(x)
    tf = logical(x ~= 0);
else
    tf = logical(fallback);
end
end

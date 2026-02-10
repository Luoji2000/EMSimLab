function p = validate(p, schema)
%VALIDATE  参数校验与归一化：补默认 + 类型修正 + 范围裁剪
%
% 输入
%   p      (1,1) struct : 原始参数（可能缺字段、越界、类型不对）
%   schema (1,1) struct : 参数定义（来自 params.schema_get）
%
% 输出
%   p (1,1) struct : 合法参数（字段齐全、类型合法、范围合法）
%
% 说明
%   - UI 不要自己 clamp；统一走这里，保证全局一致性。
%   - 字段类型由 schema.defs(i).type 决定（double/logical/enum）。
%   - 只要存在 v0/thetaDeg 字段，就会补充派生量 vx0/vy0。
%   - validate 不关心“模板业务意义”，只关心结构与类型合法性。
%
% 参见: params.schema_get, params.defaults

arguments
    p (1,1) struct
    schema (1,1) struct
end

% 1) 补字段 + 类型修正 + 范围裁剪
%    逐字段按 schema 定义执行：
%    a) 缺字段 -> 用 default 补齐
%    b) 按 type 归一化
%    c) 数值字段执行区间裁剪
for i = 1:numel(schema.defs)
    d = schema.defs(i);
    fieldName = char(d.name);

    if ~isfield(p, fieldName)
        p.(fieldName) = d.default;
    end

    v = p.(fieldName);
    v = normalizeType(v, d);
    if isfield(d, "type") && d.type == "double"
        v = params.clamp(v, d.min, d.max);
    end

    p.(fieldName) = v;
end

% 1.5) M1 粒子模板的单位/粒子联动规则
%      - 选择电子/质子时：强制 unitMode=particle，并覆盖 q/m 为预设值
if isfield(schema, "key") && strcmpi(string(schema.key), "particle")
    p = applyParticleUnitRules(p);
    p = applyMassSpecRules(p);
end

% 2) particle 模板派生量：由 (v0, thetaDeg) 反推 (vx0, vy0)
%    说明：这是几何派生，不改变速度大小，只分解方向分量。
if hasField(p, "v0") && hasField(p, "thetaDeg")
    thetaRad = deg2rad(double(p.thetaDeg));
    p.vx0 = double(p.v0) * cos(thetaRad);
    p.vy0 = double(p.v0) * sin(thetaRad);
end

% 3) 边界顺序修正（防止 xMin > xMax / yMin > yMax）
%    说明：UI 输入顺序不可信，这里做最终防护。
if hasField(p, "xMin") && hasField(p, "xMax") && p.xMin > p.xMax
    tmp = p.xMin;
    p.xMin = p.xMax;
    p.xMax = tmp;
end
if hasField(p, "yMin") && hasField(p, "yMax") && p.yMin > p.yMax
    tmp = p.yMin;
    p.yMin = p.yMax;
    p.yMax = tmp;
end

end

function p = applyParticleUnitRules(p)
%APPLYPARTICLEUNITRULES  粒子模板专用联动规则
%
% 说明
%   - 该函数是“兜底防线”：保证核心参数语义稳定
%   - 自定义粒子(custom)不强制重置 q/m，保留用户输入
if ~(hasField(p, "particleType") && hasField(p, "unitMode"))
    return;
end

particleType = lower(strtrim(string(p.particleType)));
if any(particleType == ["electron","proton"])
    p.unitMode = "particle";
    [qVal, mVal] = particlePreset(particleType);
    if hasField(p, "q")
        p.q = qVal;
    end
    if hasField(p, "m")
        p.m = mVal;
    end
end
end

function p = applyMassSpecRules(p)
%APPLYMASSSPECRULES  M5 模板参数约束（右半有界磁场）
%
% 约束目标
%   1) M5 强制有界磁场
%   2) xMin 固定在质谱仪左侧粗线（specWallX）
%   3) xMax 始终大于 xMin，避免磁场区域退化
if ~(hasField(p, "templateId") && strcmpi(strtrim(string(p.templateId)), "M5"))
    return;
end

if hasField(p, "specWallX")
    wallX = toDouble(p.specWallX, 0.0);
else
    wallX = 0.0;
end
p.specWallX = wallX;

if hasField(p, "bounded")
    p.bounded = true;
end

if hasField(p, "xMin")
    p.xMin = wallX;
else
    p.xMin = wallX;
end

if hasField(p, "xMax")
    p.xMax = max(toDouble(p.xMax, wallX + 1.0), wallX + 1e-6);
else
    p.xMax = wallX + 1.0;
end

if hasField(p, "slitCenterY")
    p.slitCenterY = toDouble(p.slitCenterY, 0.0);
else
    p.slitCenterY = 0.0;
end
if hasField(p, "slitHeight")
    p.slitHeight = max(toDouble(p.slitHeight, 0.40), 0.05);
else
    p.slitHeight = 0.40;
end
end

function [qVal, mVal] = particlePreset(particleType)
%PARTICLEPRESET  粒子单位下的 q/m 预设值（q: e，m: me）
switch lower(strtrim(string(particleType)))
    case "electron"
        qVal = -1.0;
        mVal = 1.0;
    case "proton"
        qVal = 1.0;
        mVal = 1836.15267343;
    otherwise
        qVal = 1.0;
        mVal = 1.0;
end
end

function tf = hasField(s, name)
%HASFIELD  安全字段检测（仅 struct 时返回 true）
% 输入
%   s    : 任意值
%   name : 字段名
% 输出
%   tf   : 是否存在字段
tf = isstruct(s) && isfield(s, name);
end

function v = normalizeType(vRaw, d)
%NORMALIZETYPE  按 schema 类型分发归一化逻辑
% 输入
%   vRaw : 原始值（来自 UI 或上层 payload）
%   d    : 单个 schema 定义项
% 输出
%   v    : 归一化后的值（类型与 d.type 一致）
typeName = "double";
if isfield(d, "type")
    typeName = string(d.type);
end

switch typeName
    case "logical"
        v = toLogical(vRaw, logical(d.default));
    case "enum"
        v = toEnum(vRaw, string(d.default), string(d.options));
    otherwise
        v = toDouble(vRaw, double(d.default));
end
end

function v = toDouble(vRaw, defaultValue)
%TODOUBLE  将输入转换为有限标量 double，不合法则回退默认值
% 输入
%   vRaw         : 原始值（数值/字符串等）
%   defaultValue : 兜底值
% 输出
%   v            : 有限 double 标量
if isnumeric(vRaw) && isscalar(vRaw) && isfinite(vRaw)
    v = double(vRaw);
    return;
end

if isstring(vRaw) || ischar(vRaw)
    tmp = str2double(string(vRaw));
    if isfinite(tmp)
        v = double(tmp);
        return;
    end
end

v = defaultValue;
end

function v = toLogical(vRaw, defaultValue)
%TOLOGICAL  将输入转换为逻辑值，不合法则回退默认值
% 输入
%   vRaw         : 原始值（logical/数值/字符串）
%   defaultValue : 兜底值
% 输出
%   v            : logical 标量
if islogical(vRaw) && isscalar(vRaw)
    v = logical(vRaw);
    return;
end

if isnumeric(vRaw) && isscalar(vRaw) && isfinite(vRaw)
    v = logical(vRaw ~= 0);
    return;
end

if isstring(vRaw) || ischar(vRaw)
    token = lower(strtrim(string(vRaw)));
    if any(token == ["true","1","on","yes"])
        v = true;
        return;
    end
    if any(token == ["false","0","off","no"])
        v = false;
        return;
    end
end

v = defaultValue;
end

function v = toEnum(vRaw, defaultValue, options)
%TOENUM  将输入映射到枚举候选，不匹配则回退默认值
% 输入
%   vRaw         : 原始值
%   defaultValue : 兜底值（应在 options 中）
%   options      : 枚举候选（string 向量）
% 输出
%   v            : options 中的合法值
if isempty(options)
    v = defaultValue;
    return;
end

token = strtrim(string(vRaw));
idx = find(strcmpi(options, token), 1, "first");
if isempty(idx)
    v = defaultValue;
else
    v = options(idx);
end
end

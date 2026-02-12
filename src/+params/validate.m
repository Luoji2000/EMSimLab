function p = validate(p, schema)
%VALIDATE 参数校验与归一化（统一入口）
%
% 输入
%   p      (1,1) struct
%          原始参数结构。可能存在以下问题：
%          1) 缺少字段
%          2) 类型不匹配（例如字符串输入到数值字段）
%          3) 数值越界
%
%   schema (1,1) struct
%          参数定义，由 params.schema_get 生成。
%          validate 依赖 schema.defs 中的 name/type/default/min/max 信息。
%
% 输出
%   p      (1,1) struct
%          合法参数结构。经过补字段、类型归一化、范围裁剪和模板联动修正。
%
% 处理顺序（非常重要）
%   1) 按 schema 逐字段归一化（补齐默认值 + 类型修正 + clamp）
%   2) 根据 schema.key 应用模板联动规则（particle/selector/rail）
%   3) 生成派生字段（vx0/vy0）
%   4) 修正边界顺序（xMin<=xMax, yMin<=yMax）
%
% 设计原则
%   - UI 层不做业务级数据兜底；统一由 params.validate 收敛。
%   - 业务逻辑要“可组合”：schema 负责定义，validate 负责落实。

arguments
    p (1,1) struct
    schema (1,1) struct
end

%% 1) 按 schema 逐字段归一化
% 规则
%   - 缺字段：写入默认值
%   - 有字段：按 type 归一化
%   - 数值型：执行 min/max 裁剪
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

%% 2) 模板级联动规则
% 说明
%   - 同一套 schema 可能被多个模板复用，模板语义需要在此处进一步约束。
%   - 例如 R8 的条带磁场语义、M4 的 selector 模式约束等。
if isfield(schema, "key") && any(strcmpi(string(schema.key), ["particle", "selector"]))
    p = applyParticleUnitRules(p);
    if strcmpi(string(schema.key), "particle")
        p = applyMassSpecRules(p);
    end
    if strcmpi(string(schema.key), "selector")
        p = applySelectorRules(p);
    end
end
if isfield(schema, "key") && strcmpi(string(schema.key), "rail")
    p = applyRailRules(p);
end

%% 3) 派生量：由 v0/thetaDeg 生成 vx0/vy0
% 说明
%   - 该步骤不会改变速度大小，只做方向分解。
%   - 目的是让引擎层可直接读取 vx0/vy0，减少重复计算。
if hasField(p, "v0") && hasField(p, "thetaDeg")
    thetaRad = deg2rad(double(p.thetaDeg));
    p.vx0 = double(p.v0) * cos(thetaRad);
    p.vy0 = double(p.v0) * sin(thetaRad);
end

%% 4) 边界顺序安全修正
% 说明
%   - 用户输入可能出现 xMin>xMax 或 yMin>yMax。
%   - 此处统一交换，保证几何边界语义稳定。
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
%APPLYPARTICLEUNITRULES 粒子模板单位联动（电子/质子预设）
%
% 输入
%   p (1,1) struct
%     已通过 schema 基础校验的参数结构。
%
% 输出
%   p (1,1) struct
%     应用单位联动后的参数结构。
%
% 规则
%   - particleType=electron/proton 时，强制 unitMode=particle
%   - 并覆盖 q/m 为标准预设值
%   - particleType=custom 时，不覆盖用户自定义 q/m
if ~(hasField(p, "particleType") && hasField(p, "unitMode"))
    return;
end
particleType = lower(strtrim(string(p.particleType)));
if any(particleType == ["electron", "proton"])
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
%APPLYMASSSPECRULES M5 参数约束（右半有界磁场）
%
% 输入
%   p (1,1) struct
%     参数结构。
%
% 输出
%   p (1,1) struct
%     施加 M5 场景几何约束后的参数结构。
%
% 关键约束
%   1) 强制 bounded=true
%   2) xMin 与 specWallX 对齐
%   3) xMax 必须严格大于 xMin（防止场区退化）
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
p.xMin = wallX;
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

function p = applySelectorRules(p)
%APPLYSELECTORRULES M4 速度选择器参数约束
%
% 输入
%   p (1,1) struct
%     参数结构。
%
% 输出
%   p (1,1) struct
%     应用 M4 规则后的参数结构。
%
% 规则
%   1) 模型类型固定为 selector
%   2) 默认保持 bounded=true（用于“进场/出场”教学链条）
%   3) qOverMOut 与当前 q/m 同步
if hasField(p, "templateId") && strcmpi(strtrim(string(p.templateId)), "M4")
    p.modelType = "selector";
    if hasField(p, "bounded")
        p.bounded = true;
    end
end
if hasField(p, "qOverMOut") && hasField(p, "q") && hasField(p, "m")
    mSafe = max(toDouble(p.m, 1.0), 1e-12);
    p.qOverMOut = toDouble(p.q, 0.0) / mSafe;
end
if hasField(p, "plateGap")
    p.plateGap = max(toDouble(p.plateGap, 1.2), 0.05);
end
if hasField(p, "Ey")
    p.Ey = toDouble(p.Ey, 1.0);
end
end

function p = applyRailRules(p)
%APPLYRAILRULES R 系列参数联动规则（含 R2LC 与 R8）
%
% 输入
%   p (1,1) struct
%     参数结构。
%
% 输出
%   p (1,1) struct
%     应用 R 系列联动规则后的参数结构。
%
% 总规则
%   1) elementType 归一化到 R/C/L
%   2) C/L 分支做数值安全下界（避免除零/奇异）
%   3) R8 分支应用条带磁场语义约束
%   4) C/L 分支统一映射到 R2 语义（闭路 + 驱动）
if hasField(p, "elementType")
    p.elementType = upper(strtrim(string(p.elementType)));
else
    p.elementType = "R";
end
if ~any(p.elementType == ["R", "C", "L"])
    p.elementType = "R";
end
if hasField(p, "C")
    p.C = max(toDouble(p.C, 1.0), 1e-12);
end
if hasField(p, "Ls")
    p.Ls = max(toDouble(p.Ls, 1.0), 1e-12);
end

% R8：线框在条带磁场中运动，初速度强制朝右，磁场强制有界条带
if hasField(p, "templateId") && strcmpi(strtrim(string(p.templateId)), "R8")
    if hasField(p, "v0")
        p.v0 = abs(toDouble(p.v0, 0.0));
    end
    if hasField(p, "bounded")
        p.bounded = true;
    end
    if hasField(p, "loopClosed")
        p.loopClosed = true;
    end
    if hasField(p, "xMin")
        p.xMin = toDouble(p.xMin, 0.0);
    else
        p.xMin = 0.0;
    end
    if hasField(p, "xMax")
        p.xMax = toDouble(p.xMax, 4.0);
    else
        p.xMax = 4.0;
    end
    if p.xMax <= p.xMin
        p.xMax = p.xMin + 1e-6;
    end

    % R8 坐标语义：主坐标是线框中心 (xCenter, yCenter)
    if hasField(p, "xCenter")
        p.xCenter = toDouble(p.xCenter, 0.0);
    else
        p.xCenter = toDouble(pickFieldR8(p, "x0", 0.0), 0.0);
    end
    if hasField(p, "yCenter")
        p.yCenter = toDouble(p.yCenter, 0.0);
    else
        p.yCenter = toDouble(pickFieldR8(p, "y0", 0.0), 0.0);
    end
    p.x0 = p.xCenter;
    p.y0 = p.yCenter;

    if hasField(p, "h")
        p.h = max(toDouble(p.h, 3.0), 1e-9);
    else
        p.h = max(toDouble(pickFieldR8(p, "L", 3.0), 3.0), 1e-9);
    end
    p.H = p.h;
    p.L = p.h;

    if hasField(p, "w")
        p.w = max(toDouble(p.w, 4.0), 1e-9);
    else
        p.w = max(toDouble(pickFieldR8(p, "W", 4.0), 4.0), 1e-9);
    end
    p.W = p.w;

    % 匀速模式：强制 Fdrive=0，并隐藏受力箭头
    if hasField(p, "driveEnabled") && ~toLogical(p.driveEnabled, false)
        if hasField(p, "Fdrive")
            p.Fdrive = 0.0;
        end
        if hasField(p, "showDriveForce")
            p.showDriveForce = false;
        end
        if hasField(p, "showAmpereForce")
            p.showAmpereForce = false;
        end
    end
end

% C/L 分支统一归并到 R2 语义
if p.elementType ~= "R"
    if hasField(p, "loopClosed")
        p.loopClosed = true;
    end
    if hasField(p, "driveEnabled")
        p.driveEnabled = true;
    end
    if hasField(p, "templateId")
        p.templateId = "R2";
    end
    if hasField(p, "Fdrive") && abs(toDouble(p.Fdrive, 0.0)) <= 1e-12
        p.Fdrive = 1.0;
    end
end
end

function [qVal, mVal] = particlePreset(particleType)
%PARTICLEPRESET 粒子单位下 q/m 预设（q 以 e 为单位，m 以 me 为单位）
%
% 输入
%   particleType (1,1) string/char
%     粒子类型键，支持 electron/proton/custom。
%
% 输出
%   qVal (1,1) double
%     电荷数（以元电荷 e 为单位）。
%   mVal (1,1) double
%     质量数（以电子质量 me 为单位）。
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
%HASFIELD 安全字段检测（仅 struct 时返回 true）
%
% 输入
%   s    任意值
%   name 字段名（char/string）
%
% 输出
%   tf (1,1) logical
%     当 s 为 struct 且包含目标字段时返回 true。
tf = isstruct(s) && isfield(s, name);
end

function v = normalizeType(vRaw, d)
%NORMALIZETYPE 按 schema 类型归一化
%
% 输入
%   vRaw 任意值
%     原始值，可能来自 UI 字符串、数值或逻辑值。
%   d    (1,1) struct
%     schema 单字段定义，至少包含 type/default，枚举还需 options。
%
% 输出
%   v    归一化后的值
%     类型与 d.type 一致；非法值会回退 default。
%
% 支持类型
%   - double
%   - logical
%   - enum
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
%TODOUBLE 转为有限 double 标量，不合法则回退默认值
%
% 输入
%   vRaw         任意值（数值/字符串/其他）
%   defaultValue (1,1) double
%
% 输出
%   v (1,1) double
%     有限标量 double。若转换失败，则返回 defaultValue。
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
%TOLOGICAL 转为 logical 标量，不合法则回退默认值
%
% 输入
%   vRaw         任意值（logical/数值/字符串）
%   defaultValue (1,1) logical
%
% 输出
%   v (1,1) logical
%     合法逻辑值；非法输入回退 defaultValue。
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
    if any(token == ["true", "1", "on", "yes"])
        v = true;
        return;
    end
    if any(token == ["false", "0", "off", "no"])
        v = false;
        return;
    end
end
v = defaultValue;
end

function v = toEnum(vRaw, defaultValue, options)
%TOENUM 映射到枚举候选，不匹配则回退默认值
%
% 输入
%   vRaw         任意值
%   defaultValue (1,1) string
%   options      (1,:) string
%
% 输出
%   v (1,1) string
%     若 vRaw 匹配 options（忽略大小写）则返回匹配项，
%     否则返回 defaultValue。
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

function v = pickFieldR8(s, name, fallback)
%PICKFIELDR8  R8 内部安全取字段（缺失则回退）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

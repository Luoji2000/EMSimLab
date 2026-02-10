function p = applyTemplatePreset(templateId, pIn)
%APPLYTEMPLATEPRESET  按模板 ID 应用业务默认参数
%
% 说明
%   - R1/R2/R3 统一并入 R 模板
%   - 本函数只做“模板默认值”，不覆盖用户后续改参

arguments
    templateId
    pIn (1,1) struct
end

p = pIn;
tpl = upper(strtrim(string(templateId)));

if tpl == "M5"
    p = applyMassSpecPreset(p);
elseif startsWith(tpl, "R")
    p = applyRailPreset(p);
end
end

function p = applyRailPreset(p)
%APPLYRAILPRESET  R 系列统一预设
p.modelType = "rail";
p.templateId = "R";

if isfield(p, 'showCurrent')
    p.showCurrent = true;
end

% 统一模板下不强制 loopClosed/driveEnabled，由用户在参数面板选择
end

function p = applyMassSpecPreset(p)
%APPLYMASSSPECPRESET  M5 质谱仪场景预设
%
% 场景语义
%   1) 粒子从左向右入射
%   2) 磁场仅在右半区域（左边界固定为狭缝粗线）
%   3) 默认打开有界磁场和磁场标记，便于教学演示

p.modelType = "particle";
p.templateId = "M5";

% 质谱仪几何参数（非 schema 字段，用于渲染和约束）
p.specWallX = 0.0;
p.slitCenterY = 0.0;
p.slitHeight = 0.40;

% 默认入射与磁场参数
p.q = 1.0;
p.m = 1.0;
p.B = 1.0;
p.Bdir = "out";
p.v0 = 1.2;
p.thetaDeg = 0.0;
p.x0 = -1.2;
p.y0 = p.slitCenterY;

% 右半有界磁场（左边界与狭缝粗线对齐）
p.bounded = true;
p.xMin = p.specWallX;
p.xMax = max(double(pickField(p, 'xMax', 4.0)), p.specWallX + 1.0);
p.yMin = -2.0;
p.yMax = 2.0;

% 可视化默认
p.showTrail = true;
p.showV = true;
p.showF = false;
p.showGrid = true;
p.showBMarks = true;
p.autoFollow = false;
p.followSpan = 6.0;
p.maxSpan = 20.0;
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

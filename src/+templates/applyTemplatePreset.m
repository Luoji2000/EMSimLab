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

if startsWith(tpl, "R")
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

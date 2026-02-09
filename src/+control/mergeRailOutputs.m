function p = mergeRailOutputs(p, state)
%MERGERAILOUTPUTS  将 R 系列状态输出写回参数结构（供 UI 输出区显示）
%
% 输入
%   p     (1,1) struct : 当前参数
%   state (1,1) struct : 当前状态
%
% 输出
%   p (1,1) struct : 合并输出后的参数
%
% 说明
%   - 仅在 modelType=rail 时写入
%   - 字段命名与 schema_get("rail") 中输出字段一致

arguments
    p (1,1) struct
    state (1,1) struct
end

modelType = lower(strtrim(string(pickField(p, 'modelType', pickField(state, 'modelType', "")))));
if ~startsWith(modelType, "rail")
    return;
end

p.epsilonOut = double(pickField(state, 'epsilon', 0.0));
p.currentOut = double(pickField(state, 'current', 0.0));
p.fMagOut = double(pickField(state, 'fMag', 0.0));
p.pElecOut = double(pickField(state, 'pElec', 0.0));
p.xOut = double(pickField(state, 'x', 0.0));
p.vOut = double(pickField(state, 'vx', 0.0));
p.qHeatOut = double(pickField(state, 'qHeat', 0.0));
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

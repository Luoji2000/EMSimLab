function modelType = resolveModelType(params)
%RESOLVEMODELTYPE  统一解析模型类型（particle/selector/rail）
%
% 用途
%   - 将 modelType 归一化到引擎支持的三类主模型。
%
% 输入
%   params (1,1) struct
%     参数结构，允许缺失 modelType 字段。
%
% 输出
%   modelType (1,1) string
%     归一化后的模型类型，仅可能为：
%       - "particle"
%       - "selector"
%       - "rail"
%
% 说明
%   - 采用前缀匹配：rail* -> rail，selector* -> selector。
%   - 其它值统一回退为 particle。
modelType = lower(strtrim(string(pickField(params, 'modelType', "particle"))));
if startsWith(modelType, "rail")
    modelType = "rail";
elseif startsWith(modelType, "selector")
    modelType = "selector";
else
    modelType = "particle";
end
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取结构体字段（局部工具函数）
%
% 用途
%   - 在 helper 内部安全读取字段，避免缺字段时报错。
%
% 输入
%   s        (1,1) struct : 源结构体
%   name     (1,:) char/string : 字段名
%   fallback 任意类型 : 回退值
%
% 输出
%   v 任意类型
%     字段存在时返回字段值，否则返回 fallback。
%
% 说明
%   - 本函数不做类型转换，只做缺字段保护。
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

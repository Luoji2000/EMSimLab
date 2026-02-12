function elementType = resolveRailElement(params)
%RESOLVERAILELEMENT  统一解析 R 系列回路元件类型（R/C/L）
%
% 用途
%   - 将参数中的 elementType 归一化为受支持的元件类型。
%
% 输入
%   params (1,1) struct
%     参数结构，允许缺失 elementType 字段。
%
% 输出
%   elementType (1,1) string
%     归一化后的元件类型，仅可能为 "R"、"C"、"L"。
%
% 说明
%   - 非法值会自动回退到 "R"。
elementType = upper(strtrim(string(pickField(params, 'elementType', "R"))));
if ~any(elementType == ["R","C","L"])
    elementType = "R";
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

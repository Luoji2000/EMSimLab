function tf = isR5Template(params)
%ISR5TEMPLATE  统一判断当前参数是否属于 R5 双导体棒模板
%
% 用途
%   - 归一化读取 templateId，并给出 R5 判定结果。
%
% 输入
%   params (1,1) struct
%     参数结构，允许缺失 templateId 字段。
%
% 输出
%   tf (1,1) logical
%     templateId 规范化后等于 "R5" 时返回 true。
%
% 说明
%   - 本函数是模板判定真源，供 step/reset 等流程统一复用。
token = upper(strtrim(string(pickField(params, 'templateId', ""))));
tf = token == "R5";
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
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end


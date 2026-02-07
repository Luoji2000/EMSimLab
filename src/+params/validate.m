function p = validate(p, schema)
%VALIDATE  参数校验与归一化：补默认 + clamp + 类型修正
%
% 输入
%   p      (1,1) struct : 原始参数（可能缺字段、越界、类型不对）
%   schema (1,1) struct : 参数定义（来自 params.schema_get）
%
% 输出
%   p (1,1) struct : 合法参数（字段齐全、范围合法）
%
% 说明
%   - UI 不要自己 clamp；统一走这里，保证全局一致性。
%   - 如果你希望“越界就报错”而不是 clamp，可以把 clamp 改成 error。
%
% 参见: params.schema_get, params.defaults

arguments
    p (1,1) struct
    schema (1,1) struct
end

% 1) 补字段 + 类型修正
for i = 1:numel(schema.defs)
    d = schema.defs(i);
    if ~isfield(p, d.name)
        p.(d.name) = d.default;
    end
    % 统一转为 double（你也可以按字段类型扩展）
    p.(d.name) = double(p.(d.name));
end

% 2) clamp（范围裁剪）
for i = 1:numel(schema.defs)
    d = schema.defs(i);
    v = p.(d.name);
    p.(d.name) = params.clamp(v, d.min, d.max);
end

end

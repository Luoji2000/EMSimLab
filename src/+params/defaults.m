function p = defaults(schema)
%DEFAULTS  根据 schema 生成默认 params 结构体
%
% 输入
%   schema (1,1) struct : 来自 params.schema_get
% 输出
%   p (1,1) struct : 含所有 schema.defs(i).name 字段

arguments
    schema (1,1) struct
end

p = struct();
for i = 1:numel(schema.defs)
    name = schema.defs(i).name;
    p.(name) = schema.defs(i).default;
end

end

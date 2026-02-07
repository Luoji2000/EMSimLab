function list = registry()
%REGISTRY  模板注册表（模板树数据源）
%
% 输出
%   list : struct 数组，每个元素至少包含：
%       - id        (string) 模板唯一ID（用于 NodeData）
%       - title     (string) 模板显示名（用于树节点 Text）
%       - group     (string) 分组名（用于树父节点）
%       - engineKey (string) 对应引擎键（决定显示哪个参数面板/用哪个 engine）
%       - schemaKey (string) 参数 schema 键（决定有哪些参数、默认值、范围）
%
% 说明
%   以后新增模板，优先只改这里 + params.schema_get（以及对应 UI 映射）。
%
% 参见: templates.getById, params.schema_get

list = struct( ...
    "id",        ["particle"; "ampere"], ...
    "title",     ["带电粒子（基础）"; "安培定律（演示）"], ...
    "group",     ["运动学"; "电磁定律"], ...
    "engineKey", ["particle"; "ampere"], ...
    "schemaKey", ["particle"; "ampere"] ...
);

end

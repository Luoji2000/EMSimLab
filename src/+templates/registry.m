function list = registry()
%REGISTRY  模板注册表（模板树数据源）
%
% 文件结构
%   - 模板定义：src/+templates/+defs/*.m（每个模板一个函数）
%   - 本文件：只做模板汇总，不堆叠单模板细节
%
% 输出
%   list : struct 数组，每个元素至少包含：
%       - id        (string) 模板唯一 ID（用于 NodeData）
%       - title     (string) 模板显示名（用于树节点 Text）
%       - group     (string) 分组名（用于树父节点）
%       - engineKey (string) 对应引擎键（决定使用哪个 engine）
%       - schemaKey (string) 参数 schema 键（决定参数定义）
%
% 参见: templates.getById, params.schema_get

list = [ ...
    templates.defs.M1(), ...
    templates.defs.R() ...
];

end

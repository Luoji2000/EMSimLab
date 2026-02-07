function schema = schema_get(key)
%SCHEMA_GET  获取某一类模板/引擎的参数 Schema（中文注释风格示例）
%
% 输入
%   key (1,1) string : schemaKey，例如 "particle" / "ampere"
%
% 输出
%   schema (1,1) struct :
%     - key     : schemaKey
%     - version : 版本号（参数定义变化时 +1）
%     - defs    : 结构体数组，每个元素描述一个参数字段
%
% 设计原则
%   1) UI / 校验 / 文档共享同一份 schema
%   2) schema 只描述“定义”，不做计算
%
% 参见: params.validate, params.defaults

arguments
    key (1,1) string
end

switch key
    case "particle"
        schema = struct();
        schema.key = key;
        schema.version = 1;
        schema.defs = [ ...
            def("B",   "磁感应强度 B", 1.0,  -10, 10, "T"); ...
            def("q",   "电荷量 q",     1.0,  -10, 10, "C"); ...
            def("m",   "质量 m",       1.0,  1e-6, 1e6, "kg"); ...
            def("x0",  "初始位置 x0",  0.0,  -10, 10, "m"); ...
            def("y0",  "初始位置 y0",  0.0,  -10, 10, "m"); ...
            def("vx0", "初速度 vx0",   1.0,  -100, 100, "m/s"); ...
            def("vy0", "初速度 vy0",   0.0,  -100, 100, "m/s") ...
        ];

    case "ampere"
        schema = struct();
        schema.key = key;
        schema.version = 1;
        schema.defs = [ ...
            def("I", "电流 I",  1.0,  -100, 100, "A"); ...
            def("r", "半径 r",  1.0,  1e-3, 100, "m") ...
        ];

    otherwise
        error("params:UnknownSchema", "未知 schemaKey=%s", key);
end

end

function d = def(name, label, defaultValue, minValue, maxValue, unit)
%DEF  构造一个参数定义（内部帮助函数）
d = struct();
d.name = string(name);
d.label = string(label);
d.default = defaultValue;
d.min = minValue;
d.max = maxValue;
d.unit = string(unit);
end

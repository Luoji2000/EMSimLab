function schema = schema_get(key)
%SCHEMA_GET  获取某一类模板/引擎的参数 Schema
%
% 输入
%   key (1,1) string : schemaKey，例如 "particle" / "ampere"
%
% 输出
%   schema (1,1) struct :
%     - key     : schemaKey
%     - version : 版本号（参数定义变化时 +1）
%     - defs    : 结构体数组，每个元素描述一个参数字段
%         * name    : 参数字段名
%         * label   : 中文标签
%         * type    : 参数类型（double/logical/enum）
%         * default : 默认值
%         * min/max : 数值上下界（非数值类型为 NaN）
%         * unit    : 单位字符串（无量纲可填 '-'）
%         * options : 枚举候选列表（仅 enum 使用）
%
% 设计原则
%   1) UI / 校验 / 文档共享同一份 schema
%   2) schema 只描述“定义”，不做计算
%   3) 参数合法性由 params.validate 统一执行
%
% 参见: params.validate, params.defaults

arguments
    key (1,1) string
end

key = lower(strtrim(key));  % 去掉首尾空格，转换为小写

switch key
    case "particle"
        % M1 粒子模板参数定义（含视图开关与派生速度分量）
        schema = struct();
        schema.key = key;
        schema.version = 3;
        schema.defs = [ ...
            defNum("q",         "电荷量 q",           1.0,   -10, 10,   "C"); ...
            defNum("m",         "质量 m",             1.0,   1e-9, 1e6, "kg"); ...
            defNum("B",         "磁感应强度 B",       1.0,   0, 10,     "T"); ...
            defNum("v0",        "初速度大小 v0",      0.8,   0, 1e3,    "m/s"); ...
            defNum("thetaDeg",  "初速度方向角 theta", 0.0,   -360, 360, "deg"); ...
            defEnum("Bdir",     "磁场方向",           "out", ["out","in"], "-"); ...
            defNum("x0",        "初始位置 x0",        0.0,   -100, 100, "m"); ...
            defNum("y0",        "初始位置 y0",        0.8,   -100, 100, "m"); ...
            defBool("bounded",  "是否有界磁场",       false, "-"); ...
            defNum("xMin",      "边界 xMin",          -1.0,  -1e3, 1e3, "m"); ...
            defNum("xMax",      "边界 xMax",          1.0,   -1e3, 1e3, "m"); ...
            defNum("yMin",      "边界 yMin",          -1.0,  -1e3, 1e3, "m"); ...
            defNum("yMax",      "边界 yMax",          1.0,   -1e3, 1e3, "m"); ...
            defBool("showTrail","显示轨迹",           true,  "-"); ...
            defBool("showV",    "显示速度箭头",       true,  "-"); ...
            defBool("showF",    "显示受力箭头",       false, "-"); ...
            defBool("showGrid", "显示网格",           true,  "-"); ...
            defBool("showBMarks","显示 B 标记",       true,  "-"); ...
            defBool("autoFollow","自动跟随粒子",      true,  "-"); ...
            defNum("followSpan","跟随视野跨度",       2.4,   0.5, 40.0, "m"); ...
            defNum("maxSpan",   "最大视野跨度",       40.0,  2.0, 200.0, "m"); ...
            defEnum("unitMode", "单位模式",           "SI", ["SI","particle"], "-"); ...
            defEnum("particleType", "粒子类型",       "custom", ["custom","electron","proton"], "-"); ...
            defNum("speedScale","速度倍率",           1.0,   0.25, 4.0, "x"); ...
            defNum("vx0",       "初速度 vx0（派生）", 0.8,   -1e3, 1e3, "m/s"); ...
            defNum("vy0",       "初速度 vy0（派生）", 0.0,   -1e3, 1e3, "m/s") ...
        ];

    case "ampere"
        % 安培演示模板参数定义（当前阶段最小集合）
        schema = struct();
        schema.key = key;
        schema.version = 2;
        schema.defs = [ ...
            defNum("I", "电流 I", 1.0, -100, 100, "A"); ...
            defNum("r", "半径 r", 1.0, 1e-3, 100, "m") ...
        ];

    otherwise
        error("params:UnknownSchema", "未知 schemaKey=%s", key);
end

end

function d = defNum(name, label, defaultValue, minValue, maxValue, unit)
%DEFNUM  构造数值参数定义
% 输入
%   name          : 字段名
%   label         : 中文标签
%   defaultValue  : 默认值（数值）
%   minValue      : 最小值（数值）
%   maxValue      : 最大值（数值）
%   unit          : 单位字符串
% 输出
%   d             : 结构体，含数值参数定义字段
d = baseDef(name, label, unit);
d.type = "double";
d.default = double(defaultValue);
d.min = double(minValue);
d.max = double(maxValue);
d.options = strings(0, 1);
end

function d = defBool(name, label, defaultValue, unit)
%DEFBOOL  构造布尔参数定义
% 输入
%   name          : 字段名
%   label         : 中文标签
%   defaultValue  : 默认值（逻辑值）
%   unit          : 单位字符串
% 输出
%   d             : 结构体，含布尔参数定义字段
d = baseDef(name, label, unit);
d.type = "logical";
d.default = logical(defaultValue);
d.min = NaN;
d.max = NaN;
d.options = strings(0, 1);
end

function d = defEnum(name, label, defaultValue, options, unit)
%DEFENUM  构造枚举参数定义
% 输入
%   name          : 字段名
%   label         : 中文标签
%   defaultValue  : 默认值（字符串）
%   options       : 枚举可选值集合
%   unit          : 单位字符串
% 输出
%   d             : 结构体，含枚举参数定义字段
d = baseDef(name, label, unit);
d.type = "enum";
d.default = string(defaultValue);
d.min = NaN;
d.max = NaN;
d.options = string(options(:));
end

function d = baseDef(name, label, unit)
%BASEDEF  构造参数定义公共字段（内部帮助函数）
% 输入
%   name         : 字段名
%   label        : 中文标签
%   unit         : 单位字符串
% 输出
%   d            : 结构体，含公共字段
d = struct();
d.name = string(name);
d.label = string(label);
d.unit = string(unit);
end

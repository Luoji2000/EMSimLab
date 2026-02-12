function entry = logEvent(app, level, eventName, payload)
%% 入口：日志写入与回显
%LOGEVENT  统一日志入口：写入界面日志区，并同步命令行输出
%
% 输入
%   app       : App 实例（可为空）
%   level     : 日志级别（支持 INFO/DEBUG/WARN/ERROR 或中文）
%   eventName : 事件名（建议中文）
%   payload   : 结构化负载
%
% 输出
%   entry     : 结构化日志记录

if nargin < 2 || strlength(string(level)) == 0
    level = "信息";
end
if nargin < 3 || strlength(string(eventName)) == 0
    eventName = "事件";
end
if nargin < 4 || isempty(payload)
    payload = struct();
end

entry = struct();
entry.ts = datetime('now');
entry.level = normalizeLevel(level);
entry.event = string(eventName);
entry.payload = payload;

line = composeLine(entry);

% 优先写入 UI 日志面板；失败时不打断主流程
if ~isempty(app) && isa(app, 'handle') && isvalidHandle(app) && ismethod(app, 'appendLogLine')
    try
        app.appendLogLine(line);
    catch
        % 忽略界面写日志失败，继续输出到命令行
    end
end

% 命令行输出策略：
%   - 默认输出，便于无界面调试
%   - 若 App 提供 shouldEchoLogToConsole 策略，则按策略决定
shouldEcho = true;
if ~isempty(app) && isa(app, 'handle') && isvalidHandle(app) && ismethod(app, 'shouldEchoLogToConsole')
    try
        % 新签名：传完整 entry，便于按事件名做精细过滤
        shouldEcho = logical(app.shouldEchoLogToConsole(entry));
    catch
        try
            % 兼容签名：level + event
            shouldEcho = logical(app.shouldEchoLogToConsole(entry.level, entry.event));
        catch
            try
                % 兼容旧签名：只传 level
                shouldEcho = logical(app.shouldEchoLogToConsole(entry.level));
            catch
                shouldEcho = true;
            end
        end
    end
end

if shouldEcho
    fprintf('%s\n', line);
end
end

%% 级别与句柄安全
function label = normalizeLevel(levelRaw)
%NORMALIZELEVEL  统一日志级别显示（中文优先）
token = upper(strtrim(string(levelRaw)));
switch token
    case {"DEBUG","调试"}
        label = "调试";
    case {"WARN","WARNING","警告"}
        label = "警告";
    case {"ERROR","ERR","错误"}
        label = "错误";
    otherwise
        label = "信息";
end
end

function tf = isvalidHandle(obj)
%ISVALIDHANDLE  兼容判定对象句柄有效性
tf = false;
try
    tf = isvalid(obj);
catch
    tf = false;
end
end

%% 文本拼装
function line = composeLine(entry)
%COMPOSELINE  生成单行日志文本
ts = char(datetime(entry.ts, 'Format', 'HH:mm:ss.SSS'));
payloadText = payloadToText(entry.payload);
if strlength(payloadText) > 0
    line = sprintf('[%s][%s][%s] %s', ts, char(entry.level), char(entry.event), char(payloadText));
else
    line = sprintf('[%s][%s][%s]', ts, char(entry.level), char(entry.event));
end
end

%% payload 序列化
function text = payloadToText(payload)
%PAYLOADTOTEXT  将 payload 安全序列化为单行文本
text = "";
if isempty(payload)
    return;
end

if isstruct(payload)
    fields = fieldnames(payload);
    if isempty(fields)
        return;
    end

    pieces = strings(numel(fields), 1);
    for i = 1:numel(fields)
        key = string(fields{i});
        value = payload.(fields{i});
        pieces(i) = payloadKeyToLabel(key) + "=" + scalarToText(value);
    end
    text = strjoin(pieces, ", ");
    return;
end

text = scalarToText(payload);
end

%% payload 键名映射（结构体表）
function label = payloadKeyToLabel(key)
%PAYLOADKEYTOLABEL  将内部英文键映射为中文显示名（结构体映射表版本）
token = char(lower(strtrim(string(key))));
map = payloadLabelMap();
if isfield(map, token)
    label = map.(token);
else
    label = string(key);
end
end

function map = payloadLabelMap()
%PAYLOADLABELMAP  payload 键名映射表（集中维护，避免超长 switch）
persistent labelMap
if ~isempty(labelMap)
    map = labelMap;
    return;
end

pairs = {
    "entry",                    "入口";
    "template",                 "模板";
    "group_count",              "分组数";
    "template_count",           "模板数";
    "class_name",               "类名";
    "property_count",           "属性数";
    "event",                    "事件";
    "source",                   "来源";
    "value",                    "数值";
    "delta",                    "增量";
    "reason",                   "原因";
    "path",                     "路径";
    "line_count",               "行数";
    "requested_id",             "请求模板ID";
    "raw_token",                "原始模板令牌";
    "template_id",              "模板ID";
    "current_template",         "当前模板";
    "current_schema",           "当前参数模式";
    "current_engine",           "当前引擎模式";
    "schema_key",               "参数模式";
    "engine_key",               "引擎模式";
    "param_component",          "参数组件";
    "changed_summary",          "变化摘要";
    "dt",                       "步长";
    "t",                        "当前时间";
    "enabled",                  "启用";
    "loop_closed",              "闭合回路";
    "drive_enabled",            "外力驱动";
    "ui_render_path",           "UI渲染路径";
    "viz_scene_path",           "场景渲染路径";
    "engine_step_path",         "步进引擎路径";
    "traj_points",              "轨迹点数";
    "point_count",              "点数";
    "x_lim_text",               "X范围";
    "y_lim_text",               "Y范围";
    "view_span",                "视野跨度";
    "finite_xy",                "坐标有效";
    "mark_count",               "标记数量";
    "marker",                   "标记形状";
    "bdir",                     "磁场方向";
    "show_switch",              "开关";
    "visible",                  "可见";
    "speed",                    "速度";
    "radius",                   "半径";
    "arrow_len",                "箭头长度";
    "omega",                    "角速度";
    "child_count",              "子对象数";
    "allchild_count",           "全部对象数";
    "first_type",               "首对象类型";
    "first_visible",            "首对象可见";
    "axes_visible",             "坐标轴可见";
    "axes_pos_text",            "坐标轴位置";
    "axes_inner_text",          "绘图区位置";
    "figure_visible",           "窗口可见";
    "scene_tab_visible",        "场景页可见";
    "scene_selected",           "场景页选中";
    "selected_tab_title",       "当前Tab";
    "trail_visible",            "轨迹可见";
    "particle_visible",         "粒子可见";
    "vel_visible",              "速度箭头可见";
    "bmark_visible",            "磁场标记可见";
    "field_box_visible",        "磁场边框可见";
    "bounded",                  "有界模式";
    "box_visible",              "边框可见";
    "cache_hit",                "缓存命中";
    "auto_follow",              "自动跟随";
    "follow_span",              "跟随视野";
    "x",                        "x";
    "y",                        "y";
    "vx",                       "vx";
    "vy",                       "vy";
    "mode",                     "模式";
    "step_ms",                  "物理推进耗时ms";
    "output_ms",                "输出回写耗时ms";
    "render_ms",                "渲染耗时ms";
    "tick_ms",                  "单帧总耗时ms";
    "ema_step_ms",              "物理推进均值ms";
    "ema_output_ms",            "输出回写均值ms";
    "ema_render_ms",            "渲染均值ms";
    "ema_tick_ms",              "单帧总耗时均值ms";
    "frame_budget_ms",          "帧预算ms";
    "headroom_ms",              "帧余量ms";
    "fps_est",                  "估算FPS";
    "main_cost",                "主耗时环节";
    "main_cost_ms",             "主耗时ms";
    "model_type",               "模型";
    "wall_x",                   "粗线x";
    "slit_center_y",            "小孔中心y";
    "slit_height",              "小孔高度";
    "show_efield",              "显示电场箭头";
    "ey",                       "Ey";
    "y_top",                    "上极板y";
    "y_bottom",                 "下极板y";
    "show_felec",               "电场力箭头开关";
    "show_fmag",                "磁场力箭头开关";
    "f_total",                  "合力模";
    "f_elec",                   "电场力模";
    "f_mag",                    "磁场力模";
    "rail_visible",             "导轨可见";
    "rod_visible",              "导体棒可见";
    "resistor_visible",         "电阻可见";
    "show_current",             "电流箭头显示";
    "current_source",           "电流方向来源";
    "show_drive_force",         "外力箭头显示";
    "show_ampere_force",        "安培力箭头显示";
    "epsilon",                  "感应电动势";
    "current",                  "电流";
    "fmag",                     "安培力";
    "fdrive",                   "外力";
    "sub_dt",                   "子步长";
    "sub_steps",                "子步数";
    "x_min",                    "x_min";
    "x_max",                    "x_max";
    "x_out",                    "输出x_t";
    "v_out",                    "输出v_t";
    "q_heat_out",               "输出Q";
    "q_heat",                   "焦耳热";
    "in_field",                 "在磁场内";
    "from_class",               "旧组件";
    "to_class",                 "新组件";
    "force_recreate",           "强制重建";
    "resolved_class",           "目标组件类";
    "actual_class",             "实际组件类";
    "old_class",                "旧组件类";
    "has_old_component",        "存在旧组件";
    "m1_class_exists",          "M1类可用";
    "m4_class_exists",          "M4类可用";
    "r2_class_exists",          "R2类可用";
    "m5_class_exists",          "M5类可用";
    "m1_path",                  "M1类路径";
    "m4_path",                  "M4类路径";
    "r2_path",                  "R2类路径";
    "m5_path",                  "M5类路径";
    "on_template_changed_path", "模板切换函数路径";
    "main_app_path",            "MainApp路径"
};

labelMap = struct();
for i = 1:size(pairs, 1)
    keyName = char(pairs{i, 1});
    labelMap.(keyName) = string(pairs{i, 2});
end
map = labelMap;
end

%% 标量转文本工具
function text = scalarToText(v)
%SCALARTOTEXT  将常见值转换为可读文本
if isstring(v) || ischar(v)
    text = string(v);
    return;
end
if islogical(v) && isscalar(v)
    text = string(v);
    return;
end
if isnumeric(v) && isscalar(v)
    text = string(v);
    return;
end
if isnumeric(v) && ~isscalar(v)
    text = sprintf('[%dx%d %s]', size(v, 1), size(v, 2), class(v));
    return;
end
if iscell(v)
    text = sprintf('{cell %d}', numel(v));
    return;
end
if isstruct(v)
    text = sprintf('{struct %d}', numel(fieldnames(v)));
    return;
end

text = string(class(v));
end

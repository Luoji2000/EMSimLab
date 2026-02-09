function entry = logEvent(app, level, eventName, payload)
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

% 保留命令行输出，便于无界面调试
fprintf('%s\n', line);
end

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

function label = payloadKeyToLabel(key)
%PAYLOADKEYTOLABEL  将内部英文键映射为中文显示名
token = lower(strtrim(string(key)));
switch token
    case "entry"
        label = "入口";
    case "template"
        label = "模板";
    case "group_count"
        label = "分组数";
    case "template_count"
        label = "模板数";
    case "class_name"
        label = "类名";
    case "property_count"
        label = "属性数";
    case "event"
        label = "事件";
    case "source"
        label = "来源";
    case "value"
        label = "数值";
    case "delta"
        label = "增量";
    case "reason"
        label = "原因";
    case "path"
        label = "路径";
    case "line_count"
        label = "行数";
    case "requested_id"
        label = "请求模板ID";
    case "template_id"
        label = "模板ID";
    case "schema_key"
        label = "参数模式";
    case "engine_key"
        label = "引擎模式";
    case "param_component"
        label = "参数组件";
    case "changed_summary"
        label = "变化摘要";
    case "dt"
        label = "步长";
    case "t"
        label = "当前时间";
    case "enabled"
        label = "启用";
    case "ui_render_path"
        label = "UI渲染路径";
    case "viz_scene_path"
        label = "场景渲染路径";
    case "engine_step_path"
        label = "步进引擎路径";
    case "traj_points"
        label = "轨迹点数";
    case "point_count"
        label = "点数";
    case "x_lim_text"
        label = "X范围";
    case "y_lim_text"
        label = "Y范围";
    case "view_span"
        label = "视野跨度";
    case "finite_xy"
        label = "坐标有效";
    case "mark_count"
        label = "标记数量";
    case "marker"
        label = "标记形状";
    case "bdir"
        label = "磁场方向";
    case "show_switch"
        label = "开关";
    case "visible"
        label = "可见";
    case "speed"
        label = "速度";
    case "radius"
        label = "半径";
    case "arrow_len"
        label = "箭头长度";
    case "omega"
        label = "角速度";
    case "child_count"
        label = "子对象数";
    case "allchild_count"
        label = "全部对象数";
    case "first_type"
        label = "首对象类型";
    case "first_visible"
        label = "首对象可见";
    case "axes_visible"
        label = "坐标轴可见";
    case "axes_pos_text"
        label = "坐标轴位置";
    case "axes_inner_text"
        label = "绘图区位置";
    case "figure_visible"
        label = "窗口可见";
    case "scene_tab_visible"
        label = "场景页可见";
    case "scene_selected"
        label = "场景页选中";
    case "selected_tab_title"
        label = "当前Tab";
    case "trail_visible"
        label = "轨迹可见";
    case "particle_visible"
        label = "粒子可见";
    case "vel_visible"
        label = "速度箭头可见";
    case "bmark_visible"
        label = "磁场标记可见";
    case "field_box_visible"
        label = "磁场边框可见";
    case "bounded"
        label = "有界模式";
    case "box_visible"
        label = "边框可见";
    case "auto_follow"
        label = "自动跟随";
    case "follow_span"
        label = "跟随视野";
    case "x"
        label = "x";
    case "y"
        label = "y";
    case "vx"
        label = "vx";
    case "vy"
        label = "vy";
    otherwise
        label = key;
end
end

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

function onTemplateChanged(app, varargin)
%ONTEMPLATECHANGED  处理模板切换（来自树节点或事件负载）
%
% 输入
%   app      : MainApp 实例
%   varargin : 可能是 SelectionChanged 事件，也可能是模板 id
%
% 主链路
%   1) 解析模板 ID
%   2) 更新 app 的当前模板/参数模式/引擎模式
%   3) 生成默认参数并校验
%   4) 重置状态、刷新参数区与渲染

rawToken = control.parseTemplateId(varargin{:});
tplId = resolveTemplateId(rawToken, app.CurrentTemplateId);
logger.logEvent(app, '信息', '模板切换请求', struct('requested_id', tplId, 'raw_token', rawToken));
logger.logEvent(app, '调试', '模板切换前状态', struct( ...
    'current_template', string(app.CurrentTemplateId), ...
    'current_schema', string(app.CurrentSchemaKey), ...
    'current_engine', string(app.CurrentEngineKey), ...
    'param_component', getParamComponentName(app), ...
    'on_template_changed_path', string(which('control.onTemplateChanged')), ...
    'main_app_path', string(which('MainApp')) ...
));

% 切模板前先暂停播放，避免切换过程中定时器并发推进
if ismethod(app, 'isPlaybackRunning') && ismethod(app, 'pausePlayback')
    if app.isPlaybackRunning()
        app.pausePlayback();
    end
elseif ismethod(app, 'pausePlayback')
    app.pausePlayback();
end

% 1) 读取模板定义
try
    tpl = templates.getById(tplId);
catch err
    logger.logEvent(app, '警告', '模板切换已忽略', struct('reason', err.message, 'raw_token', rawToken));
    return;
end

% 2) 同步模板上下文
if isprop(app, 'CurrentTemplateId')
    app.CurrentTemplateId = tpl.id;
end
if isprop(app, 'CurrentSchemaKey')
    app.CurrentSchemaKey = tpl.schemaKey;
end
if isprop(app, 'CurrentEngineKey')
    app.CurrentEngineKey = tpl.engineKey;
end
logger.logEvent(app, '调试', '模板上下文已更新', struct( ...
    'template_id', string(tpl.id), ...
    'schema_key', string(tpl.schemaKey), ...
    'engine_key', string(tpl.engineKey) ...
));

% 3) 构建并校验默认参数
schema = params.schema_get(tpl.schemaKey);
p0 = params.defaults(schema);
p = params.validate(p0, schema);
p.modelType = string(tpl.engineKey);
p.templateId = string(tpl.id);
p = templates.applyTemplatePreset(tpl.id, p);
p = params.validate(p, schema);
logger.logEvent(app, '调试', '模板预设已应用', struct( ...
    'template_id', string(tpl.id), ...
    'loop_closed', logicalFieldSafe(p, 'loopClosed', false), ...
    'drive_enabled', logicalFieldSafe(p, 'driveEnabled', false), ...
    'fdrive', doubleFieldSafe(p, 'Fdrive', 0.0) ...
));

if isprop(app, 'Params')
    app.Params = p;
end

% 4) 同步顶部速度控件显示（若 schema 包含 speedScale）
if isprop(app, 'SpeedSlider') && isgraphics(app.SpeedSlider) && isfield(p, 'speedScale')
    app.SpeedSlider.Value = double(p.speedScale);
end
if isprop(app, 'SpeedValueField') && isgraphics(app.SpeedValueField) && isfield(p, 'speedScale')
    app.SpeedValueField.Value = double(p.speedScale);
end
if isprop(app, 'SpeedValueLabel') && isgraphics(app.SpeedValueLabel) && isfield(p, 'speedScale')
    app.SpeedValueLabel.Text = sprintf('%.2fx', double(p.speedScale));
end

% 5) 重置状态并刷新 UI
if isprop(app, 'State')
    app.State = engine.reset(app.State, p);
    p = control.mergeRailOutputs(p, app.State);
    app.Params = p;
end

if ismethod(app, 'reloadParamComponent')
    app.reloadParamComponent(tpl.id, true);
else
    logger.logEvent(app, '警告', '参数组件重载入口缺失', struct('reason', 'MainApp.reloadParamComponent 不可用'));
end
logger.logEvent(app, '调试', '模板切换后组件状态', struct('param_component', getParamComponentName(app)));

ui.setPanelsForTemplate(app, tpl);
ui.applyPayload(app, p);
if isprop(app, 'State')
    ui.render(app, app.State);
end

logger.logEvent(app, '信息', '模板切换完成', struct( ...
    'template_id', tpl.id, ...
    'schema_key', tpl.schemaKey, ...
    'engine_key', tpl.engineKey, ...
    'param_component', getParamComponentName(app) ...
));
end

function v = logicalFieldSafe(s, name, fallback)
%LOGICALFIELDSAFE  安全读取 logical 字段
if isstruct(s) && isfield(s, name)
    raw = s.(name);
    if islogical(raw) && isscalar(raw)
        v = raw;
        return;
    end
    if isnumeric(raw) && isscalar(raw)
        v = raw ~= 0;
        return;
    end
end
v = logical(fallback);
end

function v = doubleFieldSafe(s, name, fallback)
%DOUBLEFIELDSAFE  安全读取数值字段
if isstruct(s) && isfield(s, name)
    raw = s.(name);
    if isnumeric(raw) && isscalar(raw) && isfinite(raw)
        v = double(raw);
        return;
    end
end
v = double(fallback);
end

function tplId = resolveTemplateId(rawToken, currentId)
%RESOLVETEMPLATEID  将解析出的 token 映射为合法模板 id
%
% 规则
%   1) 优先直接按 id 匹配
%   2) 若 token 是模板标题，则按标题映射到 id
%   3) 均失败时保持当前模板，不回退到固定 M1

if nargin < 2 || strlength(strtrim(string(currentId))) == 0
    currentId = "M1";
end
tplId = string(currentId);

token = strtrim(string(rawToken));
if strlength(token) == 0
    return;
end

% 兼容旧模板编号：R1/R2/R3/R4 -> R（R8 保持独立）
tokenUpper = upper(token);
if any(tokenUpper == ["R1","R2","R3","R4"])
    tplId = "R";
    return;
end

list = templates.registry();
if isempty(list)
    return;
end

idList = upper(string({list.id}));
titleList = string({list.title});

idx = find(idList == upper(token), 1, 'first');
if ~isempty(idx)
    tplId = string(list(idx).id);
    return;
end

idx = find(titleList == token, 1, 'first');
if ~isempty(idx)
    tplId = string(list(idx).id);
end
end

function name = getParamComponentName(app)
%GETPARAMCOMPONENTNAME  读取当前参数组件类型名
name = "无";
if isprop(app, 'ParamComponent') && ~isempty(app.ParamComponent)
    try
        name = string(class(app.ParamComponent));
    catch
        name = "未知";
    end
end
end

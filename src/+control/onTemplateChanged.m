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
%
% 说明
%   - 切模板前会先暂停连续播放，避免定时器与重置并发
%   - 本函数只做“编排”，具体参数/渲染细节委托给各层模块

tplId = control.parseTemplateId(varargin{:});
logger.logEvent(app, '信息', '模板切换请求', struct('requested_id', tplId));

% 切模板前先暂停播放，避免切换过程中定时器并发推进
if ismethod(app, 'isPlaybackRunning') && ismethod(app, 'pausePlayback')
    if app.isPlaybackRunning()
        app.pausePlayback();
    end
elseif ismethod(app, 'pausePlayback')
    app.pausePlayback();
end

% 1) 读取模板定义
tpl = templates.getById(tplId);

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

% 3) 构建并校验默认参数
schema = params.schema_get(tpl.schemaKey);
p0 = params.defaults(schema);
p = params.validate(p0, schema);

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
end

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


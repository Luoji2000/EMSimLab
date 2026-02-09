function startup(app)
%STARTUP  应用启动接线入口（只做装配，不做业务计算）
%
% 输入
%   app : MainApp 实例
%
% 启动链路
%   1) 读取当前模板并同步 schemaKey/engineKey
%   2) 根据 schema 生成默认参数并统一校验
%   3) 重置引擎状态
%   4) 回写参数面板并触发首帧渲染
%   5) 记录关键函数来源路径，便于排查路径抢占问题
%
% 设计原则
%   - boot 层只负责“接线”，不承载物理/渲染细节
%   - 任何功能函数都通过 package 入口调用，避免隐式依赖

arguments
    app
end

if ~isprop(app, 'CurrentTemplateId') || isempty(app.CurrentTemplateId)
    app.CurrentTemplateId = "M1";
end

tpl = templates.getById(app.CurrentTemplateId);

if isprop(app, 'CurrentSchemaKey')
    app.CurrentSchemaKey = tpl.schemaKey;
end
if isprop(app, 'CurrentEngineKey')
    app.CurrentEngineKey = tpl.engineKey;
end

schema = params.schema_get(tpl.schemaKey);
p0 = params.defaults(schema);
p = params.validate(p0, schema);
p.modelType = string(tpl.engineKey);
p.templateId = string(tpl.id);
p = templates.applyTemplatePreset(tpl.id, p);
p = params.validate(p, schema);

if isprop(app, 'Params')
    app.Params = p;
end
if isprop(app, 'State')
    app.State = engine.reset(struct(), p);
end

if hasFunction('ui.applyPayload')
    ui.applyPayload(app, p);
end
if hasFunction('ui.setPanelsForTemplate')
    ui.setPanelsForTemplate(app, tpl);
end
if isprop(app, 'State') && hasFunction('ui.render')
    ui.render(app, app.State);
end

% 记录关键函数的实际来源路径，排查“同名旧函数抢占”问题
logger.logEvent(app, '调试', '函数来源检查', struct( ...
    'ui_render_path', string(which('ui.render')), ...
    'viz_scene_path', string(which('viz.renderScene')), ...
    'engine_step_path', string(which('engine.step')) ...
));
end

function tf = hasFunction(name)
%HASFUNCTION  判断函数是否可解析（兼容 package 函数）
%
% 输入
%   name : 函数全名，例如 'ui.render'
%
% 输出
%   tf   : logical，true 表示当前路径下可解析
tf = ~isempty(which(name));
end

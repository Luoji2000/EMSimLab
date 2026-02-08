function onTemplateChanged(app, varargin)
%ONTEMPLATECHANGED  处理模板切换（来自树节点或事件负载）

tplId = control.parseTemplateId(varargin{:});
tpl = templates.getById(tplId);

if isprop(app, 'CurrentTemplateId')
    app.CurrentTemplateId = tpl.id;
end
if isprop(app, 'CurrentSchemaKey')
    app.CurrentSchemaKey = tpl.schemaKey;
end
if isprop(app, 'CurrentEngineKey')
    app.CurrentEngineKey = tpl.engineKey;
end

schema = params.schema_get(tpl.schemaKey);
p0 = params.defaults(schema);
p = params.validate(p0, schema);

if isprop(app, 'Params')
    app.Params = p;
end

if isprop(app, 'SpeedSlider') && isgraphics(app.SpeedSlider) && isfield(p, 'speedScale')
    app.SpeedSlider.Value = double(p.speedScale);
end
if isprop(app, 'SpeedValueField') && isgraphics(app.SpeedValueField) && isfield(p, 'speedScale')
    app.SpeedValueField.Value = double(p.speedScale);
end
if isprop(app, 'SpeedValueLabel') && isgraphics(app.SpeedValueLabel) && isfield(p, 'speedScale')
    app.SpeedValueLabel.Text = sprintf('%.2fx', double(p.speedScale));
end

if isprop(app, 'State')
    app.State = engine.reset(app.State, p);
end

ui.setPanelsForTemplate(app, tpl);
ui.applyPayload(app, p);
if isprop(app, 'State')
    ui.render(app, app.State);
end
end


function onTemplateChanged(app, varargin)
%ONTEMPLATECHANGED Handle template switch from tree/event payload.

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
if isprop(app, 'State')
    app.State = engine.reset(app.State, p);
end

ui.setPanelsForTemplate(app, tpl);
ui.applyPayload(app, p);
if isprop(app, 'State')
    ui.render(app, app.State);
end
end

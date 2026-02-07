function startup(app)
%STARTUP Safe bootstrap for skeleton app.
% Keeps this layer as wiring only:
% - template/default param initialization
% - initial engine state creation
% - initial UI write-back

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

if isprop(app, 'Params')
    app.Params = p;
end
if isprop(app, 'State')
    app.State = engine.reset(struct(), p);
end

if exist('ui.applyPayload', 'file') == 2
    ui.applyPayload(app, p);
end
if exist('ui.setPanelsForTemplate', 'file') == 2
    ui.setPanelsForTemplate(app, tpl);
end
if isprop(app, 'State') && exist('ui.render', 'file') == 2
    ui.render(app, app.State);
end
end

function onParamsChanged(app, varargin)
%ONPARAMSCHANGED Handle parameter updates from UI controls.

schema = params.schema_get(app.CurrentSchemaKey);

p = ui.buildPayload(app);
p = params.validate(p, schema);

app.Params = p;
ui.applyPayload(app, p);

% Current skeleton chooses reset-on-change for deterministic behavior.
app.State = engine.reset(app.State, app.Params);
ui.render(app, app.State);
end

function onParamsChanged(app, varargin)
%ONPARAMSCHANGED  处理 UI 控件触发的参数更新

schema = params.schema_get(app.CurrentSchemaKey);

p = ui.buildPayload(app);

% 顶部速度控件属于全局参数，不在 M1 参数组件内，需显式并入 payload
if isprop(app, 'SpeedSlider') && isgraphics(app.SpeedSlider)
    p.speedScale = double(app.SpeedSlider.Value);
elseif isprop(app, 'SpeedValueField') && isgraphics(app.SpeedValueField)
    p.speedScale = double(app.SpeedValueField.Value);
end

p = params.validate(p, schema);

app.Params = p;
ui.applyPayload(app, p);

% 当前骨架采用“改参即重置”策略，保证行为确定性，便于调试。
app.State = engine.reset(app.State, app.Params);
ui.render(app, app.State);
end

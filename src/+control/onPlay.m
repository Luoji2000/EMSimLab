function onPlay(app, varargin)
%ONPLAY Run one simulation step (placeholder behavior).

% Keep varargin for callback compatibility.
dt = 0.05;
app.State = engine.step(app.State, app.Params, dt);
ui.render(app, app.State);
end

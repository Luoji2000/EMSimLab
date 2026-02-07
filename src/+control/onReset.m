function onReset(app, varargin)
%ONRESET Reset state and refresh UI.

% Keep varargin for callback compatibility.
app.State = engine.reset(app.State, app.Params);
ui.render(app, app.State);
end

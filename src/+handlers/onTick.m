function onTick(app)
%ONTICK Placeholder tick handler.
if nargin < 1
    return;
end
if isprop(app, 'State') && isprop(app, 'Params')
    app.State = engine.step(app.State, app.Params, 1/60);
end
end

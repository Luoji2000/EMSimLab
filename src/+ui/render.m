function render(app, state)
%RENDER Render scene and plots.

arguments
    app
    state (1,1) struct
end

if exist('viz.renderScene', 'file') == 2
    viz.renderScene(app, state);
end
if exist('viz.renderPlots', 'file') == 2
    viz.renderPlots(app, state);
end
end

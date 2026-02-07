function renderScene(app, state)
%RENDERSCENE Placeholder scene renderer.

if isprop(app, 'SceneAxes') && isgraphics(app.SceneAxes)
    t = 0;
    if isfield(state, 't')
        t = state.t;
    end
    title(app.SceneAxes, sprintf('场景渲染（t = %.2f s）', t));
end
end

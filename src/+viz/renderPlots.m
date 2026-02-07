function renderPlots(app, state)
%RENDERPLOTS Placeholder plot renderer.

if isprop(app, 'PlotsAxes') && isgraphics(app.PlotsAxes)
    n = 0;
    if isfield(state, 'traj')
        n = size(state.traj, 1);
    end
    title(app.PlotsAxes, sprintf('曲线渲染（采样点 = %d）', n));
end
end

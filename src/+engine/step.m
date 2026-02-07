function state = step(state, params, dt)
%STEP Advance one simulation step.

arguments
    state (1,1) struct
    params (1,1) struct
    dt (1,1) double {mustBePositive}
end

if isfield(params, 'speedScale')
    dt = dt * max(0.01, double(params.speedScale));
end

state.t = state.t + dt;
state.x = state.x + state.vx * dt;
state.y = state.y + state.vy * dt;
state.traj(end+1, :) = [state.x, state.y];
end

function ok = smoke_m1_unbounded_rotation()
%SMOKE_M1_UNBOUNDED_ROTATION  M1 无界旋转矩阵步进烟雾测试
%
% 验证目标
%   1) B ~= 0 时速度模长近似守恒
%   2) B = 0 时退化为匀速直线

ok = false;

params = struct( ...
    'x0', 0.0, ...
    'y0', 0.0, ...
    'vx0', 1.2, ...
    'vy0', 0.3, ...
    'q', 1.0, ...
    'm', 2.0, ...
    'B', 1.5, ...
    'Bdir', "out", ...
    'speedScale', 1.0 ...
);

state = engine.reset(struct(), params);
v0 = hypot(state.vx, state.vy);
for k = 1:200
    state = engine.step(state, params, 0.01);
end
v1 = hypot(state.vx, state.vy);
assert(abs(v1 - v0) < 1e-9, '旋转矩阵步进应保持速度模长。');

params.B = 0.0;
state = engine.reset(struct(), params);
state2 = engine.step(state, params, 0.25);
assert(abs(state2.x - (state.x + state.vx * 0.25)) < 1e-12, 'B=0 时 x 应线性推进。');
assert(abs(state2.y - (state.y + state.vy * 0.25)) < 1e-12, 'B=0 时 y 应线性推进。');

ok = true;
end

function ok = smoke_m1_bounded_chain()
%SMOKE_M1_BOUNDED_CHAIN  M1 有界磁场链条烟雾测试
%
% 验证目标
%   1) 粒子初始在磁场外时，先按匀速直线推进
%   2) 轨迹可出现“外 -> 内 -> 外”的链条
%   3) 离开磁场后（短窗口内）速度保持常量

ok = false;

params = struct( ...
    'x0', -1.20, ...
    'y0', 0.00, ...
    'vx0', 2.00, ...
    'vy0', 0.00, ...
    'q', 1.0, ...
    'm', 1.0, ...
    'B', 1.0, ...
    'Bdir', "out", ...
    'speedScale', 1.0, ...
    'bounded', true, ...
    'xMin', -0.5, ...
    'xMax', 0.5, ...
    'yMin', -0.5, ...
    'yMax', 0.5 ...
);

state = engine.reset(struct(), params);
assert(~insideRect(state, params), '初始点应位于磁场外。');

% 1) 外部直线验证：短步内不应入场，且位置线性
state1 = engine.step(state, params, 0.05);
assert(~insideRect(state1, params), '短步后仍应在场外。');
assert(abs(state1.x - (state.x + state.vx * 0.05)) < 1e-10, '场外 x 应线性推进。');
assert(abs(state1.y - (state.y + state.vy * 0.05)) < 1e-10, '场外 y 应线性推进。');

% 2) 链条验证：外->内->外
stateRun = state;
insideFlags = false(1, 400);
vHistory = zeros(2, 400);
for k = 1:400
    stateRun = engine.step(stateRun, params, 0.01);
    insideFlags(k) = insideRect(stateRun, params);
    vHistory(:, k) = [stateRun.vx; stateRun.vy];
end

firstIn = find(insideFlags, 1, 'first');
assert(~isempty(firstIn), '轨迹应进入有界磁场区域。');
firstOutAfterIn = find(~insideFlags(firstIn+1:end), 1, 'first');
assert(~isempty(firstOutAfterIn), '进入后应再次离开有界磁场区域。');
firstOutAfterIn = firstOutAfterIn + firstIn;

% 3) 离开后短窗口速度常量（若期间未再次入场）
windowEnd = min(firstOutAfterIn + 5, numel(insideFlags));
outWindow = firstOutAfterIn:windowEnd;
if all(~insideFlags(outWindow))
    vRef = vHistory(:, firstOutAfterIn);
    dv = vecnorm(vHistory(:, outWindow) - vRef, 2, 1);
    assert(all(dv < 1e-8), '离场后短窗口内速度应近似常量。');
end

ok = true;
end

function tf = insideRect(state, p)
x = double(state.x);
y = double(state.y);
tf = (x >= double(p.xMin)) && (x <= double(p.xMax)) && ...
     (y >= double(p.yMin)) && (y <= double(p.yMax));
end

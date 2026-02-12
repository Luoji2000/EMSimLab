function ok = smoke_r8_reset_step_semantics()
%SMOKE_R8_RESET_STEP_SEMANTICS  R8 reset/step 语义烟雾测试
%
% 测试目标
%   1) reset 后主状态坐标采用中心坐标语义（xCenter, yCenter）
%   2) 匀速模式（driveEnabled=false）下速度保持常量，位置按 v*dt 前进
%   3) step 输出与 frameStripOutputs 真源一致
%   4) 阻尼模式（driveEnabled=true）下速度不增，且不允许回退

ok = false;
tol = 1e-10;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

schema = params.schema_get("rail");
p = struct( ...
    'templateId', "R8", ...
    'modelType', "rail", ...
    'xCenter', 0.2, ...
    'yCenter', 0.0, ...
    'v0', 1.2, ...
    'm', 1.0, ...
    'B', 1.5, ...
    'Bdir', "out", ...
    'R', 2.0, ...
    'w', 2.0, ...
    'h', 1.0, ...
    'xMin', 0.0, ...
    'xMax', 4.0, ...
    'bounded', true, ...
    'loopClosed', true, ...
    'driveEnabled', false, ...
    'Fdrive', 0.0 ...
);
p = params.validate(p, schema);

% 1) reset 语义
s0 = engine.reset(struct(), p);
assert(abs(double(s0.x) - double(p.xCenter)) < tol, 'reset 后 state.x 应等于 xCenter。');
assert(abs(double(s0.y) - double(p.yCenter)) < tol, 'reset 后 state.y 应等于 yCenter。');
assert(abs(double(s0.xCenter) - double(s0.x)) < tol, 'reset 后 xCenter 与 x 应一致。');
assert(abs(double(s0.yCenter) - double(s0.y)) < tol, 'reset 后 yCenter 与 y 应一致。');
assert(isnumeric(s0.traj) && size(s0.traj, 1) == 1 && size(s0.traj, 2) == 2, 'reset 后 traj 初值应为 1x2。');
assert(double(s0.stepCount) == 0, 'reset 后 stepCount 应为 0。');
assert(abs(double(s0.qHeat)) < tol, 'reset 后 qHeat 应为 0。');

% 2) 匀速模式 step：速度常量，位置线性推进
dt = 0.1;
s1 = engine.step(s0, p, dt);
assert(abs(double(s1.vx) - double(s0.vx)) < tol, '匀速模式下 vx 应保持不变。');
assert(abs(double(s1.x) - (double(s0.x) + double(s0.vx) * dt)) < tol, '匀速模式下 x 应按 v*dt 推进。');
assert(double(s1.x) >= double(s0.x) - tol, 'R8 约束下 x 不应回退。');
assert(abs(double(s1.xCenter) - double(s1.x)) < tol, 'step 后 xCenter 与 x 应一致。');
assert(size(s1.traj, 1) == 2, 'step 一次后 traj 应新增一个点。');
assert(double(s1.stepCount) == 1, 'step 一次后 stepCount 应为 1。');

% 3) 与公式真源口径一致
out1 = physics.frameStripOutputs(double(s1.x), double(s1.vx), p);
assert(abs(double(s1.epsilon) - double(out1.epsilon)) < tol, 'step 输出 epsilon 应与真源一致。');
assert(abs(double(s1.current) - double(out1.current)) < tol, 'step 输出 current 应与真源一致。');
assert(abs(double(s1.fMag) - double(out1.fMag)) < tol, 'step 输出 fMag 应与真源一致。');
assert(abs(double(s1.xFront) - double(out1.xFront)) < tol, 'step 输出 xFront 应与真源一致。');
assert(abs(double(s1.xBack) - double(out1.xBack)) < tol, 'step 输出 xBack 应与真源一致。');

% 4) 阻尼模式：无外驱时速度不应增加，且仍不回退
pD = p;
pD.driveEnabled = true;
pD.Fdrive = 0.0;
sD0 = engine.reset(struct(), pD);
sD1 = engine.step(sD0, pD, dt);
assert(double(sD1.vx) <= double(sD0.vx) + tol, '阻尼模式无外驱时 vx 不应增加。');
assert(double(sD1.vx) >= -tol, 'R8 约束下 vx 不应为负。');
assert(double(sD1.x) >= double(sD0.x) - tol, 'R8 约束下 x 不应回退。');
assert(double(sD1.qHeat) >= double(sD0.qHeat) - tol, 'qHeat 应单调不减。');

ok = true;
disp('R8 reset/step 语义烟雾测试通过。');
end

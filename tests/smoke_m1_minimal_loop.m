function ok = smoke_m1_minimal_loop()
%SMOKE_M1_MINIMAL_LOOP  M1 最小闭环烟雾测试（手动触发版）
%
% 验证目标
%   1) MainApp 能初始化出 M1 默认参数与状态
%   2) 参数变化链路可执行：读取参数 -> 校验归一化 -> 回写 UI
%   3) Play/Reset 链路可执行：步进更新与重置刷新均可运行
%
% 运行方式（MATLAB 命令行）：
%   cd('F:/code/matlab/EMSimLab');
%   addpath('tests');
%   ok = smoke_m1_minimal_loop();

ok = false;

app = MainApp();
cleanupObj = onCleanup(@()delete(app)); %#ok<NASGU>

assert(isstruct(app.Params), 'app.Params 必须是 struct。');
assert(isfield(app.Params, 'B'), 'M1 参数应包含 B。');
assert(isfield(app.Params, 'v0'), 'M1 参数应包含 v0。');

if ~isempty(app.ParamComponent) && ismethod(app.ParamComponent, 'getPayload')
    payload = app.ParamComponent.getPayload();
    payload.B = payload.B + 0.2;
    app.ParamComponent.setPayload(payload);
end
control.onParamsChanged(app);
assert(app.Params.B >= 0, '参数校验后 B 应保持合法。');

t0 = app.State.t;
control.onPlay(app);
assert(app.State.t > t0, 'Play 后时间应推进。');

control.onReset(app);
assert(app.State.t == 0, 'Reset 后时间应回到 0。');

ok = true;
end


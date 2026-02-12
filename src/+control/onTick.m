function onTick(app, varargin)
%% 入口：连续播放单帧回调
%ONTICK  连续播放单帧回调（由定时器驱动）
%
% 输入
%   app      : MainApp 实例
%   varargin : 保留参数，用于兼容 TimerFcn 回调签名
%
% 行为
%   1) 检查 app 与关键字段可用性
%   2) 读取渲染帧步长，并拆分为多个物理子步推进
%   3) 触发 UI 渲染
%   4) 按节流规则输出播放日志
%
% 异常策略
%   - 任一异常都会记录日志
%   - 若 App 支持 pausePlayback，则自动停播防止异常刷屏

% 保留 varargin，当前不使用。
if ~isLiveApp(app)
    return;
end
if ~(isprop(app, 'State') && isprop(app, 'Params'))
    return;
end

try
    frameDt = resolveFrameDt(app);
    tickTic = tic;

    % 1) 物理推进（子步进）
    %    每个渲染帧内自动拆分成多个物理小步，减少轨迹“跳点感”。
    stepTic = tic;
    [app.State, subSteps, subDt] = advanceWithSubsteps(app.State, app.Params, frameDt);
    stepMs = toc(stepTic) * 1000.0;

    % 2) 输出区增量回写（只写输出字段，避免全量参数回写）
    outputTic = tic;
    app.Params = control.mergeRailOutputs(app.Params, app.State);
    ui.applyOutputs(app, extractOutputFields(app.Params));
    outputMs = toc(outputTic) * 1000.0;

    % 3) 刷新渲染
    renderTic = tic;
    ui.render(app, app.State);
    renderMs = toc(renderTic) * 1000.0;

    tickMs = toc(tickTic) * 1000.0;
    [app.State, perfSnapshot] = updatePerfStats(app.State, stepMs, outputMs, renderMs, tickMs, frameDt);

    % 4) 日志节流：每 10 帧记录一次推进信息
    if shouldLogTick(app.State)
        tNow = NaN;
        if isfield(app.State, 't')
            tNow = app.State.t;
        end
        payload = buildTickLogPayload(app, frameDt, subDt, subSteps, tNow);
        logger.logEvent(app, '调试', '连续播放推进', payload);
    end

    % 5) 性能采样日志：低频输出“谁最耗时”
    if shouldLogPerf(app.State)
        perfPayload = buildPerfLogPayload(frameDt, subDt, subSteps, perfSnapshot);
        logger.logEvent(app, '调试', '性能采样', perfPayload);
    end
catch err
    logger.logEvent(app, '错误', '连续播放失败', struct('reason', err.message));
    if ismethod(app, 'pausePlayback')
        app.pausePlayback();
    end
end

%% 输出区字段提取与性能统计
function out = extractOutputFields(paramsIn)
%EXTRACTOUTPUTFIELDS  从完整参数中提取输出区字段（用于增量 UI 刷新）
out = struct();
if ~isstruct(paramsIn)
    return;
end

keys = ["epsilonOut","currentOut","xOut","vOut","fMagOut","qHeatOut","pElecOut","qCollOut","qOverMOut"];
for i = 1:numel(keys)
    key = char(keys(i));
    if isfield(paramsIn, key)
        out.(key) = paramsIn.(key);
    end
end
end
end

function [stateOut, perf] = updatePerfStats(stateIn, stepMs, outputMs, renderMs, tickMs, frameDt)
%UPDATEPERFSTATS  更新运行时性能统计（EMA），并返回本帧快照
stateOut = stateIn;

alpha = 0.20;
if ~isstruct(stateOut)
    stateOut = struct();
end
if ~isfield(stateOut, 'perfEmaStepMs')
    stateOut.perfEmaStepMs = stepMs;
    stateOut.perfEmaOutputMs = outputMs;
    stateOut.perfEmaRenderMs = renderMs;
    stateOut.perfEmaTickMs = tickMs;
else
    stateOut.perfEmaStepMs = alpha * stepMs + (1 - alpha) * double(stateOut.perfEmaStepMs);
    stateOut.perfEmaOutputMs = alpha * outputMs + (1 - alpha) * double(stateOut.perfEmaOutputMs);
    stateOut.perfEmaRenderMs = alpha * renderMs + (1 - alpha) * double(stateOut.perfEmaRenderMs);
    stateOut.perfEmaTickMs = alpha * tickMs + (1 - alpha) * double(stateOut.perfEmaTickMs);
end

phaseMs = [stepMs, outputMs, renderMs];
phaseName = ["物理推进","输出回写","渲染"];
[mainCostMs, idx] = max(phaseMs);
mainCost = phaseName(idx);

budgetMs = frameDt * 1000.0;
headroomMs = budgetMs - tickMs;
fpsEst = 1000.0 / max(tickMs, 1e-6);

perf = struct( ...
    'step_ms', stepMs, ...
    'output_ms', outputMs, ...
    'render_ms', renderMs, ...
    'tick_ms', tickMs, ...
    'ema_step_ms', double(stateOut.perfEmaStepMs), ...
    'ema_output_ms', double(stateOut.perfEmaOutputMs), ...
    'ema_render_ms', double(stateOut.perfEmaRenderMs), ...
    'ema_tick_ms', double(stateOut.perfEmaTickMs), ...
    'frame_budget_ms', budgetMs, ...
    'headroom_ms', headroomMs, ...
    'fps_est', fpsEst, ...
    'main_cost', mainCost, ...
    'main_cost_ms', mainCostMs ...
);
end

%% 日志 payload 组装
function payload = buildTickLogPayload(app, frameDt, subDt, subSteps, tNow)
%BUILDTICKLOGPAYLOAD  生成单帧推进日志负载
payload = struct( ...
    'dt', frameDt, ...
    'sub_dt', subDt, ...
    'sub_steps', subSteps, ...
    't', tNow ...
);

if ~(isprop(app, 'State') && isstruct(app.State))
    return;
end

state = app.State;
modelType = string(pickField(state, 'modelType', ""));
if ~startsWith(lower(strtrim(modelType)), "rail")
    return;
end

payload.template_id = string(pickField(app, 'CurrentTemplateId', ""));
payload.mode = string(pickField(state, 'mode', ""));
payload.x = double(pickField(state, 'x', 0.0));
payload.vx = double(pickField(state, 'vx', 0.0));
payload.epsilon = double(pickField(state, 'epsilon', 0.0));
payload.current = double(pickField(state, 'current', 0.0));
payload.fmag = double(pickField(state, 'fMag', 0.0));
payload.q_heat = double(pickField(state, 'qHeat', 0.0));
payload.in_field = logicalField(state, 'inField', true);
end

function payload = buildPerfLogPayload(frameDt, subDt, subSteps, perf)
%BUILDPERFLOGPAYLOAD  生成性能采样日志负载
payload = struct( ...
    'dt', frameDt, ...
    'sub_dt', subDt, ...
    'sub_steps', subSteps, ...
    'step_ms', perf.step_ms, ...
    'output_ms', perf.output_ms, ...
    'render_ms', perf.render_ms, ...
    'tick_ms', perf.tick_ms, ...
    'ema_step_ms', perf.ema_step_ms, ...
    'ema_output_ms', perf.ema_output_ms, ...
    'ema_render_ms', perf.ema_render_ms, ...
    'ema_tick_ms', perf.ema_tick_ms, ...
    'frame_budget_ms', perf.frame_budget_ms, ...
    'headroom_ms', perf.headroom_ms, ...
    'fps_est', perf.fps_est, ...
    'main_cost', perf.main_cost, ...
    'main_cost_ms', perf.main_cost_ms ...
);
end

%% 子步推进与子步规划
function [stateOut, subSteps, subDt] = advanceWithSubsteps(stateIn, params, frameDt)
%ADVANCEWITHSUBSTEPS  单帧子步进推进
%
% 输入
%   stateIn : 当前状态
%   params  : 当前参数
%   frameDt : 单渲染帧时长（秒）
%
% 输出
%   stateOut : 子步进后的状态
%   subSteps : 子步数量
%   subDt    : 单个子步的基础步长（未乘 speedScale）
%
% 设计目标
%   1) 渲染帧率不变时，通过子步提高轨迹平滑度
%   2) 保持现有 engine.step 接口不变（由 engine 内部处理 speedScale）
%   3) 自动按“角度上限 + 时间上限”估算子步数量

stateOut = stateIn;
if frameDt <= 0
    subSteps = 1;
    subDt = frameDt;
    return;
end

[subSteps, subDt] = computeSubstepPlan(params, frameDt);
for k = 1:subSteps
    stateOut = engine.step(stateOut, params, subDt);
end
end

function [subSteps, subDt] = computeSubstepPlan(params, frameDt)
%COMPUTESUBSTEPPLAN  估算本帧需要的物理子步数量
%
% 规则
%   - 时间上限：单个物理子步不超过 maxSubDt（默认 1/240 s）
%   - 角度上限：粒子模型单个子步转角不超过 maxAngle（默认 0.12 rad）
%   - 总子步数限制：不超过 maxSubSteps（默认 64）

maxSubDt = 1/240;
maxAngle = 0.12;
maxSubSteps = 64;

speedScale = max(0.01, double(pickField(params, 'speedScale', 1.0)));
physFrameDt = frameDt * speedScale;

% 基于时间上限的子步数
nByTime = ceil(physFrameDt / maxSubDt);
nByTime = max(nByTime, 1);

% 基于角速度上限的子步数（仅粒子模型有意义）
modelType = lower(strtrim(string(pickField(params, 'modelType', "particle"))));
if startsWith(modelType, "rail")
    nByAngle = 1;
else
    omega = cyclotronOmega(params);
    nByAngle = ceil(abs(omega) * physFrameDt / maxAngle);
    nByAngle = max(nByAngle, 1);
end

subSteps = min(maxSubSteps, max(nByTime, nByAngle));
subDt = frameDt / subSteps;
end

%% 运行时环境与节流判定
function omega = cyclotronOmega(params)
%CYCLOTRONOMEGA  估算角速度 omega = q*Bz/m（用于子步规划）
q = double(pickField(params, 'q', 0.0));
m = max(double(pickField(params, 'm', 1.0)), 1e-12);
B = double(pickField(params, 'B', 0.0));
Bdir = lower(strtrim(string(pickField(params, 'Bdir', "out"))));
if Bdir == "in"
    Bz = -B;
else
    Bz = B;
end
omega = q * Bz / m;
end

function tf = isLiveApp(app)
%ISLIVEAPP  判断 app 是否为有效句柄对象
tf = false;
if isempty(app)
    return;
end
if ~(isa(app, 'handle'))
    return;
end
try
    tf = isvalid(app);
catch
    tf = false;
end
end

function stepDt = resolveFrameDt(app)
%RESOLVEFRAMEDT  解析当前渲染帧步长
%
% 规则
%   1) 优先使用 app.getPlaybackPeriod()
%   2) 回退到 app.PlaybackPeriod
%   3) 最终兜底为 1/30，并限制最小值 1e-4
stepDt = 1/30;
if ismethod(app, 'getPlaybackPeriod')
    stepDt = double(app.getPlaybackPeriod());
else
    try
        stepDt = double(app.PlaybackPeriod);
    catch
        stepDt = 1/30;
    end
end
stepDt = max(stepDt, 1e-4);
end

function tf = shouldLogTick(state)
%SHOULDLOGTICK  连续播放日志节流判定
%
% 规则
%   - 若有 stepCount：每 10 帧记录一次
%   - 无 stepCount：默认记录
if isstruct(state) && isfield(state, 'stepCount')
    tf = mod(double(state.stepCount), 10) == 0;
else
    tf = true;
end
end

function tf = shouldLogPerf(state)
%SHOULDLOGPERF  性能采样日志节流判定
%
% 规则
%   - 若有 stepCount：每 30 帧记录一次
%   - 无 stepCount：默认记录
if isstruct(state) && isfield(state, 'stepCount')
    tf = mod(double(state.stepCount), 30) == 0;
else
    tf = true;
end
end

%% 通用字段读取工具
function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
elseif isobject(s) && isprop(s, name)
    v = s.(name);
else
    v = fallback;
end
end

function v = logicalField(s, name, fallback)
%LOGICALFIELD  安全读取 logical 字段
raw = pickField(s, name, fallback);
if islogical(raw) && isscalar(raw)
    v = raw;
elseif isnumeric(raw) && isscalar(raw)
    v = raw ~= 0;
else
    v = logical(fallback);
end
end

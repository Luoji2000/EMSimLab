function onTick(app, varargin)
%ONTICK  连续播放单帧回调（由定时器驱动）
%
% 输入
%   app      : MainApp 实例
%   varargin : 保留参数，用于兼容 TimerFcn 回调签名
%
% 行为
%   1) 检查 app 与关键字段可用性
%   2) 读取单帧步长并推进引擎状态
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
    stepDt = resolveStepDt(app);

    % 1) 推进一步
    app.State = engine.step(app.State, app.Params, stepDt);
    app.Params = control.mergeRailOutputs(app.Params, app.State);
    ui.applyPayload(app, app.Params);

    % 2) 刷新渲染
    ui.render(app, app.State);

    % 3) 日志节流：每 10 帧记录一次，减少日志压力
    if shouldLogTick(app.State)
        tNow = NaN;
        if isfield(app.State, 't')
            tNow = app.State.t;
        end
        payload = buildTickLogPayload(app, stepDt, tNow);
        logger.logEvent(app, '调试', '连续播放推进', payload);
    end
catch err
    logger.logEvent(app, '错误', '连续播放失败', struct('reason', err.message));
    if ismethod(app, 'pausePlayback')
        app.pausePlayback();
    end
end
end

function payload = buildTickLogPayload(app, stepDt, tNow)
%BUILDTICKLOGPAYLOAD  生成单帧推进日志负载
payload = struct('dt', stepDt, 't', tNow);

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

function stepDt = resolveStepDt(app)
%RESOLVESTEPDT  解析当前单帧步长
%
% 规则
%   1) 优先使用 app.getPlaybackPeriod()
%   2) 回退到 app.PlaybackPeriod
%   3) 最终兜底为 0.05，并限制最小值 1e-4
stepDt = 0.05;
if ismethod(app, 'getPlaybackPeriod')
    stepDt = double(app.getPlaybackPeriod());
else
    try
        stepDt = double(app.PlaybackPeriod);
    catch
        stepDt = 0.05;
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

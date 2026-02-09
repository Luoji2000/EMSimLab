function onPlay(app, varargin)
%ONPLAY  运行按钮回调：启动连续播放
%
% 输入
%   app      : MainApp 实例
%   varargin : 保留参数，用于兼容 MATLAB 回调签名
%
% 行为
%   1) 优先调用 app.startPlayback() 进入定时播放
%   2) 若 App 不支持该接口，则回退为“单步推进”模式
%
% 兼容说明
%   - 保留回退路径是为了兼容旧版 MainApp（尚未接入定时器）
%   - 新版主路径下，实际推进由 control.onTick 执行

% 保留 varargin，当前不使用。
if ismethod(app, 'startPlayback')
    app.startPlayback();
    return;
end

% 兼容回退：执行一次单步推进
stepOnceFallback(app);
end

function stepOnceFallback(app)
%STEPONCEFALLBACK  旧版兼容的单步推进逻辑
%
% 说明
%   - 与历史行为保持一致：默认单步时间间隔为 0.05s
%   - 仅在未接入 startPlayback 接口时使用

stepDt = 0.05;

% 1) 推进一步
app.State = engine.step(app.State, app.Params, stepDt);
app.Params = control.mergeRailOutputs(app.Params, app.State);
ui.applyPayload(app, app.Params);

% 2) 刷新渲染
ui.render(app, app.State);

% 3) 输出日志
tNow = NaN;
if isfield(app.State, 't')
    tNow = app.State.t;
end
logger.logEvent(app, '调试', '单步推进（回退模式）', struct('dt', stepDt, 't', tNow));
end

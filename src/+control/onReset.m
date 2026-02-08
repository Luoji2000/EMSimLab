function onReset(app, varargin)
%ONRESET  重置仿真状态并刷新界面
%
% 输入
%   app      : MainApp 实例
%   varargin : 保留参数，用于兼容 MATLAB 回调签名
%
% 行为
%   1) 先暂停连续播放（若处于运行态）
%   2) 根据当前参数重建初始状态
%   3) 刷新场景与曲线
%   4) 输出重置日志

% 保留 varargin，当前不使用。
if ismethod(app, 'isPlaybackRunning') && ismethod(app, 'pausePlayback')
    if app.isPlaybackRunning()
        app.pausePlayback();
    end
elseif ismethod(app, 'pausePlayback')
    app.pausePlayback();
end

% 1) 根据当前参数重建状态
app.State = engine.reset(app.State, app.Params);

% 2) 刷新界面
ui.render(app, app.State);

% 3) 写日志
logger.logEvent(app, '信息', '仿真重置', struct('template', app.CurrentTemplateId));
end

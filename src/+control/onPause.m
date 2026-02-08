function onPause(app, varargin)
%ONPAUSE  暂停按钮回调：停止连续播放
%
% 输入
%   app      : MainApp 实例
%   varargin : 保留参数，用于兼容 MATLAB 回调签名
%
% 行为
%   1) 若 App 暴露 pausePlayback 接口，优先调用
%   2) 旧版兼容路径仅写日志，不影响其他功能

% 保留 varargin，当前不使用。
if ismethod(app, 'pausePlayback')
    app.pausePlayback();
    return;
end

logger.logEvent(app, '信息', '暂停请求（旧版兼容）', struct());
end

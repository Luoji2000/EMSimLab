function render(app, state)
%RENDER  渲染总入口（场景 + 曲线，统一容错）
%
% 输入
%   app   : MainApp 实例
%   state : 当前仿真状态结构
%
% 行为
%   1) 若存在 viz.renderScene，则尝试渲染场景
%   2) 若存在 viz.renderPlots，则尝试渲染曲线
%   3) 任一子渲染失败仅写日志，不中断主流程
%
% 设计说明
%   - UI 层只负责调度渲染，不直接写绘图细节
%   - 通过 hasFunction 兼容“模块逐步迁移”阶段

arguments
    app
    state (1,1) struct
end

if hasFunction('viz.renderScene')
    try
        viz.renderScene(app, state);
    catch err
        logger.logEvent(app, '错误', '场景渲染失败', struct('reason', err.message));
    end
end

if hasFunction('viz.renderPlots')
    try
        viz.renderPlots(app, state);
    catch err
        logger.logEvent(app, '错误', '曲线渲染失败', struct('reason', err.message));
    end
end
end

function tf = hasFunction(name)
%HASFUNCTION  判断函数是否可解析（兼容 package 函数）
%
% 输入
%   name : 函数全名，例如 'viz.renderScene'
%
% 输出
%   tf   : logical，true 表示路径可解析
tf = ~isempty(which(name));
end

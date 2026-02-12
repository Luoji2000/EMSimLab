function render(app, state)
%% 入口：渲染总调度
%RENDER  渲染总入口（场景 + 曲线，统一容错）
%
% 输入
%   app   : MainApp 实例
%   state : 当前仿真状态结构
%
% 行为
%   1) 按当前 CenterTabs 焦点选择渲染目标
%   2) 场景页：仅渲染场景
%   3) 曲线页：仅渲染曲线
%   3) 任一子渲染失败仅写日志，不中断主流程
%
% 设计说明
%   - UI 层只负责调度渲染，不直接写绘图细节
%   - 通过 hasFunction 兼容“模块逐步迁移”阶段

arguments
    app
    state (1,1) struct
end

[shouldRenderSceneNow, shouldRenderPlotsNow] = resolveRenderTargets(app);

if shouldRenderSceneNow && hasFunction('viz.renderScene')
    try
        viz.renderScene(app, state);
    catch err
        logger.logEvent(app, '错误', '场景渲染失败', struct('reason', err.message));
    end
end

if shouldRenderPlotsNow && hasFunction('viz.renderPlots')
    try
        viz.renderPlots(app, state);
    catch err
        logger.logEvent(app, '错误', '曲线渲染失败', struct('reason', err.message));
    end
end
end

%% 渲染目标判定
function [sceneOn, plotsOn] = resolveRenderTargets(app)
%RESOLVERENDERTARGETS  根据当前中心 Tab 决定本帧渲染目标
%
% 返回
%   sceneOn : 是否渲染场景
%   plotsOn : 是否渲染曲线
%
% 规则
%   - 选中“场景”页：sceneOn=true,  plotsOn=false
%   - 选中“曲线”页：sceneOn=false, plotsOn=true
%   - 无法判定（兼容旧 UI）：两者都为 true
sceneOn = true;
plotsOn = true;

if ~(isprop(app, 'CenterTabs') && isgraphics(app.CenterTabs))
    return;
end
if ~(isprop(app, 'SceneTab') && isgraphics(app.SceneTab))
    return;
end
if ~(isprop(app, 'PlotsTab') && isgraphics(app.PlotsTab))
    return;
end

try
    selected = app.CenterTabs.SelectedTab;
    if isequal(selected, app.SceneTab)
        sceneOn = true;
        plotsOn = false;
    elseif isequal(selected, app.PlotsTab)
        sceneOn = false;
        plotsOn = true;
    end
catch
    % 读取失败时保留双渲染兜底
end
end

%% 通用函数可用性检查
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

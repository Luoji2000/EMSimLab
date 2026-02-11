function applyOutputs(app, outputs)
%APPLYOUTPUTS  仅更新参数组件中的“输出区字段”，避免全量回写带来的卡顿
%
% 输入
%   app     : MainApp 实例
%   outputs : 输出字段结构（如 epsilonOut/currentOut/xOut/vOut/...）
%
% 说明
%   - 该函数不会改动输入控件，只尝试调用参数组件的 setOutputs 方法
%   - 若参数组件不支持 setOutputs，则静默忽略（保持主链路稳定）

arguments
    app
    outputs (1,1) struct
end

if isempty(app) || isempty(fieldnames(outputs))
    return;
end

% 保留一份兜底缓存，便于调试时从 ParamTab.UserData 查看最新输出
if isprop(app, 'ParamTab') && isgraphics(app.ParamTab)
    data = struct();
    if isstruct(app.ParamTab.UserData)
        data = app.ParamTab.UserData;
    end
    names = fieldnames(outputs);
    for i = 1:numel(names)
        key = names{i};
        data.(key) = outputs.(key);
    end
    app.ParamTab.UserData = data;
end

comp = findOutputComponent(app);
if isempty(comp)
    return;
end

try
    comp.setOutputs(outputs);
catch
    % 输出区写回失败时不抛出，避免影响播放主循环
end
end

function comp = findOutputComponent(app)
%FINDOUTPUTCOMPONENT  查找支持 setOutputs 的参数组件
comp = [];

if isprop(app, 'ParamComponent')
    candidate = app.ParamComponent;
    if isOutputComponent(candidate)
        comp = candidate;
        return;
    end
end

% 兜底：在 app 属性中扫描（兼容旧结构）
try
    propNames = string(properties(app));
catch
    propNames = strings(0, 1);
end
for i = 1:numel(propNames)
    name = propNames(i);
    try
        candidate = app.(name);
    catch
        continue;
    end
    if isOutputComponent(candidate)
        comp = candidate;
        return;
    end
end
end

function tf = isOutputComponent(candidate)
%ISOUTPUTCOMPONENT  判断对象是否具备 setOutputs 最小接口
tf = false;
if isempty(candidate) || ~isa(candidate, 'handle')
    return;
end
try
    tf = isvalid(candidate) && ismethod(candidate, 'setOutputs');
catch
    tf = false;
end
end

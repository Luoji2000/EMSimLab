function p = buildPayload(app)
%BUILDPAYLOAD  从 UI 读取当前参数，生成 params 结构体
%
% 说明
%   - 这里不做校验，只“采集”
%   - 优先读取支持 getPayload/setPayload 的自定义组件
%   - 若未找到组件，则回退到 app.Params / ParamTab.UserData
%
% 读取优先级（由高到低）
%   1) 自定义组件 getPayload()
%   2) ParamTab.UserData
%   3) app.Params

arguments
    app
end

p = struct();

comp = findPayloadComponent(app);
if ~isempty(comp)
    try
        % 自定义组件负责把分散控件聚合成统一 payload
        p = comp.getPayload();
        if isstruct(p)
            return;
        end
    catch
        % 组件读取失败时继续执行回退路径，避免中断主链路
    end
end

if isprop(app, 'ParamTab') && isgraphics(app.ParamTab) && isstruct(app.ParamTab.UserData)
    p = app.ParamTab.UserData;
    return;
end

if isprop(app, 'Params') && isstruct(app.Params)
    p = app.Params;
end

end

function comp = findPayloadComponent(app)
%FINDPAYLOADCOMPONENT  从 app 属性中查找支持 getPayload/setPayload 的组件
% 输入
%   app : App 实例
% 输出
%   comp: 命中的组件句柄；未找到则返回 []
comp = [];

if isempty(app)
    return;
end

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
    if isPayloadComponent(candidate)
        comp = candidate;
        return;
    end
end
end

function tf = isPayloadComponent(candidate)
%ISPAYLOADCOMPONENT  判断对象是否满足参数组件最小接口
% 判定条件：
%   - handle 且 isvalid
%   - 同时具备 getPayload / setPayload 方法
tf = false;
if isempty(candidate) || ~isa(candidate, 'handle')
    return;
end
try
    tf = isvalid(candidate) && ismethod(candidate, 'getPayload') && ismethod(candidate, 'setPayload');
catch
    tf = false;
end
end

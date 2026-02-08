function applyPayload(app, p)
%APPLYPAYLOAD  将校验后的参数写回 UI
%
% 写回策略
%   1) 永远先写 ParamTab.UserData（作为通用兜底缓存）
%   2) 若存在自定义 payload 组件，则调用 setPayload(p) 同步控件

arguments
    app
    p (1,1) struct
end

if isprop(app, 'ParamTab') && isgraphics(app.ParamTab)
    app.ParamTab.UserData = p;
end

comp = findPayloadComponent(app);
if ~isempty(comp)
    try
        % 组件内部负责把 payload 分发到各个 UI 控件
        comp.setPayload(p);
    catch
        % 组件写回失败时不抛出，避免影响控制主链路
    end
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

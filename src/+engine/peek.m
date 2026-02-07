function state = peek(state)
%PEEK  返回当前状态（为了接口统一保留）
%
% 在某些实现中，你可能会把 state 存在 app 或 engine 内部；
% 这里提供一个统一入口，方便 control 层调用。

arguments
    state (1,1) struct
end

% 当前为直通
end

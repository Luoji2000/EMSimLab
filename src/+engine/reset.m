function state = reset(state, params)
%RESET  重置仿真状态（支持 M1 有界/无界初始模式）
%
% 输入
%   state  (1,1) struct : 旧状态（可为空）
%   params (1,1) struct : 合法参数（来自 params.validate）
%
% 输出
%   state (1,1) struct : 新状态（包含 t/x/y/vx/vy/traj/mode/inField）
%
% 说明
%   - reset 只负责“设置初值”，不做单步推进
%   - 若 bounded=true，会根据初始位置判断是否在磁场区域内

arguments
    state (1,1) struct
    params (1,1) struct
end

state.t = 0.0;
state.x = pickField(params, 'x0', 0.0);
state.y = pickField(params, 'y0', 0.0);

% 优先使用 validate 已派生的速度分量；若缺失则由 v0/thetaDeg 反推
if isfield(params, 'vx0') && isfield(params, 'vy0')
    state.vx = double(params.vx0);
    state.vy = double(params.vy0);
else
    v0 = pickField(params, 'v0', 0.0);
    thetaDeg = pickField(params, 'thetaDeg', 0.0);
    thetaRad = deg2rad(double(thetaDeg));
    state.vx = double(v0) * cos(thetaRad);
    state.vy = double(v0) * sin(thetaRad);
end

% 轨迹缓存（首点）
state.traj = [state.x, state.y];
state.stepCount = 0;

bounded = logicalField(params, 'bounded', false);
if bounded
    box = readBoundaryBox(params);
    inField = isInsideRect([state.x; state.y], box);
    state.inField = inField;
    if inField
        state.mode = "bounded_inside";
    else
        state.mode = "bounded_outside";
    end
else
    state.inField = true;
    state.mode = "unbounded";
end

end

function box = readBoundaryBox(params)
%READBOUNDARYBOX  读取并规范化矩形边界
xMin = double(pickField(params, 'xMin', -1.0));
xMax = double(pickField(params, 'xMax', 1.0));
yMin = double(pickField(params, 'yMin', -1.0));
yMax = double(pickField(params, 'yMax', 1.0));

if xMin > xMax
    t = xMin;
    xMin = xMax;
    xMax = t;
end
if yMin > yMax
    t = yMin;
    yMin = yMax;
    yMax = t;
end

box = struct('xMin', xMin, 'xMax', xMax, 'yMin', yMin, 'yMax', yMax);
end

function tf = isInsideRect(r, box)
%ISINSIDERECT  判断点是否位于边界盒内部（含边界）
x = double(r(1));
y = double(r(2));
tol = 1e-12;

tf = (x >= box.xMin - tol) && (x <= box.xMax + tol) && ...
     (y >= box.yMin - tol) && (y <= box.yMax + tol);
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

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
% 输入
%   s        struct : 目标结构体
%   name     char   : 字段名
%   fallback any    : 缺失时的返回值
% 输出
%   v        any    : 读取到的值或 fallback
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

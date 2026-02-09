function box = readBoundsFromParams(params)
%READBOUNDSFROMPARAMS  从参数结构读取并规范化矩形边界
%
% 输入
%   params (1,1) struct : 参数结构（应包含 xMin/xMax/yMin/yMax）
%
% 输出
%   box (1,1) struct : 规范化边界
%     - xMin, xMax, yMin, yMax（保证 Min <= Max）
%
% 说明
%   - 缺字段时使用默认值 [-1,1]。
%   - 该函数用于 M 系列与后续 R 系列共用边界语义，避免重复实现。

arguments
    params (1,1) struct
end

box = struct();
box.xMin = double(pickField(params, 'xMin', -1.0));
box.xMax = double(pickField(params, 'xMax', 1.0));
box.yMin = double(pickField(params, 'yMin', -1.0));
box.yMax = double(pickField(params, 'yMax', 1.0));

if box.xMin > box.xMax
    t = box.xMin;
    box.xMin = box.xMax;
    box.xMax = t;
end
if box.yMin > box.yMax
    t = box.yMin;
    box.yMin = box.yMax;
    box.yMax = t;
end
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取字段（缺失则返回 fallback）
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

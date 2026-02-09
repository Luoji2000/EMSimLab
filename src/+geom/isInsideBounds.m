function tf = isInsideBounds(point, box, tol)
%ISINSIDEBOUNDS  判断二维点是否位于矩形边界内（含边界）
%
% 输入
%   point : 点坐标，可为 [x;y] 或 [x,y]
%   box   : 边界结构体（xMin/xMax/yMin/yMax）
%   tol   : 数值容差（可选，默认 1e-12）
%
% 输出
%   tf (1,1) logical : true 表示点在边界内

arguments
    point {mustBeNumeric}
    box (1,1) struct
    tol (1,1) double {mustBeNonnegative} = 1e-12
end

p = double(point(:));
if numel(p) < 2
    tf = false;
    return;
end

x = p(1);
y = p(2);

tf = (x >= box.xMin - tol) && (x <= box.xMax + tol) && ...
     (y >= box.yMin - tol) && (y <= box.yMax + tol);
end

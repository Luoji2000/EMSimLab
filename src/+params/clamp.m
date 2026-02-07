function v = clamp(v, vmin, vmax)
%CLAMP  把数值 v 限制到 [vmin, vmax] 区间
%
% 输入
%   v    : 数值
%   vmin : 下限（可为空/NaN 表示不限制）
%   vmax : 上限（可为空/NaN 表示不限制）
%
% 输出
%   v : 裁剪后的数值

arguments
    v (1,1) double
    vmin (1,1) double = NaN
    vmax (1,1) double = NaN
end

if ~isnan(vmin)
    v = max(v, vmin);
end
if ~isnan(vmax)
    v = min(v, vmax);
end

end

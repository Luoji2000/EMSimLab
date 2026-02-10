function Bz = signedBFromParams(params)
%SIGNEDBFROMPARAMS  从参数结构读取带符号磁感应强度 Bz
%
% 输入
%   params (1,1) struct : 参数结构，至少可包含：
%       - B    : 磁感应强度大小（标量）
%       - Bdir : 方向枚举，"out" 表示出屏，"in" 表示入屏
%
% 输出
%   Bz (1,1) double : 带符号磁感应强度
%
% 约定
%   - 出屏（out）取正：Bz = +B
%   - 入屏（in）取负：Bz = -B
%   - 若字段缺失，按 B=0、Bdir="out" 兜底

arguments
    params (1,1) struct
end

B = double(localPickField(params, 'B', 0.0));
Bdir = lower(strtrim(string(localPickField(params, 'Bdir', "out"))));
if Bdir == "in"
    Bz = -B;
else
    Bz = B;
end
end

function v = localPickField(s, name, fallback)
%LOCALPICKFIELD  局部安全读字段，避免依赖外部工具函数
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end


function state = attachR8Outputs(state, params, out, Fdrive)
%ATTACHR8OUTPUTS  统一挂载 R8 输出字段（step/reset 共用实现）
%
% 用途
%   - 将 frameStripOutputs 的真源输出写回到状态结构。
%   - 统一维护 R8 输出口径，避免 step/reset 双份逻辑漂移。
%
% 输入
%   state  (1,1) struct
%     当前状态结构。
%   params (1,1) struct
%     当前参数结构（用于读取 h/H/L 等口径字段）。
%   out    (1,1) struct
%     physics.frameStripOutputs 的输出结构。
%   Fdrive (1,1) double
%     外驱动力，用于计算机械功率 pMech。
%
% 输出
%   state  (1,1) struct
%     已写回 epsilon/current/fMag/pElec/pMech 与 state.rail 子结构。
%
% 说明
%   - 本函数只负责“字段挂载”，不负责推进状态。
%   - qHeat 在此不积分，只回写当前累计值。

if ~isfield(state, 'qHeat')
    state.qHeat = 0.0;
end

state.epsilon = double(out.epsilon);
state.current = double(out.current);
state.fMag = double(out.fMag);
state.pElec = double(out.pElec);
state.pMech = double(Fdrive) * double(pickField(state, 'vx', 0.0));

loopH = max(double(pickField(params, 'h', pickField(params, 'H', pickField(params, 'L', 1.0)))), 1e-9);
state.rail = struct( ...
    'elementType', "R", ...
    'L', loopH, ...
    'w', double(out.w), ...
    'h', double(out.h), ...
    'x', double(pickField(state, 'x', 0.0)), ...
    'xFront', double(out.xFront), ...
    'xBack', double(out.xBack), ...
    'inField', logical(out.inField), ...
    'overlap', double(out.overlap), ...
    'sPrime', double(out.sPrime), ...
    'phi', double(out.phi), ...
    'epsilon', double(out.epsilon), ...
    'current', double(out.current), ...
    'fMag', double(out.fMag), ...
    'pElec', double(out.pElec), ...
    'qHeat', double(pickField(state, 'qHeat', 0.0)) ...
);
end

function v = pickField(s, name, fallback)
%PICKFIELD  安全读取结构体字段（局部工具函数）
%
% 用途
%   - 在 helper 内部安全读取字段，避免缺字段时报错。
%
% 输入
%   s        (1,1) struct : 源结构体
%   name     (1,:) char/string : 字段名
%   fallback 任意类型 : 回退值
%
% 输出
%   v 任意类型
%     字段存在时返回字段值，否则返回 fallback。
%
% 说明
%   - 本函数不做类型转换，只做缺字段保护。
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

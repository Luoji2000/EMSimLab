function state = attachRailOutputsCommon(state, params, inField)
%ATTACHRAILOUTPUTSCOMMON  统一挂载 R 系列输出（R/C/L + R8）
%
% 用途
%   - 作为 step/reset 共用的输出挂载实现，消除双份公式导致的维护漂移。
%   - 统一写回 epsilon/current/fMag/pElec/pMech 与 state.rail 口径。
%
% 输入
%   state   (1,1) struct
%     当前导轨状态结构。
%   params  (1,1) struct
%     当前导轨参数结构。
%   inField (1,1) logical
%     当前时刻是否位于磁场有效区域。
%
% 输出
%   state   (1,1) struct
%     已写回分支状态（aBranch/iBranch/qHeat）与统一输出字段。
%
% 说明
%   - R8 分支直接复用 physics.frameStripOutputs 真源。
%   - R/C/L 分支保持现有教学口径，仅做“实现位置收敛”，不改物理行为。
if engine.helpers.isR8Template(params)
    outR8 = physics.frameStripOutputs( ...
        double(localPickField(state, 'x', 0.0)), ...
        double(localPickField(state, 'vx', 0.0)), ...
        params);
    state.iBranch = double(outR8.current);
    state.aBranch = double(localPickField(state, 'aBranch', 0.0));
    state.inField = logical(outR8.inField);
    state.xFront = double(outR8.xFront);
    state.xBack = double(outR8.xBack);
    state = engine.helpers.attachR8Outputs(state, params, outR8, double(localPickField(params, 'Fdrive', 0.0)));
    return;
end

vx = double(localPickField(state, 'vx', 0.0));
L = max(double(localPickField(params, 'L', 1.0)), 1e-9);
R = max(double(localPickField(params, 'R', 1.0)), 1e-12);
Bz = engine.helpers.signedBFromParams(params);
K = Bz * L;
elementType = engine.helpers.resolveRailElement(params);
loopClosed = localLogicalField(params, 'loopClosed', false);
Fdrive = double(localPickField(params, 'Fdrive', 0.0));
m = max(double(localPickField(params, 'm', 1.0)), 1e-12);
useCoupling = logical(inField) && loopClosed;

aBranch = 0.0;
iBranch = double(localPickField(state, 'iBranch', 0.0));
qHeatCandidate = NaN;

switch elementType
    case "C"
        Cval = max(double(localPickField(params, 'C', 1.0)), 1e-12);
        if useCoupling
            mEff = m + Cval * (K^2);
            aBranch = Fdrive / max(mEff, 1e-12);
            iBranch = Cval * K * aBranch;
            epsilon = K * vx;
            fMag = -K * iBranch;
            pElec = epsilon * iBranch;
            qHeatCandidate = 0.5 * Cval * epsilon^2;
        else
            aBranch = Fdrive / m;
            iBranch = 0.0;
            epsilon = 0.0;
            fMag = 0.0;
            pElec = 0.0;
            qHeatCandidate = 0.0;
        end
        out = struct('epsilon', epsilon, 'current', iBranch, 'fMag', fMag, 'pElec', pElec, 'pMech', Fdrive * vx);
    case "L"
        LsVal = max(double(localPickField(params, 'Ls', 1.0)), 1e-12);
        if useCoupling
            iBranch = double(localPickField(state, 'iBranch', 0.0));
            epsilon = K * vx;
            fMag = -K * iBranch;
            pElec = epsilon * iBranch;
            qHeatCandidate = 0.5 * LsVal * iBranch^2;
            aBranch = (Fdrive - K * iBranch) / m;
        else
            iBranch = 0.0;
            epsilon = 0.0;
            fMag = 0.0;
            pElec = 0.0;
            qHeatCandidate = 0.0;
            aBranch = Fdrive / m;
        end
        out = struct('epsilon', epsilon, 'current', iBranch, 'fMag', fMag, 'pElec', pElec, 'pMech', Fdrive * vx);
    otherwise
        out = physics.railOutputsNoFriction(vx, L, R, Bz, logical(inField), loopClosed, Fdrive);
        k = engine.helpers.railDampingK(Bz, L, R);
        if useCoupling
            aBranch = (Fdrive - k * vx) / m;
        else
            aBranch = Fdrive / m;
        end
        iBranch = double(out.current);
end

state.aBranch = double(aBranch);
state.iBranch = double(iBranch);
if ~isfield(state, 'qHeat')
    state.qHeat = 0.0;
end
if isfinite(qHeatCandidate)
    state.qHeat = double(qHeatCandidate);
end

state.epsilon = double(out.epsilon);
state.current = double(out.current);
state.fMag = double(out.fMag);
state.pElec = double(out.pElec);
state.pMech = double(out.pMech);

state.rail = struct( ...
    'elementType', elementType, ...
    'L', L, ...
    'x', double(localPickField(state, 'x', 0.0)), ...
    'yCenter', double(localPickField(state, 'y', 0.0)), ...
    'inField', logical(inField), ...
    'epsilon', double(out.epsilon), ...
    'current', double(out.current), ...
    'fMag', double(out.fMag), ...
    'pElec', double(out.pElec), ...
    'qHeat', double(localPickField(state, 'qHeat', 0.0)) ...
);
end

function v = localPickField(s, name, fallback)
%LOCALPICKFIELD  安全读取结构体字段（缺失则返回 fallback）
%
% 输入
%   s        (1,1) struct
%   name     (1,:) char/string
%   fallback 任意类型
%
% 输出
%   v        任意类型
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

function v = localLogicalField(s, name, fallback)
%LOCALLOGICALFIELD  安全读取并归一化逻辑字段
%
% 输入
%   s        (1,1) struct
%   name     (1,:) char/string
%   fallback (1,1) logical/numeric
%
% 输出
%   v        (1,1) logical
raw = localPickField(s, name, fallback);
if islogical(raw) && isscalar(raw)
    v = logical(raw);
elseif isnumeric(raw) && isscalar(raw) && isfinite(raw)
    v = logical(raw ~= 0);
else
    v = logical(fallback);
end
end

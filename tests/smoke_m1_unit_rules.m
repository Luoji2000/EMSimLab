function ok = smoke_m1_unit_rules()
%SMOKE_M1_UNIT_RULES  M1 单位模式/粒子类型联动烟雾测试
%
% 验证目标
%   1) 电子/质子会强制切换到粒子单位并覆盖 q/m
%   2) 自定义在切入粒子模式时重置为 (q,m)=(1,1)
%   3) validate 兜底规则与组件规则保持一致

ok = false;

fig = uifigure('Visible', 'off');
comp = M1_for_test(fig);
cleanupObj = onCleanup(@()deleteSafe(fig)); %#ok<NASGU>

% 1) 电子 -> 强制粒子单位，q/m 固定
p = comp.getPayload();
p.unitMode = "SI";
p.particleType = "electron";
p.q = 99;
p.m = 99;
comp.setPayload(p);
p1 = comp.getPayload();
assert(string(p1.unitMode) == "particle", '电子应强制粒子单位。');
assert(abs(double(p1.q) + 1.0) < 1e-12, '电子 q 应为 -1。');
assert(abs(double(p1.m) - 1.0) < 1e-12, '电子 m 应为 1。');

% 2) 电子 -> 自定义（仍在粒子模式）应重置 q/m=1/1
p1.particleType = "custom";
comp.setPayload(p1);
p2 = comp.getPayload();
assert(string(p2.unitMode) == "particle", '此步骤应保持粒子单位。');
assert(abs(double(p2.q) - 1.0) < 1e-12, '自定义切入粒子模式时 q 应重置为 1。');
assert(abs(double(p2.m) - 1.0) < 1e-12, '自定义切入粒子模式时 m 应重置为 1。');

% 3) 自定义粒子允许手动修改 q/m
p2.q = 2.5;
p2.m = 12.0;
comp.setPayload(p2);
p3 = comp.getPayload();
assert(abs(double(p3.q) - 2.5) < 1e-12, '自定义粒子 q 应允许手动修改。');
assert(abs(double(p3.m) - 12.0) < 1e-12, '自定义粒子 m 应允许手动修改。');

% 4) validate 兜底：质子应被纠正为粒子单位并覆盖 q/m
schema = params.schema_get("particle");
pv = params.validate(struct( ...
    'unitMode', "SI", ...
    'particleType', "proton", ...
    'q', 9, ...
    'm', 9, ...
    'B', 1, ...
    'v0', 1, ...
    'thetaDeg', 0, ...
    'Bdir', "out", ...
    'x0', 0, ...
    'y0', 0, ...
    'bounded', false, ...
    'xMin', -1, ...
    'xMax', 1, ...
    'yMin', -1, ...
    'yMax', 1, ...
    'showTrail', true, ...
    'showV', true, ...
    'showF', false, ...
    'showGrid', true, ...
    'showBMarks', true, ...
    'speedScale', 1 ...
), schema);

assert(string(pv.unitMode) == "particle", 'validate 应强制质子使用粒子单位。');
assert(abs(double(pv.q) - 1.0) < 1e-12, '质子 q 应为 1。');
assert(abs(double(pv.m) - 1836.15267343) < 1e-9, '质子 m 应为 mp/me。');

ok = true;
end

function deleteSafe(h)
if ~isempty(h) && isvalid(h)
    delete(h);
end
end

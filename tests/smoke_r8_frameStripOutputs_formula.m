function ok = smoke_r8_frameStripOutputs_formula()
%SMOKE_R8_FRAMESTRIPOUTPUTS_FORMULA  R8 公式真源烟雾测试（frameStripOutputs）
%
% 测试目标
%   1) 几何重叠量 overlap 与分段导数 sPrime 符合中心坐标语义
%   2) 电磁量满足公式：
%      Phi = Bz*h*overlap
%      epsilon = -Bz*h*sPrime*v
%      I = epsilon/R（闭路）
%      Fmag = -(B^2*h^2/R)*(sPrime^2)*v（闭路）
%   3) 开路时电流/安培力/电功率归零

ok = false;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

base = struct( ...
    'templateId', "R8", ...
    'w', 2.0, ...
    'h', 3.0, ...
    'B', 4.0, ...
    'Bdir', "out", ...
    'R', 5.0, ...
    'xMin', 0.0, ...
    'xMax', 10.0, ...
    'loopClosed', true ...
);

vx = 2.0;
tol = 1e-12;

% Case A：完全在场内，sPrime=0，感应量应为 0
outA = physics.frameStripOutputs(5.0, vx, base);
assert(abs(outA.overlap - 2.0) < tol, 'Case A overlap 应为线框宽度 w。');
assert(abs(outA.sPrime - 0.0) < tol, 'Case A sPrime 应为 0。');
assert(abs(outA.phi - 24.0) < tol, 'Case A Phi 公式不一致。');
assert(abs(outA.epsilon) < tol, 'Case A epsilon 应为 0。');
assert(abs(outA.current) < tol, 'Case A current 应为 0。');
assert(abs(outA.fMag) < tol, 'Case A fMag 应为 0。');

% Case B：左侧进入阶段（部分重叠），sPrime=+1
outB = physics.frameStripOutputs(0.5, vx, base);
expectedOverlapB = 1.5;
expectedSPrimeB = 1.0;
expectedPhiB = 4.0 * 3.0 * expectedOverlapB;
expectedEpsB = -4.0 * 3.0 * expectedSPrimeB * vx;
expectedIB = expectedEpsB / 5.0;
expectedFB = -((4.0^2) * (3.0^2) / 5.0) * (expectedSPrimeB^2) * vx;
assert(abs(outB.overlap - expectedOverlapB) < tol, 'Case B overlap 不一致。');
assert(abs(outB.sPrime - expectedSPrimeB) < tol, 'Case B sPrime 不一致。');
assert(abs(outB.phi - expectedPhiB) < tol, 'Case B Phi 公式不一致。');
assert(abs(outB.epsilon - expectedEpsB) < tol, 'Case B epsilon 公式不一致。');
assert(abs(outB.current - expectedIB) < tol, 'Case B current 公式不一致。');
assert(abs(outB.fMag - expectedFB) < tol, 'Case B fMag 公式不一致。');
assert(outB.fMag <= tol, 'Case B 在 v>0 时 fMag 应与速度反向（<=0）。');

% Case C：右侧离开阶段（部分重叠），sPrime=-1
outC = physics.frameStripOutputs(9.5, vx, base);
expectedOverlapC = 1.5;
expectedSPrimeC = -1.0;
expectedPhiC = 4.0 * 3.0 * expectedOverlapC;
expectedEpsC = -4.0 * 3.0 * expectedSPrimeC * vx;
expectedIC = expectedEpsC / 5.0;
expectedFC = -((4.0^2) * (3.0^2) / 5.0) * (expectedSPrimeC^2) * vx;
assert(abs(outC.overlap - expectedOverlapC) < tol, 'Case C overlap 不一致。');
assert(abs(outC.sPrime - expectedSPrimeC) < tol, 'Case C sPrime 不一致。');
assert(abs(outC.phi - expectedPhiC) < tol, 'Case C Phi 公式不一致。');
assert(abs(outC.epsilon - expectedEpsC) < tol, 'Case C epsilon 公式不一致。');
assert(abs(outC.current - expectedIC) < tol, 'Case C current 公式不一致。');
assert(abs(outC.fMag - expectedFC) < tol, 'Case C fMag 公式不一致。');
assert(outC.fMag <= tol, 'Case C 在 v>0 时 fMag 应与速度反向（<=0）。');

% Case D：开路时，电磁耦合输出应归零
openLoop = base;
openLoop.loopClosed = false;
outD = physics.frameStripOutputs(0.5, vx, openLoop);
assert(abs(outD.current) < tol, 'Case D 开路 current 应为 0。');
assert(abs(outD.fMag) < tol, 'Case D 开路 fMag 应为 0。');
assert(abs(outD.pElec) < tol, 'Case D 开路 pElec 应为 0。');
assert(abs(outD.dragCoeff) < tol, 'Case D 开路 dragCoeff 应为 0。');

% Case E：Bdir=in 时符号翻转（Bz 为负）
inFieldDir = base;
inFieldDir.Bdir = "in";
outE = physics.frameStripOutputs(0.5, vx, inFieldDir);
expectedEpsE = -(-4.0) * 3.0 * 1.0 * vx;
assert(abs(outE.epsilon - expectedEpsE) < tol, 'Case E Bdir=in 的 epsilon 符号不正确。');

ok = true;
disp('R8 frameStripOutputs 公式烟雾测试通过。');
end

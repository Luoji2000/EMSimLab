function ok = smoke_r8_validate_rules()
%SMOKE_R8_VALIDATE_RULES  R8 参数联动规则烟雾测试（params.validate）
%
% 测试目标
%   1) R8 强制规则：bounded=true、loopClosed=true、v0 朝右（非负）
%   2) 中心坐标语义：xCenter/yCenter 与 x0/y0 统一
%   3) 尺寸语义：h/H/L 统一，w/W 统一
%   4) 条带边界修正：xMax 必须大于 xMin
%   5) 匀速模式（driveEnabled=false）联动隐藏受力可视化并置 Fdrive=0

ok = false;
tol = 1e-12;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

schema = params.schema_get("rail");
raw = struct( ...
    'templateId', "R8", ...
    'modelType', "rail", ...
    'elementType', "R", ...
    'v0', -3.0, ...
    'bounded', false, ...
    'loopClosed', false, ...
    'xMin', 5.0, ...
    'xMax', 2.0, ...
    'x0', 1.25, ...
    'y0', -0.75, ...
    'L', 6.0, ...
    'W', 7.0, ...
    'driveEnabled', false, ...
    'Fdrive', 9.0, ...
    'showDriveForce', true, ...
    'showAmpereForce', true ...
);

p = params.validate(raw, schema);

% 1) R8 强制规则
assert(strcmpi(string(p.templateId), "R8"), 'R8 模板 ID 不应被改写。');
assert(logical(p.bounded), 'R8 应强制 bounded=true。');
assert(logical(p.loopClosed), 'R8 应强制 loopClosed=true。');
assert(double(p.v0) >= -tol, 'R8 v0 应被修正为非负。');
assert(abs(double(p.v0) - 3.0) < tol, 'R8 v0 应等于 abs(原始 v0)。');

% 2) 中心坐标语义
assert(abs(double(p.xCenter) - 1.25) < tol, 'xCenter 应从 x0 继承。');
assert(abs(double(p.yCenter) + 0.75) < tol, 'yCenter 应从 y0 继承。');
assert(abs(double(p.x0) - double(p.xCenter)) < tol, 'x0 应与 xCenter 对齐。');
assert(abs(double(p.y0) - double(p.yCenter)) < tol, 'y0 应与 yCenter 对齐。');

% 3) 尺寸语义
assert(abs(double(p.h) - 6.0) < tol, 'h 应从 L 继承。');
assert(abs(double(p.H) - double(p.h)) < tol, 'H 应与 h 一致。');
assert(abs(double(p.L) - double(p.h)) < tol, 'L 应与 h 一致。');
assert(abs(double(p.w) - 7.0) < tol, 'w 应从 W 继承。');
assert(abs(double(p.W) - double(p.w)) < tol, 'W 应与 w 一致。');

% 4) 条带边界修正
assert(double(p.xMax) > double(p.xMin), 'R8 条带应满足 xMax > xMin。');
assert(abs(double(p.xMin) - 5.0) < tol, 'R8 xMin 应保持输入值。');
assert(abs(double(p.xMax) - (double(p.xMin) + 1e-6)) < 1e-12, ...
    '当输入 xMax<=xMin 时，R8 应修正为 xMin+1e-6。');

% 5) 匀速模式联动
assert(~logical(p.driveEnabled), '当前用例应保持 driveEnabled=false。');
assert(abs(double(p.Fdrive)) < tol, '匀速模式下 Fdrive 应被置零。');
assert(~logical(p.showDriveForce), '匀速模式下应隐藏外力箭头。');
assert(~logical(p.showAmpereForce), '匀速模式下应隐藏安培力箭头。');

ok = true;
disp('R8 validate 规则烟雾测试通过。');
end

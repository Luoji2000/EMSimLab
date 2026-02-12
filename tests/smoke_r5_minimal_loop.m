function smoke_r5_minimal_loop()
%SMOKE_R5_MINIMAL_LOOP  R5 双导体棒模板最小闭环烟雾测试
%
% 测试目标
%   1) 模板切换链路可用（MainApp -> R5 参数组件）
%   2) 参数校验、reset、step 主链路可执行
%   3) R5 关键状态字段与输出映射字段存在且数值有效

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'apps'), '-begin');
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

app = MainApp();
cleanupObj = onCleanup(@()deleteIfValid(app)); %#ok<NASGU>

% 1) 切换到 R5 模板
control.onTemplateChanged(app, "R5");
assert(app.CurrentTemplateId == "R5", 'R5 模板切换失败。');
assert(strcmpi(string(app.CurrentEngineKey), "rail"), 'R5 引擎模式应为 rail。');

% 2) 配置一组稳定参数并重置
app.Params.templateId = "R5";
app.Params.modelType = "rail";
app.Params.loopClosed = true;
app.Params.driveEnabled = true;
app.Params.bounded = true;
app.Params.B = 1.5;
app.Params.Bdir = "out";
app.Params.xMin = 0.0;
app.Params.xMax = 4.0;
app.Params.yMin = 0.0;
app.Params.yMax = 1.0;

app.Params.LA = 1.0;
app.Params.LB = 1.2;
app.Params.RA = 1.0;
app.Params.RB = 1.0;
app.Params.mA = 1.0;
app.Params.mB = 1.0;
app.Params.xA0 = 0.8;
app.Params.xB0 = 2.0;
app.Params.vA0 = 0.1;
app.Params.vB0 = 0.6;
app.Params.FdriveA = 0.0;
app.Params.FdriveB = 0.0;
app.Params.rho = 1.0;

app.Params = params.validate(app.Params, params.schema_get("rail"));
app.State = engine.reset(struct(), app.Params);

% 3) 推进若干步并执行渲染链路
for k = 1:20
    app.State = engine.step(app.State, app.Params, 0.02);
end
app.Params = control.mergeRailOutputs(app.Params, app.State);
ui.applyPayload(app, app.Params);
ui.render(app, app.State);

% 4) 状态断言
assert(strcmpi(string(app.State.modelType), "rail"), 'R5 状态 modelType 应为 rail。');
assert(isfield(app.State, 'templateId') && string(app.State.templateId) == "R5", 'R5 状态 templateId 缺失或错误。');
assert(isfield(app.State, 'xA') && isfield(app.State, 'xB'), 'R5 状态缺少 A/B 位置字段。');
assert(double(app.State.xB) >= double(app.State.xA), 'R5 状态应满足 xB >= xA。');
assert(isfield(app.State, 'vA') && isfield(app.State, 'vB'), 'R5 状态缺少 A/B 速度字段。');
assert(isfield(app.State, 'current') && isfinite(double(app.State.current)), 'R5 电流输出无效。');
assert(isfield(app.State, 'fMag') && isfinite(double(app.State.fMag)), 'R5 合安培力输出无效。');
assert(isfield(app.State, 'qHeat') && double(app.State.qHeat) >= 0.0, 'R5 总热量应为非负。');
assert(isfield(app.State, 'qHeatColl') && double(app.State.qHeatColl) >= 0.0, 'R5 碰撞热量应为非负。');
assert(isfield(app.State, 'traj') && size(app.State.traj, 1) >= 2, 'R5 中心轨迹应至少有 2 个点。');
assert(isfield(app.State, 'trajA') && size(app.State.trajA, 1) >= 2, 'R5 A 棒轨迹应至少有 2 个点。');
assert(isfield(app.State, 'trajB') && size(app.State.trajB, 1) >= 2, 'R5 B 棒轨迹应至少有 2 个点。');

% 5) 输出映射断言（给参数面板输出区）
assert(isfield(app.Params, 'xOut') && isfinite(double(app.Params.xOut)), 'R5 输出映射 xOut 无效。');
assert(isfield(app.Params, 'vOut') && isfinite(double(app.Params.vOut)), 'R5 输出映射 vOut 无效。');
assert(isfield(app.Params, 'qCollOut') && double(app.Params.qCollOut) >= 0.0, 'R5 输出映射 qCollOut 无效。');
assert(isfield(app.Params, 'xAOut') && isfield(app.Params, 'xBOut'), 'R5 输出映射 xAOut/xBOut 缺失。');
assert(isfield(app.Params, 'modeOut'), 'R5 输出映射 modeOut 缺失。');

disp('R5 双导体棒最小闭环烟雾测试通过。');
end

function deleteIfValid(obj)
%DELETEIFVALID  安全释放 App 句柄，避免测试残留窗口
if isempty(obj)
    return;
end
if isa(obj, 'handle')
    try
        if isvalid(obj)
            delete(obj);
        end
    catch
    end
end
end

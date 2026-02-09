function smoke_r1_minimal_loop()
%SMOKE_R1_MINIMAL_LOOP  R 统一模板下 R1 场景烟雾测试（开路/无外力）

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'apps'), '-begin');
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

app = MainApp();
cleanupObj = onCleanup(@()deleteIfValid(app)); %#ok<NASGU>

% 1) 切到统一 R 模板（旧 ID R1 也可）
control.onTemplateChanged(app, "R");
assert(app.CurrentTemplateId == "R", 'R 模板切换失败');
assert(strcmpi(string(app.CurrentEngineKey), "rail"), 'R 引擎模式应为 rail');

% 2) 配置为 R1 场景：开路、无外力
app.Params.loopClosed = false;
app.Params.driveEnabled = false;
app.Params.Fdrive = 0.0;
app.Params = params.validate(app.Params, params.schema_get("rail"));
app.State = engine.reset(app.State, app.Params);

% 3) 单步推进 + 渲染
app.State = engine.step(app.State, app.Params, 0.05);
ui.render(app, app.State);

% 4) 断言
assert(strcmpi(string(app.State.modelType), "rail"), '状态 modelType 应为 rail');
assert(isfield(app.State, 'epsilon'), 'R1 场景应包含 epsilon 输出');
assert(isfield(app.State, 'traj') && size(app.State.traj, 2) == 2, '轨迹字段异常');

disp('R 统一模板（R1场景）烟雾测试通过。');
end

function deleteIfValid(obj)
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

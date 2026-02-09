function smoke_r2_minimal_loop()
%SMOKE_R2_MINIMAL_LOOP  R 统一模板下 R2 场景烟雾测试（闭路/外力）

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'apps'), '-begin');
addpath(fullfile(root, 'src'), '-begin');
addpath(fullfile(root, 'm'), '-begin');

app = MainApp();
cleanupObj = onCleanup(@()deleteIfValid(app)); %#ok<NASGU>

% 1) 切到统一 R 模板
control.onTemplateChanged(app, "R");
assert(app.CurrentTemplateId == "R", 'R 模板切换失败');
assert(strcmpi(string(app.CurrentEngineKey), "rail"), 'R 引擎模式应为 rail');

% 2) 配置为 R2 场景：闭路 + 外力
app.Params.loopClosed = true;
app.Params.driveEnabled = true;
if ~isfield(app.Params, 'Fdrive') || abs(double(app.Params.Fdrive)) < 1e-12
    app.Params.Fdrive = 1.0;
end
app.Params.showDriveForce = true;
app.Params.showAmpereForce = true;
app.Params = params.validate(app.Params, params.schema_get("rail"));
app.State = engine.reset(app.State, app.Params);

% 3) 推进多步并渲染
for k = 1:20
    app.State = engine.step(app.State, app.Params, 0.05);
end
app.Params = control.mergeRailOutputs(app.Params, app.State);
ui.applyPayload(app, app.Params);
ui.render(app, app.State);

% 4) 断言
assert(strcmpi(string(app.State.modelType), "rail"), 'R2 场景状态 modelType 应为 rail');
assert(isfield(app.State, 'current') && isfinite(double(app.State.current)), '电流输出无效');
assert(isfield(app.State, 'fMag') && isfinite(double(app.State.fMag)), '安培力输出无效');
assert(isfield(app.State, 'qHeat') && double(app.State.qHeat) >= 0, '焦耳热累计应为非负');

disp('R 统一模板（R2场景）烟雾测试通过。');
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

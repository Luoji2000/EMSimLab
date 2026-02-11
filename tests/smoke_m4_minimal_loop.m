function ok = smoke_m4_minimal_loop()
%SMOKE_M4_MINIMAL_LOOP  M4 速度选择器最小闭环烟雾测试
%
% 验证目标
%   1) M4 模板可切换，参数组件可正确加载
%   2) 选择条件 v0 = Ey/B 下，初始 y 向偏转应接近 0
%   3) 单步推进链路可执行，状态字段完整

ok = false;

app = MainApp();
cleanupObj = onCleanup(@()deleteIfValid(app)); %#ok<NASGU>

control.onTemplateChanged(app, "M4");
assert(app.CurrentTemplateId == "M4", 'M4 模板切换失败。');
assert(strcmpi(class(app.ParamComponent), 'M4_for_test'), 'M4 参数组件未加载。');

p = app.ParamComponent.getPayload();
p.B = 1.0;
p.Bdir = "out";
p.Ey = 2.0;
p.v0 = 2.0;            % 满足速度选择条件 v = Ey/B
p.x0 = -0.8;
p.y0 = 0.0;
p.plateGap = 1.0;
p.xMin = -1.0;
p.xMax = 1.0;
p.bounded = true;
app.ParamComponent.setPayload(p);
control.onParamsChanged(app);

assert(strcmpi(string(app.Params.modelType), "selector"), 'M4 应进入 selector 模型。');
assert(isfield(app.Params, 'Ey'), 'M4 参数应包含 Ey。');

state1 = engine.step(app.State, app.Params, 0.02);
assert(state1.t > app.State.t, 'M4 单步推进失败。');
assert(isfield(state1, 'qOverM'), 'M4 状态应包含 qOverM 输出。');
assert(isfinite(state1.x) && isfinite(state1.y), 'M4 推进后位置应为有限值。');
assert(abs(state1.vy) < 1e-8, '速度选择条件下 vy 应接近 0。');

ok = true;
end

function deleteIfValid(obj)
%DELETEIFVALID  安全释放句柄对象
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

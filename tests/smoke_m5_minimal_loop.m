function ok = smoke_m5_minimal_loop()
%SMOKE_M5_MINIMAL_LOOP  M5 质谱仪最小闭环烟雾测试
%
% 验证目标
%   1) M5 模板可切换并正确加载参数组件
%   2) 左边界 xMin 会被锁定到 specWallX（不允许越过左侧粗线）
%   3) 单步推进链路可执行

ok = false;

app = MainApp();
cleanupObj = onCleanup(@()deleteIfValid(app)); %#ok<NASGU>

control.onTemplateChanged(app, "M5");
assert(app.CurrentTemplateId == "M5", 'M5 模板切换失败。');
assert(strcmpi(class(app.ParamComponent), 'M5_for_test'), 'M5 参数组件未加载。');

payload = app.ParamComponent.getPayload();
payload.xMin = payload.specWallX - 10.0;  % 故意写非法值
app.ParamComponent.setPayload(payload);
control.onParamsChanged(app);

assert(app.Params.bounded, 'M5 模板应保持有界磁场。');
assert(abs(double(app.Params.xMin) - double(app.Params.specWallX)) < 1e-12, ...
    'M5 左边界未锁定到粗线位置。');

t0 = app.State.t;
control.onPlay(app);
assert(app.State.t > t0, 'M5 单步推进失败。');

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

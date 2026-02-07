function p = buildPayload(app)
%BUILDPAYLOAD  从 UI 读取当前参数，生成 params 结构体
%
% 说明
%   - 这里不做校验，只“采集”
%   - 你可以按 CurrentSchemaKey/EngineKey 决定读取哪些控件
%   - UI 控件句柄命名建议与 params 字段对应（例如 app.BField -> B）

arguments
    app
end

% 如果你的 UI 还没接好，这里先返回 app.Params 作为兜底
p = app.Params;

% TODO: 示例（把实际控件名替换为你 UI 里的控件）
% p.B   = app.BField.Value;
% p.q   = app.QField.Value;
% p.m   = app.MField.Value;
% p.x0  = app.X0Field.Value;
% p.y0  = app.Y0Field.Value;
% p.vx0 = app.Vx0Field.Value;
% p.vy0 = app.Vy0Field.Value;

end

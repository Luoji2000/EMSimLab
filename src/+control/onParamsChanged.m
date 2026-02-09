function onParamsChanged(app, varargin)
%ONPARAMSCHANGED  处理 UI 控件触发的参数更新
%
% 主链路
%   1) 采集参数（UI -> payload）
%   2) 参数校验与归一化
%   3) 回写 UI（统一显示格式）
%   4) 重置状态并刷新渲染
%   5) 输出“参数变化摘要”日志

% 保留 varargin 以兼容回调签名（当前未使用）。

% 记录旧参数，用于生成差异摘要
oldParams = struct();
if isprop(app, 'Params') && isstruct(app.Params)
    oldParams = app.Params;
end

% 1) 按当前模板参数模式读取 schema
schema = params.schema_get(app.CurrentSchemaKey);

% 2) 从 UI 读取 payload
p = ui.buildPayload(app);

% 顶部速度控件属于全局参数，不在 M1 参数组件内，需显式并入 payload
if isprop(app, 'SpeedSlider') && isgraphics(app.SpeedSlider)
    p.speedScale = double(app.SpeedSlider.Value);
elseif isprop(app, 'SpeedValueField') && isgraphics(app.SpeedValueField)
    p.speedScale = double(app.SpeedValueField.Value);
end

% 统一写入当前引擎标签，避免不同模板间参数串线
if isprop(app, 'CurrentEngineKey')
    p.modelType = string(app.CurrentEngineKey);
end
if isprop(app, 'CurrentTemplateId')
    p.templateId = string(app.CurrentTemplateId);
end

% 3) 统一参数校验
p = params.validate(p, schema);

% 4) 更新 app 参数并回写 UI
app.Params = p;
ui.applyPayload(app, p);

% 5) 当前骨架采用“改参即重置”策略，保证行为确定性，便于调试
app.State = engine.reset(app.State, app.Params);
app.Params = control.mergeRailOutputs(app.Params, app.State);
ui.applyPayload(app, app.Params);
ui.render(app, app.State);

% 5.1) 磁场标记开关日志（按你的调试诉求单独记录）
logBMarkToggle(app, oldParams, p);

% 6) 输出参数变化摘要日志（只记录变化项）
changedSummary = summarizeParamChanges(oldParams, p, 8);
if strlength(changedSummary) == 0
    logger.logEvent(app, '调试', '参数已更新', struct('changed_summary', '无变化'));
else
    logger.logEvent(app, '调试', '参数已更新', struct('changed_summary', changedSummary));
end
end

function logBMarkToggle(app, oldParams, newParams)
%LOGBMARKTOGGLE  磁场标记开关变化时写日志
if ~isstruct(oldParams) || ~isstruct(newParams)
    return;
end
if ~(isfield(oldParams, 'showBMarks') && isfield(newParams, 'showBMarks'))
    return;
end

oldVal = toLogical(oldParams.showBMarks);
newVal = toLogical(newParams.showBMarks);
if oldVal == newVal
    return;
end

if newVal
    logger.logEvent(app, '信息', '磁场标记已开启', struct('enabled', true));
else
    logger.logEvent(app, '信息', '磁场标记已关闭', struct('enabled', false));
end
end

function v = toLogical(raw)
%TOLOGICAL  宽松转 logical
if islogical(raw) && isscalar(raw)
    v = raw;
    return;
end
if isnumeric(raw) && isscalar(raw)
    v = raw ~= 0;
    return;
end
if isstring(raw) || ischar(raw)
    token = lower(strtrim(string(raw)));
    v = any(token == ["true","1","on","yes"]);
    return;
end
v = false;
end

function summary = summarizeParamChanges(oldParams, newParams, maxItems)
%SUMMARIZEPARAMCHANGES  生成参数变化摘要文本
%
% 规则
%   - 仅显示发生变化的字段
%   - 最多显示 maxItems 条，超出部分用“...(+N)”折叠
summary = "";
if nargin < 3
    maxItems = 8;
end

if ~isstruct(newParams)
    return;
end
if ~isstruct(oldParams)
    oldParams = struct();
end

allNames = unique([fieldnames(oldParams); fieldnames(newParams)]);
if isempty(allNames)
    return;
end

changes = strings(0, 1);
for i = 1:numel(allNames)
    name = string(allNames{i});
    oldExists = isfield(oldParams, char(name));
    newExists = isfield(newParams, char(name));

    % 新增字段
    if ~oldExists && newExists
        changes(end+1, 1) = name + ': <新增> -> ' + valueToText(newParams.(char(name))); %#ok<AGROW>
        continue;
    end

    % 删除字段
    if oldExists && ~newExists
        changes(end+1, 1) = name + ': ' + valueToText(oldParams.(char(name))) + ' -> <删除>'; %#ok<AGROW>
        continue;
    end

    % 普通字段比较
    vOld = oldParams.(char(name));
    vNew = newParams.(char(name));
    if valuesDiffer(vOld, vNew)
        changes(end+1, 1) = name + ': ' + valueToText(vOld) + ' -> ' + valueToText(vNew); %#ok<AGROW>
    end
end

if isempty(changes)
    return;
end

if numel(changes) > maxItems
    visible = changes(1:maxItems);
    summary = strjoin(visible, '; ') + sprintf('; ...(+%d)', numel(changes) - maxItems);
else
    summary = strjoin(changes, '; ');
end
end

function tf = valuesDiffer(a, b)
%VALUESDIFFER  宽松判定两个参数值是否不同
%
% 说明
%   - 数值标量：用小阈值比较，避免浮点噪声
%   - 字符串/逻辑：直接比较
%   - 其他类型：退化到 isequaln

if isnumeric(a) && isnumeric(b) && isscalar(a) && isscalar(b)
    tf = abs(double(a) - double(b)) > 1e-12;
    return;
end

if (isstring(a) || ischar(a)) && (isstring(b) || ischar(b))
    tf = ~strcmp(string(a), string(b));
    return;
end

if islogical(a) && islogical(b) && isscalar(a) && isscalar(b)
    tf = logical(a) ~= logical(b);
    return;
end

try
    tf = ~isequaln(a, b);
catch
    tf = true;
end
end

function text = valueToText(v)
%VALUETOTEXT  将参数值转为短文本
if isstring(v) || ischar(v)
    text = string(v);
    return;
end
if isnumeric(v) && isscalar(v)
    text = string(v);
    return;
end
if islogical(v) && isscalar(v)
    text = string(v);
    return;
end
if isnumeric(v)
    text = sprintf('[%dx%d %s]', size(v, 1), size(v, 2), class(v));
    return;
end
if isstruct(v)
    text = sprintf('{struct %d}', numel(fieldnames(v)));
    return;
end
if iscell(v)
    text = sprintf('{cell %d}', numel(v));
    return;
end

text = string(class(v));
end

function tpl = getById(id)
%GETBYID  按模板 ID 返回模板定义（含旧 ID 兼容映射）
%
% 兼容策略
%   - R1/R2/R3/R4 统一映射到 R
%   - R5/R8 为独立模板，不参与映射

list = templates.registry();
if isempty(list)
    error("templates:EmptyRegistry", "模板注册表为空。");
end

token = upper(strtrim(string(id)));
if any(token == ["R1","R2","R3","R4"])
    token = "R";
end
if token == "R2LC"
    token = "R";
end

ids = upper(string({list.id}));
idx = find(ids == token, 1, 'first');
if isempty(idx)
    known = strjoin(unique(ids), ", ");
    error("templates:NotFound", "未找到模板 id=%s（已注册：%s）", token, known);
end

tpl = list(idx);
end

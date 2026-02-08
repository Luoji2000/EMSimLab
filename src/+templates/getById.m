function tpl = getById(id)
%GETBYID  按模板 id 返回模板定义
%
% 输入
%   id (1,1) string/char
% 输出
%   tpl (1,1) struct

% 获取注册表，并检验是否为空
list = templates.registry();
if isempty(list)
    error("templates:EmptyRegistry", "模板注册表为空。");
end

id = upper(strtrim(string(id)));     % 标准化输入 id ，转写为大写字符串 ， id最后可能是 char 或 string 类型
ids = arrayfun(@(x) upper(string(x.id)), list);     % 获取所有注册模板的 id 列表，并转写为大写字符串 数组
idx = find(ids == id, 1, "first");   % 查找第一个为true的索引位置

% 若未找到，抛出错误
if isempty(idx)
    known = strjoin(unique(ids), ", ");
    error("templates:NotFound", "未找到模板 id=%s（已注册：%s）", id, known);
end
tpl = list(idx);

end

function tpl = getById(id)
%GETBYID  按模板 id 返回模板定义
%
% 输入
%   id (1,1) string
% 输出
%   tpl (1,1) struct

arguments
    id (1,1) string
end

list = templates.registry();
idx = find(list.id == id, 1, "first");
if isempty(idx)
    error("templates:NotFound", "未找到模板 id=%s", id);
end
tpl = list(idx);

end

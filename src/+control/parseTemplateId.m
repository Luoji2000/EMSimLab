function tplId = parseTemplateId(varargin)
%PARSETEMPLATEID  从各种可能的回调参数里提取模板 id
%
% 说明
%   不同 MATLAB 版本/控件回调参数形态不同，可能传入事件对象、
%   树节点对象，或带 SelectedNodes/CurrentNode 字段的结构体。
%   该函数只负责“尽力提取”，提取失败时返回空字符串，由上层决定回退策略。

% 返回空而不是固定 M1：避免点击分组节点时误切回 M1
tplId = "";

if nargin == 0
    return;
end

a1 = varargin{1};

% 情况 1：直接传入模板 id
if isstring(a1) || ischar(a1)
    candidate = strtrim(string(a1));
    if strlength(candidate) > 0
        tplId = candidate;
    end
    return;
end

% 情况 2：事件结构/对象里带 SelectedNodes（常见于 SelectionChanged）
try
    hasSelectedNodes = (isstruct(a1) && isfield(a1, "SelectedNodes")) || ...
        (isobject(a1) && isprop(a1, "SelectedNodes"));
    if hasSelectedNodes && ~isempty(a1.SelectedNodes)
        node = a1.SelectedNodes(1);
        candidate = readNodeToken(node);
        if strlength(candidate) > 0
            tplId = candidate;
            return;
        end
    end
catch
end

% 情况 3：事件对象里带 CurrentNode
try
    hasCurrentNode = isobject(a1) && isprop(a1, "CurrentNode");
    if hasCurrentNode && ~isempty(a1.CurrentNode)
        candidate = readNodeToken(a1.CurrentNode);
        if strlength(candidate) > 0
            tplId = candidate;
            return;
        end
    end
catch
end

% 情况 4：直接传入树节点对象
try
    candidate = readNodeToken(a1);
    if strlength(candidate) > 0
        tplId = candidate;
        return;
    end
catch
end

end

function token = readNodeToken(node)
%READNODETOKEN  从树节点读取可用标识（优先 NodeData，其次 Text）

token = "";
if isempty(node)
    return;
end

if isprop(node, "NodeData")
    data = strtrim(string(node.NodeData));
    if strlength(data) > 0
        token = data;
        return;
    end
end

if isprop(node, "Text")
    txt = strtrim(string(node.Text));
    if strlength(txt) > 0
        token = txt;
        return;
    end
end
end

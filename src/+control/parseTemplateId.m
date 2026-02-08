function tplId = parseTemplateId(varargin)
%PARSETEMPLATEID  从各种可能的回调参数里提取模板 id
%
% 说明
%   不同 MATLAB 版本/控件回调参数形态不同，可能传入事件对象、
%   树节点对象，或带 `SelectedNodes` 字段的结构体。
%   我们把“兼容性脏活”集中在这里，主流程就干净了。

tplId = "M1"; % 默认兜底

if nargin == 0
    return;
end

a1 = varargin{1};

% 情况 1：直接传入 id
if isstring(a1) || ischar(a1)
    tplId = string(a1);
    return;
end

% 情况 2：事件结构/对象里带 SelectedNodes（不同版本字段略有差异）
try
    hasSelectedNodes = (isstruct(a1) && isfield(a1, "SelectedNodes")) || ...
        (isobject(a1) && isprop(a1, "SelectedNodes"));
    if hasSelectedNodes && ~isempty(a1.SelectedNodes)
        node = a1.SelectedNodes(1);
        if isprop(node, "NodeData")
            candidate = string(node.NodeData);
            if strlength(strtrim(candidate)) > 0
                tplId = candidate;
                return;
            end
        end
    end
catch
end

% 情况 3：直接传入树节点对象
try
    if isprop(a1, "NodeData")
        candidate = string(a1.NodeData);
        if strlength(strtrim(candidate)) > 0
            tplId = candidate;
            return;
        end
    end
catch
end

end


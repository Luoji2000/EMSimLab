function tplId = parseTemplateId(varargin)
%PARSETEMPLATEID  从各种可能的回调参数里提取模板 id
%
% 说明
%   不同 MATLAB 版本/控件回调可能传：event、node、SelectedNodes 等。
%   我们把“兼容性脏活”集中在这里，主流程就干净了。

tplId = "particle"; % 默认兜底

if nargin == 0
    return;
end

a1 = varargin{1};

% 情况 1：直接传入 id
if isstring(a1) || ischar(a1)
    tplId = string(a1);
    return;
end

% 情况 2：event 结构/对象里带 SelectedNodes / Node / Source
try
    if isstruct(a1) && isfield(a1, "SelectedNodes") && ~isempty(a1.SelectedNodes)
        node = a1.SelectedNodes(1);
        if isprop(node, "NodeData")
            tplId = string(node.NodeData);
            return;
        end
    end
catch
end

% 情况 3：直接传入 node
try
    if isprop(a1, "NodeData")
        tplId = string(a1.NodeData);
        return;
    end
catch
end

end

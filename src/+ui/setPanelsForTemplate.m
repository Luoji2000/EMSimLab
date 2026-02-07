function setPanelsForTemplate(app, tpl)
%SETPANELSFORTEMPLATE Toggle panel visibility by template.

arguments
    app
    tpl (1,1) struct
end

if isprop(app, 'RightPanel') && isgraphics(app.RightPanel)
    app.RightPanel.Title = sprintf('控制台 [%s]', string(tpl.id));
end
end

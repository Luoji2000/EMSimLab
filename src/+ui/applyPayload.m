function applyPayload(app, p)
%APPLYPAYLOAD Write validated params back to UI.

arguments
    app
    p (1,1) struct
end

if isprop(app, 'ParamTab') && isgraphics(app.ParamTab)
    app.ParamTab.UserData = p;
end
end

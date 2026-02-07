function openReleaseApp()
%OPENRELEASEAPP Open release mlapp in apps_release.
root = boot.projectRoot();
mlappPath = fullfile(root, 'apps_release', 'MainApp.mlapp');
if ~isfile(mlappPath)
    error('未找到发布版文件：%s', mlappPath);
end
open(mlappPath);
end

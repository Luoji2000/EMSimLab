function run
    % 启动文件（开发态）
    root = fileparts(mfilename('fullpath'));
    addpath(fullfile(root, 'apps'));
    addpath(fullfile(root, 'src'));
    addpath(fullfile(root, 'm'));
    MainApp;
end

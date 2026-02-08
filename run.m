function run
    % 启动文件（开发态）
    root = fileparts(mfilename('fullpath'));
    % 使用 -begin，确保本项目代码优先于历史路径中的同名函数
    addpath(fullfile(root, 'apps'), '-begin');
    addpath(fullfile(root, 'src'), '-begin');
    addpath(fullfile(root, 'm'), '-begin');
    MainApp;
end

%% 批量烟雾测试入口（脚本版）
% 用途
%   - 一键运行 tests 目录下所有 smoke_* 测试函数。
%   - 兼容“有返回值 ok”与“无返回值仅断言”两类测试写法。
%
% 使用方式
%   - MATLAB 命令行：run('tests/smoke.m')
%   - 或先 addpath('tests') 再执行：smoke
%
% 说明
%   - 不再使用 run(file) 逐个执行函数文件；改为按函数名 feval 调用。
%   - 若任一测试失败，脚本最后会 error，便于批处理/CI 感知失败状态。

folder = fileparts(mfilename("fullpath"));
addpath(folder, '-begin');

files = dir(fullfile(folder, "smoke_*.m"));
if isempty(files)
    error('未找到 smoke_*.m 测试文件。目录：%s', folder);
end

% 按文件名排序，确保每次运行顺序稳定
[~, order] = sort(lower(string({files.name})));
files = files(order);

total = numel(files);
passCount = 0;
failNames = strings(0, 1);
failMsgs = strings(0, 1);

fprintf('\n===== Smoke 测试开始（共 %d 项）=====\n', total);
for k = 1:total
    fileName = string(files(k).name);
    [~, funcName] = fileparts(fileName);
    fprintf('[%02d/%02d] RUN  %s\n', k, total, funcName);

    try
        % 按函数签名决定调用方式，避免依赖本地化报错文本（中/英文）
        hasBoolResult = false;
        nout = nargout(funcName);
        if nout == 0
            feval(funcName);
            ok = true;
        else
            ok = feval(funcName);
            hasBoolResult = true;
        end

        if hasBoolResult
            % 若函数显式返回值，则按逻辑真值判定通过/失败
            if isempty(ok)
                ok = true;
            elseif isnumeric(ok) || islogical(ok)
                ok = all(logical(ok(:)));
            else
                ok = true;
            end
        end

        if ok
            passCount = passCount + 1;
            fprintf('[%02d/%02d] PASS %s\n', k, total, funcName);
        else
            failNames(end+1, 1) = funcName; %#ok<SAGROW>
            failMsgs(end+1, 1) = "测试返回 false"; %#ok<SAGROW>
            fprintf(2, '[%02d/%02d] FAIL %s (返回 false)\n', k, total, funcName);
        end
    catch ME
        failNames(end+1, 1) = funcName; %#ok<SAGROW>
        failMsgs(end+1, 1) = string(ME.message); %#ok<SAGROW>
        fprintf(2, '[%02d/%02d] FAIL %s\n', k, total, funcName);
        fprintf(2, '  -> %s\n', ME.message);
    end
end

failCount = numel(failNames);
fprintf('===== Smoke 测试结束：通过 %d，失败 %d =====\n', passCount, failCount);

if failCount > 0
    fprintf(2, '失败清单：\n');
    for i = 1:failCount
        fprintf(2, '  - %s: %s\n', failNames(i), failMsgs(i));
    end
    error('Smoke 测试失败：%d/%d 未通过。', failCount, total);
end

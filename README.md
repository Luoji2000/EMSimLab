# EMSimLab

EMSimLab 是 ElectroSim 的重构迁移工程，目标是把 UI、控制、物理引擎、渲染与日志彻底分层，便于后续逐模块迁移与回归测试。

## 目录约定

- `apps/`：开发入口（纯 `.m`，便于 VS Code + AI 协作）
- `apps_release/`：发布入口（仅放稳定版 `MainApp.mlapp`）
- `src/`：核心逻辑（boot/templates/params/engine/control/ui/viz/logger）
- `docs/`：中文技术文档与变更记录
- `tests/`：烟雾测试与回归测试脚本
- `sandbox/`：临时代码，不进入主链
- `logs/`：运行日志输出（不进 Git）

## 快速开始（开发）

在 MATLAB 命令行执行：

```matlab
cd('F:/code/matlab/EMSimLab');
addpath('apps');
addpath('src');
app = MainApp;
```

如果你希望统一启动脚本，也可以执行：

```matlab
run('run_dev.m')
```

## 发布版入口

发布版 `MainApp.mlapp` 放到 `apps_release/` 后，执行：

```matlab
boot.openReleaseApp()
```

## 本次迁移说明

1. 已建立 `apps/apps_release/src` 三层结构。
2. 已将原骨架包复制到 `src/`（旧根目录包保留，便于对照与回退）。
3. 已补齐 `docs`，包含与 ElectroSim 同规格的中文技术文档。
4. 已新增 `.gitattributes`，将 `.mlapp` 视为二进制。

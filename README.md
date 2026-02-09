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

## 当前进度（M1）

1. 参数链路已打通：模板切换、参数回写、统一校验、状态重置与渲染刷新可闭环工作。
2. 运动模型已接通：
   - 无界：解析旋转矩阵推进（`B=0` 自动退化匀速直线）。
   - 有界：支持“场外直线 -> 场内旋转 -> 场外直线”链条，支持初始在场外。
3. 播放与视角已接通：
   - `运行/暂停/重置` 可控制定时推进；
   - 视角默认固定，粒子越界再平移窗口。
4. 有界可视化规则已接通：
   - 有界模式下磁场标记只在有界方框内铺设；
   - 方框使用黑色粗边框持续标识磁场区域；
   - 无界模式下磁场标记按当前视窗覆盖。
5. 已补充测试脚本：
   - `tests/smoke_m1_minimal_loop.m`
   - `tests/smoke_m1_unbounded_rotation.m`
   - `tests/smoke_m1_unit_rules.m`
   - `tests/smoke_m1_bounded_chain.m`

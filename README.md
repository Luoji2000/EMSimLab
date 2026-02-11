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

## 当前进度（M1 + M4 + R + M5）

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
6. R 系列最小闭环已接入（统一模板 + 场景参数）：
   - 模板注册采用统一 `R`，并兼容 `R1/R2/R3/R4 -> R` 的查询映射；
   - 参数组件按模板动态切换（`M1 -> M1_for_test`, `M4 -> M4_for_test`, `M5 -> M5_for_test`, `R* -> R2_for_test`）；
   - 引擎 `rail` 分支支持开路输出 `ε=BLv`、闭路电流与安培力、以及有界磁场判定；
   - 场景已接入导轨/滑杆/电阻（矩形符号）与电流/外力/安培力箭头；
   - 速度箭头在导轨模型中上移到上导轨外侧，避免与受力箭头重叠。
7. R2 曲线渲染已接入：
   - 曲线页改为三子图：`v(t)`、`I(t)`、`F_mag(t)`；
   - R1（无外力）阶段显示占位说明，R2（有外力）阶段绘制实时曲线；
   - 时间回退（重置/切模）会自动清空历史，避免旧曲线残留。
8. M5 质谱仪模板第一版已接入：
   - 新增模板定义 `src/+templates/+defs/M5.m`；
   - 新增参数组件 `m/M5_for_test.m`；
   - 场景叠层支持“左侧粗线 + 中间小孔 + 右半有界磁场”；
   - M5 下 `xMin` 强制锁定 `specWallX`，避免左边界越过粗线。
9. 连续播放平滑化已接入：
   - 定时渲染节拍默认改为 `30 FPS`（`PlaybackPeriod=1/30`）；
   - `control.onTick` 改为单帧子步进推进（按角速度/步长自适应拆分）；
   - `viz.renderScene` 改为 `drawnow nocallbacks`，移除 `limitrate` 限帧顿感；
   - 磁场标记加入缓存键机制，减少重复点阵重建导致的渲染抖动。
10. 运行态性能优化（A+B）已接入：
   - 日志面板改为“缓冲 + 节流刷新”：隐藏日志页时不频繁重绘，切到日志页再刷新；
   - `logger.logEvent` 在播放中抑制 `信息/调试` 级别命令行输出，保留 `警告/错误`；
   - 新增 `ui.applyOutputs`，运行中只增量更新输出区，避免每帧全量 `setPayload`。
11. M4 速度选择器最小闭环已接入：
   - 模板定义新增 `src/+templates/+defs/M4.m`，参数 schema 新增 `selector`；
   - 引擎新增交叉场解析推进 `physics.crossedFieldStep2D`，并接入 `engine.step/reset` 的 `selector` 分支；
   - 场景渲染新增速度选择器极板与电场方向叠层，支持电场力/磁场力箭头开关；
   - 参数组件新增 `m/M4_for_test.m`（统一 payload 接口）；
   - 新增烟雾测试 `tests/smoke_m4_minimal_loop.m`。

## UI 协作流程（约定）

1. `mlapp/*.mlapp` 作为可视化编辑源（App Designer 中维护）。
2. 每次 UI 结构更新后，把导出的 `.m` 放入 `m/Version/` 作为版本快照。
3. 当前接入文件保持在 `m/*_for_test.m`，由此与 `src/` 逻辑层联通。
4. 逻辑修改优先发生在 `src/`；UI 可替换时，保持对外接口稳定（`payload` 与事件）。

## 通用函数复用（当前）

1. 边界读取与判定已抽离到 `src/+geom/`：
   - `geom.readBoundsFromParams`
   - `geom.isInsideBounds`
2. `engine.reset`、`engine.step` 与 `viz.renderScene` 已复用该公共实现，后续 R 系列可直接沿用。

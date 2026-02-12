# FAQ 常见坑汇总

本页用于快速定位问题。  
原则：先看现象，再看最短排查路径。

快速跳转：

1. 上一页：`07_发布与日常开发协作.md`
2. 返回索引：`00_索引.md`
3. 术语表：`GLOSSARY.md`

## Q1：启动时报找不到参数组件类（例如 `M1_for_test`）

排查顺序：

1. 确认已加入 `m` 路径（`run.m` 会加，手动启动时也要加）。
2. 确认文件存在：`m/M1_for_test.m` 等。
3. 查看 `MainApp` 日志里“参数组件装载决策/结果”。

相关文件：

1. `run.m`
2. `apps/MainApp.m`（`ensureDevPaths`、`ensureParamComponent`）

## Q2：模板树里看不到新模板

排查顺序：

1. 是否在 `src/+templates/registry.m` 注册。
2. 模板定义文件是否在 `src/+templates/+defs/`，且函数返回结构包含 `id/title/group/engineKey/schemaKey`。
3. 启动后是否走了 `buildTemplateTree`。

相关文件：

1. `src/+templates/registry.m`
2. `apps/MainApp.m`（`buildTemplateTree`）

## Q3：改参数后没有触发业务逻辑

排查顺序：

1. 组件是否触发 `PayloadChanged`。
2. `MainApp` 是否绑定监听到 `control.onParamsChanged`。
3. `getPayload` 返回是否是有效 struct。

相关文件：

1. `apps/MainApp.m`（`ensureParamComponent`）
2. `src/+control/onParamsChanged.m`

## Q4：播放按钮点了但看起来没动

排查顺序：

1. `onPlay` 是否走到 `startPlayback`。
2. 定时器是否创建成功（`ensurePlaybackTimer`）。
3. `onTick` 是否持续执行（看日志节流输出）。

相关文件：

1. `src/+control/onPlay.m`
2. `apps/MainApp.m`（`startPlayback/ensurePlaybackTimer`）
3. `src/+control/onTick.m`

## Q5：输出区不刷新或曲线不更新

排查顺序：

1. `mergeRailOutputs` 是否写入输出字段。
2. 组件是否实现 `setOutputs`。
3. 模型是否满足曲线绘制条件（`renderPlots` 对 `rail` 有场景判定）。

相关文件：

1. `src/+control/mergeRailOutputs.m`
2. `src/+ui/applyOutputs.m`
3. `src/+viz/renderPlots.m`

## Q6：切模板后画面或图元残留

排查顺序：

1. 渲染分支是否在“不适用模型”下执行隐藏逻辑。
2. `renderScene` 缓存句柄是否复用且有 `hideHandle` 路径。

相关文件：

1. `src/+viz/renderScene.m`

## Q7：我新增了参数字段，但总被改回去

排查顺序：

1. `schema_get` 是否定义该字段。
2. `validate` 是否有联动规则覆盖该字段。
3. 组件 `normalizePayload` 是否把该字段重置。

相关文件：

1. `src/+params/schema_get.m`
2. `src/+params/validate.m`
3. `m/*_for_test.m`

## Q8：为什么 README 里命令和实际不一致

已知现状：

1. README 里含 `run_dev.m` 提示。
2. 仓库实际入口是 `run.m`。

建议：

1. 以实际文件为准。
2. 文档逐步收敛到 `docs/参考手册/` 主线。

## Q9：`R2LC` 能不能直接当已完成功能使用

当前建议：不能。  
原因：

1. 当前手册与主线不把 `R2LC` 作为已接通业务分支。
2. 它目前是模板层占位，不是完整实现链路。

相关文件：

1. `src/+templates/+defs/R2LC.m`
2. `src/+templates/registry.m`

## Q10：`docs/代码原理介绍/` 和 `docs/参考手册/` 有什么区别

定位区别：

1. `代码原理介绍`：核心公式推导来源（手写理论资料，当前保持只读）。
2. `参考手册`：工程落地与扩展指南（面向开发与维护）。

建议：

1. 推导看前者。
2. 实现与扩展按后者执行。

## 附：高频定位命令（可选）

```powershell
rg -n "onTemplateChanged|onParamsChanged|onTick" src apps
rg -n "PayloadChanged|getPayload|setPayload|setOutputs" m
rg -n "modelType|engineKey|schemaKey" src/+templates src/+engine src/+params
```

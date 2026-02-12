# 术语表（Glossary）

快速跳转：

1. 返回索引：`00_索引.md`
2. 3 分钟入口：`README.md`

## 模板（Template）

用于选择一个教学/仿真场景的元数据项。  
在本项目中，模板定义位于 `src/+templates/+defs/*.m`，注册入口位于 `src/+templates/registry.m`。

## 模板注册表（Template Registry）

模板集合的统一来源。  
对应函数：`templates.registry()`，文件：`src/+templates/registry.m`。

## 引擎键（engineKey）

模板声明“应该走哪个计算分支”的键。  
例如：`particle`、`selector`、`rail`。  
消费位置：`src/+engine/reset.m`、`src/+engine/step.m`。

## 参数模式（schemaKey）

模板声明“参数结构长什么样”的键。  
例如：`particle`、`selector`、`rail`。  
定义位置：`src/+params/schema_get.m`。

## 参数载荷（Payload）

UI 与控制层交换的一份参数结构体。  
典型链路：`ui.buildPayload -> params.validate -> ui.applyPayload`。  
对应文件：`src/+ui/buildPayload.m`、`src/+params/validate.m`、`src/+ui/applyPayload.m`。

## 状态（State）

引擎运行时状态结构体，包含位置、速度、时间、轨迹等。  
生成位置：`src/+engine/reset.m`；推进位置：`src/+engine/step.m`。

## 控制层（Control Layer）

按钮、模板切换、参数变化、播放 tick 的调度层。  
目录：`src/+control/`。

## 引擎层（Engine Layer）

按模型分支执行“重置/推进”的层。  
目录：`src/+engine/`。

## 物理核（Physics Kernel）

可复用的物理公式实现函数。  
目录：`src/+physics/`，例如 `rotmatStep2D.m`、`crossedFieldStep2D.m`。

## 参数组件（Param Component）

位于 `m/*_for_test.m` 的 UI 自定义组件，负责参数控件与 payload 映射。  
统一接口通常包含：`getPayload`、`setPayload`、`PayloadChanged`，部分组件有 `setOutputs`。

## 输出区增量回写（setOutputs）

运行中只更新输出字段，避免每帧全量回写控件。  
入口：`src/+ui/applyOutputs.m`，组件实现见 `m/R2_for_test.m`、`m/M4_for_test.m`、`m/M5_for_test.m`。

## 连续播放（Playback）

`MainApp` 内部使用 MATLAB `timer` 周期触发 `control.onTick` 的机制。  
关键代码：`apps/MainApp.m` 中 `ensurePlaybackTimer` 与 `startPlayback`。

## 冒烟测试（Smoke Test）

项目里位于 `tests/smoke_*.m` 的最小链路验证脚本。  
本手册以“可选”方式提及，不作为必须流程。

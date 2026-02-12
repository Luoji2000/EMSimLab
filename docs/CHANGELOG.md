# 更新日志

## 2026-02-12
- 新增：R5 独立模板接入（`src/+templates/+defs/R5.m` + `registry` + `applyTemplatePreset`），并在 `apps/MainApp.m` 增加 `R5_for_test` 参数组件分配。
- 新增：R5 物理真源 `src/+physics/dualRodOutputs.m`（模式/合电动势/电流/安培力）与 `src/+physics/dualRodAdvance.m`（事件驱动推进、碰撞映射、热量累计）。
- 引擎：`src/+engine/reset.m` 新增 `resetR5DualState`，`src/+engine/step.m` 新增 `stepR5DualState`，并通过 `src/+engine/+helpers/isR5Template.m` 统一模板判定。
- 参数：`src/+params/validate.m` 新增 R5 联动规则（A/B 参数归一化、`xB0>=xA0`、`rho` 约束、兼容字段回填）。
- 输出：`src/+control/mergeRailOutputs.m` 新增 R5 输出映射（中心量 + 合量 + `qCollOut`）。
- 渲染：`src/+viz/renderScene.m` 新增 R5 双棒场景分支（A/B 两棒同屏）；`src/+viz/renderPlots.m` 新增 R5 3x2 曲线布局（A/B/中心 + 电学 + 热量）。
- UI：`m/R5_for_test.m` 补齐 payload 组件协议（`Value/getPayload/setPayload/setOutputs/PayloadChanged`）与 A/B 导体切换编辑逻辑。
- 文档：新增 `docs/参考手册/10_R5双导体棒模板接入说明.md`，并更新 `docs/参考手册/00_索引.md`。
- 测试：新增 `tests/smoke_r5_minimal_loop.m`，覆盖 R5 模板切换、参数校验、reset/step、输出映射与渲染最小闭环。
- 修复：`src/+templates/applyTemplatePreset.m` 中 `applyR8Preset/applyR5Preset` 的函数边界错误，解决 `smoke_r5_minimal_loop` 报错“未定义函数 applyR5Preset”。
- 对齐：`m/R5_for_test.m` 按 `R5_V2` 口径移除“匀速/阻尼”模式输入，新增 `rho`（恢复系数）输入，并强制 `driveEnabled=true`。
- 对齐：`m/R5_for_test.m` 的边界输入不再因 `bounded` 被禁用，满足“除输出区外均可输入”规则。
- 对齐：`src/+params/validate.m`、`src/+physics/dualRodOutputs.m`、`src/+physics/dualRodAdvance.m`、`src/+templates/applyTemplatePreset.m` 的 R5 分支移除 `driveEnabled=false` 演示语义，统一为动力学公式链路（`Fdrive=0` 时自然退化）。
- 调整：`src/+viz/renderScene.m` 的 R5 分支不再绘制左侧电阻符号，仅保留双棒/导轨与相关箭头显示。
- 修复：`src/+viz/renderPlots.m` 中 R5 历史采样/追加/绘制函数块的误嵌套，恢复 R5 曲线区正常出图（x/v/I/epsilon/F/Q）。
- 调整：R5 默认参数改为 `bounded=false`（无界）且 `showDriveForce/showAmpereForce=false`（力箭头默认关闭），对应 `m/R5_for_test.m` 与 `src/+templates/applyTemplatePreset.m`。
- 调整：`src/+viz/renderScene.m` 的 R5 电流箭头方向口径修正（右棒按 current/epsilon 同号映射），用于匹配“B 离场阻碍离场”阶段的顺时针显示。
- 公式：`src/+physics/dualRodOutputs.m` 的 `Leff` 改为按导体段与磁场 y 边界交叠计算：`max(0, min(y0+L/2,yMax)-max(y0-L/2,yMin))`（R5 分支）。
- 修复：`src/+ui/render.m` 改为每帧执行曲线渲染链路，持续累计历史采样，解决“在场景页播放后切到曲线页出现空白”的问题。
- 测试：`tests/smoke.m` 批跑入口改为基于 `nargout` 判定是否接收返回值，修复中文 MATLAB 环境下“输出参数太多”文本不匹配导致的误失败。
- 测试：重写 `tests/smoke.m` 批量入口，改为按 `smoke_*.m` 函数名 `feval` 执行，兼容“有返回值/无返回值”两类 smoke 用例，并在失败时统一汇总并抛错。
- 重构：新增 `src/+engine/+helpers/attachRailOutputsCommon.m`，统一 R/C/L + R8 输出挂载；`src/+engine/step.m` 与 `src/+engine/reset.m` 的 `attachRailOutputs` 改为薄封装委托，减少双份公式维护风险。
- 一致性：`src/+viz/renderScene.m` 的 R8 渲染优先使用 `state.xFront/state.xBack`（源于 `frameStripOutputs`），仅在旧状态缺失时回退几何推导，确保渲染几何与物理输出口径一致。
- 一致性：`src/+viz/renderScene.m` 补充 R8 电流箭头方向注释，明确按 `frameStripOutputs` 的 `current/epsilon` 符号口径渲染（保持“出屏磁场进入阶段右侧边向下”）。
- 公式：`src/+viz/renderPlots.m` 的 `computeFrameFlux` 改为直接复用 `physics.frameStripOutputs` 真源输出（`out.phi`），移除渲染层重复磁通公式，避免口径漂移。
- 规范：补齐 `src/+engine/step.m`、`src/+engine/reset.m` 及 `src/+engine/+helpers/*.m` 的函数注释模板（用途/输入/输出/说明），局部临时函数同步采用同一规范。
- 重构：新增 `src/+engine/+helpers/isR8Template.m`、`src/+engine/+helpers/resolveRailElement.m`、`src/+engine/+helpers/resolveModelType.m`，统一模板与模型判定逻辑；`src/+engine/step.m` 与 `src/+engine/reset.m` 对应本地函数改为委托共享实现（行为不变）。
- 文档：新增 `docs/参考手册/09_引擎共享助手与去重规范.md`，并在 `docs/参考手册/00_索引.md` 增加入口。
- 重构：新增 `src/+engine/+helpers/attachR8Outputs.m`，统一 R8 输出挂载逻辑；`src/+engine/step.m` 与 `src/+engine/reset.m` 的 `attachR8Outputs` 改为委托共享实现，行为保持不变。
- 新增：R2LC 核心物理核接入（同一 `R` 模板内按 `elementType=R/C/L` 切换），电容分支采用等效质量递推，电感分支采用闭式旋转递推。
- 新增：`src/+physics/railAdvanceCapacitor.m` 与 `src/+physics/railAdvanceInductor.m`，将 R2LC 核心公式从流程控制中抽离。
- 重构：`src/+engine/reset.m` 与 `src/+engine/step.m` 的 rail 分支升级为 R/C/L 三分支，补齐 `iBranch/aBranch` 状态与输出挂载。
- 参数：`schema_get("rail")` 新增 `elementType/C/Ls`，`params.validate` 新增 `applyRailRules`（C/L 强制闭路与外力驱动）。
- UI：`m/R2_for_test.m` 新增“回路元件（电阻/电容/电感）”控件，并按元件类型动态切换参数标签（`R/C/Ls`）与输出标签（`Q/U_C/U_L`）。
- 调整：`src/+templates/registry.m` 回归单一 R 模板入口（移除 `R2LC` 独立模板注册），保持“R2LC 作为 R2 场景扩展”的设计。

## 2026-02-11
- 文档：`docs/中文技术文档.md` 新增“新手版函数链条拆解”“递归与循环说明”“关键文件总入口速查”，明确按钮触发后的完整调用路径。
- 文档：补充“主业务链无递归、播放为定时器循环、递归仅用于模板树节点查找（findNodeById）”说明，降低新手阅读成本。
- 新增：M4 模板接入（`src/+templates/+defs/M4.m` + `schema_get("selector")`）。
- 新增：参数组件 `m/M4_for_test.m`，支持 `Value/getPayload/setPayload/PayloadChanged` 统一接口。
- 新增：交叉场解析推进 `src/+physics/crossedFieldStep2D.m`（漂移+旋转+解析位移积分）。
- 重构：`engine.reset/engine.step` 增加 `selector` 分支，支持 M4 的有界进出场链路。
- 新增：`engine.helpers.selectorOutputs`，统一计算 `q/m` 与电场力/磁场力/合力分量。
- 新增：`viz.renderScene` 速度选择器叠层（极板 + 电场箭头）与受力箭头分层渲染。
- 测试：新增 `tests/smoke_m4_minimal_loop.m`。
- 优化（A）：日志面板改为“缓冲 + 节流刷新”，隐藏日志页时不频繁重绘；切换到日志页时立即刷新。
- 优化（A）：`logger.logEvent` 在播放中抑制 `信息/调试` 级别 `fprintf`，保留 `警告/错误` 命令行输出。
- 新增（B）：`src/+ui/applyOutputs.m`，运行态支持输出区增量回写，避免每帧全量 `setPayload`。
- 优化（B）：`control.onTick`、`control.onReset`、`control.onParamsChanged`、`control.onPlay`（回退链路）切换为 `ui.applyOutputs`。
- 新增：`m/R2_for_test.m` 与 `m/M5_for_test.m` 增加 `setOutputs` 接口，仅刷新输出控件。

## 2026-02-10
- 新增：M5 质谱仪模板第一版接入（`src/+templates/+defs/M5.m`），并加入模板注册表与模板预设链路。
- 新增：参数组件 `m/M5_for_test.m`，支持统一 payload 接口与 `q/m = 2*pi/(B*T)` 输出。
- 新增：M5 场景叠层渲染（左侧粗线 + 中间小孔 + 右半有界磁场）。
- 新增：`params.validate` 的 M5 约束规则，强制 `xMin=specWallX`，避免磁场左边界越过质谱仪粗线。
- 优化：连续播放默认节拍从 `0.05s` 调整为 `1/30s`（30 FPS）。
- 优化：`control.onTick` 改为“单帧子步进推进”，按时间上限与角速度上限自动估算子步数量。
- 优化：`viz.renderScene` 移除 `drawnow limitrate`，改为 `drawnow nocallbacks`，减少播放顿感。
- 优化：磁场标记渲染新增缓存键机制，点阵未变化时跳过重建与重复写入，降低渲染抖动。
- 新增：`tests/smoke_m5_minimal_loop.m` 冒烟测试脚本（用于模板切换与边界锁定链路验证）。
## 2026-02-09
- 重构：R 系列模板统一为 `src/+templates/+defs/R.m`，`templates.getById` 新增 `R1/R2/R3/R4 -> R` 别名映射。
- 优化：导轨场景速度箭头上移到上导轨外侧，避免与外力/安培力箭头重叠。
- 优化：导轨场景电阻符号改为“矩形+引线”表示，便于教学演示识别。
- 修复：闭路导轨安培力方向按楞次定律处理，保证始终阻碍导体棒当前运动。
- 新增：`viz.renderPlots` 接入 R2 三子图曲线（`v(t)`、`I(t)`、`F_mag(t)`），R1 显示占位提示。
- 重构：新增 `src/+geom/readBoundsFromParams.m` 与 `src/+geom/isInsideBounds.m`，统一边界读取与点内判定逻辑。
- 重构：`src/+engine/reset.m`、`src/+engine/step.m`、`src/+viz/renderScene.m` 改为复用 `geom` 公共函数，减少重复实现。
- 文档：`README.md` 与 `docs/中文技术文档.md` 新增 UI 协作链条约定（`mlapp -> m/Version -> *_for_test.m`）。
- 新增：`src/+templates/+defs/R1.m` 与 `schema_get(\"rail\")`，接入 R1 导轨模板。
- 重构：`apps/MainApp.m` 参数组件加载改为按模板动态切换（`M*`/`R*`）。
- 重构：`m/R2_for_test.m` 改为统一 payload 组件接口（`Value/getPayload/setPayload/PayloadChanged`）。
- 新增：引擎 `rail` 分支与导轨场景渲染分支，支持 R1 的 `ε=BLv` 输出与有界磁场判定。
- 新增：`src/+control/mergeRailOutputs.m`，把状态输出同步到参数面板输出区。
- 测试：新增 `tests/smoke_r1_minimal_loop.m`。

## 2026-02-08
- 闭环：`apps/MainApp.m` 接通 M1 最小运行链路（模板树构建、参数组件挂载、回调绑定、`boot.startup` 启动初始化）。
- 闭环：参数变化事件已联通 `control.onParamsChanged`，实现 `buildPayload -> validate -> applyPayload -> reset -> render`。
- 优化：顶部速度控件并入参数链路，避免参数回调把 `speedScale` 覆盖回默认值。
- 优化：`run.m` 补齐 `apps/src/m` 路径注入，降低开发态启动失败概率。
- 测试：新增 `tests/smoke_m1_minimal_loop.m`，用于手动验证 M1 启动/改参/运行/重置四步。
- 重构：模板注册表改为“汇总函数 + 单模板定义文件”结构，新增 src/+templates/+defs/M1.m。
- 重构：src/+templates/registry.m 不再内联模板数据，统一从 src/+templates/+defs/*.m 汇总。
- 优化：src/+templates/getById.m 增强空注册表/未注册 id 的错误信息，便于排查模板链路问题。
- 修复：src/+control/parseTemplateId.m 默认模板兜底值改为 M1，与当前迁移阶段一致。
- 文档：新增 docs/02_模板注册表规范.md，明确模板注册字段、目录约定与扩展步骤。
- 参数：`params.schema_get` 增加类型元数据（double/logical/enum），并在 `particle` schema 中补齐 M1 参数集合。
- 参数：`params.validate` 增强类型归一化、范围裁剪、边界顺序修正，并自动派生 `vx0/vy0`。
- UI：`m/M1_for_test.m` 新增公共传参接口（`Value` / `getPayload` / `setPayload`）与 `PayloadChanged` 事件。
- UI：`src/+ui/buildPayload.m` 与 `src/+ui/applyPayload.m` 接入自定义组件接口，未找到组件时回退到原有路径。

## 2026-02-06
- 修复：`+UI/PanelRail.m` 与 `+Engine/RailSliderEngine.m` 中 R2/R3/R4 模式字符串乱码，恢复“阻尼减速/终端速度/功率验证”模式切换与事件链路一致性。
- 修复：`+Services/SceneEngineRenderer.m` 为 R2 右上信息框补齐位置设置，恢复导轨参数信息可见。
- 修复：`+Services/SceneEngineRenderer.m` 在 M5 场景接入 `showF`，使“受力箭头”勾选生效。
- 修复：`+Engine/AmpereEngine.m` 重建静态/动态双模式；静态模式不再运动，动态模式补齐导轨几何输出（`state.rail`）与 `iArrow/thetaArc/info`，恢复导轨显示与曲线数据链路。
- 优化：`+Services/SceneController.m` 导轨箭头缩放改为“可视窗口尺度 + 杆长尺度”并降低最小/最大长度，抑制 R3/R4 箭头过长。
- 优化：`+Services/SceneController.m` 与 `+Viz/SceneRenderer.m` 改为按当前可视范围绘制磁场标记并提高密度，修复“磁场标记只在小区域显示/过稀疏”。
- 修复：R2/R3/R4 合并模板补齐事件链路，新增 rail.reach_terminal（终端速度达成）与 rail.power_balance（功率平衡成立）事件日志，保留进/出磁场事件优先级。
- 修复：+UI/PanelAmpere.m 补全动态参数与扩展开关读写（ampereMode/v0/alphaDeg/useRail/boundedField/allowRotate/useFriction/mu/Fext/bounds）。
- 修复：+UI/PanelAmpere.m 布局恢复为与构建器一致的 4 列 fit 结构，避免参数面板变窄。
- 修复：+UI/PanelMassSpec.m 接入 M5BoundedCheck 读写，并将 M5ViewGrid 行数恢复为 3 行。
- 修复：+UI/PanelRail.m 统一模式映射与 UI 读写（R2_阻尼减速/R3_终端速度/R4_功率验证），保证模式链路稳定。
- 修复：+Services/PlotController.m 增加 ampere_f_theta 通道取值与中文显示名，避免静态安培模式曲线缺失。
- 优化：+Services/SceneController.m 导轨箭头缩放改为“杆长 + 场景跨度”双限幅，并增强 rail 状态识别，减少 R3/R4 视觉过长问题。

## 2026-02-05
- 重构（拆分）：`+Services/UiController.m` 变为薄门面，模板逻辑下沉到 `+Services/TemplateUiController.m`，参数/单位逻辑下沉到 `+Services/ParamUiController.m`。
- 重构（拆分）：新增 `+Services/SceneEngineRenderer.m`，将 `SceneController` 的分引擎渲染逻辑独立出来。
- 重构（拆分）：`+UI/PanelBuilder.m` 拆分为 Core/Particle/Templates/Knowledge 子构建器，主类仅保留聚合与通用 helper。
- 重构（建议项）：单位/粒子类型切换的业务判断下沉到 `+Services/UnitService.m`，UI 回调保持最小逻辑。
- 重构（Phase 5）：新增 `+Services/UiController.m`，UI 回调与模板树逻辑从 `MainApp.m` 下沉为服务。
- 重构（Phase 4）：新增 `+Services/SyncController.m`，控制器回调与参数同步从 `MainApp.m` 下沉为服务。
- 重构（Phase 3）：新增 `+Services/PlotController.m`，曲线绘制与缓存逻辑从 `MainApp.m` 下沉为服务，MainApp 保留薄封装。
- 优化：速度选择器极板标注改为箭头，并放大正负极字符。
- 优化：速度选择器极板中线增加上下短线并标注正负极，视觉更清晰。
- 修复：速度选择器场景在部分状态缺少 bounds 时无法显示极板正负标签，加入状态 bounds 同步与渲染兜底。
- 重构（Phase 2）：新增 `+Services/SceneController.m`，场景渲染/装饰逻辑从 `MainApp.m` 下沉为服务，MainApp 仅保留薄封装。
- 优化：在电子/质子模式下手动编辑 q/m 会自动切换为“自定义”，避免数值被常量强制回写。
- 重构（隔离）：新增 `+Services/UnitService.m`，将单位/粒子类型的业务规则从 UI 中抽离。
- 修复：Q/m 输入框限制过严导致电子质量被夹断为 0.1，放宽 q/m 数值输入 Limits。
- 修复：单位模式切换时，若粒子类型为电子/质子，强制 q/m 使用物理常量，避免粒子模式下出现超大质量值。
- 优化：面板网格间距/内边距缩小，减少空隙；列宽继续采用 label 自适应 + 输入框拉伸。
- 修复：粒子单位模式下的质量基准随“电子/质子”切换，`m(m_e)`/`m(m_p)` 标签与数值一致。
- 优化：参数面板栅格列宽统一为 `{'fit','1x'}`，输入框拉伸填充，布局更均匀。
- 重构（Phase 1）：新增 `+Services/TemplateService.m` 与 `+Services/LogService.m`，模板加载与日志导出从 `MainApp.m` 迁移为服务调用。
- 结构：`MainApp.m` 的模板加载逻辑改为调用 `Services.TemplateService.loadAll`，日志格式化改为 `Services.LogService.formatLine`。
- 增强：新增“导出日志”按钮（位于帮助按钮旁），日志支持导出为 UTF-8 文本文件。
- 增强：调试日志覆盖模板加载/注册表索引与模板切换关键链路。
- 修复：模板注册表内部引用改为 `Config.TemplateRegistry.*`，避免 `TemplateRegistry.range` 解析失败导致模板切换失效。
- 增强：切换模板时在日志页输出“模板切换：ID（引擎=xxx）”，便于排查未切换问题。
- 修复：目录树点击模板后仍停留在默认模板（2025b：优先使用事件对象 event.SelectedNodes）。
- 教学模板 ID 改为编号（M1/M4/M5/A1），用于模板通信信号。
- 新增模板目录清单：`docs/TEACHING_CATALOG.md`，并预留 `docs/knowledge/`。
- 将教学模板目录迁移到 `+Config/TeachingCatalog.m`，与模板注册表解耦。
- 模板注册表拆分到 `+Config/+templates`，每个模板一个文件。
- 新增 `+Control/ParamValidator.m`，支持模板级参数校验与优先策略（当前 M5 为 `qm` 优先）。
- 新增 `+UI/PanelBuilder.m`（方案 C），在运行期动态创建参数/知识点/日志控件并绑定手动回调。
- 新增 `+UI/PanelLayout.m`，集中管理模板面板显示/隐藏逻辑。
- 修复中文乱码：为新增 UI/Config 文件补充 UTF-8 BOM。
- MainApp.m 以极简控件为基准重构：动态控件迁移到 PanelBuilder，便于与 .mlapp 相互复制。

## 2026-02-04
- 新增模板：速度选择器（交叉场）、质谱、安培力（直导线）。
- 新增引擎：`+Engine/CrossedFieldEngine.m`、`+Engine/MassSpecEngine.m`、`+Engine/AmpereEngine.m`。
- 控制器支持按模板切换引擎并输出模板特有日志（通过/偏转、q/m、安培力方向）。
- 参数面板新增 M4/M5/A1 专属控件，模板切换时自动显示/隐藏。
- 场景渲染新增极板、狭缝、半径线、安培力导线与电/磁力箭头。

## 2026-02-03
- 迁移并整理 `simulinkcode/MagSim` 的结构，拆分为 `+Control/+Engine/+Viz/+Logger`。
- 匀强磁场粒子运动改为解析更新，替换 ODE 求解器。
- 主界面支持知识点与日志面板。



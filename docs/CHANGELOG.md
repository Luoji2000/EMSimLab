# 更新日志

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


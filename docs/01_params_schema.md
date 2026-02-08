# 参数 Schema 约定

schema 由 `params.schema_get(schemaKey)` 返回，建议字段格式：

- `schema.key`：字符串 key
- `schema.version`：整数版本
- `schema.defs`：结构体数组，每个元素描述一个参数：
  - `name`：字段名（用于 params 结构体）
  - `label`：中文显示名
  - `type`：参数类型（`double` / `logical` / `enum`）
  - `default`：默认值
  - `min/max`：范围（可为空）
  - `unit`：单位字符串（可为空）
  - `options`：枚举可选值（仅 `enum` 使用）
  - `ui`：UI 建议（如 step、format、group，可后续扩展）

当前实现约定：

1. `params.validate` 会按 `type` 做归一化与校验，再对 `double` 字段执行范围裁剪。
2. 粒子模板中 `vx0/vy0` 作为派生量，由 `v0/thetaDeg` 自动计算并写回参数结构。

这样 UI / 校验 / 文档 三方都能共享同一份定义。

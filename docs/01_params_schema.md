# 参数 Schema 约定

schema 由 `params.schema_get(schemaKey)` 返回，建议字段格式：

- `schema.key`：字符串 key
- `schema.version`：整数版本
- `schema.defs`：结构体数组，每个元素描述一个参数：
  - `name`：字段名（用于 params 结构体）
  - `label`：中文显示名
  - `default`：默认值
  - `min/max`：范围（可为空）
  - `unit`：单位字符串（可为空）
  - `ui`：UI 建议（如 step、format、group）

这样 UI / 校验 / 文档 三方都能共享同一份定义。

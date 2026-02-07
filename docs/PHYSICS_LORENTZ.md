# Physics.Lorentz 说明

## 目标
- 统一洛伦兹力计算入口，避免散落在 UI/Controller/Engine。
- 提供“已知 4 个求第 5 个”的工具函数，便于教学和调试。

## 基本公式
`F = q ( E + v × B )`

## 接口概览
- `force(q, v, B, E)`：3D 力计算（E 默认 0）。
- `force2D(q, vxy, Bz, Exy)`：2D 力计算（B 沿 z，Exy 默认 0）。
- `solveQ(F, v, B, E)` / `solveQ2D(...)`：反解电荷。
- `solveV(F, q, B, E, vParallel)` / `solveV2D(...)`：反解速度。
- `solveB(F, q, v, E, bParallel)` / `solveBz2D(...)`：反解磁场。

## 反解约定
3D 情况下，`v × B = C` 的解不唯一：
- `solveV` 默认返回 **最小范数解**（即 `v ⟂ B`）。
- `solveB` 默认返回 **最小范数解**（即 `B ⟂ v`）。
- 如需指定平行分量，可传入 `vParallel` 或 `bParallel`（标量）。

## E 的处理
若未显式传入 `E`，默认 `E = [0 0 0]`（或 `Exy = [0 0]`）。
当前不提供“求 E”的入口，以避免与求解不唯一产生混淆。

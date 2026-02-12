# R2拓展 导轨滑杆模型的电容/电感版本：严谨推导与递推公式（用于定时器仿真）

> 目标：在 R2（导轨-滑杆-有界匀强磁场）框架下，把回路元件从电阻 R 替换为  
> **(A) 理想电容 C** 或 **(B) 理想电感 Ls**，给出**不跳步**的推导与**可直接用于仿真的递推公式**。  
> 适配教学硬性输出：\|v\|(t)、\|a\|(t)，以及 ε(t)、I(t)、功率/能量等。

---

## 0. 统一模型、符号与方向约定

### 0.1 几何与运动
- 两条平行导轨间距（滑杆有效长度）：\(\ell\)  
- 滑杆沿 \(+x\) 方向运动：位置 \(x(t)\)、速度 \(v(t)=\dot x(t)\)、加速度 \(a(t)=\dot v(t)\)  
- 匀强磁场（可能有界）：\(\mathbf B = B\,\hat{\mathbf z}\)，允许 \(B\) 带符号表示方向  
- 定义便捷常数：
\[
K \equiv B\ell
\]
则很多式子可写得非常紧凑。

### 0.2 “电磁力方向”用能量锁定（避免符号踩坑）
回路中电流为 \(I(t)\)（正方向由你选定的回路正向决定）。  
滑杆所受磁力沿 \(x\) 方向的分量记作 \(F_{\text{mag}}(t)\)。

关键能量关系（动生电动势来自机械运动）：
- 电路吸收功率：\(P_{\text{elec}} = \varepsilon I\)
- 磁力对滑杆做功率：\(P_{\text{mag}} = F_{\text{mag}} v\)
- 能量守恒（电路吸收来自机械）：\(P_{\text{mag}} = - P_{\text{elec}}\)

因此（当 \(v\neq 0\)）：
\[
F_{\text{mag}}v = -\varepsilon I
\quad\Rightarrow\quad
F_{\text{mag}} = -\frac{\varepsilon I}{v}
\]
又因为本模型 \(\varepsilon\propto v\)，所以上式可化为极简单的形式（见 §1）。

---

## 1. 动生电动势 \(\varepsilon = B\ell v\) 的严格推导

对运动导体回路，动生电动势定义为
\[
\varepsilon = \oint (\mathbf v\times \mathbf B)\cdot d\mathbf l
\]
只有滑杆在运动，导轨近似静止，因此只需对滑杆积分。

- \(\mathbf v = v\hat{\mathbf x}\)
- \(\mathbf B = B\hat{\mathbf z}\)
- 滑杆沿 \(\hat{\mathbf y}\) 方向，\(d\mathbf l = dy\,\hat{\mathbf y}\)，\(y\in[0,\ell]\)

计算叉乘：
\[
\mathbf v\times \mathbf B = (v\hat{\mathbf x})\times(B\hat{\mathbf z})
= vB(\hat{\mathbf x}\times\hat{\mathbf z})
= -vB\hat{\mathbf y}
\]
点乘：
\[
(\mathbf v\times\mathbf B)\cdot d\mathbf l
= (-vB\hat{\mathbf y})\cdot(dy\,\hat{\mathbf y})=-vB\,dy
\]
积分：
\[
\varepsilon=\int_0^\ell (-vB)\,dy=-vB\ell
\]

负号取决于你选的回路正向与滑杆积分方向。工程上最稳的做法是：
> 允许 \(B\) 带符号，把电动势定义为
\[
\boxed{\varepsilon = K v = B\ell v}
\]
这样方向信息由 \(B\) 或回路方向统一管理，不在每一步“手搓符号”。

---

## 2. 共同的力学方程（外力 + 电磁力）

设外力（驱动力）沿 \(+x\) 方向为 \(F(t)\)，则
\[
m\dot v = F(t) + F_{\text{mag}}(t)
\]

由 §0.2 的功率锁定 + \(\varepsilon=Kv\) 得：
\[
F_{\text{mag}}v = -\varepsilon I = -(Kv)I
\quad\Rightarrow\quad
\boxed{F_{\text{mag}} = -KI}
\]
于是力学方程统一为
\[
\boxed{m\dot v = F(t) - K I(t)}
\]

> 这条式子对电容版/电感版都成立；区别只在电路方程（\(I\) 如何由 \(v\) 决定）。

---

# A. 纯电容版（把 R 换成理想电容 C）

## A1. 电路方程与核心约束（不跳步）

理想电容两端电压：
\[
V_C = \frac{q}{C}
\]
其中 \(q(t)\) 为电容正极板电荷。

理想导线、回路中只剩电容压降，则 KVL：
\[
\varepsilon - V_C = 0
\quad\Rightarrow\quad
\varepsilon = \frac{q}{C}
\]
代入 \(\varepsilon=Kv\)：
\[
Kv = \frac{q}{C}
\quad\Rightarrow\quad
\boxed{q = CKv}
\]

电流定义：
\[
I = \dot q = \frac{d}{dt}(CKv) = CK\dot v = CKa
\]
即
\[
\boxed{I = C K a}
\]

> 电阻版是 \(I\propto v\)（阻尼）；电容版是 \(I\propto a\)（反加速，等效惯性）。

---

## A2. 磁力与“等效质量”推导（严格）

由统一磁力式 \(F_{\text{mag}}=-KI\)，代入 \(I=CKa\)：
\[
F_{\text{mag}} = -K(CKa) = -C K^2 a
\]
将其代入力学方程：
\[
m a = F(t) - C K^2 a
\]
把含 \(a\) 项移到左边：
\[
(m + C K^2)a = F(t)
\]
得到
\[
\boxed{a = \frac{F(t)}{m + C K^2}}
\qquad
\boxed{m_{\text{eff}} = m + C K^2}
\]

**结论：电容使系统表现为“附加质量”**，不引入耗散。

---

## A3. 能量与功率（用于 ε/I/P 曲线）

电容能量：
\[
U_C = \frac12 C V_C^2
\]
而 \(V_C=\varepsilon=Kv\)，故
\[
\boxed{U_C = \frac12 C (Kv)^2 = \frac12 C K^2 v^2}
\]
电路功率：
\[
P_C = V_C I = \varepsilon I = (Kv)(CKa)=C K^2 v a
\]
同时
\[
\frac{dU_C}{dt} = \frac{d}{dt}\left(\frac12 C K^2 v^2\right)=C K^2 v a = P_C
\]
自洽。

---

## A4. **递推公式（时间推进）**：场内闭路/场外开路的分段

> 与现有 R2 工程“教学口径”一致：  
> **仅当 `inField && loopClosed` 时施加电磁耦合；否则取 \(I=0\)、\(F_{\text{mag}}=0\)、\(\varepsilon=0\)。**  
> （更物理一致的“电容记忆”见 A6 备注。）

设单步仿真时间步长为 \(\Delta t\)（即 dtSim），且本步内 \(F\) 视作常量。

### A4.1 场内且闭路（耦合有效）
\[
m_{\text{eff}} = m + CK^2
\quad,\quad
a = \frac{F}{m_{\text{eff}}}
\]
匀加速更新：
\[
\boxed{v_{n+1} = v_n + a\Delta t}
\]
\[
\boxed{x_{n+1} = x_n + v_n\Delta t + \tfrac12 a\Delta t^2}
\]

输出量（建议用于曲线/读数）：
\[
\boxed{\varepsilon_n = K v_n}
\quad,\quad
\boxed{I_n = C K a}\ (\text{本步常量})
\]
\[
\boxed{F_{\text{mag},n} = -K I_n}
\quad,\quad
\boxed{P_{C,n} = \varepsilon_n I_n}
\quad,\quad
\boxed{U_{C,n} = \tfrac12 C \varepsilon_n^2}
\]
加速度曲线直接用
\[
\boxed{a_n = a}
\]

### A4.2 场外或开路（耦合无效）
\[
a = \frac{F}{m},\quad I=0,\quad \varepsilon=0,\quad F_{\text{mag}}=0
\]
并仍用匀加速更新 \(x,v\)。

---

## A5. 有界磁场跨界：本步内“先推进-检测-二分定位”

若磁场存在区间 \([x_L,x_R]\)，本步预测 \(x_{n+1}\) 后若发现跨界，则需在 \([0,\Delta t]\) 内找 \(t_*\) 使得
\[
x(t_*) = x_L\ \text{或}\ x_R
\]
电容版场内推进是二次多项式：
\[
x(t)=x_n+v_n t+\tfrac12 a t^2
\]
因此跨界时间 \(t_*\) 可直接解二次方程；也可用你现有的二分法（稳健）。

处理流程（建议）：
1. 先按当前段（场内/场外）推进得到试探 \(x_{n+1}\)
2. 若未跨界：接受
3. 若跨界：解 \(t_*\in(0,\Delta t)\)，先推进到边界，再把剩余 \(\Delta t-t_*\) 切换到另一段继续推进

---

## A6. 物理一致性备注（电容边界“瞬时电流”问题）
理想电容满足 \(q=C\varepsilon\)。若你把 \(B\) 设为硬边界（突然从 \(B\to0\)），则 \(\varepsilon\) 突变会要求 \(q\) 突变，意味着出现不现实的“冲击电流”。工程上常用补丁：
- 给边界做平滑过渡 \(B(x)\) 连续；
- 或串联小电阻 \(R_s\)：\(\varepsilon = IR_s + q/C\)；
- 或引入寄生电感。

你当前“场外视为不工作”的教学口径也可接受，但要在论文/注释中说明简化。

---

# B. 纯电感版（把 R 换成理想电感 Ls）

> 注意：电感符号用 \(L_s\)，避免与滑杆长度 \(\ell\) 混淆。

## B1. 电路方程（严格）

理想电感电压：
\[
V_L = L_s\frac{dI}{dt}
\]
KVL（回路仅电感压降）：
\[
\varepsilon - V_L = 0
\quad\Rightarrow\quad
L_s\frac{dI}{dt} = \varepsilon = Kv
\]
故
\[
\boxed{\dot I = \frac{K}{L_s}v}
\]

与统一力学方程联立：
\[
\boxed{m\dot v = F(t) - K I}
\]

---

## B2. 化为标准振子：引入平衡电流（最干净）

若本段内外力 \(F\) 视为常量，则存在“平衡电流”
\[
I_{\text{eq}} \equiv \frac{F}{K}
\]
定义偏移量
\[
\tilde I \equiv I - I_{\text{eq}}
\]
则力学方程变为：
\[
m\dot v = F - K(\tilde I + I_{\text{eq}})=F-K\tilde I - K\frac{F}{K} = -K\tilde I
\]
即
\[
\boxed{\dot v = -\frac{K}{m}\tilde I}
\]
电路方程保持：
\[
\boxed{\dot{\tilde I}=\dot I=\frac{K}{L_s}v}
\]

对 \(v\) 再求导：
\[
\ddot v = -\frac{K}{m}\dot{\tilde I}
= -\frac{K}{m}\frac{K}{L_s}v
= -\frac{K^2}{mL_s}v
\]
得到简谐：
\[
\boxed{\ddot v + \omega^2 v = 0}
\quad,\quad
\boxed{\omega = \frac{K}{\sqrt{mL_s}}}
\]

---

## B3. 连续时间解析解（便于校验/论文）

设某段起点时刻为 \(t_0\)，初值 \(v(t_0)=v_0\)、\(I(t_0)=I_0\)，则
\[
\tilde I_0 = I_0 - \frac{F}{K}
\]

速度：
\[
\boxed{
v(t)=v_0\cos\bigl(\omega(t-t_0)\bigr)
-\sqrt{\frac{L_s}{m}}\ \tilde I_0\ \sin\bigl(\omega(t-t_0)\bigr)
}
\]

电流：
\[
\boxed{
I(t)=\frac{F}{K}
+\tilde I_0\cos\bigl(\omega(t-t_0)\bigr)
+\sqrt{\frac{m}{L_s}}\,v_0\sin\bigl(\omega(t-t_0)\bigr)
}
\]

> 你手写推导里常见的小坑：  
> \(\dot v(t_0) = (F-KI_0)/m = -(K/m)\tilde I_0\)，不是直接等于 \(F\)。

---

## B4. 能量与功率（用于 ε/I/P 曲线）

电感能量：
\[
\boxed{U_L=\frac12 L_s I^2}
\]
电感吸收功率：
\[
P_L = V_L I = (L_s\dot I)I = \varepsilon I = Kv\,I
\]
磁力做功率：
\[
P_{\text{mag}}=F_{\text{mag}}v = (-KI)v = -Kv\,I = -P_L
\]
自洽（电感储能来自机械）。

---

## B5. **递推公式（时间推进）**：给定 \(\Delta t\) 的闭式更新（推荐用于 Engine）

这是电感版最适合仿真的地方：**不必数值积分 ODE**，直接用旋转更新，稳定且快。

设本步 \([t_n,t_n+\Delta t]\) 内 \(F\) 常量，记
\[
\omega=\frac{K}{\sqrt{mL_s}},\quad
c=\cos(\omega\Delta t),\quad
s=\sin(\omega\Delta t)
\]
并定义本步起点的偏移电流：
\[
\tilde I_n = I_n - \frac{F}{K}
\]

### B5.1 更新 \(v,I\)（核心递推）
\[
\boxed{
v_{n+1}=v_n\,c-\sqrt{\frac{L_s}{m}}\ \tilde I_n\,s
}
\]
\[
\boxed{
I_{n+1}=\frac{F}{K}+\tilde I_n\,c+\sqrt{\frac{m}{L_s}}\ v_n\,s
}
\]

### B5.2 更新位置 \(x\)（同样用解析积分，避免误差累积）
因为
\[
x_{n+1}=x_n+\int_0^{\Delta t} v(t_n+\tau)\,d\tau
\]
而本步内
\[
v(\tau)=v_n\cos(\omega\tau)-\sqrt{\frac{L_s}{m}}\tilde I_n\sin(\omega\tau)
\]
积分得：
\[
\boxed{
x_{n+1}=x_n+\frac{v_n}{\omega}s
-\sqrt{\frac{L_s}{m}}\ \frac{\tilde I_n}{\omega}\ (1-c)
}
\]

### B5.3 输出量（曲线/读数）
\[
\boxed{\varepsilon_n = Kv_n}
\]
\[
\boxed{a_n = \dot v(t_n) = \frac{F-KI_n}{m} = -\frac{K}{m}\tilde I_n}
\]
\[
\boxed{F_{\text{mag},n}=-KI_n}
\quad,\quad
\boxed{P_{L,n}=\varepsilon_n I_n}
\quad,\quad
\boxed{U_{L,n}=\tfrac12 L_s I_n^2}
\]

---

## B6. 场外或开路（与你 R2 口径一致）
当 `~inField || ~loopClosed`：
- 令 \(I=0\)、\(\varepsilon=0\)、\(F_{\text{mag}}=0\)
- 力学退化为 \(m\dot v = F\)，用匀加速更新 \(x,v\)

> 物理一致性提示：理想电感电流不能瞬间变化。若你严格保留电感记忆，就不能在“开路”时硬置 \(I=0\)。  
> 教学简化可以这么做，但论文建议注明“开路相当于断开回路并忽略电感保持电流的过渡过程”。

---

## B7. 有界磁场跨界：电感版的 \(x(t)\) 不是多项式（推荐数值求根）
电感版场内 \(x(t)\) 含 \(\sin,\cos\)，跨界时间 \(t_*\) 一般不再有简单代数解（可写成反三角但分支复杂）。工程上推荐：
1. 用 B5 的解析公式写出“本步任意 \(\tau\in[0,\Delta t]\) 的 \(x(\tau)\)”
2. 若预测跨界，则在 \([0,\Delta t]\) 内对 \(g(\tau)=x(\tau)-x_{\text{bdry}}\) 做二分/牛顿
3. 找到 \(t_*\) 后分段推进（到边界→切换段→推进剩余）

---

# C. 链式法则把“对 t”改为“对 x”的形式（辅助推导/校验）

## C1. 通用换元公式
因 \(\dot x=v\)，所以
\[
\boxed{\frac{d}{dt}=v\frac{d}{dx}}
\]

## C2. 电感版得到的漂亮结果：\(I(x)\) 线性
电感方程：\(L_s\dot I = Kv\)。换元：
\[
L_s\left(v\frac{dI}{dx}\right)=Kv
\]
当 \(v\neq 0\) 可约去 \(v\)：
\[
\boxed{\frac{dI}{dx}=\frac{K}{L_s}}
\Rightarrow
\boxed{I(x)=I_0+\frac{K}{L_s}(x-x_0)}
\]

再把力学方程 \(m\dot v=F-KI(x)\) 换元：
\[
m v\frac{dv}{dx}=F-KI(x)
\]
得到一阶积分（速度平方-位移关系）：
\[
\boxed{
v^2(x)=v_0^2+\frac{2}{m}(F-KI_0)(x-x_0)-\frac{K^2}{mL_s}(x-x_0)^2
}
\]

用途：
- 快速求转向点（令 \(v^2=0\) 解二次方程）
- 用作仿真校验：场内闭路段 \(I\)–\(x\) 应近似直线

---

# D. 定时器仿真中的“递推使用方式”建议（符合你的 speed 语义）

## D1. 渲染 Hz 固定，speed 只改变仿真时间推进
设渲染周期（timer Period）为 \(T_r\)（如 1/30 s），速度倍率为 `speedScale`。

建议每帧推进的“总仿真时间”：
\[
\Delta t_{\text{sim,total}} = T_r \cdot \text{speedScale}
\]

为数值/事件稳定，把它分成 \(N\) 个子步：
\[
\Delta t = \frac{\Delta t_{\text{sim,total}}}{N}
\]
每个子步调用一次 Engine 递推（电容版用 A4；电感版用 B5），并在子步内部处理跨界分段（A5/B7）。

## D2. 曲线最小集合（教学硬性）
每个子步或每帧至少更新/可采样：
- \(|v|(t)\)（这里 \(v\ge0\) 可直接用 \(v\)）
- \(|a|(t)\)（电容：\(a=F/m_{\text{eff}}\)；电感：\(a=(F-KI)/m\)）
并建议同时输出：
- \(\varepsilon(t)=Kv(t)\)
- \(I(t)\)
- 功率 \(P(t)=\varepsilon I\)
- 储能：\(U_C=\frac12C\varepsilon^2\) 或 \(U_L=\frac12L_s I^2\)

## D3. Reset 语义（工程一致性）
重置时至少：
- `speedScale=1×`
- 清空轨迹/曲线历史缓冲
- 状态回到初值（含 \(I_0\)、\(q_0\) 等）

---

# E. 可选扩展：加入串联小电阻 Rs（更物理、更平滑）
若你希望边界处无冲击、且现象更贴近实验，可在电容/电感前串联 \(R_s\)：
- 电容：\(\varepsilon = I R_s + q/C\)
- 电感：\(\varepsilon = I R_s + L_s\dot I\)

这样系统变成一阶/二阶线性系统（可用矩阵指数给出解析递推），也更适合长期演示稳定。

---

## 速查：两种版本的“核心递推”一页总结

### 电容版（场内闭路）
\[
m_{\text{eff}}=m+CK^2,\quad a=\frac{F}{m_{\text{eff}}}
\]
\[
v_{n+1}=v_n+a\Delta t,\quad
x_{n+1}=x_n+v_n\Delta t+\tfrac12 a\Delta t^2
\]
\[
\varepsilon_n=Kv_n,\quad I_n=CKa,\quad P_n=\varepsilon_n I_n
\]

### 电感版（场内闭路、F 常量）
\[
\omega=\frac{K}{\sqrt{mL_s}},\ c=\cos(\omega\Delta t),\ s=\sin(\omega\Delta t),\ 
\tilde I_n=I_n-\frac{F}{K}
\]
\[
v_{n+1}=v_n c-\sqrt{\frac{L_s}{m}}\tilde I_n s
\]
\[
I_{n+1}=\frac{F}{K}+\tilde I_n c+\sqrt{\frac{m}{L_s}}v_n s
\]
\[
x_{n+1}=x_n+\frac{v_n}{\omega}s-\sqrt{\frac{L_s}{m}}\frac{\tilde I_n}{\omega}(1-c)
\]
\[
a_n=\frac{F-KI_n}{m}
\quad,\quad
\varepsilon_n=Kv_n
\quad,\quad
P_n=\varepsilon_n I_n
\]

---

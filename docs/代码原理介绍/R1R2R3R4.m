%% R2/R3/R4 导轨滑杆闭合回路：解析推进与能量推导（可转 MLX）
% 说明：
% - 本 .m 脚本用 %% 分节，适合在 MATLAB 中 "Open as Live Script" 后另存为 .mlx。
% - Live Editor 的 LaTeX 支持是子集：建议用 Insert -> Equation -> LaTeX Equation 插入关键公式。
%
% 本脚本要点：
% 1) 物理模型：ε=BLv, I=ε/R, |Fmag|=k v, 其中 k=B^2 L^2/R
% 2) 动力学：m dv/dt = Fdrive - k v - Ff
% 3) 解析递推（无截断误差）：
%       v_{n+1} = vInf + (v_n - vInf) e^{-αΔt}
%       x_{n+1} = x_n + vInf Δt + (v_n - vInf)(1-e^{-αΔt})/α
% 4) R4 能量核对（一步内解析积分）：
%       W_drive = Fdrive * ∫v dt = Fdrive * Δx
%       E_R     = ∫ I^2 R dt = k ∫ v(t)^2 dt  （闭式）
%       ΔK      = 1/2 m (v_{n+1}^2 - v_n^2)
%       res     = W_drive - E_R - Qf - ΔK  （理想≈0）

%% 0. 清理与参数设置
clear; clc;

% ===== 基本参数（可改）=====
par.B = 0.80;      % 磁场强度（T），可带符号影响 ε 符号
par.L = 0.50;      % 杆长（m）
par.R = 2.0;       % 回路等效电阻（Ω）
par.m = 0.20;      % 质量（kg）

par.Fdrive = 0.60; % 驱动力（N，沿 +x 方向）
par.Ffric  = 0.0;  % 常值摩擦（N，阻碍运动；本脚本视作常量便于解析）

% 初值
x0 = 0.0;
v0 = 0.0;

% 仿真设置
dt   = 0.02;
Tsim = 6.0;
N    = floor(Tsim/dt);

%% 1. 预分配与常量计算
t = (0:N)' * dt;

x = zeros(N+1,1); x(1)=x0;
v = zeros(N+1,1); v(1)=v0;

eps_ = zeros(N+1,1);
I    = zeros(N+1,1);
Fmag = zeros(N+1,1);

P_elec = zeros(N+1,1);
P_mech = zeros(N+1,1);

% 每步"积分能量"（更适合做 R4 验证）
W_drive = zeros(N,1);   % 外力做功（J）
E_R     = zeros(N,1);   % 电阻发热（J）
dK      = zeros(N,1);   % 动能变化（J）
res     = zeros(N,1);   % 能量残差（理想≈0）

% k = B^2 L^2 / R
kcoef = (par.B^2) * (par.L^2) / par.R;

if kcoef < 1e-15
    error('k≈0：可能 B=0 或 R→∞，此时不存在电磁阻尼（R2/R3/R4 不成立）。');
end

% α = k/m, vInf = (Fdrive - Ffric)/k
alpha = kcoef / par.m;
vInf  = (par.Fdrive - par.Ffric) / kcoef;

fprintf('k = %.6g, alpha = %.6g, tau = %.6g s, v_terminal = %.6g m/s\n', ...
    kcoef, alpha, 1/alpha, vInf);

%% 2. 主循环：解析递推（无截断误差）
for n = 1:N
    vn = v(n);
    xn = x(n);

    % e = exp(-alpha*dt)
    e = exp(-alpha*dt);

    % ---- 速度解析递推 ----
    % v_{n+1} = vInf + (vn - vInf) * e
    vnp1 = vInf + (vn - vInf) * e;

    % ---- 位置解析递推 ----
    % x_{n+1} = xn + vInf*dt + (vn - vInf)*(1 - e)/alpha
    dx = vInf*dt + (vn - vInf) * (1 - e) / alpha;
    xnp1 = xn + dx;

    v(n+1) = vnp1;
    x(n+1) = xnp1;

    % ---- 派生物理量（取步末） ----
    % ε = BLv
    eps_(n+1) = par.B * par.L * vnp1;

    % I = ε/R
    I(n+1) = eps_(n+1) / par.R;

    % |Fmag| = k v（方向永远阻碍运动：与 v 反向）
    Fmag(n+1) = kcoef * vnp1;

    % P_elec = I^2 R = k v^2
    P_elec(n+1) = I(n+1)^2 * par.R;

    % P_mech = F v
    P_mech(n+1) = par.Fdrive * vnp1;

    % ---- R4：每步能量核对（解析积分） ----
    % 外力做功：W = Fdrive * ∫v dt = Fdrive * dx
    W = par.Fdrive * dx;

    % 电阻发热：E_R = ∫ I^2 R dt = k ∫ v(t)^2 dt
    % v(t) = A + B e^{-alpha t}, A=vInf, B=(vn - vInf)
    A = vInf;
    B = (vn - vInf);

    % ∫0^dt v^2 dt
    int_v2 = A^2*dt ...
           + 2*A*B*(1 - e)/alpha ...
           + (B^2) * (1 - exp(-2*alpha*dt)) / (2*alpha);

    ER = kcoef * int_v2;

    % 动能变化 ΔK
    dK_step = 0.5*par.m*(vnp1^2 - vn^2);

    % 常值摩擦转热：Qf = Ffric * dx
    Qf = par.Ffric * dx;

    W_drive(n) = W;
    E_R(n)     = ER;
    dK(n)      = dK_step;
    res(n)     = W - ER - Qf - dK_step;
end

fprintf('能量残差 max|res| = %.3g J\n', max(abs(res)));

%% 3. 绘图：v(t), ε(t), I(t), |Fmag|, 功率, 能量残差
figure('Name','R2/R3/R4 解析递推（无截断误差）','Color','w');
tiledlayout(3,2,'Padding','compact','TileSpacing','compact');

% v(t)
nexttile(1);
plot(t, v, 'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('v (m/s)');
title('v(t)（指数趋于终端速度）');
yline(vInf,'--','v_{terminal}','LabelHorizontalAlignment','left');

% ε(t) 与 I(t)
nexttile(2);
plot(t, eps_, 'LineWidth', 1.5); hold on;
plot(t, I,    'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('\epsilon (V) / I (A)');
title('\epsilon(t)=BLv,  I(t)=\epsilon/R');
legend('\epsilon','I','Location','best');

% |Fmag|(t)
nexttile(3);
plot(t, Fmag, 'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('|F_{mag}| (N)');
title('|F_{mag}| = (B^2 L^2 / R) v');

% 瞬时功率对比
nexttile(4);
plot(t, P_mech, 'LineWidth', 1.5); hold on;
plot(t, P_elec, 'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('Power (W)');
title('瞬时功率：P_{mech}=Fv vs P_{elec}=I^2R');
legend('P_{mech}','P_{elec}','Location','best');

% 每步能量：W、E_R、ΔK
nexttile(5);
tt = t(1:end-1);
plot(tt, W_drive, 'LineWidth', 1.5); hold on;
plot(tt, E_R,     'LineWidth', 1.5);
plot(tt, dK,      'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('Energy per step (J)');
title('每步能量：W_{drive}, E_R, \Delta K');
legend('W_{drive}','E_R','\Delta K','Location','best');

% 能量残差
nexttile(6);
plot(tt, res, 'LineWidth', 1.5); grid on;
xlabel('t (s)'); ylabel('res (J)');
title('能量残差：res = W - E_R - Q_f - \Delta K（理想≈0）');

%% 4. 附：瞬态"额外热量"公式（相对稳态基准）
% 定义：
%   Q_transient = lim_{t->∞} [ Q(t) - k vInf^2 t ]
% 解析闭式：
%   Q_transient = m (v0 - vInf) * ( 3/2*vInf + 1/2*v0 )
%
% 注意：这不是"总热量"（总热量随时间线性增长到无穷大）；
% 它表示"达到稳态过程中相对稳态基准多（或少）产生的热"。

Q_transient = par.m * (v0 - vInf) * (1.5*vInf + 0.5*v0);
fprintf('Q_transient (relative to steady) = %.6g J\n', Q_transient);

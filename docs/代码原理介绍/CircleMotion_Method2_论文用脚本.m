%% 匀强磁场圆周运动（方法2：圆心 + 旋转）——论文式“公式 + 代码”脚本
% 说明
% - 本脚本用于把“匀强磁场中的匀速圆周运动”写成论文友好的“公式 + 可运行代码”。
% - 你可以直接运行本脚本生成图像；也可以在 MATLAB 编辑器中选择 “Open as Live Script” 转成 .mlx。
%
% ⚠ 注意：MATLAB Live Editor 的 LaTeX 支持不是完整 LaTeX。
%   尤其矩阵环境不建议使用 \begin{bmatrix}...\end{bmatrix}。
%   更稳妥的是 MATLAB 风格矩阵写法：\matrix{a & b \cr c & d}（官方示例也采用这种写法）。

%% 1. 物理模型（洛伦兹力 + 牛顿第二定律）
% 场景：二维平面内运动的带电粒子，处于垂直纸面的匀强磁场 $B_z$ 中，且 $\mathbf E=0$。
%
% 记位置与速度向量：
%
% $$\mathbf r = \matrix{x \cr y},\quad \mathbf v = \matrix{v_x \cr v_y}$$
%
% 洛伦兹力：
%
% $$\mathbf F = q\,(\mathbf v \times \mathbf B)$$
%
% 牛顿第二定律：
%
% $$m\mathbf a = \mathbf F$$
%
% 在二维情形，磁场沿 z 轴：$\mathbf B=(0,0,B_z)$。磁力始终垂直速度，因此理想情况下 $|\mathbf v|$ 恒定。

%% 2. 角速度与 90° 旋转算子 J
% 定义角速度（带符号，决定旋向）：
%
% $$\omega = \frac{qB_z}{m}$$
%
% 引入二维 90° 旋转算子：
%
% $$J = \matrix{0 & -1 \cr 1 & 0}$$
%
% 它满足：$J\,\matrix{a \cr b}=\matrix{-b \cr a}$。
% 在该模型下，速度的微分方程可以写成：
%
% $$\dot{\mathbf v} = \omega J\mathbf v$$
%
% 因此速度向量会以角速度 $\omega$ 在平面内匀速旋转。

%% 3. 方法2核心：先求圆心，再旋转相对位置
% 设圆心为 $\mathbf r_c$。圆周运动满足“速度 = 角速度 × 半径向量的 90° 旋转”：
%
% $$\mathbf v = \omega J(\mathbf r-\mathbf r_c)$$
%
% 可反解圆心：
%
% $$\mathbf r_c = \mathbf r + \frac{1}{\omega}J\mathbf v$$
%
% 在一步时间 $\Delta t$ 内，转角为 $\theta=\omega\Delta t$，旋转矩阵为：
%
% $$R(\theta)=\matrix{\cos\theta & -\sin\theta \cr \sin\theta & \cos\theta}$$
%
% 速度与位置的一步更新：
%
% $$\mathbf v_{n+1}=R(\theta)\mathbf v_n$$
%
% $$\mathbf r_{n+1}=\mathbf r_c + R(\theta)\bigl(\mathbf r_n-\mathbf r_c\bigr)$$
%
% 该方法的优点：旋转矩阵保持向量长度，因此理论上 $|\mathbf v|$ 不会漂移，轨迹更接近理想圆。

%% 4. MATLAB 实现（可运行）
clear; clc;

% --- 参数（你可自行修改）
q  = 1.0;      % 电荷量（任意单位，只要与 Bz、m 一致）
m  = 2.0;      % 质量
Bz = +1.5;     % 磁场 z 分量（正负决定旋向）
omega = q*Bz/m;

dt   = 0.02;   % 时间步长 Δt
Tsim = 6.0;    % 总仿真时间
N    = floor(Tsim/dt);

% 初始条件
r = [0.0; 0.8]; % 初始位置 [x;y]
v = [0.8; 0.0]; % 初始速度 [vx;vy]

% 记录数组（矩阵存储，MATLAB 友好）
t = (0:N)'*dt;
Rhist = zeros(2, N+1);
Vhist = zeros(2, N+1);
Ahist = zeros(2, N+1);

J = [0 -1; 1 0];
Rhist(:,1) = r;
Vhist(:,1) = v;
Ahist(:,1) = omega*(J*v);

for k = 1:N
    theta = omega*dt;
    Rot = rot2d(theta);

    if abs(omega) < 1e-12
        % ω≈0：退化为匀速直线
        r_next = r + v*dt;
        v_next = v;
    else
        % 圆心：rc = r + (1/ω) J v
        rc = r + (1/omega)*(J*v);

        % 位置：r_{n+1} = rc + R(θ)(r_n-rc)
        r_next = rc + Rot*(r - rc);

        % 速度：v_{n+1} = R(θ) v_n
        v_next = Rot*v;
    end

    r = r_next;
    v = v_next;

    Rhist(:,k+1) = r;
    Vhist(:,k+1) = v;
    Ahist(:,k+1) = omega*(J*v);
end

% 计算 |v|(t) 与 |a|(t)
speed = sqrt(sum(Vhist.^2,1));
acc   = sqrt(sum(Ahist.^2,1));

%% 5. 绘图与自检
figure('Name','方法2：圆心+旋转','Color','w');
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% 轨迹
nexttile(1);
plot(Rhist(1,:), Rhist(2,:), 'LineWidth', 1.5);
grid on; axis equal;
xlabel('x'); ylabel('y');
title('轨迹 r(t)');

% |v|(t)
nexttile(2);
plot(t, speed, 'LineWidth', 1.5);
grid on;
xlabel('t'); ylabel('|v|');
title('|v|(t)');

% |a|(t)
nexttile(3);
plot(t, acc, 'LineWidth', 1.5);
grid on;
xlabel('t'); ylabel('|a|');
title('|a|(t)');

% 速度相图
nexttile(4);
plot(Vhist(1,:), Vhist(2,:), 'LineWidth', 1.5);
grid on; axis equal;
xlabel('v_x'); ylabel('v_y');
title('速度相图 v(t)');

% 控制台自检
fprintf('omega = %.6g\n', omega);
fprintf('|v| 初值=%.6g 末值=%.6g 相对漂移=%.3g\n', speed(1), speed(end), (speed(end)-speed(1))/max(speed(1),eps));

if abs(omega) >= 1e-12
    % 用平均圆心估计半径与圆心漂移（验证“圆心近似恒定”）
    rc_hist = Rhist + (1/omega) * (J*Vhist);
    rc_mean = mean(rc_hist, 2);
    rc_err  = vecnorm(rc_hist - rc_mean, 2, 1);
    radius  = vecnorm(Rhist - rc_mean, 2, 1);

    fprintf('圆心漂移 max|rc-mean(rc)| = %.3g\n', max(rc_err));
    fprintf('半径漂移 max|R-mean(R)|   = %.3g\n', max(abs(radius - mean(radius))));
end

%% 局部函数：二维旋转矩阵
function Rot = rot2d(theta)
% rot2d - 返回二维旋转矩阵
% $$R(\theta)=\matrix{\cos\theta & -\sin\theta \cr \sin\theta & \cos\theta}$$
    c = cos(theta);
    s = sin(theta);
    Rot = [c -s; s c];
end

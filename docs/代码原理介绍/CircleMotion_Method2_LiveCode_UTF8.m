%[text] # 匀强磁场圆周运动（方法2：圆心 + 旋转）
%[text] 本文件是 **MATLAB R2025a+ 支持的“纯文本 Live Code(.m)”** 示例：包含 *公式(LaTeX)* + *可运行代码*。
%[text] 打开方式：在 MATLAB 中双击该文件（默认在 Live Editor 打开）。如需纯文本查看，可右键文件选择 *Open as Text*。
%[text] 保存：可在 Live Editor 中 *Save As* 为 **.mlx**，或继续以 **MATLAB Live Code File (UTF-8) (*.m)** 形式纳入 Git。
%[text] 
%[text] ---
%[text] ## 1 物理模型
%[text] 匀强磁场、无电场：$\mathbf E=0$，磁场沿 $z$ 轴：$\mathbf B=(0,0,B_z)$。
%[text] 洛伦兹力：$\mathbf F=q\,\mathbf v\times\mathbf B$，牛顿第二定律：$m\mathbf a=\mathbf F$。
%[text] 状态向量：$\mathbf r=\matrix{x\cr y}$，$\mathbf v=\matrix{v_x\cr v_y}$。
%[text] 
%[text] ---
%[text] ## 2 90° 旋转算子与角速度
%[text] 用二维 90° 旋转算子 $J$ 表达“切向/法向”关系：
%[text] $J=\matrix{0 & -1 \cr 1 & 0}$。
%[text] 定义角速度（带符号，决定旋向）：$\omega=\dfrac{qB_z}{m}$。
%[text] 则速度微分方程可写为：$\dot{\mathbf v}=\omega J\mathbf v$。
%[text] 
%[text] ---
%[text] ## 3 方法2：先求圆心，再旋转相对位置
%[text] 圆心向量记为 $\mathbf r_c=\matrix{x_c\cr y_c}$。
%[text] 圆周运动满足：$\mathbf v=\omega J(\mathbf r-\mathbf r_c)$。
%[text] 反解得到圆心：$\mathbf r_c=\mathbf r+\dfrac{1}{\omega}J\mathbf v$。
%[text] 
%[text] 一步推进：令 $\theta=\omega\Delta t$，二维旋转矩阵为
%[text] $R(\theta)=\matrix{\cos\theta & -\sin\theta \cr \sin\theta & \cos\theta}$。
%[text] 则位置与速度更新为：
%[text] $\mathbf r_{n+1}=\mathbf r_c+R(\theta)(\mathbf r_n-\mathbf r_c)$，$\mathbf v_{n+1}=R(\theta)\mathbf v_n$。
%[text] 
%[text] **注意（MATLAB 的 LaTeX 兼容性）**：Live Editor 支持“多数 math mode 命令”，但不一定支持 `\begin{bmatrix}...\end{bmatrix}` 这类 AMS 环境；矩阵推荐用 `\matrix{... \cr ...}` 语法（MathWorks 文档示例）。

%% 4 可运行代码（直接运行本节）
% 参数可自由修改。为了突出方法结构，q/m/Bz 使用无量纲示例。

clear; clc;

% -------------------------
% 4.1 参数
% -------------------------
q  = 1.0;    % 电荷量
m  = 2.0;    % 质量
Bz = +1.5;   % 磁场 z 分量（正负决定旋向）

omega = q*Bz/m;   % \omega = qB/m

dt   = 0.02;      % \Delta t
Tsim = 6.0;       % 总时长
N    = floor(Tsim/dt);

% 初始条件
r = [0.0; 0.8];   % r0=[x0;y0]
v = [0.8; 0.0];   % v0=[vx0;vy0]

% -------------------------
% 4.2 预分配（矩阵存储，MATLAB 风格）
% -------------------------
t = (0:N)'*dt;
Rhist = zeros(2, N+1);
Vhist = zeros(2, N+1);
Ahist = zeros(2, N+1);

J = [0 -1; 1 0];  % 90° 旋转算子

Rhist(:,1) = r;
Vhist(:,1) = v;
Ahist(:,1) = omega*(J*v);  % a = \omega J v

% -------------------------
% 4.3 主循环：圆心 + 旋转
% -------------------------
for k = 1:N
    theta = omega*dt;
    Rot = rot2d(theta);

    if abs(omega) < 1e-12
        % \omega \approx 0 时退化为匀速直线
        r_next = r + v*dt;
        v_next = v;
    else
        % 圆心：rc = r + (1/\omega) J v
        rc = r + (1/omega) * (J*v);

        % 位置：r_{n+1} = rc + R(\theta) (r_n - rc)
        r_next = rc + Rot*(r - rc);

        % 速度：v_{n+1} = R(\theta) v_n
        v_next = Rot*v;
    end

    r = r_next;
    v = v_next;

    Rhist(:,k+1) = r;
    Vhist(:,k+1) = v;
    Ahist(:,k+1) = omega*(J*v);
end

%% 5 结果绘图：轨迹 + |v|(t) + |a|(t)

speed = sqrt(sum(Vhist.^2,1));
acc   = sqrt(sum(Ahist.^2,1));

figure('Name','方法2：圆心+旋转','Color','w');
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

nexttile(1);
plot(Rhist(1,:), Rhist(2,:), 'LineWidth', 1.5);
grid on; axis equal;
xlabel('x'); ylabel('y');
title('轨迹 r(t)');

nexttile(2);
plot(t, speed, 'LineWidth', 1.5);
grid on;
xlabel('t'); ylabel('|v|');
title('|v|(t)');

nexttile(3);
plot(t, acc, 'LineWidth', 1.5);
grid on;
xlabel('t'); ylabel('|a|');
title('|a|(t)');

nexttile(4);
plot(Vhist(1,:), Vhist(2,:), 'LineWidth', 1.5);
grid on; axis equal;
xlabel('v_x'); ylabel('v_y');
title('速度相图 v(t)');

%% 6 自检：圆心是否稳定、半径是否稳定、|v| 是否漂移

if abs(omega) >= 1e-12
    % 用 rc = r + (1/\omega) J v 反推圆心并检验是否恒定
    rc_hist = Rhist + (1/omega) * (J*Vhist);
    rc_mean = mean(rc_hist, 2);
    rc_err  = vecnorm(rc_hist - rc_mean, 2, 1);

    radius  = vecnorm(Rhist - rc_mean, 2, 1);

    fprintf('omega = %.6g\n', omega);
    fprintf('|v| 初值=%.6g 末值=%.6g 相对漂移=%.3g\n', speed(1), speed(end), (speed(end)-speed(1))/max(speed(1),eps));
    fprintf('圆心漂移 max|rc-mean(rc)| = %.3g\n', max(rc_err));
    fprintf('半径漂移 max|R-mean(R)|   = %.3g\n', max(abs(radius - mean(radius))));
end

%% 局部函数：二维旋转矩阵
function Rot = rot2d(theta)
    c = cos(theta);
    s = sin(theta);
    Rot = [c, -s; s, c];
end

clc; close all; clear;

% Devre parametreleri
V_in = 60;             % Volt cinsinden giriş gerilimi
R = 3;                 % Ohm cinsinden direnç
L = 28.5e-6;           % Henry cinsinden endüktans
C = 82e-9;             % Farad cinsinden kapasitans
i_t_init = 0;           % Başlangıçtaki bobin akımı (sıfır)
V_c_init = 0;          % Başlangıçtaki kondansatör gerilimi (sıfır)
T_on = 8e-6;           % İlk 8 µs seri RL devresi olarak çalışma süresi
T_off = 8e-6;          % Kondansatör devrede, diyotlu çalışma süresi
T_total = T_on + T_off; % Toplam süre

% Sembolik değişkenleri tanımlayın
syms Vc(t) i_t(t)

% Diferansiyel denklemleri tanımlayın
dVcdt = diff(Vc, t);  % Vc(t)'nin türevi
di_tdt = diff(i_t, t); % i_t(t)'nin türevi

% Zaman aralığını ve grafik için değer dizilerini oluşturun
time_span = linspace(0, T_total, 1000);
V_c_values = zeros(size(time_span));
i_t_values = zeros(size(time_span));

% İlk 8 µs boyunca (seri RL devresi)
sol_rl = dsolve(L * di_tdt == V_in - R * i_t, i_t(0) == i_t_init);

% Zaman aralığında değerleri hesaplayın
for j = 1:length(time_span)
    if time_span(j) <= T_on
        i_t_values(j) = double(subs(sol_rl, t, time_span(j)));
        V_c_values(j) = 0;  % RL devresi sırasında kondansatör gerilimi 0
    end
end

% Seri RLC devresi (kondansatör devrede iken)
i_t_at_end_rl = double(subs(sol_rl, t, T_on)); % RL sonundaki akım
conds_r2 = [i_t(T_on) == i_t_at_end_rl, Vc(T_on) == V_c_init];

% RLC için çözümler
sol_rlc = dsolve([L * di_tdt == V_in - R * i_t - Vc, ...
                  i_t == C * dVcdt, ...
                  conds_r2]);

% Diyot devreye girdiğinde negatif gerilimi engelle
for j = 1:length(time_span)
    if time_span(j) > T_on && time_span(j) <= T_total
        V_c_values(j) = max(0, double(subs(sol_rlc.Vc, t, time_span(j)))); % Diyot nedeniyle negatif olamaz
        i_t_values(j) = double(subs(sol_rlc.i_t, t, time_span(j)));
    end
end

% Kondansatör geriliminin maksimum değerini bul
[max_vc, max_index] = max(V_c_values);
max_time = time_span(max_index);

% Maksimum değerden sonra ilk sıfıra düşme zamanını bul
zero_crossing_index = find(V_c_values(max_index:end) <= 0, 1) + max_index - 1;
zero_crossing_time = time_span(zero_crossing_index);


% Sonuçları grafikte gösterin
figure;

% Bobin Akımı Grafiği
subplot(2, 1, 1);
plot(time_span, i_t_values, 'r', 'DisplayName', 'Bobin Akımı i_t(t)');
xlabel('Zaman (µs)');
ylabel('Akım (A)');
title('Bobin Akımı Zamanla Değişimi');
legend;
grid on;

% 1. Durum: 0-8 µs arası
hold on;
area([0 T_on], [max(i_t_values) max(i_t_values)], 'FaceColor', 'cyan', 'FaceAlpha', 0.5);
text(T_on/2, max(i_t_values) * 0.9, '1. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% 2. Durum: 8 µs ile kondansatörün tekrar 0 olduğu yere kadar
hold on;
area([T_on zero_crossing_time], [max(i_t_values) max(i_t_values)], 'FaceColor', 'magenta', 'FaceAlpha', 0.5);
text((T_on + zero_crossing_time) / 2, max(i_t_values) * 0.9, '2. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% 3. Durum: Kondansatör geriliminin 0 olduğu noktadan 16 µs'ye kadar (yeşil)
hold on;
area([zero_crossing_time T_total], [max(i_t_values) max(i_t_values)], 'FaceColor', 'green', 'FaceAlpha', 0.5);
text((zero_crossing_time + T_total) / 2, max(i_t_values) * 0.9, '3. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

hold off;
legend({'Bobin Akımı i_t(t)', '1. Durum', '2. Durum', '3. Durum'}, 'Location', 'southeast');

subplot(2, 1, 2);
plot(time_span, V_c_values, 'b', 'DisplayName', 'Kondansatör Gerilimi Vc(t)');
xlabel('Zaman (µs)');
ylabel('Gerilim (V)');
title('Kondansatör Gerilimi Zamanla Değişimi');
legend;
grid on;

% 1. Durum: 0-8 µs arası
hold on;
area([0 T_on], [max(V_c_values) max(V_c_values)], 'FaceColor', 'cyan', 'FaceAlpha', 0.5);
text(T_on/2, max(V_c_values) * 0.9, '1. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% 2. Durum: 8 µs ile kondansatörün tekrar 0 olduğu yere kadar
hold on;
area([T_on zero_crossing_time], [max(V_c_values) max(V_c_values)], 'FaceColor', 'magenta', 'FaceAlpha', 0.5);
text((T_on + zero_crossing_time) / 2, max(V_c_values) * 0.9, '2. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% 3. Durum: Kondansatör geriliminin 0 olduğu noktadan 16 µs'ye kadar (yeşil)
hold on;
area([zero_crossing_time T_total], [max(V_c_values) max(V_c_values)], 'FaceColor', 'green', 'FaceAlpha', 0.5);
text((zero_crossing_time + T_total) / 2, max(V_c_values) * 0.9, '3. Durum', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

hold off;
legend({'Kondansatör Gerilimi Vc(t)', '1. Durum', '2. Durum', '3. Durum'}, 'Location', 'southeast');

% Yeni grafiği oluştur
figure;

% Yeni grafikte akım ve gerilimi ayrı eksenlerde göster
yyaxis left; % Soldaki y ekseni için
plot(time_span, i_t_values, 'DisplayName', 'Bobin Akımı i_t(t)');
ylabel('Akım (A)'); % Soldaki y ekseni için etiket
grid on;

% Sağdaki y ekseni için
yyaxis right; % Sağdaki y ekseni için
plot(time_span, V_c_values, 'DisplayName', 'Kondansatör Gerilimi Vc(t)');
ylabel('Gerilim (V)'); % Sağdaki y ekseni için etiket

xlabel('Zaman (µs)');
title('Akım ve Gerilim Zamanla Değişimi (Ayrı Eksenlerde)');
legend('show', 'Location', 'northwest');

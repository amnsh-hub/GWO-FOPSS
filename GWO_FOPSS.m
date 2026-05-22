%% GWO-FOPSS Optimization (Safe Mode)
% تحسين المتغيرات: K, Tw, T1, T2, Alpha
% تم ضبط الحدود لمنع تعليق البرنامج
clc; clear; close all;

% --- 1. إعدادات الخوارزمية ---
SearchAgents_no = 10;   % عدد الذئاب
Max_iter = 20;          % عدد المحاولات
dim = 5;                % عدد المتغيرات: [K, Tw, T1, T2, Alpha]

% --- 2. حدود البحث الآمنة (Safety Bounds) ---
% الترتيب:      [K,   Tw,   T1,    T2,    Alpha]
lb = [1,   3,   0.05, 0.05, 0.3];  % الحد الأدنى (رفعناه لمنع التعليق)
ub = [50,  15,  1.5,  1.5,  0.99];  % الحد الأعلى (منطقي ومستقر)

% --- 3. تهيئة الذئاب ---
Alpha_pos = zeros(1, dim); Alpha_score = inf; 
Beta_pos  = zeros(1, dim); Beta_score  = inf;
Delta_pos = zeros(1, dim); Delta_score = inf;
Positions = initialization(SearchAgents_no, dim, ub, lb);
Convergence_curve = zeros(1, Max_iter);

disp('بدأ تحسين FOPSS بحدود آمنة... الرجاء الانتظار ⏳');

% --- 4. حلقة التكرار الرئيسية ---
for l = 1:Max_iter
    for i = 1:SearchAgents_no
        
        % ضبط الحدود بدقة
        Positions(i,:) = max(Positions(i,:), lb);
        Positions(i,:) = min(Positions(i,:), ub);
        
        % استخراج القيم
        K_val  = Positions(i, 1);
        Tw_val = Positions(i, 2);
        T1_val = Positions(i, 3);
        T2_val = Positions(i, 4);
        alpha_val = Positions(i, 5);
        
        % --- إرسال القيم للسيمولينك ---
        % المتغيرات المباشرة (K, Tw)
        assignin('base', 'K', K_val);
        assignin('base', 'Tw', Tw_val);
        
        % حساب البسط والمقام للـ FOPSS
        % 1. حساب الجزء الكسري (Oustaloup)
        try
            [num_s, den_s] = oustaloup(alpha_val, 1, 0.001, 1000, 5);
            sys_alpha = tf(num_s, den_s);
        catch
            % حماية في حال فشل حساب Oustaloup
            sys_alpha = tf(1, 1); 
        end
        
        % 2. حساب جزء Lead-Lag
        sys_leadlag = tf([T1_val 1], [T2_val 1]);
        
        % 3. دمج النظامين
        sys_combined = sys_leadlag * sys_alpha; 
        [num_temp, den_temp] = tfdata(sys_combined, 'v');
        
        % إرسال المصفوفات للسيمولينك
        assignin('base', 'num_fopss', num_temp);
        assignin('base', 'den_fopss', den_temp);
        
        % --- تشغيل المحاكاة ---
        try
            % ================================================
            % 🔴 ضعي اسم ملف السيمولينك هنا بدقة 🔴
            % تشغيل المحاكاة مع ميزة 'Timeout' لقتل المحاكاة إذا علقت لأكثر من 60 ثانية
           simOut = sim('System_Model2', 'Timeout', 1000);
            % ================================================
            
            % قراءة النتائج (تأكدي من طريقة الخرج لديك)
            % هذا الكود يتوقع وجود To Workspace يحفظ كـ Structure with Time
            % إذا كان يحفظ كـ Array غيري الكود أدناه
            if exist('simOut', 'var')
                 % قراءة البيانات (افترضنا أن المتغير المحفوظ اسمه GWO_Speed)
                 % عدلي السطر التالي حسب اسم المتغير في الـ Workspace بعد التشغيل
                 y_data = simOut.yout{1}.Values.Data; 
                 t_data = simOut.tout;
                 
                 % حساب دالة التكلفة (ITAE)
                 error = abs(y_data);
                 itae = sum(t_data .* error);
                 fitness = itae;
            else
                 fitness = 1e10;
            end
             
        catch
            % في حال علق السيمولينك أو حدث خطأ، نعطي قيمة سيئة جداً ليتجنبها الذئب
            fitness = 1e10;
        end
        
        % تحديث القادة (Alpha, Beta, Delta)
        if fitness < Alpha_score
            Alpha_score = fitness; Alpha_pos = Positions(i,:);
            fprintf('New Best: Cost=%.2f | K=%.2f | Tw=%.2f | Alpha=%.3f\n', fitness, K_val, Tw_val, alpha_val);
        end
        if fitness > Alpha_score && fitness < Beta_score
            Beta_score = fitness; Beta_pos = Positions(i,:);
        end
        if fitness > Alpha_score && fitness > Beta_score && fitness < Delta_score
            Delta_score = fitness; Delta_pos = Positions(i,:);
        end
    end
    
    % معادلات حركة الذئاب (GWO)
    a = 2 - l * ((2) / Max_iter); 
    for i = 1:SearchAgents_no
        for j = 1:dim
            r1 = rand(); r2 = rand();
            A1 = 2*a*r1 - a; C1 = 2*r2;
            D_alpha = abs(C1*Alpha_pos(j) - Positions(i,j));
            X1 = Alpha_pos(j) - A1*D_alpha;
            
            r1 = rand(); r2 = rand();
            A2 = 2*a*r1 - a; C2 = 2*r2;
            D_beta = abs(C2*Beta_pos(j) - Positions(i,j));
            X2 = Beta_pos(j) - A2*D_beta;
            
            r1 = rand(); r2 = rand();
            A3 = 2*a*r1 - a; C3 = 2*r2;
            D_delta = abs(C3*Delta_pos(j) - Positions(i,j));
            X3 = Delta_pos(j) - A3*D_delta;
            
            Positions(i,j) = (X1 + X2 + X3) / 3;
        end
    end
    
    Convergence_curve(l) = Alpha_score;
    fprintf('Iteration %d / %d Completed.\n', l, Max_iter);
end

% --- النتائج النهائية ---
disp('=========================================');
disp('Optimized FOPSS Parameters (Best Solution):');
fprintf('Gain (K):  %.4f\n', Alpha_pos(1));
fprintf('Washout (Tw): %.4f\n', Alpha_pos(2));
fprintf('T1:        %.4f\n', Alpha_pos(3));
fprintf('T2:        %.4f\n', Alpha_pos(4));
fprintf('Alpha:     %.4f\n', Alpha_pos(5));
disp('=========================================');

% تثبيت القيم النهائية في الـ Workspace
assignin('base', 'K', Alpha_pos(1));
assignin('base', 'Tw', Alpha_pos(2));
[num_s, den_s] = oustaloup(Alpha_pos(5), 1, 0.001, 1000, 5);
sys_comb = tf([Alpha_pos(3) 1], [Alpha_pos(4) 1]) * tf(num_s, den_s);
[num_fopss, den_fopss] = tfdata(sys_comb, 'v');
assignin('base', 'num_fopss', num_fopss);
assignin('base', 'den_fopss', den_fopss);

disp('✅ تم حفظ القيم. جاهز للمقارنة!');

% دالة التهيئة
function Positions = initialization(SearchAgents_no, dim, ub, lb)
    Boundary_no = size(ub, 2);
    for i = 1:dim
        Positions(:, i) = rand(SearchAgents_no, 1) .* (ub(i) - lb(i)) + lb(i);
    end
end
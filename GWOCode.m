% -----------------------------------------------------------
% GWO Optimization for FOPSS Controller (4 Parameters)
% Optimized Variables: Kp, T1, T2, Tw
% -----------------------------------------------------------
clear all;
clc;
warning off;

%% 1. إعدادات الخوارزمية
SearchAgents_no = 10;   % عدد الذئاب
Max_iter = 20;          % عدد الجولات
dim = 4;                % أصبح لدينا 4 متغيرات الآن

% حدود البحث [Kp, T1, T2, Tw]
% Tw عادة يكون بين 1 و 20 ثانية

lb = [1,    0.05,  0.01,   5];   % Lower Bounds
% الحدود العليا (Upper Bounds) - نضع سقفاً للذئب لكي لا يتهور
% Kp: نجعله 15 كحد أقصى (لأن 24 سببت مشكلة)
% T1, T2: ثوابت زمنية لا تزيد عادة عن 1 أو 2 ثانية
% Tw: زمن الغسيل عادة بين 5 و 20

ub = [15,   1.0,   0.5,    20];  % Upper Bounds

%% 2. تهيئة المواقع
Alpha_pos = zeros(1,dim); Alpha_score = inf; 
Beta_pos = zeros(1,dim);  Beta_score = inf;
Delta_pos = zeros(1,dim); Delta_score = inf;

Positions = rand(SearchAgents_no, dim) .* (ub - lb) + lb;
Convergence_curve = zeros(1, Max_iter);

disp('Starting GWO Optimization (4 Params)... 🐺');

%% 3. الحلقة الرئيسية
for l = 1:Max_iter
    
    for i = 1:size(Positions,1)
        
        % ضبط الحدود
        Flag4ub = Positions(i,:) > ub;
        Flag4lb = Positions(i,:) < lb;
        Positions(i,:) = (Positions(i,:) .* (~(Flag4ub + Flag4lb))) + ub .* Flag4ub + lb .* Flag4lb;
        
        % استدعاء الموديل وحساب التكلفة
        Current_Cost = Run_Simulink_Model(Positions(i,:));
        
        % تحديث القادة
        if Current_Cost < Alpha_score
            Alpha_score = Current_Cost; 
            Alpha_pos = Positions(i,:);
            fprintf('New Alpha! Cost: %.4f \n', Alpha_score);
        end
        
        if Current_Cost > Alpha_score && Current_Cost < Beta_score
            Beta_score = Current_Cost; 
            Beta_pos = Positions(i,:);
        end
        
        if Current_Cost > Alpha_score && Current_Cost > Beta_score && Current_Cost < Delta_score
            Delta_score = Current_Cost; 
            Delta_pos = Positions(i,:);
        end
    end
    
    % تحديث المواقع (رياضيات GWO)
    a = 2 - l * ((2) / Max_iter); 
    
    for i = 1:size(Positions,1)
        for j = 1:size(Positions,2)
            r1=rand(); r2=rand();
            A1=2*a*r1-a; C1=2*r2;
            D_alpha=abs(C1*Alpha_pos(j)-Positions(i,j));
            X1=Alpha_pos(j)-A1*D_alpha;
            
            r1=rand(); r2=rand();
            A2=2*a*r1-a; C2=2*r2;
            D_beta=abs(C2*Beta_pos(j)-Positions(i,j));
            X2=Beta_pos(j)-A2*D_beta;
            
            r1=rand(); r2=rand();
            A3=2*a*r1-a; C3=2*r2;
            D_delta=abs(C3*Delta_pos(j)-Positions(i,j));
            X3=Delta_pos(j)-A3*D_delta;
            
            Positions(i,j)=(X1+X2+X3)/3;
        end
    end
    
    Convergence_curve(l) = Alpha_score;
    fprintf('Iteration %d completed. Best Cost = %.5f \n', l, Alpha_score);
end

%% 4. النتائج
disp('-----------------------------------------');
disp('Optimization Finished! 🏁');
disp(['Best Kp = ', num2str(Alpha_pos(1))]);
disp(['Best T1 = ', num2str(Alpha_pos(2))]);
disp(['Best T2 = ', num2str(Alpha_pos(3))]);
disp(['Best Tw = ', num2str(Alpha_pos(4))]);  % عرض قيمة Tw

figure;
plot(Convergence_curve, 'LineWidth', 2);
title('Convergence Curve (GWO)');
xlabel('Iteration'); ylabel('ITAE Cost');
grid on;

% --- دالة تشغيل الموديل ---
function cost = Run_Simulink_Model(vars)
    % 1. إرسال المتغيرات من الخوارزمية إلى الموديل
    assignin('base', 'Kp', vars(1));
    assignin('base', 'T1', vars(2));
    assignin('base', 'T2', vars(3));
    assignin('base', 'Tw', vars(4));
    
   
    % --- بداية كود الحماية الجديد ---
    try
        % تشغيل الموديل مع مهلة زمنية (Timeout)
        % إذا استغرقت المحاكاة أكثر من 15 ثانية، سيقوم الماتلاب بإيقافها فوراً
        simOut = sim('System_Model', 'Timeout', 15); 
        
        % استخراج قيمة الخطأ (Cost)
        % هذا السطر يفترض أنك حفظت البيانات في simOut
        cost = simOut.ITAE_Data(end); 
        
    catch
        % إذا حدث تعليق أو خطأ، نعطي قيمة عقابية عالية جداً
        % ليفهم الذئب أن هذه القيم سيئة ويبتعد عنها
        cost = 1000000;
        disp('⚠️ Simulation stuck or failed (Skipping...)');
    end
    % --- نهاية كود الحماية ---
end 
    
   



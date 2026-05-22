function [num, den] = oustaloup(alpha, wb, wl, wh, N)
% OUSTALOUP Fractional Order Approximation
% تقوم هذه الدالة بتحويل s^alpha إلى بسط ومقام (Transfer Function)
% Inputs:
%   alpha: الأس الكسري (Order)
%   wb: تردد الوحدة (عادة 1)
%   wl: أقل تردد (Low Frequency Bound)
%   wh: أعلى تردد (High Frequency Bound)
%   N:  دقة التقريب (Order of Approximation, e.g., 5)

    % التحقق من المدخلات الافتراضية إذا لم يتم إدخالها
    if nargin < 5, N = 5; end
    if nargin < 4, wh = 1000; end
    if nargin < 3, wl = 0.001; end
    if nargin < 2, wb = 1; end
if nargin < 1, alpha = 0.5; end
    % حساب النسبة بين الترددات
    mu = wh / wl;

    % حساب الأصفار (Zeros) والأقطاب (Poles) بشكل تكراري
    % المعادلات القياسية لطريقة Oustaloup Recursive Approximation
    k = -N:N;
    
    % حساب مواقع الأصفار (Zeros)
    w_z = wl * (mu .^ ((k + N + 0.5*(1 - alpha)) / (2*N + 1)));
    
    % حساب مواقع الأقطاب (Poles)
    w_p = wl * (mu .^ ((k + N + 0.5*(1 + alpha)) / (2*N + 1)));

    % تحويل الجذور إلى معاملات معادلة (Polynomials)
    % نضع إشارة سالبة لأن (s + z) تعني الجذر هو -z
    num = poly(-w_z);
    den = poly(-w_p);

    % --- ضبط الكسب (Gain Adjustment) ---
    % هذه الخطوة تضمن أن قيمة المعادلة عند تردد 1 rad/s تساوي 1
    % لكي يكون التأثير فقط في الطور والأس
    
    % نحسب قيمة المعادلة الحالية عند التردد s = j*1
    s_val = 1j * wb; 
    current_response = polyval(num, s_val) / polyval(den, s_val);
    
    % القيمة المطلوبة هي |(j*1)^alpha| = 1^alpha = 1
    desired_response = wb^alpha; 
    
    % معامل التصحيح
    K_adj = abs(desired_response) / abs(current_response);
    
    % ضرب البسط في معامل التصحيح
    num = num * K_adj;

end
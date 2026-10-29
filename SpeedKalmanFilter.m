%% Disclaimer:
% If this code works, good, if not, do not blame LittelMooMoo

function data = SpeedKalmanFilter(t,v)
    data = struct();
    t = t(:);
    v = v(:);
    Hk = [1 0];
    R = 1;
    Q = ones(2,2);
    x_true = zeros(2,1);
    x_before = [0; 0];
    x_after = zeros(2,1);
    P_after = zeros(2,2);
    q = 1;
    for k = 2:length(t)
        Z = v(k);
        dt(k) = t(k) - t(k-1);
        Q = q .* [dt(k).^3./3 dt(k).^2./2;
                 dt(k).^2./2 dt(k)];
        F = [1 dt(k);
                0 1];
        x_before = F * x_after;

        Y = Z - Hk * x_before;

        P_before = F * P_after * F.' + Q;

        S = Hk * P_before * Hk.' + R;
        K = P_before * Hk.'/S;
        x_after = x_before + K * Y;
        P_after = ...
            (eye(2) - K * Hk) * P_before * (eye(2)- K*Hk).'...
            + K * R * K.';
        data.predicted_accel(k) = x_after(2);
        data.filtered_speed(k) = x_after(1);
        q = var(gradient(data.predicted_accel,t(1:k)).*dt(k))/dt(k);
    end
end

 
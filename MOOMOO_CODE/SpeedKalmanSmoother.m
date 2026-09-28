function data = SpeedKalmanSmoother(t, v, q, R)
% SpeedKalmanSmoother estimates speed and acceleration using RTS smoothing.
% t: timestamps (s); v: measured speed (ft/s).
% q: fixed process-noise intensity (ft^2/s^5), default 5.
% R: speed measurement-error variance ((ft/s)^2), default 1.
% Defaults are starting values for testing, not calibrated parameters.
% Assumes the vehicle starts at known rest: speed = acceleration = 0.
% Runs its own forward filter because SpeedKalmanFilter does not return
% the covariance history needed by the backward pass. No files are changed.
% All returned speed and acceleration vectors are columns.
% Example: result = SpeedKalmanSmoother(time, speed_fts, 5, 1);

    if nargin < 3, q = 5; end
    if nargin < 4, R = 1; end
    validateattributes(t, {'numeric'}, {'real', 'finite', 'vector', 'nonempty'});
    validateattributes(v, {'numeric'}, {'real', 'finite', 'vector', 'nonempty'});
    validateattributes(q, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
    validateattributes(R, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
    t = double(t(:));
    v = double(v(:));
    q = double(q);
    R = double(R);
    N = numel(t);
    if N < 2 || numel(v) ~= N
        error('SpeedKalmanSmoother:Size', ...
            'Time and speed must have equal lengths and at least two samples.');
    end
    badInterval = find(diff(t) <= 0, 1);

    % Forward pass: same [speed; acceleration] model, with fixed q and R.
    H = [1 0];
    xFiltered = zeros(2, N);
    PFiltered = zeros(2, 2, N);
    xPredicted = zeros(2, N);
    PPredicted = zeros(2, 2, N);

    for k = 2:N
        dt = t(k) - t(k-1);
        F = [1 dt; 0 1];
        Q = q * [dt^3/3 dt^2/2; dt^2/2 dt];
        xPredicted(:, k) = F * xFiltered(:, k-1);
        PPredicted(:, :, k) = F * PFiltered(:, :, k-1) * F.' + Q;

        P = PPredicted(:, :, k);
        K = P * H.' / (H * P * H.' + R);
        xFiltered(:, k) = xPredicted(:, k) + K * (v(k) - H * xPredicted(:, k));
        A = eye(2) - K * H;
        PFiltered(:, :, k) = A * P * A.' + K * R * K.';
        PFiltered(:, :, k) = (PFiltered(:, :, k) + PFiltered(:, :, k).') / 2;
    end

    % Backward pass: use later information to revise earlier estimates.
    xSmoothed = xFiltered;
    PSmoothed = PFiltered;
    for k = N-1:-1:1
        dt = t(k+1) - t(k);
        F = [1 dt; 0 1];
        C = (PFiltered(:, :, k) * F.') / PPredicted(:, :, k+1);
        xSmoothed(:, k) = xFiltered(:, k) + ...
            C * (xSmoothed(:, k+1) - xPredicted(:, k+1));
        PSmoothed(:, :, k) = PFiltered(:, :, k) + ...
            C * (PSmoothed(:, :, k+1) - PPredicted(:, :, k+1)) * C.';
        PSmoothed(:, :, k) = (PSmoothed(:, :, k) + PSmoothed(:, :, k).') / 2;
    end

    data.Time_sec = t;
    data.filtered_speed = xFiltered(1, :).';
    data.filtered_accel = xFiltered(2, :).';
    data.smoothed_speed = xSmoothed(1, :).';
    data.smoothed_accel = xSmoothed(2, :).';
    data.filtered_covariance = PFiltered;
    data.smoothed_covariance = PSmoothed;
end

%% Print the saved model parameters for the report
% this file only reads the saved predictions; it does not refit or save data;
% run ModelPrediction first only if you want to update the saved models;
source_folder = fileparts(mfilename('fullpath'));
SavedModels = load(fullfile(source_folder, "ModelPredictionData.mat"));
VehicleModels = SavedModels.VehicleModels;
Predictions = SavedModels.Predictions;
Courses = SavedModels.Courses;

fprintf("MODEL PARAMETERS: Jetta and Camry\n");
fprintf("Source: ModelPredictionData.mat\n");
fprintf("tau is time since the start of each phase, in seconds.\n");
fprintf("Coefficients are printed in descending powers of tau.\n");
fprintf("Fuel quantities use US gallons.\n");

%% 1. Mean trial motion coefficients
% these are the saved average fits, including their recorded starting values;
% the course predictions use new starting values, printed in section 5;
fprintf("\na = a1*tau + a0\n");
fprintf("v = v2*tau^2 + v1*tau + v0\n");
fprintf("x = x3*tau^3 + x2*tau^2 + x1*tau + x0\n");
for phase = ["accel", "decel"]
    JettaFit = VehicleModels{1}.fits.(phase);
    CamryFit = VehicleModels{2}.fits.(phase);
    % join the coefficient vectors into columns so matching rows line up;
    values = [JettaFit.fitted_accel_param(:), ...
              CamryFit.fitted_accel_param(:); ...
              JettaFit.fitted_velocity_param(:), ...
              CamryFit.fitted_velocity_param(:); ...
              JettaFit.fitted_position_param(:), ...
              CamryFit.fitted_position_param(:)];
    names = ["a1", "a0", "v2", "v1", "v0", ...
             "x3", "x2", "x1", "x0"];
    units = ["ft/s^3", "ft/s^2", "ft/s^3", "ft/s^2", ...
             "ft/s", "ft/s^3", "ft/s^2", "ft/s", "ft"];
    fprintf("\nMean trial coefficients: %s\n", phase);
    fprintf("%-12s %-12s %14s %14s\n", ...
        "Parameter", "Unit", "Jetta", "Camry");
    for row = 1:numel(names)
        fprintf("%-12s %-12s %14.7g %14.7g\n", ...
            names(row), units(row), values(row,1), values(row,2));
    end
end

%% 2. RPM and fuel rate vs speed coefficients
% these fits use speed u in mph, not ft/s;
fprintf("\nRPM = mR*u + bR; fuel rate = mF*u + bF\n");
for phase = ["accel", "decel"]
    values = [VehicleModels{1}.rpm_param.(phase)(:), ...
              VehicleModels{2}.rpm_param.(phase)(:); ...
              VehicleModels{1}.fuel_rate_param.(phase)(:), ...
              VehicleModels{2}.fuel_rate_param.(phase)(:)];
    names = ["mR", "bR", "mF", "bF"];
    units = ["rpm/mph", "rpm", "(gal/s)/mph", "gal/s"];
    fprintf("\nRPM and fuel coefficients: %s\n", phase);
    fprintf("%-12s %-12s %14s %14s\n", ...
        "Parameter", "Unit", "Jetta", "Camry");
    for row = 1:numel(names)
        fprintf("%-12s %-12s %14.7g %14.7g\n", ...
            names(row), units(row), values(row,1), values(row,2));
    end
end
fprintf("\n%-22s %14s %14s\n", "Other values", "Jetta", "Camry");
fprintf("%-22s %14.7g %14.7g\n", "Idle RPM (rpm)", ...
    VehicleModels{1}.idle_rpm, VehicleModels{2}.idle_rpm);
fprintf("%-22s %14.7g %14.7g\n", "Max measured (mph)", ...
    VehicleModels{1}.max_measured_speed_mph, ...
    VehicleModels{2}.max_measured_speed_mph);
fprintf("RPM is limited below by idle RPM; fuel rate is limited to >= 0.\n");
fprintf("Cruise uses the mean accel/decel fits at the cruise speed.\n");
fprintf("RPM fitting uses speed > 0 and RPM > 0.\n");
fprintf("Fuel fitting uses fuel rate >= 0 only.\n");
fprintf("Before averaging, a trial fuel fit negative at 0 or 25 mph\n");
fprintf("is replaced by its constant phase mean.\n");
fprintf("Idle selections: Jetta initial-idle indices; Camry RPM < 900,\n");
fprintf("including zero readings in the Camry selection.\n");

%% 3. Recorded phase durations and idle motion
% these durations describe the tests, not the predicted course timings;
for car = 1:2
    model = VehicleModels{car};
    fprintf("\n%s: recorded phase durations\n", model.name);
    fprintf("%-12s %12s %12s %10s\n", ...
        "Phase", "Mean (s)", "Max (s)", "Trials");
    for phase = ["idle1", "accel", "decel", "idle2"]
        % a missing phase has no fitted parameters; do not replace it by 0;
        if ~isfield(model.fits, phase)
            fprintf("%-12s %12s\n", phase, "Not recorded");
            continue;
        end
        fit = model.fits.(phase);
        fprintf("%-12s %12.7g %12.7g %10d\n", phase, ...
            fit.duration_sec, fit.max_duration_sec, fit.trial_count);
    end
    fprintf("\n%s: saved idle motion constants\n", model.name);
    fprintf("%-12s %12s %12s %12s\n", ...
        "Phase", "a (ft/s^2)", "v (ft/s)", "x (ft)");
    for phase = ["idle1", "idle2"]
        if ~isfield(model.fits, phase)
            continue;
        end
        fit = model.fits.(phase);
        fprintf("%-12s %12.7g %12.7g %12.7g\n", phase, ...
            fit.fitted_accel_param, fit.fitted_velocity_param, ...
            fit.fitted_position_param);
    end
end

%% 4. Course inputs
fprintf("\n%-8s %14s %14s %14s\n", ...
    "Course", "Distance (ft)", "Target (mph)", "Average (mph)");
for course = 1:numel(Courses)
    target = NaN;
    average = NaN;
    if isfield(Courses{course}, 'target_speed')
        target = Courses{course}.target_speed * 3600 / 5280;
    end
    if isfield(Courses{course}, 'average_speed')
        average = Courses{course}.average_speed * 3600 / 5280;
    end
    fprintf("%-8d %14.7g %14.7g %14.7g\n", course, ...
        Courses{course}.total_distance, target, average);
end
fprintf("NaN here means that the course does not prescribe that value.\n");

%% 5. Course-specific motion coefficients and timings
% each phase resets tau to 0; t_start tells us where it starts on the plot;
% these are the actual reintegrated coefficients used for prediction;
phase_names = ["Accel", "Cruise", "Brake"];
for course = 1:numel(Courses)
    for car = 1:2
        prediction = Predictions{car,course};
        durations = [prediction.accel_time, ...
            prediction.cruise_time, prediction.decel_time];
        start_times = [0, durations(1), sum(durations(1:2))];
        fprintf("\n%s Course %d: time and coefficient tables\n", ...
            VehicleModels{car}.name, course);
        fprintf("%-12s %12s %12s\n", "Phase", "t_start (s)", "Length (s)");
        for phase = 1:3
            if durations(phase) <= 0
                continue;
            end
            fprintf("%-12s %12.7g %12.7g\n", phase_names(phase), ...
                start_times(phase), durations(phase));
            % print each vector separately so the output is not too wide;
            fprintf("  a coefficients (ft/s^2 polynomial): ");
            fprintf("%.7g ", prediction.accel_param{phase});
            fprintf("\n  v coefficients (ft/s polynomial): ");
            fprintf("%.7g ", prediction.velocity_param{phase});
            fprintf("\n  x coefficients (ft polynomial): ");
            fprintf("%.7g ", prediction.position_param{phase});
            fprintf("\n");
        end
        % cruise RPM and fuel rate are constants, so print them separately;
        cruise = prediction.phase == 2;
        if any(cruise)
            first_cruise = find(cruise,1);
            fprintf("Cruise RPM: %.7g rpm; fuel rate: %.7g gal/s\n", ...
                prediction.rpm(first_cruise), ...
                prediction.fuel_rate(first_cruise));
        end
    end
end

%% 6. Shared settings from the current source code
% these settings are copied from ModelPrediction and SpeedKalmanFilter;
% unlike the tables above, they are not stored in ModelPredictionData.mat;
fprintf("\nShared prediction settings\n");
fprintf("Maximum phase sample spacing: 0.05 s\n");
fprintf("Idle RPM display duration: 15 s before each course\n");
fprintf("Course 2 also shows 15 s of final idle RPM.\n");
fprintf("Idle display is excluded from course travel time and fuel totals.\n");
fprintf("Camry gasoline density: 6.17 lb/US gal\n");
fprintf("Speed conversion: 5280/3600 ft/s per mph\n");
fprintf("Root imaginary-part tolerance: 1e-9 s\n");
fprintf("Cruise distance rounding tolerance: 1e-8 ft\n");
fprintf("\nKalman filter settings\n");
fprintf("State = [speed; acceleration]; H = [1 0]\n");
fprintf("Initial state = [0;0]; initial covariance P = zeros(2,2)\n");
fprintf("R = 1 (ft/s)^2; initial q = 1 ft^2/s^5\n");
fprintf("F = [1 dt; 0 1]\n");
fprintf("Q = q*[dt^3/3 dt^2/2; dt^2/2 dt]\n");
fprintf("dt comes from recorded timestamps. q updates after each sample.\n");
fprintf("q_next = var(gradient(a,t).*dt)/dt, using acceleration history.\n");
fprintf("\nMotion section detection settings\n");
fprintf("Idle speed threshold: 0.2 ft/s\n");
fprintf("Positive adjacent speed-change threshold: 0.2 ft/s\n");
fprintf("Extrapolation flag: acceleration duration exceeds the longest\n");
fprintf("recorded accel phase, or speed exceeds the measured maximum.\n");

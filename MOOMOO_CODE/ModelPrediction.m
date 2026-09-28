%% Mean vehicle models: equal weight for each of the three trials
project_folder = fileparts(mfilename('fullpath'));
load(fullfile(project_folder, "DataParser.mat"), ...
    "JettaData", "CamryData", "JettaMotion", "CamryMotion");
display_motion_data = true;
time_step = 0.05; % s, prediction spacing, not OBD sampling frequency
camry_fuel_density_lb_gal = 6.17; % Estimated gasoline density, lb/US gal.
% BOEM Appendix II-C, PDF p. 6; not measured for our test fuel.
% https://www.boem.gov/sites/default/files/documents/renewable-energy/state-activities/Appendix-II-C-Air-EmissionsCalcs.pdf
Data = {JettaData, CamryData};
Motion = {JettaMotion, CamryMotion};
car_names = ["Jetta", "Camry"];
fuel_units = ["gal", "gal"]; % US gallons for both cars.
fuel_fields = ["instantFuelRategals", "fuelrate_lbs"];
VehicleModels = cell(1,2);
Courses = {struct('total_distance',300,'target_speed',15*5280/3600), ...
    struct('total_distance',600,'target_speed',25*5280/3600), ...
    struct('total_distance',5280/4,'average_speed',15*5280/3600), ...
    struct('total_distance',5280/4)};
Predictions = cell(2,4); % Rows: Jetta/Camry; columns: Courses 1-4.

%% Average the saved motion coefficients in local phase time
for car = 1:2
    model = struct('name',car_names(car),'fuel_unit',fuel_units(car));
    for phase = ["idle1", "accel", "decel", "idle2"]
        durations = NaN(3,1);
        for quantity = ["accel", "velocity", "position"]
            field = "fitted_" + quantity + "_param";
            coefficients = [];
            for i = 1:3
                if isfield(Motion{car}{i}.fits, phase)
                    fit = Motion{car}{i}.fits.(phase);
                    coefficients(end+1,:) = fit.(field);
                    durations(i) = fit.duration_sec;
                end
            end
            if ~isempty(coefficients)
                model.fits.(phase).(field) = mean(coefficients,1);
            end
        end
        if any(isfinite(durations))
            model.fits.(phase).duration_sec = mean(durations,'omitnan');
            model.fits.(phase).max_duration_sec = max(durations,[],'omitnan');
            model.fits.(phase).trial_count = nnz(isfinite(durations));
        end
    end

    %% Average each trial's RPM and fuel-rate coefficients
    % Same phase models as before: RPM/fuel rate versus speed in mph.
    for phase = ["accel", "decel"]
        rpm_coefficients = zeros(3,2);
        fuel_coefficients = zeros(3,2);
        for i = 1:3
            index = Motion{car}{i}.fits.(phase).indices;
            speed = Data{car}{i}.VehicleSpeed_MPH(index);
            rpm = Data{car}{i}.EngineRPM_rpm(index);
            fuel = Data{car}{i}.(fuel_fields(car))(index);
            if car == 2
                fuel = fuel / camry_fuel_density_lb_gal; % lb/s to US gal/s
            end
            speed = speed(:);
            rpm = rpm(:);
            fuel = fuel(:);
            valid = isfinite(speed) & speed > 0 & isfinite(rpm) & rpm > 0;
            rpm_coefficients(i,:) = polyfit(speed(valid),rpm(valid),1);
            valid = valid & isfinite(fuel) & fuel >= 0;
            fuel_coefficients(i,:) = polyfit(speed(valid),fuel(valid),1);
            % Retain the previous phase-mean fallback for negative fuel fits.
            if any(polyval(fuel_coefficients(i,:),[0,25]) < 0)
                fuel_coefficients(i,:) = [0,mean(fuel(valid))];
            end
        end
        model.rpm_param.(phase) = mean(rpm_coefficients,1);
        model.fuel_rate_param.(phase) = mean(fuel_coefficients,1);
    end
    model.idle_rpm = 0; % No engine-running floor assumed for Camry.
    if car == 1
        idle_rpm = zeros(3,1);
        for i = 1:3
            valid = Data{car}{i}.VehicleSpeed_MPH == 0 & ...
                isfinite(Data{car}{i}.EngineRPM_rpm) & ...
                Data{car}{i}.EngineRPM_rpm > 0;
            idle_rpm(i) = median(Data{car}{i}.EngineRPM_rpm(valid));
        end
        model.idle_rpm = mean(idle_rpm); % Jetta: engine-running assumption.
    end
    model.max_measured_speed_mph = max([ ...
        max(Data{car}{1}.VehicleSpeed_MPH), ...
        max(Data{car}{2}.VehicleSpeed_MPH), ...
        max(Data{car}{3}.VehicleSpeed_MPH)]);
    VehicleModels{car} = model;
end
JettaModel = VehicleModels{1};
CamryModel = VehicleModels{2};

%% Course timing from the mean acceleration and braking models
% Reintegrate with course initial conditions; do not reuse trial offsets.
% Course 1: accelerate/cruise. Course 2: accelerate/cruise/brake.
% Course 3: accelerate/cruise, 15 mph overall. Course 4: accelerate only.
for car = 1:2
    model = VehicleModels{car};
    for course = 1:4
        distance = Courses{course}.total_distance;
        accel_param = model.fits.accel.fitted_accel_param;
        decel_param = model.fits.decel.fitted_accel_param;
        jerk = accel_param(1);
        initial_accel = accel_param(2);
        velocity_accel = polyint(accel_param,0);
        position_accel = polyint(velocity_accel,0);
        if course <= 2
            target_speed = Courses{course}.target_speed;
            possible_times = roots(velocity_accel - [0,0,target_speed]);
        elseif course == 3
            %% Accelerating-only average check: x(t)/t = 22 ft/s
            average_speed = Courses{course}.average_speed;
            check_times = roots([jerk/6,initial_accel/2,-average_speed]);
            check_times = real(check_times(abs(imag(check_times)) < ...
                1e-9 & real(check_times) > 0));
            average_check = struct('accel_time',NaN,'accel_distance',NaN, ...
                'final_speed_mph',NaN,'within_course_distance',false);
            if ~isempty(check_times)
                average_check.accel_time = min(check_times);
                average_check.accel_distance = polyval( ...
                    position_accel,average_check.accel_time);
                average_check.final_speed_mph = polyval( ...
                    velocity_accel,average_check.accel_time)*3600/5280;
                average_check.within_course_distance = ...
                    average_check.accel_distance <= distance;
            end
            % Full course: x(ta) + v(ta)*(T-ta) = distance, T = 60 s.
            % The acceleration-only average is NOT the full-course average.
            required_time = distance/average_speed;
            possible_times = roots([-jerk/3, ...
                jerk*required_time/2-initial_accel/2, ...
                initial_accel*required_time,-distance]);
        else
            %% Course 4: keep accelerating until x(t) = 1320 ft
            possible_times = roots(position_accel - [0,0,0,distance]);
        end
        valid_times = real(possible_times(abs(imag(possible_times)) < ...
            1e-9 & real(possible_times) > 0));
        if course == 3
            valid_times = valid_times(valid_times <= required_time);
        end
        if isempty(valid_times)
            warning('%s Course %d has no feasible time.',model.name,course);
            continue;
        end
        ta = min(valid_times);
        if course >= 3
            target_speed = polyval(velocity_accel,ta);
        end
        velocity_decel = polyint(decel_param,target_speed);
        position_decel = polyint(velocity_decel,0);
        td = 0;
        if course == 2
            possible_times = roots(velocity_decel);
            valid_times = real(possible_times(abs(imag(possible_times)) < ...
                1e-9 & real(possible_times) > 0));
            if isempty(valid_times)
                warning('%s Course 2 cannot stop with this model.',model.name);
                continue;
            end
            td = min(valid_times);
        end
        da = polyval(position_accel,ta);
        dd = polyval(position_decel,td);
        dc = distance - da - dd;
        if abs(dc) < 1e-8
            dc = 0;
        end
        feasible = dc >= 0 && all(polyval(accel_param,[0,ta]) >= -1e-9);
        if course == 2
            feasible = feasible && all(polyval(decel_param,[0,td]) <= 1e-9);
        end
        if ~feasible
            warning('%s Course %d is not physically feasible.',model.name,course);
            continue;
        end
        tc = dc / target_speed;
        phases = 1:2;
        if course == 2
            phases = 1:3;
        elseif course == 4
            phases = 1; % No cruise or braking in Course 4.
        end

        %% Phase histories: acceleration, cruising, then braking if needed
        % Cruise RPM/fuel is an unvalidated midpoint of the two phase fits.
        target_mph = target_speed * 3600 / 5280;
        rpm_cruise = mean([polyval(model.rpm_param.accel,target_mph), ...
            polyval(model.rpm_param.decel,target_mph)]);
        fuel_cruise = mean([polyval(model.fuel_rate_param.accel,target_mph), ...
            polyval(model.fuel_rate_param.decel,target_mph)]);
        acceleration_params = {accel_param, 0, decel_param};
        rpm_params = {model.rpm_param.accel, [0,rpm_cruise], ...
            model.rpm_param.decel};
        fuel_params = {model.fuel_rate_param.accel, [0,fuel_cruise], ...
            model.fuel_rate_param.decel};
        durations = [ta,tc,td];
        starting_speeds = [0,target_speed,target_speed];
        starting_positions = [0,da,da+dc];
        starting_times = [0,ta,ta+tc];
        predicted = struct('time_sec',[],'position_ft',[], ...
            'speed_fts',[],'accel_fts2',[],'rpm',[],'fuel_rate',[],'phase',[]);
        for phase = phases
            tau = linspace(0,durations(phase), ...
                max(2,ceil(durations(phase)/time_step)+1)).';
            ap = acceleration_params{phase};
            vp = polyint(ap,starting_speeds(phase));
            xp = polyint(vp,starting_positions(phase));
            speed = polyval(vp,tau);
            if phase == 1
                speed(end) = target_speed;
            elseif phase == 3
                speed(end) = 0;
            end
            predicted.time_sec = [predicted.time_sec; starting_times(phase)+tau];
            predicted.position_ft = [predicted.position_ft; polyval(xp,tau)];
            predicted.speed_fts = [predicted.speed_fts; speed];
            predicted.accel_fts2 = [predicted.accel_fts2; polyval(ap,tau)];
            predicted.rpm = [predicted.rpm; max(model.idle_rpm, ...
                polyval(rpm_params{phase},speed*3600/5280))];
            predicted.fuel_rate = [predicted.fuel_rate; max(0, ...
                polyval(fuel_params{phase},speed*3600/5280))];
            predicted.phase = [predicted.phase; phase*ones(size(tau))];
            predicted.accel_param{phase} = ap;
            predicted.velocity_param{phase} = vp;
            predicted.position_param{phase} = xp;
        end
        % Duplicate boundary times show phase jumps; their integration area is 0.
        predicted.fuel_used = cumtrapz(predicted.time_sec,predicted.fuel_rate);
        predicted.fuel_economy = NaN(size(predicted.time_sec));
        valid = predicted.fuel_rate > 0;
        predicted.fuel_economy(valid) = predicted.speed_fts(valid) ./ ...
            (5280*predicted.fuel_rate(valid));
        predicted.economy_unit = "mi/gal";
        predicted.accel_time = ta;
        predicted.cruise_time = tc;
        predicted.decel_time = td;
        predicted.accel_distance = da;
        predicted.cruise_distance = dc;
        predicted.decel_distance = dd;
        predicted.total_travel_time = ta+tc+td;
        predicted.total_fuel = predicted.fuel_used(end);
        predicted.max_accel_fts2 = max(predicted.accel_fts2);
        predicted.final_speed_mph = predicted.speed_fts(end)*3600/5280;
        predicted.average_speed_mph = predicted.position_ft(end) / ...
            predicted.total_travel_time*3600/5280;
        predicted.extrapolated = ta > model.fits.accel.max_duration_sec || ...
            target_mph > model.max_measured_speed_mph;
        if course == 3
            predicted.acceleration_average_check = average_check;
        end
        Predictions{car,course} = predicted;
        if display_motion_data
            fprintf('\n%s Course %d (mean of 3 trials)\n',model.name,course);
            fprintf('Accel / cruise / brake time: %.3f / %.3f / %.3f s\n',ta,tc,td);
            fprintf('Total: %.3f s, %.3f ft, %.6f %s fuel\n', ...
                predicted.total_travel_time,predicted.position_ft(end), ...
                predicted.total_fuel,model.fuel_unit);
            fprintf('Average / final speed: %.3f / %.3f mph\n', ...
                predicted.average_speed_mph,predicted.final_speed_mph);
            fprintf('Maximum acceleration: %.3f ft/s^2\n', ...
                predicted.max_accel_fts2);
            if course == 3
                fprintf('Acceleration-only 15 mph average: %.3f s, %.3f ft\n', ...
                    average_check.accel_time,average_check.accel_distance);
                fprintf('Within 1/4 mile: %d; full-course average uses 60 s.\n', ...
                    average_check.within_course_distance);
            end
        end
        if predicted.extrapolated
            warning('%s Course %d exceeds the test range; not validated.', ...
                model.name,course);
        end
    end
end
JettaPrediction = Predictions(1,:);
CamryPrediction = Predictions(2,:);
% Run ModelPredictionPlotting next to export the graphs. Source MAT is unchanged.




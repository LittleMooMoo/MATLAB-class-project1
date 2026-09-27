% Author: Jiale Jiang
% Editor: Jiale Jiang(self-edited)
clearvars;
load("JettaData.mat");
load("CamryData.mat");

plot_camry_accel = 0;
plot_camry_vel = 0;
plot_camry_filtered_vel = 0;
plot_camry_pos = 0;
plot_camry_rpmtime = 0;
plot_camry_rpmvel = 0;
plot_camry_rpmvel_idle1 = 0;
plot_camry_rpmvel_accel = 0;
plot_camry_rpmvel_decel = 0;
plot_camry_rpmvel_idle2 = 0;
plot_camry_fuelratetime = 0;
plot_camry_fuelused = 0;
export_camry_png = 0; % Save only the Camry plots enabled above.
plot_output_folder = fileparts(mfilename('fullpath'));

plot_jetta_pos = 0;
plot_jetta_vel = 0;
plot_jetta_accel = 0;
plot_jetta_filtered_accel = 0;
plot_jetta_rpmtime = 0;
plot_jetta_rpmvel_idle1 = 0;
plot_jetta_rpmvel_accel = 0;
plot_jetta_rpmvel_decel = 0;
plot_jetta_rpmvel_idle2 = 0;
plot_jetta_fuelratetime = 0;
plot_jetta_fuelused = 0;
% Model and report plots (0 = off, 1 = on).
fit_models = 1;
predict_courses = 1;
plot_jetta_phase_fits = 0;
plot_camry_phase_fits = 0;
plot_jetta_courses = 0;
plot_camry_courses = 0;
save_plot_png = 0;
save_model_results = 0;

%% 1. Data Parsing
% a.
% load data from previously saved workspace
% the data was imported as numerical matrix, following data parsing can
% help our code to be way easier to work with and more human readable;

% b.
% create a cell containing 3 raw data matricies
RawJettaData = {Jetta1, Jetta2, Jetta3};
RawCamryData = {CamryData1 CamryData2 CamryData3};

% create a vector of string names for struct name parsing
newNameJetta = ["Time_sec", "TripDistance_mile", "VehicleSpeed_MPH", ...
    "Acceleration_fts2", "TripFuel_gal", "TotalFuelEcon_MPG", ...
    "InstantFuelEcon_MPG", "EngineRPM_rpm"];
newNameCamry = ["Time_sec","EngineRPM_rpm","VehicleSpeed_MPH",...
    "FuelRate_lb_per_min"];
% c.
% parse raw data into two cells;
JettaData = parsingData(newNameJetta,RawJettaData);
CamryData = parsingData(newNameCamry,RawCamryData);

% unit conversion
JettaData = convertUnits(JettaData);
CamryData = convertUnits(CamryData);
for i = 1:3
    JettaData{i}.trip_distanceft = ...
        JettaData{i}.TripDistance_mile  .* 5280;
    JettaData{i}.instantFuelRategals = ...
        (JettaData{i}.VehicleSpeed_MPH ./ ...
        JettaData{i}.InstantFuelEcon_MPG)./3600;
end


%% 2. Compute Data Sampling Frequency

% a. Frequency calculation
JettaTimeData = cell(1,3);
CamryTimeData = cell(1,3);

for i = 1:3
    JettaTimeData{i} = calculateTimeData(JettaData{i}.Time_sec);
    CamryTimeData{i} = calculateTimeData(CamryData{i}.Time_sec);
end

%% 3. Data Presentation as table output in MATLAB terminal

% a. 2022 Volkswagen Jetta SE;
% Test Procedure: 1)Park at a relatively flat parking lot;
%                 2)Accelerate the car from 0-35 mph;
%                 3)Once reach 35 mph,deccelerate the car to 0 mph safely;

printJettaDataTable(JettaData);
printCamryDataTable(CamryData);
%% 4. Helper Function Declaration

% this function takes in a string vector, and a cell
function parsedData = parsingData(newName,RawData)
    % the parsed data should be a cell too
    parsedData = cell(size(RawData));
    for i = 1:size(RawData,2)
       % the parsed data contains structs, same size as raw data cell
        parsedData{i} = struct();
        % for each element in the name field:
        for j = 1:numel(newName)
            % the chosen named struct object = corresponding raw data
            % column
            parsedData{i}.(newName(j)) = RawData{i}(:, j);
        end
    end
end

% this function calculate the average frequency of the data in each trial
function TimeData = calculateTimeData(timeVector)
    N = numel(timeVector);
    total_time = timeVector(end) - timeVector(1);
    TimeData.aveInterval = total_time/(N-1);
    TimeData.aveFrequency = 1/TimeData.aveInterval;
end

% this function prints 3 tables of data given a data cell containing 3
% trials
function table = printJettaDataTable(Datacell)
    for i = 1:size(Datacell,2)
        fprintf("\nJetta Trial %d\n",i);
        fprintf("%5s %4s %8s %3.5s %13s %7s %5s %5s\n", ...
    "Time(s)", "Speed(mph)", "Accel(ft/s^2)", ...
    "RPM", "TripDist(mi)", "InstMPG","TripFuel","TotalMPG");

        table = [Datacell{i}.Time_sec, Datacell{i}.VehicleSpeed_MPH, ...
                Datacell{i}.Acceleration_fts2, ...
                Datacell{i}.EngineRPM_rpm, ...
                Datacell{i}.TripDistance_mile, ...
                Datacell{i}.InstantFuelEcon_MPG,...
                Datacell{i}.TripFuel_gal,...
                Datacell{i}.TotalFuelEcon_MPG];
        fprintf("%5.3f %8.2f %12.3f %9.1f %10.5f %7.2f " + ...
            "%8.2f %8.2f\n", table.');
    end
end

function table = printCamryDataTable(Datacell)
    for i = 1:size(Datacell,2)
        fprintf("\nCamry Trial %d\n",i);
        fprintf("%5s %12s %12s %12s \n", ...
    "Time(s)","RPM", "Speed(MPH)", "Fuel Rate(lb per min)");

        table = [Datacell{i}.Time_sec,...
                Datacell{i}.EngineRPM_rpm, ...
                Datacell{i}.VehicleSpeed_MPH,...
                Datacell{i}.FuelRate_lb_per_min];
        fprintf("%5.3f %12.2f %12.4f %12.5f\n", table.');
    end
end

% prints the sampling frequency of the 3 trials
fprintf("Average sampling frequency for Jetta trials 1-3:" + ...
    "[%.2f,%.2f,%.2f] Hz\n",[JettaTimeData{1}.aveFrequency,...
    JettaTimeData{2}.aveFrequency,...
    JettaTimeData{3}.aveFrequency]);
 fprintf("Average sampling frequency for Camry trials 1-3:" + ...
    "[%.2f,%.2f,%.2f] Hz\n",[CamryTimeData{1}.aveFrequency,...
    CamryTimeData{2}.aveFrequency,...
    CamryTimeData{3}.aveFrequency]);

% unit conversion function 
function Datacell_unit_converted = convertUnits(Datacell)
    for i = 1:length(Datacell)
        Datacell{i}.speed_fts = ...
            Datacell{i}.VehicleSpeed_MPH .* 5280 ./ 3600;
        if ~isfield(Datacell{i}, 'FuelRate_lb_per_min')
        continue; 
        end
        Datacell{i}.fuelrate_lbs = ...
        Datacell{i}.FuelRate_lb_per_min ./60;
    end
        Datacell_unit_converted = Datacell;
end

%% Calculating acceleration from Camry test data with Kalman Filter
% acceleration calculation and motion detection
JettaMotion = cell(1,3);
CamryMotion = cell(1,3);
for i = 1:3
    filtered_camry_data = ...
        SpeedKalmanFilter(CamryData{i}.Time_sec,...
        CamryData{i}.speed_fts);
    CamryData{i}.filtered_speed = filtered_camry_data.filtered_speed;
    CamryData{i}.filtered_accel = filtered_camry_data.predicted_accel;
    
    CamryData{i}.trip_distanceft = cumtrapz(CamryData{i}.Time_sec,...
        CamryData{i}.speed_fts);
    CamryData{i}.filtered_trip_distnaceft = ...
        cumtrapz(CamryData{i}.Time_sec,...
        CamryData{i}.filtered_speed);
    CamryData{i}.cumulated_fuel_lb = ...
        cumtrapz(CamryData{i}.Time_sec,CamryData{i}.fuelrate_lbs);

    filtered_jetta_data = SpeedKalmanFilter(JettaData{i}.Time_sec,...
        JettaData{i}.speed_fts);

    JettaData{i}.filtered_accel = ...
        filtered_jetta_data.predicted_accel;
    JettaData{i}.filtered_speed = ...
        filtered_jetta_data.filtered_speed;
    JettaMotion{i} = detectMotionSections(JettaData{i}.speed_fts);
    CamryMotion{i} = detectMotionSections(CamryData{i}.speed_fts);
end

%% Plot recorded trials (three trials on each graph)
trial_colors = lines(3);
for i = 1:3
    % Camry: Distance vs time
    if plot_camry_pos
        if i == 1, fig_camry_pos = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_pos); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.trip_distanceft,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Distance vs time'); xlabel('Time (s)'); ylabel('Distance (ft)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_pos,fullfile(plot_output_folder,'CamryAllTrials pos.png'),'Resolution',200);
        end
    end

    % Camry: Speed vs time
    if plot_camry_vel
        if i == 1, fig_camry_vel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_vel); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.speed_fts,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Speed vs time'); xlabel('Time (s)'); ylabel('Speed (ft/s)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_vel,fullfile(plot_output_folder,'CamryAllTrials vel.png'),'Resolution',200);
        end
    end

    % Camry: Kalman acceleration vs time
    if plot_camry_accel
        if i == 1, fig_camry_accel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_accel); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.filtered_accel,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Kalman acceleration vs time'); xlabel('Time (s)'); ylabel('Acceleration (ft/s^2)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_accel,fullfile(plot_output_folder,'CamryAllTrials filtered accel.png'),'Resolution',200);
        end
    end

    % Camry: Kalman speed vs time
    if plot_camry_filtered_vel
        if i == 1, fig_camry_filtered_vel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_filtered_vel); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.filtered_speed,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Kalman speed vs time'); xlabel('Time (s)'); ylabel('Speed (ft/s)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_filtered_vel,fullfile(plot_output_folder,'CamryAllTrials filtered vel.png'),'Resolution',200);
        end
    end

    % Camry: RPM vs time
    if plot_camry_rpmtime
        if i == 1, fig_camry_rpmtime = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmtime); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.EngineRPM_rpm,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: RPM vs time'); xlabel('Time (s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmtime,fullfile(plot_output_folder,'CamryAllTrials rpm time.png'),'Resolution',200);
        end
    end

    % Camry: RPM vs speed
    if plot_camry_rpmvel
        if i == 1, fig_camry_rpmvel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmvel); hold on;
        plot(CamryData{i}.speed_fts,CamryData{i}.EngineRPM_rpm,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmvel,fullfile(plot_output_folder,'CamryAllTrials rpm vel.png'),'Resolution',200);
        end
    end

    % Camry: Initial idle: RPM vs speed
    if plot_camry_rpmvel_idle1
        if i == 1, fig_camry_rpmvel_idle1 = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmvel_idle1); hold on;
        idx = CamryMotion{i}.idle_start_i:CamryMotion{i}.idle_end_i;
        plot(CamryData{i}.speed_fts(idx),CamryData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Initial idle: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmvel_idle1,fullfile(plot_output_folder,'CamryAllTrials rpm vel idle1.png'),'Resolution',200);
        end
    end

    % Camry: Acceleration: RPM vs speed
    if plot_camry_rpmvel_accel
        if i == 1, fig_camry_rpmvel_accel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmvel_accel); hold on;
        idx = CamryMotion{i}.accel_start_i:CamryMotion{i}.accel_end_i;
        plot(CamryData{i}.speed_fts(idx),CamryData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Acceleration: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmvel_accel,fullfile(plot_output_folder,'CamryAllTrials rpm vel accel.png'),'Resolution',200);
        end
    end

    % Camry: Braking: RPM vs speed
    if plot_camry_rpmvel_decel
        if i == 1, fig_camry_rpmvel_decel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmvel_decel); hold on;
        idx = CamryMotion{i}.decel_start_i:numel(CamryData{i}.speed_fts);
        if isfield(CamryMotion{i},'decel_end_i'), idx = CamryMotion{i}.decel_start_i:CamryMotion{i}.decel_end_i; end
        plot(CamryData{i}.speed_fts(idx),CamryData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Braking: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmvel_decel,fullfile(plot_output_folder,'CamryAllTrials rpm vel decel.png'),'Resolution',200);
        end
    end

    % Camry: Final idle: RPM vs speed
    if plot_camry_rpmvel_idle2 && isfield(CamryMotion{i},'second_idle_start_i')
        if i == 1, fig_camry_rpmvel_idle2 = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_rpmvel_idle2); hold on;
        idx = CamryMotion{i}.second_idle_start_i:CamryMotion{i}.second_idle_end_i;
        plot(CamryData{i}.speed_fts(idx),CamryData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Final idle: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_rpmvel_idle2,fullfile(plot_output_folder,'CamryAllTrials rpm vel idle2.png'),'Resolution',200);
        end
    end

    % Camry: Fuel rate vs time
    if plot_camry_fuelratetime
        if i == 1, fig_camry_fuelratetime = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_fuelratetime); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.fuelrate_lbs,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Fuel rate vs time'); xlabel('Time (s)'); ylabel('Fuel rate (lb/s)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_fuelratetime,fullfile(plot_output_folder,'CamryAllTrials fuelrate time.png'),'Resolution',200);
        end
    end

    % Camry: Cumulative fuel vs time
    if plot_camry_fuelused
        if i == 1, fig_camry_fuelused = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_camry_fuelused); hold on;
        plot(CamryData{i}.Time_sec,CamryData{i}.cumulated_fuel_lb,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Camry: Cumulative fuel vs time'); xlabel('Time (s)'); ylabel('Fuel (lb)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png || export_camry_png)
            exportgraphics(fig_camry_fuelused,fullfile(plot_output_folder,'CamryAllTrials cumfuel.png'),'Resolution',200);
        end
    end

    % Jetta: Distance vs time
    if plot_jetta_pos
        if i == 1, fig_jetta_pos = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_pos); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.trip_distanceft - JettaData{i}.trip_distanceft(1),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Distance vs time'); xlabel('Time (s)'); ylabel('Distance (ft)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_pos,fullfile(plot_output_folder,'JettaAllTrials pos.png'),'Resolution',200);
        end
    end

    % Jetta: Speed vs time
    if plot_jetta_vel
        if i == 1, fig_jetta_vel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_vel); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.speed_fts,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Speed vs time'); xlabel('Time (s)'); ylabel('Speed (ft/s)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_vel,fullfile(plot_output_folder,'JettaAllTrials vel.png'),'Resolution',200);
        end
    end

    % Jetta: Logged acceleration vs time
    if plot_jetta_accel
        if i == 1, fig_jetta_accel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_accel); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.Acceleration_fts2,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Logged acceleration vs time'); xlabel('Time (s)'); ylabel('Acceleration (ft/s^2)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_accel,fullfile(plot_output_folder,'JettaAllTrials accel.png'),'Resolution',200);
        end
    end

    % Jetta: Kalman acceleration vs time
    if plot_jetta_filtered_accel
        if i == 1, fig_jetta_filtered_accel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_filtered_accel); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.filtered_accel,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Kalman acceleration vs time'); xlabel('Time (s)'); ylabel('Acceleration (ft/s^2)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_filtered_accel,fullfile(plot_output_folder,'JettaAllTrials filtered accel.png'),'Resolution',200);
        end
    end

    % Jetta: RPM vs time
    if plot_jetta_rpmtime
        if i == 1, fig_jetta_rpmtime = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_rpmtime); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.EngineRPM_rpm,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: RPM vs time'); xlabel('Time (s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_rpmtime,fullfile(plot_output_folder,'JettaAllTrials rpm time.png'),'Resolution',200);
        end
    end

    % Jetta: Initial idle: RPM vs speed
    if plot_jetta_rpmvel_idle1
        if i == 1, fig_jetta_rpmvel_idle1 = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_rpmvel_idle1); hold on;
        idx = JettaMotion{i}.idle_start_i:JettaMotion{i}.idle_end_i;
        plot(JettaData{i}.speed_fts(idx),JettaData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Initial idle: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_rpmvel_idle1,fullfile(plot_output_folder,'JettaAllTrials rpm vel idle1.png'),'Resolution',200);
        end
    end

    % Jetta: Acceleration: RPM vs speed
    if plot_jetta_rpmvel_accel
        if i == 1, fig_jetta_rpmvel_accel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_rpmvel_accel); hold on;
        idx = JettaMotion{i}.accel_start_i:JettaMotion{i}.accel_end_i;
        plot(JettaData{i}.speed_fts(idx),JettaData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Acceleration: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_rpmvel_accel,fullfile(plot_output_folder,'JettaAllTrials rpm vel accel.png'),'Resolution',200);
        end
    end

    % Jetta: Braking: RPM vs speed
    if plot_jetta_rpmvel_decel
        if i == 1, fig_jetta_rpmvel_decel = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_rpmvel_decel); hold on;
        idx = JettaMotion{i}.decel_start_i:numel(JettaData{i}.speed_fts);
        if isfield(JettaMotion{i},'decel_end_i'), idx = JettaMotion{i}.decel_start_i:JettaMotion{i}.decel_end_i; end
        plot(JettaData{i}.speed_fts(idx),JettaData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Braking: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_rpmvel_decel,fullfile(plot_output_folder,'JettaAllTrials rpm vel decel.png'),'Resolution',200);
        end
    end

    % Jetta: Final idle: RPM vs speed
    if plot_jetta_rpmvel_idle2 && isfield(JettaMotion{i},'second_idle_start_i')
        if i == 1, fig_jetta_rpmvel_idle2 = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_rpmvel_idle2); hold on;
        idx = JettaMotion{i}.second_idle_start_i:JettaMotion{i}.second_idle_end_i;
        plot(JettaData{i}.speed_fts(idx),JettaData{i}.EngineRPM_rpm(idx),'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Final idle: RPM vs speed'); xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_rpmvel_idle2,fullfile(plot_output_folder,'JettaAllTrials rpm vel idle2.png'),'Resolution',200);
        end
    end

    % Jetta: Fuel rate vs time
    if plot_jetta_fuelratetime
        if i == 1, fig_jetta_fuelratetime = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_fuelratetime); hold on;
        plot(JettaData{i}.Time_sec,JettaData{i}.instantFuelRategals,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Fuel rate vs time'); xlabel('Time (s)'); ylabel('Fuel rate (gal/s)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_fuelratetime,fullfile(plot_output_folder,'JettaAllTrials fuelrate time.png'),'Resolution',200);
        end
    end

    % Jetta: Cumulative fuel vs time
    if plot_jetta_fuelused
        if i == 1, fig_jetta_fuelused = figure('Color','w','Position',[100 100 650 450]); end
        figure(fig_jetta_fuelused); hold on;
        fuel_used = JettaData{i}.TripFuel_gal;
        first_valid = find(fuel_used>0,1);
        fuel_used = fuel_used - fuel_used(first_valid);
        fuel_used(1:first_valid-1) = NaN;
        plot(JettaData{i}.Time_sec,fuel_used,'.','Color',trial_colors(i,:), ...
            'MarkerSize',6,'DisplayName',sprintf('Trial %d',i));
        title('Jetta: Cumulative fuel vs time'); xlabel('Time (s)'); ylabel('Fuel (gal)');
        set(gca,'FontSize',14); grid on; legend('Location','best');
        if i == 3 && (save_plot_png)
            exportgraphics(fig_jetta_fuelused,fullfile(plot_output_folder,'JettaAllTrials cumfuel.png'),'Resolution',200);
        end
    end

end

%% Fit acceleration, RPM and fuel rate by phase
if fit_models || predict_courses || save_model_results || plot_jetta_phase_fits || plot_camry_phase_fits || ...
        plot_jetta_courses || plot_camry_courses
    [JettaModel,JettaFitData,JettaTrialSummary] = fitCarPhases(JettaData,"Jetta","gal");
    [CamryModel,CamryFitData,CamryTrialSummary] = fitCarPhases(CamryData,"Camry","lb");
    Model = {JettaModel,CamryModel};
    PhaseData = {JettaFitData,CamryFitData};
    TrialSummary = [JettaTrialSummary;CamryTrialSummary];
end

%% Plot phase fits: acceleration, RPM and fuel rate
fit_flags = [plot_jetta_phase_fits,plot_camry_phase_fits];
phase_names = ["Acceleration","Braking"];
for car = 1:2
    if ~fit_flags(car), continue; end
    M = Model{car};
    fig = figure('Color','w','Position',[100 100 1400 1000]);
    for phase = 1:2
        P = PhaseData{car}{phase};
        t_fit = linspace(0,max(P.time),200);
        v_fit = linspace(min(P.speed),max(P.speed),200);
        subplot(3,2,phase); hold on;
        for i = 1:3
            idx = P.trial_id==i;
            plot(P.time(idx),P.accel(idx),'.','Color',trial_colors(i,:), ...
                'DisplayName',sprintf('Trial %d Kalman',i));
        end
        plot(t_fit,M.constant_a(phase)*ones(size(t_fit)),'--','Color',[.5 .5 .5], ...
            'LineWidth',1.5,'DisplayName','Constant mean');
        plot(t_fit,polyval(fliplr(M.motion_param(phase,:)),t_fit),'k', ...
            'LineWidth',1.5,'DisplayName','Linear fit');
        title(phase_names(phase)+" phase: fitted acceleration");
        xlabel('Phase time (s)'); ylabel('Acceleration (ft/s^2)'); grid on; set(gca,'FontSize',14);
        if phase == 1
            legend('Position',[.17 .01 .66 .035],'NumColumns',5,'FontSize',11);
        end

        subplot(3,2,phase+2); hold on;
        for i = 1:3
            idx = P.trial_id==i;
            plot(P.speed(idx),P.rpm(idx),'.','Color',trial_colors(i,:));
        end
        plot(v_fit,polyval(M.rpm_param(phase,:),v_fit),'k','LineWidth',1.5);
        title(phase_names(phase)+" RPM fit");
        xlabel('Speed (ft/s)'); ylabel('Engine speed (rpm)'); grid on; set(gca,'FontSize',14);

        subplot(3,2,phase+4); hold on;
        for i = 1:3
            idx = P.trial_id==i;
            plot(P.speed(idx),P.fuel(idx),'.','Color',trial_colors(i,:));
        end
        plot(v_fit,max(0,polyval(M.fuel_param(phase,:),v_fit)),'k','LineWidth',1.5);
        title(phase_names(phase)+" fuel-rate fit");
        xlabel('Speed (ft/s)'); ylabel("Fuel rate ("+M.fuel_unit+"/s)"); grid on; set(gca,'FontSize',14);
    end
    sgtitle(M.name+" phase models");
    if save_plot_png
        exportgraphics(fig,fullfile(plot_output_folder,M.name+" model fits.png"),'Resolution',200);
    end
end

%% Predict and plot the four courses
if predict_courses || plot_jetta_courses || plot_camry_courses
    [JettaCourses,JettaCourseSummary] = predictCarCourses(JettaModel);
    [CamryCourses,CamryCourseSummary] = predictCarCourses(CamryModel);
    Courses = [JettaCourses;CamryCourses];
    CourseSummary = [JettaCourseSummary;CamryCourseSummary];
    disp(CourseSummary);
    course_flags = [plot_jetta_courses,plot_camry_courses];
    for car = 1:2
        if ~course_flags(car), continue; end
        fig = plotCarCourses(Courses(car,:),Model{car}.name,Model{car}.fuel_unit);
        if save_plot_png
            exportgraphics(fig,fullfile(plot_output_folder,Model{car}.name+" courses.png"),'Resolution',200);
        end
    end
end

%% Save model results only when requested
if save_model_results
    save(fullfile(plot_output_folder,'EQ1_Simple_Results.mat'),'Model','PhaseData','TrialSummary');
    writetable(TrialSummary,fullfile(plot_output_folder,'EQ1_Trial_Summary.csv'));
    if exist('Courses','var')
        save(fullfile(plot_output_folder,'EQ1_Simple_Results.mat'),'Courses','CourseSummary','-append');
        writetable(CourseSummary,fullfile(plot_output_folder,'EQ1_Course_Summary.csv'));
    end
end

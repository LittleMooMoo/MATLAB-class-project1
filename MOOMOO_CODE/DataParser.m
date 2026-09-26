% Author: Jiale Jiang
% Editor: Jiale Jiang(self-edited)
clearvars;
load("JettaData.mat");
load("CamryData.mat");

plot_camry_accel = 0;
plot_camry_vel = 0;
plot_camry_filtered_vel = 0;
plot_camry_pos = 0;

plot_jetta_pos = 0;
plot_jetta_vel = 0;
plot_jetta_accel = 0;
plot_jetta_filtered_accel = 1;
plot_jetta_rpmtime = 0;
plot_jetta_rpmvel_accel = 0;
plot_jetta_rpmvel_decel = 0;
plot_jetta_fuelratetime = 0;
plot_jetta_fuelused = 0;
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

% motion detection
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

    filtered_jetta_data = SpeedKalmanFilter(JettaData{i}.Time_sec,...
        JettaData{i}.speed_fts);

    JettaData{i}.filtered_accel = ...
        filtered_jetta_data.predicted_accel;
    JettaData{i}.filtered_speed = ...
        filtered_jetta_data.filtered_speed;
    JettaMotion{i} = struct();
    CamryMotion{i} = struct();
    JettaMotion{i} = detectMotionSections(JettaData{i}.filtered_accel);
    CamryMotion{i} = detectMotionSections(CamryData{i}.filtered_accel);
end
%% Calculating acceleration from Camry test data with Kalman Filter
% also plot camry test speed data

if plot_camry_accel == true
    for i = 1:3
    camry_accel_title_name = ["Camry Trial 1 Acceleration vs Time",
            "Camry Trial 2 Acceleration vs Time",
            "Camry Trial 3 Acceleration vs Time"];
    subplot(2,2,i);
    plot(CamryData{i}.Time_sec,CamryData{i}.filtered_accel,"o",...
        "MarkerFaceColor","red","MarkerEdgeColor","red","MarkerSize",...
        1.5);
    title(camry_accel_title_name(i));
    xlabel("Time(sec)");
    ylabel("Acceleration(ft/s2)");
    grid on;
    end
end

if plot_camry_vel == true
    for i = 1:3
    camry_accel_title_name = ["Camry Trial 1 Speed vs Time",
            "Camry Trial 2 Speed vs Time",
            "Camry Trial 3 Speed vs Time"];
    subplot(2,2,i);
    plot(CamryData{i}.Time_sec,CamryData{i}.speed_fts,"o",...
        "MarkerFaceColor","m","MarkerEdgeColor","m","MarkerSize",...
        1.0);
    title(camry_accel_title_name(i));
    xlabel("Time(sec)");
    ylabel("Speed(ft/s)");
    grid on;
    end
end

if plot_camry_filtered_vel == true
    for i = 1:3
    camry_filtered_vel_title_name = ...
        ["Camry Trial 1 Filtered Speed vs Time",
            "Camry Trial 2 Filtered Speed vs Time",
            "Camry Trial 3 Filtered Speed vs Time"];
    subplot(2,2,i);
    plot(CamryData{i}.Time_sec,CamryData{i}.filtered_speed,"o",...
        "MarkerFaceColor","m","MarkerEdgeColor","m","MarkerSize",...
        1.0);
    title(camry_filtered_vel_title_name(i));
    xlabel("Time(sec)");
    ylabel("Speed(ft/s)");
    grid on;
    end
end

if plot_camry_pos == true
    for i = 1:3
        camry_pos_title_name = ["Camry Trial 1 Distance vs Time",
            "Camry Trial 2 Distance vs Time",
            "Camry Trial 3 Distance vs Time"];
        subplot(2,2,i);
        plot(CamryData{i}.Time_sec,CamryData{i}.trip_distanceft,"o",...
        "MarkerFaceColor","b","MarkerEdgeColor","b","MarkerSize",...
        0.8);
        title(camry_pos_title_name(i));
        xlabel("Time(sec)");
        ylabel("Distance(ft)");
        grid on;
    end
end

%% plotting motion data from Jetta test
if plot_jetta_pos == true
    for i = 1:3 
        Jetta_pos_titles = ["Jetta Trial 1 Distance vs Time",...
            "Jetta Trial 2 Distance vs Time",...
            "Jetta Trial 3 Distance vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,JettaData{i}.trip_distanceft,...
            "o",...
        "MarkerFaceColor","blue","MarkerEdgeColor","blue","MarkerSize",...
        1.5);
        title(Jetta_pos_titles(i));
        xlabel("Time(sec)");
        ylabel("Distance(ft)");
        grid on;
    end
end

if plot_jetta_vel == true
    for i = 1:3 
        Jetta_vel_titles = ["Jetta Trial 1 Speed vs Time",...
            "Jetta Trial 2 Speed vs Time",...
            "Jetta Trial 3 Speed vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,JettaData{i}.speed_fts,...
            "o",...
        "MarkerFaceColor","m","MarkerEdgeColor","m","MarkerSize",...
        2.0);
        title(Jetta_vel_titles(i));
        xlabel("Time(sec)");
        ylabel("Speed(ft/s)");
        grid on;
    end
end

if plot_jetta_accel == true
    for i = 1:3 
        Jetta_accel_titles = ["Jetta Trial 1 Acceleration vs Time",...
            "Jetta Trial 2 Acceleration vs Time",...
            "Jetta Trial 3 Acceleration vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,JettaData{i}.Acceleration_fts2,...
            "o",...
        "MarkerFaceColor","r","MarkerEdgeColor","r","MarkerSize",...
        3.0);
        title(Jetta_accel_titles(i));
        xlabel("Time(sec)");
        ylabel("Acceleration(ft/s2)");
        grid on;
    end
end

if plot_jetta_filtered_accel == true
    for i = 1:3 
        Jetta_filtered_accel_titles = ...
            ["Jetta Trial 1 Filtered Acceleration vs Time",...
            "Jetta Trial 2 Filtered Acceleration vs Time",...
            "Jetta Trial 3 Filtered Acceleration vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,JettaData{i}.filtered_accel,...
            "o",...
        "MarkerFaceColor","r","MarkerEdgeColor","r","MarkerSize",...
        3.0);
        title( Jetta_filtered_accel_titles(i));
        xlabel("Time(sec)");
        ylabel("Acceleration(ft/s2)");
        grid on;
    end
end

%% Plot Engine/Fuel Data for both vehicle tests
if plot_jetta_rpmtime == true
    for i = 1:3
        Jetta_rpm_time_title = ...
            ["Jetta Trial 1 Engine RPM vs Time",...
            "Jetta Trial 2 Engine RPM vs Time",...
            "Jetta Trial 3 Engine RPM vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,JettaData{i}.EngineRPM_rpm,"o",...
            "MarkerFaceColor","c","MarkerEdgeColor","c",...
            "MarkerSize",3);
        title(Jetta_rpm_time_title(i));
        xlabel("Time(sec)");
        ylabel("Engine RPM(rpm)")
        grid on;
    end
end

if plot_jetta_rpmvel_accel == true
    for i = 1:3
        Jetta_rpm_vel_title = ...
            ["Jetta Trial 1 Engine RPM vs Speed (accel)",...
            "Jetta Trial 2 Engine RPM vs Speed (accel)",...
            "Jetta Trial 3 Engine RPM vs Speed (accel)"];
        subplot(2,2,i);
        plot(JettaData{i}.speed_fts(12:64,1),...
            JettaData{i}.EngineRPM_rpm(12:64,1),"o",...
            "MarkerFaceColor","c","MarkerEdgeColor","c",...
            "MarkerSize",3);
        title(Jetta_rpm_vel_title(i));
        xlabel("Speed(ft/s)");
        ylabel("Engine RPM(rpm)")
        grid on;
    end
end

if plot_jetta_rpmvel_decel == true
    for i = 1:3
        Jetta_rpm_vel_title = ...
            ["Jetta Trial 1 Engine RPM vs Speed (decel)",...
            "Jetta Trial 2 Engine RPM vs Speed (decel)",...
            "Jetta Trial 3 Engine RPM vs Speed (decel)"];
        subplot(2,2,i);
        plot(JettaData{i}.speed_fts,...
            JettaData{i}.EngineRPM_rpm,"o",...
            "MarkerFaceColor","c","MarkerEdgeColor","c",...
            "MarkerSize",3);
        title(Jetta_rpm_vel_title(i));
        xlabel("Speed(ft/s)");
        ylabel("Engine RPM(rpm)")
        grid on;
    end
end

if plot_jetta_fuelratetime == true
    for i = 1:3
        Jetta_fuelratetime_title = ...
            ["Jetta Trial 1 Fuel Rate vs Time",...
            "Jetta Trial 2 Fuel Rate vs Time",...
            "Jetta Trial 3 Fuel Rate vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,...
            JettaData{i}.instantFuelRategals,"o",...
            "MarkerFaceColor","black","MarkerEdgeColor","black",...
            "MarkerSize",3);
        title(Jetta_fuelratetime_title(i));
        xlabel("Time(sec)");
        ylabel("Fuel Rate(gal/sec)")
        grid on;
    end
end

if plot_jetta_fuelused == true
    for i = 1:3
        Jetta_fuelused_title = ...
            ["Jetta Trial 1 Cumulated Fuel Consumption vs Time",...
            "Jetta Trial 2 Cumulated Fuel Consumption vs Time",...
            "Jetta Trial 3 Cumulated Fuel Consumption vs Time"];
        subplot(2,2,i);
        plot(JettaData{i}.Time_sec,...
            JettaData{i}.TripFuel_gal,"o",...
            "MarkerFaceColor","black","MarkerEdgeColor","black",...
            "MarkerSize",3);
        title(Jetta_fuelused_title(i));
        xlabel("Time(sec)");
        ylabel("Cumulated Fuel Consumption(gal)")
        grid on;
    end
end


%%
save("JettaData.mat");
save("CamryData.mat");
% Author: Jiale Jiang
% Editor: Jiale Jiang(self-edited)
%% 1. Data Parsing
% emily happy seeing 
% a.
% load data from previously saved workspace
% the data was imported as numerical matrix, following data parsing can
% help our code to be way easier to work with and more human readable;

load("C:\Users\jiaxi\OneDrive\Documentos\MATLAB\Epic_Quest_1_Data_Import\MOOMOO_CODE\CarOBD2data.mat");
% b.
% create a cell containing 3 raw data matricies
RawJettaData = {Jetta1, Jetta2, Jetta3};

% create a vector of string names for struct name parsing
newNameJetta = ["Time_sec", "TripDistance_mile", "VehicleSpeed_MPH", ...
    "Acceleration_fts2", "TripFuel_gal", "TotalFuelEcon_MPG", ...
    "InstantFuelEcon_MPG", "EngineRPM_rpm"];
% c.
% parse raw data into two cells;
JettaData = parsingData(newNameJetta,RawJettaData);

%% 2. Compute Data Sampling Frequency

% a. Frequency calculation
JettaTimeData = cell(1,3);

for i = 1:3
    JettaTimeData{i} = calculateTimeData(JettaData{i}.Time_sec);
end

%% 3. Data Presentation as table output in MATLAB terminal

% a. 2022 Volkswagen Jetta SE;
% Test Procedure: 1)Park at a relatively flat parking lot;
%                 2)Accelerate the car from 0-35 mph;
%                 3)Once reach 35 mph,deccelerate the car to 0 mph safely;

printJettaDataTable(JettaData);
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

% prints the sampling frequency of the 3 trials
fprintf("Average sampling frequency for Jetta trials 1-3:" + ...
    "[%.2f,%.2f,%.2f] Hz\n",[JettaTimeData{1}.aveFrequency,...
    JettaTimeData{2}.aveFrequency,...
    JettaTimeData{3}.aveFrequency]);
 

%% fit the rpm vs time for jetta 1;
JettaData{1}.idle_rpm_ave = mean(JettaData{1}.EngineRPM_rpm(1:11,1));
fprintf("idle rpm: %.2f\n",JettaData{1}.idle_rpm_ave);

JettaData{1}.non_idle_accel_rpm = ...
    JettaData{1}.EngineRPM_rpm(12:64, 1);
JettaData{1}.non_idle_decel_rpm = ...
    JettaData{1}.EngineRPM_rpm(65:151, 1);

JettaData{1}.non_idle_accel_time = ...
    JettaData{1}.Time_sec(12:64, 1);
JettaData{1}.non_idle_decel_time = ...
    JettaData{1}.Time_sec(65:151, 1);

JettaData{1}.nonIdleAccelRPMvsTimeParam = ...
    polyfit(JettaData{1}.non_idle_accel_time,...
    JettaData{1}.non_idle_accel_rpm,2);
JettaData{1}.nonIdleDecelRPMvsTimeParam = ...
    polyfit(JettaData{1}.non_idle_decel_time,...
    JettaData{1}.non_idle_decel_rpm,2);
JettaData{1}.TotalRPMvsTimeParam = ...
    polyfit(JettaData{1}.Time_sec, ...
        JettaData{1}.EngineRPM_rpm,2);

JettaData{1}.total_idle_time = ...
    JettaData{1}.Time_sec(12) - JettaData{1}.Time_sec(1);
JettaData{1}.total_accel_time = ...
    JettaData{1}.Time_sec(64) - JettaData{1}.Time_sec(1);
JettaData{1}.total_decel_time = ...
    JettaData{1}.Time_sec(151) - JettaData{1}.Time_sec(65);

JettaData{1}.ave_accel = mean(JettaData{1}.Acceleration_fts2(1:64,1));
JettaData{1}.ave_decel = mean(JettaData{1}.Acceleration_fts2(65:151,1));
[JettaData{1}.max_speed, max_index] = ...
    max(JettaData{1}.VehicleSpeed_MPH);
JettaData{1}.time_at_max_speed = JettaData{1}.Time_sec(max_index);

%%
JettaData{1}.ave_fuel_rate = ...
    JettaData{1}.TripFuel_gal(end)/JettaData{1}.TripDistance_mile(end);
fprintf("trip fuel ave: %.8f gal \n",JettaData{1}.ave_fuel_rate);

%%
save("CarOBD2data.mat");
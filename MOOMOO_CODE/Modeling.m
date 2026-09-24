clc
clear

%% Load data
load Toyota_Data\CamryOBD2data.mat

%% 1. Put all 0-35 mph trials into one cell

% Store all five 0-35 mph, 20 Hz trials into one cell array
Camry35 = {x0_35Mph20HzTrial1, ...
           x0_35Mph20HzTrial2, ...
           x0_35Mph20HzTrial3, ...
           x0_35Mph20HzTrial4, ...
           x0_35Mph20HzTrial5};

%% 2. Separate each column into readable variables

% Create an empty cell to store processed data
CamryData = cell(1,length(Camry35));

% For loop repeat the process for each trial
for i = 1:length(Camry35)

    % Store current trial in a temporary variable
    raw = Camry35{i};

    % Column 1 = Time in seconds
    CamryData{i}.Time_sec = raw(:,1);

    % Column 2 = Engine RPM
    CamryData{i}.EngineRPM_rpm = raw(:,2);

    % Column 3 = Vehicle speed in mph
    CamryData{i}.VehicleSpeed_MPH = raw(:,3);

    % Column 4 = Mass air flow in lb/min
    CamryData{i}.MassAirFlow_lbmin = raw(:,4);

    % Column 5 = Fuel rate in lb/min
    CamryData{i}.FuelRate_lbmin = raw(:,5);

end


%% 3. Calculate additional vehicle data

% Repeat calculations for every trial
for i = 1:length(CamryData)

    % Calculate acceleration in mph/s
    % Gradient finds the rate of change of speed over time
    CamryData{i}.Acceleration_MPHs = ...
        gradient(CamryData{i}.VehicleSpeed_MPH, ...
                 CamryData{i}.Time_sec);

    % Calculate total distance traveled in miles
    % Get time data in seconds
    time = CamryData{i}.Time_sec;
    % Get vehicle speed data in MPH
    speed = CamryData{i}.VehicleSpeed_MPH;
    % Find the time difference between each data point
    % Divide by 3600 to convert seconds to hours
    dt = diff(time) / 3600;
    % Calculate the distance traveled during each time interval
    % Distance = Speed x Time
    % Use end-1 because diff(time) will be one less value then time.
    distance_step = speed(1:end-1) .* dt;
    % Add each small distance together to get cumulative distance
    % Start the distance at 0 miles
    CamryData{i}.Distance_mile = [0; cumsum(distance_step)];

    % Convert fuel rate from lb/min to gal/sec
    % Assume gasoline density is about 6.2 lb/gal
    CamryData{i}.FuelRate_galsec = ...
        CamryData{i}.FuelRate_lbmin / 6.2 / 60;

    % Calculate total fuel used in gallons
    % Fuel rate is already in gal/sec and time is in seconds
    CamryData{i}.FuelUsed_gal = ...
        cumtrapz(CamryData{i}.Time_sec, ...
                 CamryData{i}.FuelRate_galsec);
end


%% 4. Display sampling frequency

% Print the average sampling frequency for each trial
for i = 1:length(CamryData)

    N = length(CamryData{i}.Time_sec);

    totalTime = CamryData{i}.Time_sec(end) ...
              - CamryData{i}.Time_sec(1);

    CamryData{i}.SamplingFrequency_Hz = ...
        (N-1)/totalTime;

    fprintf("Trial %d: %.2f Hz\n", ...
        i, CamryData{i}.SamplingFrequency_Hz);

end


%% 5. Plot Position, Velocity, Acceleration vs. Time graphs

figure

subplot(3,1,1)
plot(CamryData{1}.Time_sec, ...
     CamryData{1}.Distance_mile)
xlabel("Time (sec)")
ylabel("Position (mile)")
title("Position vs Time")

subplot(3,1,2)
plot(CamryData{1}.Time_sec, ...
     CamryData{1}.VehicleSpeed_MPH)
xlabel("Time (sec)")
ylabel("Velocity (mph)")
title("Velocity vs Time")

subplot(3,1,3)
plot(CamryData{1}.Time_sec, ...
     CamryData{1}.Acceleration_MPHs)
xlabel("Time (sec)")
ylabel("Acceleration (mph/s)")
title("Acceleration vs Time")

%% 6. Plot RPM vs Time - RPM vs. Speed - fuel consumption vs. Time

figure

subplot(3,1,1)
plot(CamryData{1}.Time_sec, ...
    CamryData{1}.EngineRPM_rpm)
xlabel("Time (sec)")
ylabel("Engine RPM")
title("RPM vs Time")

subplot(3,1,2)
plot(CamryData{1}.VehicleSpeed_MPH, ...
    CamryData{1}.EngineRPM_rpm)
xlabel("Vehicle Speed (mph)")
ylabel("Engine RPM")
title("RPM vs Speed")

subplot(3,1,3)
plot(CamryData{1}.Time_sec, ...
    CamryData{1}.FuelUsed_gal)
xlabel("Time (sec)")
ylabel("Fuel Used (gal)")
title("Fuel Consumption vs Time")

%% 7. Mathematical Models


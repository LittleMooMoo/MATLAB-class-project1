%% Idle Fuel Use
% Plot

% Fuel Use vs Time
% Constant Speed of 20 mph
% Constant Fuel Usage

% Assume fuel use rate while constant speed
t = 0:1:30;                 % seconds
fuel_rate1 = 0.5*ones(size(t));   % gallons/hour
fuel_use1 = fuel_rate1.*t/3600;   % gallons
total_fuel1 = fuel_use1(end);
% Fuel Use Rate vs Time

% Graphs

figure
subplot(3,2,1)
plot(t,fuel_rate1)
xlabel('Time (s)')
ylabel('Fuel Rate Idle (gal/hr)')
title('Fuel Use Rate vs Time')
grid on

% Fuel Used vs Time
subplot(3,2,2)
plot(t,fuel_use1)
xlabel('Time (s)')
ylabel('Fuel Used (gal)')
title('Fuel Used vs Time Idle')
grid on
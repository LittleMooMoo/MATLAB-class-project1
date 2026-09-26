load("JettaData.mat");

time = JettaData{1}.Time_sec;
speed = JettaData{1}.speed_fts;

filtered_data = SpeedKalmanFilter(time,speed);

filtered_filtered_data = ...
    SpeedKalmanFilter(time,filtered_data.predicted_accel);

plot(time,filtered_data.predicted_accel,"o");

hold on;
plot(time,filtered_filtered_data.predicted_accel,"b","LineWidth",2);
grid on;
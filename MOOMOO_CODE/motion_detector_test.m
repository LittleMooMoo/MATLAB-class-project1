load("JettaData.mat");
time = JettaData{3}.Time_sec;
accel = JettaData{3}.filtered_accel;
speed = JettaData{3}.speed_fts;
raw_accel = gradient(speed,time);

indices = detectMotionSections(accel);
result = SpeedKalmanSmoother(time, speed,3, 1);% q = 5, R = 1

plot(time,accel,"r","LineWidth",1);
hold on;

xline(6.99, '--r', 'LineWidth', 1);
yline(0, '--r','LineWidth', 1);

plot(time,speed,"green","LineWidth",1);

plot(time(indices.accel_start_i:indices.accel_end_i),...
    accel(indices.accel_start_i:indices.accel_end_i),"o",...
    "MarkerEdgeColor","c","MarkerFaceColor","c","MarkerSize",2);

plot(time, result.smoothed_accel, 'black', 'LineWidth', 1.5);
plot(time,raw_accel,"m","LineWidth",1);
xlabel('Time (s)');
ylabel('Acceleration (ft/s^2)');
legend('accel',"speed","detected accel",'Backward smoothed');
grid on;
hold off;
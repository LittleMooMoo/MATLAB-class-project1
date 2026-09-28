%% Math modeling 2
function motion = Motion(time,state,a,x0,v0)
    time = time - time(1); % Elapsed time since this segment began
    motion = struct();
    k_rpm = 1; % Estimated model coefficient; units: rpm/ft
    if state == "ACCEL"
        motion.distance = x0 + v0 .* time + ...
            0.5 .* a .* time.^2;
        motion.velocity = v0 + a .* time;
        motion.acceleration = a * ones(size(time));
        motion.rpm = k_rpm .* 5.5.*a .*time.^2 + 888;
    end
     if state == "DECEL"
        motion.distance = x0+v0 .* time - 0.5 .* a .* time.^2;
        motion.velocity = v0 -a .* time;
        motion.acceleration = -a .* ones(size(time));
        motion.rpm = -k_rpm .* 5.5 .*a .*time.^2 + 888;
     end
      if state == "IDLE"
        motion.distance = x0 + zeros(size(time));
        motion.velocity = v0+ zeros(size(time));
        motion.acceleration = zeros(size(time));
        motion.rpm = 0;
      end
      if state == "HOLDSPEED"
        motion.distance = x0 + v0 .* time;
        motion.velocity = v0 .* ones(size(time));
        motion.acceleration = zeros(size(time));
        motion.rpm = 0;
      end
end
dt = 1/10;
const_time = 30;
time_accel = 15;
const_accel = 20/time_accel;
const_speed = 20;
total_fuel = 0.2;
accel_time = 0:dt:time_accel;
accel_fuel_rate = total_fuel/time_accel; %gal/sec

accel_fuel_over_time = total_fuel - total_fuel ...
    .* exp(-accel_fuel_rate .* accel_time);


const_motion_time = 0:dt:const_time;
const_motion = Motion(const_motion_time,"HOLDSPEED",0,const_speed,1);
const_motion.rpm = 888 .* ones(size(const_motion_time));


accel_motion = Motion(accel_time,"ACCEL",const_accel,0,0);

subplot(3,2,1);
plot(const_motion_time,const_motion.distance,"r","LineWidth",1.5);
hold on;
plot(accel_time,accel_motion.distance,"b","LineWidth",1.5);
hold off;

subplot(3,2,2)
plot(const_motion_time,const_motion.rpm,"g","LineWidth",1.5);
hold on;
plot(accel_time,accel_motion.rpm,"m","LineWidth",1.5);
hold off;

subplot(3,2,3);
plot(accel_time,accel_fuel_over_time);


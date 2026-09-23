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
        motion.rpm = k_rpm .* a .*time.^2;
    end
     if state == "DECEL"
        motion.distance = x0+v0 .* time - 0.5 .* a .* time.^2;
        motion.velocity = v0 -a .* time;
        motion.acceleration = -a .* ones(size(time));
        motion.rpm = -k_rpm .* a .*time.^2;
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

const_motion = Motion(const_motion_time,"HOLDSPEED",0,const_speed,1);
const_motion_time = 0:dt:const_time;


accel_motion.accel_time = 0:dt:time_accel;
accel_motion = Motion(accel_motion.accel_time,"ACCEL",const_accel,0,0);

subplot(2,1,1);
plot(const_motion_time,const_motion.distance);
plot(accel_motion.accel_time)
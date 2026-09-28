%% Speed-based motion phases detection function

% Author: Jiale Jiang
% Editor: Jiale Jiang

% assuming accel is already filtered and smooth
function motion_sections = detectMotionSections(speed)
    % set tolderance for judgement
    idle_tolerance = 0.2;
    % idle always starts at the first time stamp;
    motion_sections.idle_start_i = 1;
    % no matter how the car drive, the second idle must end at the end of
    % the motion;
    motion_sections.second_idle_end_i = numel(speed);
    dela_speed_tolerance = 0.2;
    
    %find the peak speed;
    peak_speed = max(speed);
    % find the index of where peak speed happens;
    peak_i = find(speed == peak_speed, 1, 'last');
    % then acceleration ends at the peak speed;
    motion_sections.accel_end_i = peak_i;
    % then after the peak speed, the car start decelerating;
    motion_sections.decel_start_i = peak_i;

    for w = 1:numel(speed)
        % if the speed is small, then the car is idle;
        if abs(speed(w)) >= idle_tolerance
            motion_sections.idle_end_i = w;
            break;
        end
    end
    if motion_sections.idle_end_i == 1
        % if there is no initial idle, then the car is accelerating right
        % at the start;
        motion_sections.idle_end_i = 0;
        motion_sections.accel_start_i = 1;
    else
        for k = motion_sections.idle_end_i:numel(speed)
            delta_speed = speed(k) - speed(k-1);
            % if the positive change in speed is large enough, the car is
            % accelerating;
            if delta_speed >= dela_speed_tolerance
                motion_sections.accel_start_i = k;
                break;
            end
        end
    end
     for n = motion_sections.decel_start_i:numel(speed)
         % if after the car decelerates, the speed drop to near zero, the
         % car stops its deceleration and is idling;
       if abs(speed(n)) < idle_tolerance
            motion_sections.decel_end_i = n;
            motion_sections.second_idle_start_i = n;
            break;
        end
    end
end

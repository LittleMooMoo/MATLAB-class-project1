%% use acceleration sign to find motion sections and its boundary indices
% assuming accel is already filtered and smooth

function motion_sections = detectMotionSections(speed)
    idle_tolerance = 0.05;
    motion_sections.idle_start_i = 1;
    motion_sections.second_idle_end_i = numel(speed);
    dela_speed_tolerance = 0.2;

    peak_speed = max(speed);
    peak_i = find(speed == peak_speed, 1, 'last');
    motion_sections.accel_end_i = peak_i;
    motion_sections.decel_start_i = peak_i;

    for w = 1:numel(speed)
        if abs(speed(w)) >= idle_tolerance
            motion_sections.idle_end_i = w;
            break;
        end
    end
    for k = motion_sections.idle_end_i:numel(speed)
        delta_speed = speed(k) - speed(k-1);
        if delta_speed >= dela_speed_tolerance
            motion_sections.accel_start_i = k;
            break;
        end
    end
     for n = motion_sections.decel_start_i:numel(speed)
       if abs(speed(n)) < idle_tolerance
            motion_sections.decel_end_i = n;
            motion_sections.second_idle_start_i = n;
            break;
        end
    end
end

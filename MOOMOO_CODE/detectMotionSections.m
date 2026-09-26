%% use acceleration sign to find motion sections and its boundary indices
% assuming accel is already filtered and smooth

function motion_sections = detectMotionSections(accel)
    idle_tolerance = 0.1;
    motion_sections.idle_start_i = 1;
     motion_sections.second_idle_end_i = numel(accel);
    for k = 1:numel(accel)
        if accel(k) >= idle_tolerance
            motion_sections.idle_end_i = k;
            motion_sections.accel_start_i = k;
            break;
        end
    end
    for j = motion_sections.accel_start_i:1:numel(accel)
        if accel(j) < idle_tolerance
            motion_sections.accel_end_i = j-1;
            motion_sections.decel_start_i = j;
            break;
        end
    end
     for n = numel(accel):-1:1
       if accel(n) < -idle_tolerance
            motion_sections.decel_end_i = n;
            motion_sections.second_idle_start_i = n+1;
            break;
        end
    end
end

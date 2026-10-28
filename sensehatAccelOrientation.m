function [image_angle, tilt, valid] = ...
    sensehatAccelOrientation(acceleration, reference_angle)
% Returns the image correction and board tilt in degrees.
% Acceleration is [ax ay az] in m/s^2; reference_angle is measured upright.
image_angle = NaN;
tilt = NaN;
valid = false;

if numel(acceleration) ~= 3 || any(~isfinite(acceleration(:)))
    return;
end

magnitude = norm(acceleration);
% Reject near-zero readings and large disturbances; rotate the board slowly.
if magnitude < 0.5 * 9.81 || magnitude > 1.5 * 9.81
    return;
end

ax = acceleration(1);
ay = acceleration(2);
az = acceleration(3);
% Tilt is 0 degrees when flat and 90 degrees when upright.
tilt = atan2d(hypot(ax,ay),abs(az));
% With +Z toward the viewer, this compensates for the board's rotation.
image_angle = mod(atan2d(ay,ax) - reference_angle + 180,360) - 180;
valid = true;
% The angle is not meaningful when flat; the scripts use tilt to ignore it.
end

%% Accelerometer-only image control - Revision 2
% Run one script at a time. Center joystick stops either script.
% First hold the board upright with the image top pointing at the ceiling.
clear mysh rpi;
clc;

ipaddr = "192.168.0.113"; % change to your Pi's current address
image_path = fullfile(fileparts(mfilename('fullpath')), "moomoo.png");

frame_number = 1; % first 8x8 frame in supplied strip; 0 for a normal image

deadzone = 5; % degrees around the initial upright orientation

filter_weight = 0.35;

vertical_limit = 70; % degrees from flat

%% Load image and connect
[original,hatimg] = loadAndConfigureImage(image_path,frame_number);

[rpi,mysh] = senshat_setup(ipaddr);

reoriented_img = hatimg;

displayImage(mysh,hatimg);

%% Measure the reference while upright
fprintf("Hold upright, LEDs facing you, image top toward the ceiling.\n");
fprintf("Keep still. Calibration starts in 3 seconds.\n");
pause(3);
samples = zeros(10,3);
for i = 1:10
    samples(i,:) = readAcceleration(mysh);
    pause(0.05);
end
filtered_accel = mean(samples,1);

tilt = atan2d(hypot(filtered_accel(1),filtered_accel(2)), ...
    abs(filtered_accel(3)));

if any(~isfinite(filtered_accel)) || ...
        norm(filtered_accel) < 0.5*9.81 || ...
        norm(filtered_accel) > 1.5*9.81 || tilt < vertical_limit
    clearLEDMatrix(mysh);
    clear mysh rpi;
    error("Calibration needs a still, upright board. Run again.");
end
ref_angle = atan2d(filtered_accel(2),filtered_accel(1));
was_vertical = true;
fprintf("Ready. Upright: accelerometer. Otherwise: hold image. Center stops.\n");

%% Read the controls and update the display
while true
    command = readJoystick(mysh);
    if command == 1
        break;
    end
    acceleration = readAcceleration(mysh);
    % Ignore invalid readings or strong shaking.
    if any(~isfinite(acceleration)) || ...
            norm(acceleration) < 0.5*9.81 || ...
            norm(acceleration) > 1.5*9.81
        pause(0.1);
        continue;
    end

    % Use current tilt for mode selection; filter only the rotation reading.
    ax = acceleration(1);
    ay = acceleration(2);
    az = acceleration(3);
    tilt = atan2d(hypot(ax,ay),abs(az));
    if tilt >= vertical_limit
        if ~was_vertical
            filtered_accel = acceleration;
        else
            filtered_accel = filter_weight .* acceleration + ...
                (1-filter_weight) .* filtered_accel;
        end
        angle = mod(atan2d(filtered_accel(2),filtered_accel(1)) - ...
            ref_angle + 180,360) - 180;
        if abs(angle) <= deadzone
            angle = 0;
        end
        % Rotate the original image, not the previous rotated frame.
        reoriented_img = rotateImage(hatimg,angle);
    end
    % When not upright, keep the last displayed image; ignore directions.
    was_vertical = tilt >= vertical_limit;
    displayImage(mysh,reoriented_img);
    pause(0.1);
end
clearLEDMatrix(mysh);
clear mysh rpi;

%% Functions
function [rpi,mysh] = senshat_setup(ipaddr)
rpi = raspi(string(ipaddr),'pi','raspberry');
mysh = sensehat(rpi);
clearLEDMatrix(mysh);
end

function [img,hatimg] = loadAndConfigureImage(image_path,frame_number)
[img,~,alpha] = imread(image_path);
if frame_number > 0
    columns = (frame_number-1)*8 + (1:8);
    img = img(:,columns,:);
    if ~isempty(alpha)
        alpha = alpha(:,columns);
    end
end
if size(img,3) == 1
    img = repmat(img,1,1,3);
end
if ~isempty(alpha)
    img = uint8(double(img) .* im2double(alpha));
end
hatimg = imresize(img,[8 8],'nearest');
end

function rotated_img = rotateImage(img,angle)
% Use imrotate when installed; otherwise rotate the 64 pixels directly.
if exist('imrotate','file')
    rotated_img = imrotate(img,angle,'nearest','crop');
    return;
end
rotated_img = zeros(8,8,3,'uint8');
for row = 1:8
    for column = 1:8
        x = column - 4.5;
        y = 4.5 - row;
        source_column = round(cosd(angle)*x + sind(angle)*y + 4.5);
        source_row = round(4.5 + sind(angle)*x - cosd(angle)*y);
        if source_row >= 1 && source_row <= 8 && ...
                source_column >= 1 && source_column <= 8
            rotated_img(row,column,:) = img(source_row,source_column,:);
        end
    end
end
end

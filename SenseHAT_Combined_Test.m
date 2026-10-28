%% Joystick and accelerometer image rotation test
% Flat: joystick rotates/flips. Upright: image top points toward the ceiling.
% Center stops in either mode. Run only one Sense HAT test at a time.
% Reuses senshat_setup, orientImage, sensehatAccelOrientation,
% and rotateSensehatImage. Requires the Raspberry Pi support software.
clear mysh rpi;
ipaddr = "192.168.0.113"; % change to the classroom Pi's current IP address
image_path = fullfile(fileparts(mfilename('fullpath')), "8x8 mage.png");
frame_number = 1; % 1-6 for this sprite strip; use 0 for a regular RGB image
filter_weight = 0.35;
loop_pause = 0.1; % seconds; holding a direction repeats the operation
flat_limit = 20; % degrees from flat
upright_limit = 70;

%% Load one image and keep the manual image separate
[image_data,~,transparency] = imread(image_path);
if ~isa(image_data,'uint8') || size(image_data,3) ~= 3
    error('Use an 8-bit RGB image.');
end
if frame_number > 0
    columns = (frame_number-1)*8 + (1:8);
    image_data = image_data(:,columns,:);
    if ~isempty(transparency)
        transparency = transparency(:,columns);
    end
end
if ~isempty(transparency)
    image_data = uint8(double(image_data) .* im2double(transparency));
end
original_image = imresize(image_data,[8 8],'nearest');
manual_image = original_image;
displayed_image = original_image;
mode = "joystick";

%% Connect and measure the upright reference
[rpi,mysh] = senshat_setup(ipaddr);
displayImage(mysh,original_image);
fprintf('First hold upright, LEDs facing you, HDMI port downward.\n');
fprintf('Keep it still for calibration; sampling begins in 3 seconds.\n');
pause(3);
samples = zeros(10,3);
for i = 1:10
    samples(i,:) = readAcceleration(mysh);
    pause(loop_pause);
end
filtered_accel = mean(samples,1);
reference_angle = atan2d(filtered_accel(2),filtered_accel(1));
[~,tilt,valid] = sensehatAccelOrientation(filtered_accel,reference_angle);
if ~valid || tilt < upright_limit
    clearLEDMatrix(mysh);
    clear mysh rpi;
    error('Calibration needs a still, upright board. Run the script again.');
end
fprintf('Ready. Place flat for joystick control; lift for auto rotation.\n');
fprintf('Left/right rotate; up/down flip vertically; center stops.\n');

%% Select the mode and display the image
while true
    command = readJoystick(mysh);
    if command == 1
        break;
    end

    acceleration = readAcceleration(mysh);
    [~,~,valid] = sensehatAccelOrientation(acceleration,reference_angle);
    if valid
        filtered_accel = filter_weight .* acceleration + ...
            (1-filter_weight) .* filtered_accel;
        [image_angle,tilt,valid] = ...
            sensehatAccelOrientation(filtered_accel,reference_angle);
        if valid
            % Between the limits, keep the previous mode to avoid chatter.
            if tilt <= flat_limit
                mode = "joystick";
            elseif tilt >= upright_limit
                mode = "accelerometer";
            end

            if mode == "joystick"
                manual_image = orientImage(manual_image,command);
                displayed_image = manual_image;
            else
                % Auto mode ignores directions and uses the original image.
                displayed_image = ...
                    rotateSensehatImage(original_image,image_angle);
            end
        end
    end
    displayImage(mysh,displayed_image);
    pause(loop_pause);
end

clearLEDMatrix(mysh);
clear mysh rpi;

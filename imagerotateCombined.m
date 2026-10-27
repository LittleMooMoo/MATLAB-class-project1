% This code combines the accelerometer and the joystick to control
ipaddr = "192.168.0.113";
image_path = ...
    "C:\Users\engr11-2107\Downloads\MATLAB-class-project1-main/mmmoo.png";

[rpi,mysh]=senshat_setup(ipaddr);

[original,hatimg] = loadAndConfigureImage(image_path);

command = readJoystick(mysh);

B = readMagneticField(mysh);

initialAngle = atan2d(B(2),B(1));
displayImage(mysh,hatimg);

while command ~= 1
    command = readJoystick(mysh);
    B = readMagneticField(mysh);
    fieldAngle = atan2d(B(2),B(1));
    % Relative board rotation, wrapped to [-180,180)
    yaw = mod(initialAngle - fieldAngle + 180,360) - 180;

    T = table(fieldAngle,yaw,'VariableNames',...
        {'current angle','wrapped angle'});

    rotated_img = imrotate(hatimg,yaw,'nearest','crop');

    reoriented_img = orientImage(rotated_img,command);

    displayImage(mysh,reoriented_img);
    pause(0.1);
end

clearLEDMatrix(mysh);

function [rpi,mysh] = senshat_setup(ipaddr)
fprintf("connecting to raspberry pi with with ip adress: %s" ...
    ,string(ipaddr));
rpi = raspi(string(ipaddr),'pi','raspberry'); 
mysh = sensehat(rpi); 
clearLEDMatrix(mysh);
end


function hatImage = orientImage(hatImage,command)
switch command
    case 2
        hatImage = rot90(hatImage,1);   % counterclockwise
    case 3
        hatImage = flipud(hatImage); 
    case 4 
        hatImage = rot90(hatImage,-1);  % clockwise
    case 5 
        hatImage = flipud(hatImage); 
end
end

function [img,hatimg] = loadAndConfigureImage(image_file_path)
img = imread(image_file_path);
hatimg = imresize(img,[8 8],'nearest');
end


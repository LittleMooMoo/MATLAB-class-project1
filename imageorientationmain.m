%% Rpi code 
% initially, clc and clear to clear all the previous rpi and sensehat
% object in case we encounter duplicate connection error;
clc;
clear;
% declare the ip address as a string;
ipaddr = "192.168.0.113";
% declare file path for the image as a string;
image_path = ...
    "C:\Users\engr11-2107\Downloads\MATLAB-class-project1-main/mmmoo.png";
% sensehat_setup(ip adress will call the 
% rpi = raspi(string(ipaddr),'pi','raspberry') 
% mysh = sensehat(rpi) to set up the rpi and sensehat device, it will
% return the device object in an array in order of [rpi, mysh];
[rpi,mysh]=senshat_setup(ipaddr);
% the loadAndConfigureImage(image_path) calls the following functions:
% img = imread(image_file_path); reads and loads the image from the image
% from the file path, and store the image as an array;
% hatimg = imresize(img,[8 8],'nearest'); resize the original image array
% ino 8 by 8 by 3 array to be compatible for sensehat image display;
[original,hatimg] = loadAndConfigureImage(image_path);
% read the command initially, and initiate the command as a numerical value
% that we can use to control the image orientation;
command = readJoystick(mysh);
% the while loop keep running until the command reads 1;
while command ~= 1
    % orientImage uses switch to decide how to orient the image array:
    % switch command
%         case 2
%             hatImage = rot90(hatImage,1);   rotate counterclockwise
%         case 3
%             hatImage = flipud(hatImage); flip the image array vertically 
%         case 4 
%             hatImage = rot90(hatImage,-1);  rotate clockwise
%         case 5 
%             hatImage = flipud(hatImage); 
%     end
    hatimg = orientImage(hatimg,command);
    % read the command again in the while loop so that as long as the user
    % doesn't press down the joystick to exit the while loop, the command
    % will be refreshed every loop and the image array orientation will be
    % changed accordingly;
    command = readJoystick(mysh);
    % this function will display the corresponding image array to the
    % sensehat device on its 8 by 8 led matrix;
    displayImage(mysh,hatimg);
    % we chose to pause the while loop for 0.05 sec each loop so that the
    % joystick do not become over-responsive during user interaction;
    pause(0.1);
end
% once the while loop is exited, clear the led matrix display on the
% sensehat and end the entire control program;
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


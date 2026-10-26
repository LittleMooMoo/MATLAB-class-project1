function rotateRPIimageJoyStick() %#codegen

    % This program displays an image on the RPi sense hat and allows
    % the user to rotate it clockwise and anti-clockwise, and flip it
    % vertically. 
    %
    % The joy stick controls the image as follows (referenced with respect
    % to the HDMI port being down):
    %
    %     Not pressed   - do nothing
    %     Center        - (pressed down) end the application
    %     Right         - rotate image clockwise (hold to continue)    
    %     Left          - rotate image anticlockwise (hold to continue)
    %     Up            - flip image vertically (hold to continue)
    %     Down          - flip image vertically (hold to continue)
    % debug variable - set to true to enable output
    % to help with debug
    debug = false;

    % create raspberry pi and sense hat objects
    %rpi = raspi;
    
    % commented out code below is for use with MATLAB but does
    % not deploy since imread is not available for deployment
    %img = imread('BaneHusky.png');
    %K = imresize(img,[8 8]); % not needed for drawn 8 x 8 images

    % load the image using the function 'work around' for imread
    hatImage = loadImage();
    
    % initalize the image angle and read the joystick
    imageAngle = 0;
    joystickPress = readJoystick(mysh);
    pause(0.2); % debounce joystick
    
    while joystickPress ~= 1 % while center not pressed
    
        switch(joystickPress) % take action based on the joystick reading
    
            case % add cases per 
    
        end

        % debug
        % note that the deployed code is strongly typed, so the
        % format string type must match the variables. The jostick
        % is unsigned int and the image angle is float. disp does not
        % work when deployed.
        if debug == true
            %disp(['joyStick = ' sprintf('%3u',joystickPress) ...
            %    ', imageAngle = ' sprintf('%3.0f',imageAngle)])
            fprintf('joyStick = %3u, imageAngle = %3.0f\n',joystickPress,imageAngle)
        end

        % original displayImage can't take a variable as an 
        % argument when deployed - duh
        deployableDisplayImage(mysh,hatImage,imageAngle); 
    
        % read the joystick position
        joystickPress = readJoystick(mysh);
        pause(0.2); % debounce joystick
    
    end
    
    % we're done, so clear the sense hat display
    clearLEDMatrix(mysh);

end

% flips the image vertically (x - axis)
% pre-conditions: none
% post-conditions: the returned image is a vertically (up) flipped
%                  version of the input image
function newImage = flipVertical(oldImage)
    newImage = flipud(oldImage);
end


% necessary to map angle variable onto angle integer
% literal to make displayImage deployable
% pre-conditions: none
% post-conditions: none
function deployableDisplayImage(mysh,K,imageAngle)
    switch(imageAngle)
        case ... % make cases for 0 90 180 270
    end
end

% creates a specific image, since imread function
% are load are not deployable. Create this by running original
% code in MATLAB (using imread and imresize), then copy
% the result and explicitly create the matrix here using cat
% (since the other 3G matrix creation methods won't deploy)
% pre-conditions: the 8 x 8 x 3 image used by this function has to be created
%                 in matlab using A=imread and imresize(A, [8 8])
% post-conditions: specific image is returned in 8 x 8 x 3 format
function image = loadImage() % this is from original image BaneHusky.png
   % red plane
   
   % add green plane    
   
   % add blue plane         
      
end
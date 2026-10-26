ipaddr = input("enter the ip adress of the rpi: ",'s');
image_path = input("enter the file path for the image here : ",'s');
[rpi,mysh]=senshat_setup(ipaddr);
[original,hatimg] = loadAndConfigureImage(image_path);

command = readJoystick(mysh);
while command ~= 1
    hatimg = orientImage(hatimg,command);
    command = readJoystick(mysh);
    displayimage(mysh,hatimg);
    pause(0.1);
end
clearLEDMatrix(mysh);

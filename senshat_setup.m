function [rpi,mysh] = senshat_setup(ipaddr)
    fprintf("connecting to raspberry pi with with ip adress: %s" ...
        ,string(ipaddr));
    rpi = raspi(string(ipaddr),'pi','raspberry'); 
    mysh = sensehat(rpi); 
    clearLEDMatrix(mysh);
end

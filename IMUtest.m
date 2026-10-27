ipaddr = "192.168.0.113";

rpi = raspi(string(ipaddr),'pi','raspberry'); 
mysh = sensehat(rpi); 

B = readMagneticField(mysh);
initialAngle = atan2d(B(2),B(1));
integrated_w(1,:) = [0 0 0];
i = 1;
while true
    start_t = tic;
    B = readMagneticField(mysh);
    fieldAngle = atan2d(B(2),B(1));
    % Relative board rotation, wrapped to [-180,180)
    yaw = mod(initialAngle - fieldAngle + 180,360) - 180;
    w = readAngularVelocity(mysh);
    dt = toc(start_t);
    integrated_w(i,:) = w .* dt + integrated_w(i,:);
    a = readAcceleration(mysh);
    i = i+1;
    T = table(a,w,B,integrated_w,yaw,'VariableNames', ...
        {'acceleration','angular vel',...
        'magnetic field','euler angle','yaw rate from mag'});
    disp(T);
end

load("JettaData.mat","CamryData.mat");

for i = 1:3 
    subplot(2,1,1);
    time = JettaData{i}.Time_sec;
    speed = JettaData{i}.speed_fts;
    plot(time,gradient(speed,time),"o","MarkerEdgeColor",...
        JettaTrialColors(i),"MarkerFaceColor",...
        JettaTrialColors(i),"MarkerSize",2);
    hold on;
    title("Unfiltered Jetta Acceleration vs Time");
    xlabel("Time(sec)");
    ylabel("Acceleration(ft/s2)");
    legend(TrialLegends);
    grid on;
end
hold off;
for i = 1:3 
    subplot(2,1,2);
    time = CamryData{i}.Time_sec;
    speed = CamryData{i}.speed_fts;
    plot(time,gradient(speed,time),"o","MarkerEdgeColor",...
        JettaTrialColors(i),"MarkerFaceColor",...
        JettaTrialColors(i),"MarkerSize",2);
    hold on;
    title("Unfiltered Camry Acceleration vs Time");
    xlabel("Time(sec)");
    ylabel("Acceleration(ft/s2)");
    legend(TrialLegends);
    grid on;
end
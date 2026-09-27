function fig=plotCarCourses(Courses,name,fuelunit)
% Compare position, motion, RPM and fuel predictions for the four courses.
fig=figure('Color','w','Position',[100 100 1200 1050]);
layout=tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
title(layout,string(name)+" course predictions",'FontName','Times New Roman','FontSize',17);
colors=[0 .35 .7;.8 .35 .05;.5 .2 .55;.15 .5 .3];
styles={'-','--','-.',':'};
titles=["Position","Velocity","Acceleration","RPM versus time",...
    "Fuel rate","Cumulative fuel","Fuel economy","RPM versus speed"];
units=["Distance (ft)","Speed (ft/s)","Acceleration (ft/s^2)","Engine speed (rpm)",...
    "Fuel rate ("+string(fuelunit)+"/s)","Fuel ("+string(fuelunit)+")",...
    "Economy (mi/"+string(fuelunit)+")","Engine speed (rpm)"];
for panel=1:8
    nexttile; hold on;
    for course=1:4
        D=Courses{course};
        values={D.position,D.speed,D.acceleration,D.rpm,D.fuel_rate,D.fuel_used,D.economy,D.rpm};
        x=D.time; x_name='Time (s)';
        if panel==8, x=D.speed; x_name='Speed (ft/s)'; end
        plot(x,values{panel},styles{course},'Color',colors(course,:),'LineWidth',1.5);
    end
    title(titles(panel),'FontWeight','normal'); xlabel(x_name); ylabel(units(panel));
    grid on; box on; set(gca,'FontName','Times New Roman','FontSize',13,'GridAlpha',.15);
end
nexttile; hold on;
for course=1:4
    plot(NaN,NaN,styles{course},'Color',colors(course,:),'LineWidth',1.5);
end
axis off;
legend('1: 15 mph, 100 yd','2: 25 mph and stop, 200 yd',...
    '3: 1/4 mile, 15 mph average','4: accelerating 1/4 mile',...
    'Location','north','FontName','Times New Roman','FontSize',12);
text(0,.45,{'Predictions, not measurements.';...
    'Cruise RPM: launch-curve proxy.';'Cruise fuel: mean of phase fits.';...
    'Course 4: assumed continuation.'},'Units','normalized',...
    'VerticalAlignment','top','FontName','Times New Roman','FontSize',12);
end

%% Plot all the model predictions 

%% Load the saved predictions and plot them

% Author: Jiale Jiang
% Editor: Jiale Jiang

% load the results saved by ModelPrediction so we do not need them open;
load("ModelPredictionData.mat", "Predictions", "VehicleModels", "Courses");
save_folder =  ...
    "C:\Users\jiaxi\OneDrive\Documentos\GitHub\MATLAB-class-project1\MOOMOO_CODE\New plots and reports";
% Position, speed, accel, RPM/time, five RPM/speed phases, then fuel plots.
% 12 "trues" in a vector , to plot all 12 plots;
plot_graphs = true(1,12);
plot_idle = false;
plot_names = ["Pos","Vel","Accel","RPMTime", ...
    "Idle1RPMVel","AccelRPMVel","CruiseRPMVel","DecelRPMVel","Idle2RPMVel", ...
    "FuelRate","FuelUsed","FuelEconomy"];

% Each phase can now be represented using the index number from the
% follwoing vector: 1 accel, 2 cruise, 3 decel; 0/4 reserved for 
% idle
rpm_phase_names = ["Initial Idle","Acceleration","Cruising", ...
    "Deceleration","Final Idle"];
car_colors = ["b","r"];
car_styles = ["-","-"];

%% Courses: both cars in one figure, save, close, repeat
for course = 1:numel(Courses)
    if isempty(Predictions{1,course}) && isempty(Predictions{2,course})
        continue;
    end
    for graph = 1:numel(plot_names)
        if ~plot_graphs(graph)
            continue;
        end
        plot_pos = (graph == 1);
        plot_vel = (graph == 2);
        plot_accel = (graph == 3);
        plot_rpmtime = (graph == 4);
        plot_rpmvel = (graph >= 5 && graph <= 9);
        plot_fuelrate = (graph == 10);
        plot_fuelused = (graph == 11);
        plot_economy = (graph == 12);
        fig = figure('Visible','off','Color','w', ...
            'Position',[100,100,1100,760]);
        hold on;
        for car = 1:2
            prediction = Predictions{car,course};
            if isempty(prediction)
                continue;
            end
            model = VehicleModels{car};
            color = car_colors(car);
            line_style = car_styles(car);
            legend_name = model.name;

            % Position vs time
            if plot_pos
                plot(prediction.time_sec,prediction.position_ft, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Position vs Time";
                xlabel('Time (s)');
                ylabel('Distance (ft)');
            end
            % Speed vs time
            if plot_vel
                plot(prediction.time_sec,prediction.speed_fts, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Speed vs Time";
                xlabel('Time (s)');
                ylabel('Speed (ft/s)');
            end
            % Acceleration vs time
            if plot_accel
                plot(prediction.time_sec,prediction.accel_fts2, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Acceleration vs Time";
                xlabel('Time (s)');
                ylabel('Acceleration (ft/s^2)');
            end
            % RPM vs time
            if plot_rpmtime
                % negative time is idle before the course starts moving;
                plot(prediction.idle1_time_sec,prediction.idle1_rpm, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'HandleVisibility','off');
                plot(prediction.time_sec,prediction.rpm, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                if ~isempty(prediction.idle2_time_sec)
                    plot(prediction.idle2_time_sec,prediction.idle2_rpm, ...
                        'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                        'HandleVisibility','off');
                end
                plot_title = "RPM vs Time";
                xlabel('Time from motion start (s)');
                ylabel('Engine RPM (rpm)');
            end
            % RPM vs speed
            if plot_rpmvel
                if graph == 5
                    speed = zeros(size(prediction.idle1_rpm));
                    rpm = prediction.idle1_rpm;
                elseif graph == 9
                    if isempty(prediction.idle2_rpm)
                        continue;
                    end
                    speed = zeros(size(prediction.idle2_rpm));
                    rpm = prediction.idle2_rpm;
                else
                    index = find(prediction.phase == graph-5);
                    if isempty(index) || prediction.time_sec(index(end)) <= ...
                            prediction.time_sec(index(1))
                        continue;
                    end
                    speed = prediction.speed_fts(index);
                    rpm = prediction.rpm(index);
                end
                marker = 'none';
                % A constant speed/RPM pair appears as one point.
                if all(speed == speed(1)) && all(rpm == rpm(1))
                    marker = 'o';
                end
                plot(speed,rpm, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'Marker',marker,'MarkerSize',5,'MarkerFaceColor',color, ...
                    'DisplayName',legend_name);
                plot_title = rpm_phase_names(graph-4) + " RPM vs Speed";
                xlabel('Speed (ft/s)');
                ylabel('Engine RPM (rpm)');
            end
            % Fuel rate vs time
            if plot_fuelrate
                plot(prediction.time_sec,prediction.fuel_rate, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Fuel Rate vs Time";
                xlabel('Time (s)');
                ylabel('Fuel rate (US gal/s)');
            end
            % Cumulative fuel used vs time
            if plot_fuelused
                plot(prediction.time_sec,prediction.fuel_used, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Cumulative Fuel vs Time";
                xlabel('Time (s)');
                ylabel('Fuel used (US gal)');
            end
            % Fuel economy vs time
            if plot_economy
                plot(prediction.time_sec,prediction.fuel_economy, ...
                    'Color',color,'LineStyle',line_style,'LineWidth',1.5, ...
                    'DisplayName',legend_name);
                plot_title = "Fuel Economy vs Time";
                xlabel('Time (s)');
                ylabel('Fuel economy (mi/US gal)');
            end
        end
        if isempty(findobj(fig,'Type','line'))
            close(fig);
            continue;
        end
        title(sprintf('Course %d Predicted %s',course,plot_title));
        set(gca,'FontSize',14);
        grid on;
        legend('show','Location','southoutside','Orientation','horizontal');
        hold off;
        filename = sprintf('JettaCamryCourse%d%sPrediction.png', ...
            course,plot_names(graph));
        exportgraphics(fig,fullfile(save_folder,filename),'Resolution',300);
        close(fig);
    end
end

%% Initial idle acceleration reference, separate from the course clock
if plot_idle
    fig = figure('Visible','off','Color','w', ...
        'Position',[100,100,1100,760]);
    hold on;
    for car = 1:2
        model = VehicleModels{car};
        tau = linspace(0,model.fits.idle1.duration_sec,100);
        plot(tau,polyval(model.fits.idle1.fitted_accel_param,tau), ...
            'Color',car_colors(car),'LineStyle',car_styles(car), ...
            'LineWidth',1.5,'DisplayName',model.name);
    end
    title('Predicted Initial Idle Acceleration');
    xlabel('Time since initial idle began (s)');
    ylabel('Acceleration (ft/s^2)');
    % this gca means get current axis, it will set the current axis's tick
    % number font size to the requested size;
    set(gca,'FontSize',14);
    ylim([-1,1]);
    grid on;
    legend('show','Location','southoutside','Orientation','horizontal');
    hold off;
    exportgraphics(fig,fullfile(save_folder, ...
        'JettaCamryIdleAccelPrediction.png'),'Resolution',300);
    close(fig);
end

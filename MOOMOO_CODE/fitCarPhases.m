function [Model,PhaseData,TrialSummary] = fitCarPhases(Datacell,name,fuelunit)
% Fit the complete acceleration and braking phases from all three trials.
Model = struct('name',string(name),'fuel_unit',string(fuelunit));
PhaseData = cell(1,2);
for phase = 1:2
    PhaseData{phase} = struct('time',[],'accel',[],'speedchange',[],...
        'speed',[],'rpm',[],'fuel',[],'trial_id',[]);
end
phase_duration = zeros(numel(Datacell),2);
idle_rpm = zeros(numel(Datacell),1); idle_fuel = idle_rpm;
trial_rows = cell(numel(Datacell),12);
for trial = 1:numel(Datacell)
    D = Datacell{trial};
    t=D.Time_sec(:); v=D.speed_fts(:); a=D.filtered_accel(:); rpm=D.EngineRPM_rpm(:);
    if strcmpi(name,'Jetta')
        q=D.instantFuelRategals(:);
        q(~isfinite(q) | D.InstantFuelEcon_MPG(:)<=0)=NaN;
        counter=D.TripFuel_gal(:);
        first_fuel=find(counter>0,1);
        cumulative=counter-counter(first_fuel);
        cumulative(1:first_fuel-1)=NaN;
    else
        q=D.fuelrate_lbs(:);
        cumulative=cumtrapz(t,q);
    end
    peak_i=find(v==max(v),1,'last');
    start_i=find(v(1:peak_i)==0,1,'last');
    stop_i=find(v(peak_i+1:end)==0,1)+peak_i;
    stopped=~isempty(stop_i);
    if ~stopped, stop_i=numel(v); end
    Model.phase_indices(trial,:)=[start_i,peak_i,stop_i];
    stationary=find(v(1:start_i)==0 & rpm(1:start_i)>0);
    idle_rpm(trial)=median(rpm(stationary));
    if strcmpi(name,'Jetta')
        stationary=stationary(counter(stationary)>0);
        p=polyfit(t(stationary)-t(stationary(1)),counter(stationary),1);
        idle_fuel(trial)=max(0,p(1));
    else
        idle_fuel(trial)=mean(q(stationary));
    end
    indices={start_i:peak_i,peak_i:stop_i};
    for phase = 1:2
        idx=indices{phase}; u=t(idx)-t(idx(1));
        PhaseData{phase}.time=[PhaseData{phase}.time;u];
        PhaseData{phase}.accel=[PhaseData{phase}.accel;a(idx)];
        PhaseData{phase}.speedchange=[PhaseData{phase}.speedchange;v(idx)-v(idx(1))];
        PhaseData{phase}.speed=[PhaseData{phase}.speed;v(idx)];
        PhaseData{phase}.rpm=[PhaseData{phase}.rpm;rpm(idx)];
        PhaseData{phase}.fuel=[PhaseData{phase}.fuel;q(idx)];
        PhaseData{phase}.trial_id=[PhaseData{phase}.trial_id;trial*ones(numel(idx),1)];
        phase_duration(trial,phase)=u(end);
    end
    distance=cumtrapz(t,v);
    trial_rows(trial,:)={string(name),trial,numel(t),t(end)-t(1),...
        (numel(t)-1)/(t(end)-t(1)),max(v)*3600/5280,phase_duration(trial,1),...
        phase_duration(trial,2),distance(end),cumulative(end),string(fuelunit),stopped};
end
Model.idle_rpm=mean(idle_rpm); Model.idle_fuel_rate=mean(idle_fuel);
Model.max_phase_time=max(phase_duration,[],1);
Model.common_phase_time=min(phase_duration,[],1);
Model.max_speed_fts=max(PhaseData{1}.speed);
for phase = 1:2
    P=PhaseData{phase};
    valid=isfinite(P.time) & isfinite(P.accel);
    t=P.time(valid); a=P.accel(valid); dv=P.speedchange(valid);
    p=polyfit(t,a,1); % a(t)=p(1)*t+p(2), in ft/s^2.
    mean_a=mean(a);
    Model.motion_param(phase,:)=[p(2),p(1)]; % [initial acceleration, jerk]
    Model.constant_a(phase,1)=mean_a;
    Model.accel_rmse(phase,:)=[sqrt(mean((a-mean_a).^2)),...
        sqrt(mean((a-polyval(p,t)).^2))];
    Model.rmse(phase,:)=[sqrt(mean((dv-mean_a*t).^2)),...
        sqrt(mean((dv-polyval([p(1)/2,p(2),0],t)).^2))];
    valid=isfinite(P.speed) & isfinite(P.rpm) & P.rpm>0;
    Model.rpm_param(phase,:)=polyfit(P.speed(valid),P.rpm(valid),2);
    valid=isfinite(P.speed) & isfinite(P.fuel) & P.fuel>=0;
    if strcmpi(name,'Jetta') && phase==2
        Model.fuel_param(phase,:)=[0,mean(P.fuel(valid))];
    else
        Model.fuel_param(phase,:)=polyfit(P.speed(valid),P.fuel(valid),1);
    end
end
TrialSummary=cell2table(trial_rows,'VariableNames',{'Vehicle','Trial','Rows','Duration_s',...
    'LogRate_Hz','PeakSpeed_mph','AccelTime_s','BrakeTime_s','Distance_ft','Fuel','FuelUnit','Stopped'});
end

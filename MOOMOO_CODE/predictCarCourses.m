function [Courses,CourseSummary] = predictCarCourses(Model)
% Predict the four courses with fitted acceleration, RPM and fuel models.
a0=Model.motion_param(1,1); jA=Model.motion_param(1,2);
d0=Model.motion_param(2,1); jD=Model.motion_param(2,2);
assert(a0>0 && d0<0,'The launch/braking fits must start with positive/negative acceleration.');
accel_time=@(v) 2*v./(a0+sqrt(a0^2+2*jA*v));
brake_time=@(v) 2*v./(-d0+sqrt(d0^2-2*jD*v));
accel_distance=@(v) a0/2*accel_time(v).^2+jA/6*accel_time(v).^3;
brake_distance=@(v) v.*brake_time(v)+d0/2*brake_time(v).^2+jD/6*brake_time(v).^3;
speed_cap=Model.max_speed_fts;
if jA<0, speed_cap=min(speed_cap,0.999*a0^2/(-2*jA)); end
if jD>0, speed_cap=min(speed_cap,0.999*d0^2/(2*jD)); end
targets=[300 600 1320 1320]; Courses=cell(1,4); rows=cell(4,12);
for course=1:4
    goal=targets(course); tb=0; tc=0;
    continuation=struct('join_time_s',NaN,'decay_time_s',NaN,'basis',"Not used");
    if course<4
        target_speed=15*5280/3600;
        if course==2, target_speed=25*5280/3600; end
        if course==3
            phase_distance=@(v) accel_distance(v)+brake_distance(v);
            high=speed_cap;
            if phase_distance(high)>goal
                high=fzero(@(v) phase_distance(v)-goal,[eps high]);
            end
            total_time=@(v) accel_time(v)+brake_time(v)+(goal-phase_distance(v))./v;
            assert(high>22 && total_time(high)<=60,'Course 3 cannot meet 60 s with these fitted motion limits.');
            target_speed=fzero(@(v) total_time(v)-60,[22 high]);
        end
        ta=accel_time(target_speed); brake_dist=0;
        if course>1, tb=brake_time(target_speed); brake_dist=brake_distance(target_speed); end
        tc=(goal-accel_distance(target_speed)-brake_dist)/target_speed;
        assert(isreal(ta) && isfinite(ta) && isreal(tb) && isfinite(tb) && tc>=0,...
            'Course is outside the fitted motion range.');
    else
        ta=Model.common_phase_time(1);
        if jA<0, ta=min(ta,0.8*(-a0/jA)); end
        assert(ta>0 && a0+jA*ta>0,'Continuation requires a positive join time and acceleration.');
        if a0/2*ta^2+jA/6*ta^3>=goal
            ta=fzero(@(t) a0/2*t^2+jA/6*t^3-goal,[0 ta]);
        end
    end
    t=linspace(0,ta,max(2,ceil(ta/0.05)+1)).';
    v=polyval([jA/2 a0 0],t); x=polyval([jA/6 a0/2 0 0],t);
    a=a0+jA*t; [rpm,q]=phaseValues(Model,1,v);
    D=[t,x,v,a,rpm,q,cumtrapz(t,q)];
    if course<4
        if tc>1e-10
            t=linspace(0,tc,max(2,ceil(tc/0.05)+1)).'; v=target_speed*ones(size(t));
            [rpm,qA]=phaseValues(Model,1,v); [~,qD]=phaseValues(Model,2,v);
            D=appendPhase(D,t,target_speed*t,v,zeros(size(t)),rpm,(qA+qD)/2);
        end
        if course>1
            t=linspace(0,tb,max(2,ceil(tb/0.05)+1)).';
            v=target_speed+polyval([jD/2 d0 0],t); v(end)=0;
            x=target_speed*t+polyval([jD/6 d0/2 0 0],t); a=d0+jD*t;
            [rpm,q]=phaseValues(Model,2,v); D=appendPhase(D,t,x,v,a,rpm,q);
        end
    elseif D(end,2)<goal-1e-8
        join_time=ta; ab=a0+jA*ta; vb=D(end,3); xb=D(end,2);
        if jA<0
            T=-ab/jA; basis="Decay time matches the fitted negative jerk at the join.";
        else
            T=join_time; basis="Assumed decay time equals the join time; jerk changes at the join.";
        end
        tail_distance=@(u) vb*u+ab*T*(u-T*(1-exp(-u/T)));
        tail_time=fzero(@(u) xb+tail_distance(u)-goal,[0 (goal-xb)/vb]);
        t=linspace(0,tail_time,max(2,ceil(tail_time/0.05)+1)).';
        v=vb+ab*T*(1-exp(-t/T)); a=ab*exp(-t/T);
        [rpm,q]=phaseValues(Model,1,v); D=appendPhase(D,t,tail_distance(t),v,a,rpm,q);
        ta=ta+tail_time;
        continuation=struct('join_time_s',join_time,'decay_time_s',T,'basis',basis);
    end
    economy=D(:,3)/5280./D(:,6); economy(D(:,3)<=0 | D(:,6)<=0)=NaN;
    assert(all(isfinite(D(:))) && all(diff(D(:,1))>0) && all(D(:,3)>=-1e-8));
    assert(all(diff(D(:,2))>=-1e-8) && all(diff(D(:,7))>=-1e-10));
    assert(abs(D(end,2)-goal)<1e-6,'Course distance does not match its target.');
    if course==3, assert(abs(D(end,1)-60)<1e-6); end
    if course==4, assert(all(D(:,4)>0)); end
    max_accel=max(D(:,4));
    Courses{course}=struct('time',D(:,1),'position',D(:,2),'speed',D(:,3),...
        'acceleration',D(:,4),'rpm',D(:,5),'fuel_rate',D(:,6),'fuel_used',D(:,7),...
        'economy',economy,'fuel_unit',Model.fuel_unit,'phase_time',[ta tc tb],...
        'continuation',continuation,'maximum_acceleration',max_accel);
    rows(course,:)={Model.name,course,D(end,2),D(end,1),ta,tc,tb,...
        D(end,3)*3600/5280,max(D(:,3))*3600/5280,D(end,7),Model.fuel_unit,max_accel};
end
CourseSummary=cell2table(rows,'VariableNames',{'Vehicle','Course','Distance_ft','Time_s',...
    'AccelTime_s','CruiseTime_s','BrakeTime_s','FinalSpeed_mph','PeakSpeed_mph',...
    'Fuel','FuelUnit','MaxAccel_fts2'});
end

function [rpm,q]=phaseValues(Model,phase,v)
% Hold fuel rate and effective RPM/speed ratio beyond measured speed.
v_fit=min(v,Model.max_speed_fts);
rpm=max(0,polyval(Model.rpm_param(phase,:),v_fit));
above=v>Model.max_speed_fts;
rpm(above)=rpm(above).*v(above)/Model.max_speed_fts;
q=max(0,polyval(Model.fuel_param(phase,:),v_fit));
end

function D=appendPhase(D,t,x,v,a,rpm,q)
% Integrate each phase before removing its duplicate boundary sample.
fuel=D(end,7)+cumtrapz(t,q);
next=[D(end,1)+t,D(end,2)+x,v,a,rpm,q,fuel];
D=[D;next(2:end,:)];
end

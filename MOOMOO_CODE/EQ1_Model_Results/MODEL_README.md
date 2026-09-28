# Fitted vehicle models

Run `results = FitVehicleModels(sourceFolder, outputFolder)` in MATLAB R2024b.
`sourceFolder` must contain JettaData.mat, CamryData.mat, SpeedKalmanFilter.m,
and detectMotionSections.m. The script reads only the six named raw trial
matrices. It does not run DataParser or save over the source workspaces.

## Motion

For local phase time t in seconds:

v(t) = v0 + a0*t + 0.5*j*t^2, in ft/s

a(t) = a0 + j*t, in ft/s^2

s(t) = s0 + v0*t + 0.5*a0*t^2 + j*t^3/6, in ft

The first-order acceleration model is fitted directly to recorded velocity,
avoiding a second differentiation. The constant-acceleration comparator fixes
the same initial velocity. Each trial contributes equal total weight in the
pooled objective. The zero-intercept velocity-change fit uses least squares;
fminsearch enforces correctly signed acceleration endpoints if necessary.
`polyval` evaluates its polynomial coefficients. Reported fitting RMSE uses
raw velocity, not Kalman-filtered velocity or normalized time.

Leave-one-trial-out fitting uses only two trials' samples, coefficients, and
durations. Held-out phase start velocity is a known initial condition; its
remaining velocity trace is not used for training. Scoring a measured phase
does require its observed phase boundaries. This is phase-conditional
validation, not blind detection or a validation of unobserved courses.

For braking, end at the first real nonnegative root v(t)=0, then use idle.
Never continue a braking polynomial into negative speed. Fit RMSE includes
unclipped polynomial residuals on all selected measured points, retaining an
early/late-stop penalty; plotted fit curves stop at zero speed. For acceleration,
do not extrapolate past a(t)=0 and claim that acceleration continues. The
common calibration duration is the shortest of the three phase durations;
the maximum duration is the longest and has less multi-trial support.

## Phase selection

The separate modeling selection begins acceleration at the last true zero
speed before the last maximum. Deceleration ends at the first later zero, or
at the record end. Camry startup nonzero held values before a later true stop
are excluded from moving fits, but retained in raw arrays. This does not change
the user's motion detector. Camry logs end at 1.864 mph, not a measured stop.
Zero RPM is excluded from RPM fitting, not removed from the source records.

## RPM and fuel

`vehicle.rpm.accel/decel.poly` are second-degree polynomial coefficients in
speed (ft/s). They are broad phase averages, not gear-ratio models; shift
structure and trial-to-trial differences remain visible as residual error.
`vehicle.fuel.accel/decel.poly` are first-degree coefficients in speed,
evaluated as offset + max(0,polyval(p,v)). Jetta braking uses a fitted positive
baseline offset plus a clipped linear term because the high-rate transition
samples otherwise drive the fit to an artificial zero over most of braking.
The other phase offsets are zero. They are unvalidated outside recorded speed
ranges. Units are gal/s for Jetta and lb/s for Camry, never interchangeable.

Jetta fuel rate is speed(mph)/MPG/3600 where MPG is positive. Idle fuel uses a
linear slope of the positive cumulative fuel counter at zero speed; the
initial zero placeholder is excluded. Camry idle fuel is the mean recorded
rate at zero speed and positive RPM. Idle RPM is each trial's median over
these stationary engine-running samples, then an equal-trial mean.

There is no sustained-cruise data. Any average of acceleration/deceleration
RPM or fuel curves used for cruising is an explicit unvalidated assumption.
The spread is a scenario bracket, not a confidence interval. Initial idle,
phase-transition engine revving, sampling holds, and small sample sizes limit
these auxiliary fits. No gearbox type or gear number is inferred.

## Files and interface

VehicleModels.mat and VehicleModels.json hold the same `results` structure.
`results.Jetta` and `results.Camry` contain pooled `models`, `rpm`, `fuel`, and
three `trials`, each retaining its raw matrix, signals, phase indices, per-trial
motion model, and metadata. MATLAB/JSON phase indices are one-based.
Motion_Model_Summary.csv includes pooled and held-out RMSE; the trial summary
lists per-trial fits and exact phase indices. PNGs distinguish recorded points
from fitted curves. Existing Kalman code is called unchanged for comparison
plots; it is not silently corrected or treated as ground truth.

# Virtual-course simulation

Run `predictions = SimulateVehicleCourses` after `FitVehicleModels`.
The function reads `EQ1_Model_Results/VehicleModels.json`; it never runs or edits the
data parser, filter, or original workspaces. Optional inputs specify another
model JSON path and output folder.

The four courses begin at launch, without an extra initial idle. Course 1
accelerates to 15 mph and cruises until 300 ft. Course 2 accelerates to 25 mph,
cruises as needed, and stops at 600 ft. Course 3 assumes rest-to-rest motion
and solves the cruise speed that gives 1320 ft in 60 s. Each moving phase uses
local time and joins the preceding phase's position and velocity continuously.

Course 4 follows fitted quadratic velocity until the shortest acceleration
calibration duration or 80% of its acceleration-zero time, whichever is earlier.
It then assumes exponentially decaying positive acceleration. Multiplying the
decay time constant by 0.5 and 2 gives a sensitivity range, not a confidence
interval. This continuation is not a measured or validated quarter-mile run.

RPM follows the fitted phase curve in speed; cruise uses the acceleration
curve. Above the measured speed limit, RPM assumes the same effective ratio
as at that limit. Fuel follows the fitted nonnegative phase rate plus its fitted
offset, holding the measured-speed boundary rate beyond that speed. Cruise
fuel uses the midpoint of the acceleration and braking rates, with each endpoint
as an alternative scenario. None of these cruise assumptions is independently
calibrated. Engine-speed and fuel-rate steps at phase changes are permitted.

Fuel is integrated within each phase before joining phases, so trapezoidal
integration does not smear a phase-boundary rate step. Jetta fuel is gallons;
Camry fuel is pounds and its economy is mi/lb, not MPG. Zero fuel rate produces
an undefined instantaneous economy, not a zero or infinite plotted value.

Outputs are `CoursePredictions.mat`, `CoursePredictions.json`,
`Course_Summary.csv`, and eight `Jetta_Course_N.png`/`Camry_Course_N.png` figures.
JSON includes all series, coefficients, assumptions, phase boundaries, summary
values, and endpoint/monotonicity/finite-value tests. Braking ends at the first
zero-speed root; Course 4 requires strictly positive acceleration throughout.

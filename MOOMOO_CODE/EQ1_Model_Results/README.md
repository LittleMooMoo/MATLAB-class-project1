# Epic Quest 1 model results

Open `Vehicle_Performance_Modeling_Report.docx` or the matching PDF in the parent
MOOMOO_CODE folder. The report uses a formal IEEE-style layout with full-width
scientific figure appendices and editable typed equations.

## Reproduce the MATLAB results

In MATLAB, open the MOOMOO_CODE folder and run:

```matlab
Run_EQ1_Models
```

The script calls three new functions:

1. `FitVehicleModels` reads the original JettaData.mat and CamryData.mat, fits
   phase-specific motion/RPM/fuel models, and compares constant with linearly
   changing acceleration using raw-speed RMSE and held-out trials.
2. `SimulateVehicleCourses` produces all four course scenarios for each vehicle.
3. `ExportRecordedEvidence` exports six exact raw-data CSVs and overview figures.

Only this results folder is regenerated. The original workspaces, DataParser,
SpeedKalmanFilter, and motion-section detector are not edited or overwritten.
The report itself is an editable snapshot; rerunning MATLAB does not rewrite it.
`EvaluateVehiclePhase` is an optional helper for evaluating a local phase,
including stationary idle; heed its warnings about invalid extrapolation.

## Files

- `VehicleModels.mat` / `.json`: coefficients, complete selected raw trial arrays,
  phase indices, data metadata, fitted curves, and velocity validation results.
- `Motion_Model_Summary.csv`: pooled coefficients and velocity RMSE.
- `Trial_Model_Summary.csv`: per-trial coefficients and exact fitted intervals.
- `CoursePredictions.mat` / `.json`: all eight model time histories, phase boundaries,
  assumptions, course summaries, sensitivity results, and numerical assertions.
- `Course_Summary.csv`: compact comparison of all eight scenarios.
- `Raw_Trials/`: six CSVs with original values, timestamps, and quantity/unit headers.
- PNGs: recorded-data overviews, individual motion fits, pooled RPM/fuel fits,
  unchanged Kalman estimates, and complete course predictions.

See `MODEL_README.md` and `COURSE_README.md` for equations and assumptions.

## Interpretation

Lower held-out velocity RMSE supports the curved launch model for these records,
not universal vehicle performance. Jetta braking variability is substantial.
Course 3 is one assumed rest-to-rest profile; its 60-second duration follows
from the prescribed average speed. Course 4 needs an explicit positive-acceleration
continuation. Its reported range varies that assumption, not a confidence level.
Cruise fuel is not measured and is shown with a scenario bracket.

Jetta fuel is gallons; Camry fuel is pounds of mass, so Camry economy is mi/lb,
not MPG. Gear-specific RPM curves, vehicle identity/density details, video links,
field validation, peer rankings, and final team review still require evidence.

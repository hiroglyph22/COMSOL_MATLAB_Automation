% MATLAB Script for COMSOL Geometry Modification and Eigenfrequency Study
%
% To run a specific section in the MATLAB Editor, click inside it and
% press Ctrl+Enter.

%% --- SECTION 1: Initialization and Model Loading ---
% This section connects to the COMSOL server and loads your model file.

clear all;
clc;

import com.comsol.model.*
import com.comsol.model.util.*

fprintf('SECTION 1: Initializing and loading model...\n');

try
    model = mphload("C:\Users\Hiro\Downloads\racetrack_CAD_in_COMSOL.mph");
    fprintf('Model "racetrack_CAD_in_COMSOL.mph" loaded successfully.\n');
catch ME
    error('Failed to load "racetrack_CAD_in_COMSOL.mph". Please ensure the file exists and contains a parameter "L".\n%s', ME.message);
end

fprintf('--- Section 1 Complete ---\n\n');


%% --- SECTION 2: Modify Physical Dimensions ---
% This section defines and runs the eigenfrequency study.

fprintf('SECTION 2: Modifying Physical Dimensions...\n');

% Get the feature and its properties
cyl_feature = model.component('comp1').geom('geom1').feature('cyl1');
properties_struct = mphgetproperties(cyl_feature);

% The radius is returned as a STRING (e.g., '0.6')
radius_as_string = properties_struct.r;

% Convert the string to a numeric value (double)
radius_as_number = str2double(radius_as_string);

% Print the numeric value
fprintf('The radius of cyl1 is: %f\n', radius_as_number);

% Set radius to new value
model.component('comp1').geom('geom1').feature('cyl1').set('r', 0.05);

cyl_feature = model.component('comp1').geom('geom1').feature('cyl1');
properties_struct = mphgetproperties(cyl_feature);
radius_as_string = properties_struct.r;
radius_as_number = str2double(radius_as_string);
fprintf('The radius of cyl1 is: %f\n', radius_as_number);

% Build All
model.component('comp1').geom('geom1').run();
model.component('comp1').mesh('mesh1').run();

%% SECTION 3: Eigenfrequency study

study_tag = 'std1';

% --- Run the Study ---
fprintf('Running Eigenfrequency study...\n');
try
    model.study(study_tag).run();
    fprintf('Study finished successfully.\n');
catch ME
    warning('The study failed to run. See the error message below.');
    rethrow(ME); % This will print the detailed error from COMSOL
end

% Evaluate the expression 'freq' for all solutions
% The result is a column vector of the frequencies in Hz
eigenfrequencies = mphglobal(model, 'freq', 'solnum', 'all');

fprintf('Found %d eigenfrequencies:\n', length(eigenfrequencies));
for i = 1:length(eigenfrequencies)
    fprintf('  Mode %d: %.2f Hz\n', i, eigenfrequencies(i));
end

fprintf('--- Section 3 Complete ---\n\n');

%% SECTION 4: Plotting 3D Plots 

num_modes = length(eigenfrequencies);

plot_group_tag = 'pg1';
plot_group = model.result(plot_group_tag);
pg_properties = mphgetproperties(plot_group);
dset_tag = pg_properties.data;

for i = 1:num_modes
    fprintf('Plotting Mode %d...\n', i);

    model.result(plot_group_tag).set('solnum', i);

    figure;

    mphplot(model, plot_group_tag);

    title(sprintf('Mode %d: %.2f Hz', i, eigenfrequencies(i)));
end

disp('Finished plotting all modes.');
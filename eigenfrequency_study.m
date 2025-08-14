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

fprintf('SECTION 2: Modifying Physical Dimensions...\n');

comp_tag = 'comp1';
geom_tag = 'geom1';
wp_tag   = 'wp6';
rect_tag = 'r1';
new_width = 0.01; % in mm

% Get handles
wp_feature   = model.component(comp_tag).geom(geom_tag).feature(wp_tag);
rect_feature = wp_feature.geom().feature(rect_tag);

% --- Get current size array ---
properties_before       = mphgetproperties(rect_feature);
size_before_java_array  = properties_before.size; % Java array
size_before_str         = char(size_before_java_array); % e.g. "[0.12;0.06]"

% Parse numeric values
size_vals = sscanf(size_before_str, '[%f;%f]'); % returns [width; height]
width_before  = size_vals(1);
height_before = size_vals(2);

fprintf('The original width of %s was: %g mm\n', rect_tag, width_before);
fprintf('The height of %s is: %g mm (this will be preserved)\n', rect_tag, height_before);

% --- Set new width, preserve height ---
fprintf('Setting width of %s to: %g mm\n', rect_tag, new_width);
rect_feature.set('size', [new_width, height_before]);

% --- Confirm the change ---
properties_after      = mphgetproperties(rect_feature);
size_after_str        = char(properties_after.size);
size_after_vals       = sscanf(size_after_str, '[%f;%f]');
width_after           = size_after_vals(1);

fprintf('The new width of %s is: %g mm\n', rect_tag, width_after);

% --- Rebuild geometry and mesh ---
fprintf('Rebuilding geometry and mesh...\n');
model.component(comp_tag).geom(geom_tag).run();
model.component(comp_tag).mesh('mesh1').run();

fprintf('Modification complete.\n');


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
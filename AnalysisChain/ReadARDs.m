addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

% User defined
% Since CPI is 4s, try looking at the middle of the run
ARD_File = 'Output_archive/1970-01-01T02.02.28.000000.ard';

if ~exist(ARD_File, 'file')
    error('File not found. Run MatlabProcServ first.');
end

% Plot 2D function
figure(1);
oARD2 = cARD;
oARD2.readFromFile(ARD_File);

% Plot using Meters and Hz
% Max Amplitude: 0 dB (Target)
% Min Amplitude: -40 dB (Noise Floor)
fprintf('Plotting %s with dynamic range -40dB to 0dB\n', ARD_File);
oARD2.plot2D('m','Hz', 0, -40);

% Add a marker for the baseline (Direct Signal)
xline(74483, 'r--', 'Direct Path');

% Plot 3D function
%if plot_all == 1
%    figure(2);
%    oARD2 = cARD;
%    oARD2.readFromFile(ARD_File);
%    oARD2.plot3D('m','Hz',0,-40);
%end

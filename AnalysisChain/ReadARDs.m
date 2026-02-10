addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

% User defined
plot_all = 0; % Plot 3D function 1/0
ARD_File = 'Output/100.ard';

% Plot 2D function
figure(1);
oARD2 = cARD;
oARD2.readFromFile(ARD_File);

% Plot using Meters and Hz
% The last two arguments are Max/Min dB for the color scale.
% You might need to tweak -40 to -60 or -20 depending on signal strength.
oARD2.plot2D('m','Hz', 0, -50);

% Plot 3D function
%if plot_all == 1
%    figure(2);
%    oARD2 = cARD;
%    oARD2.readFromFile(ARD_File);
%    oARD2.plot3D('m','Hz',0,-40);
%end

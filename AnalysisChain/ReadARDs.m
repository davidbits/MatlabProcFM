addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

ARD_File = 'CleanSingleTarget.ard';

% Plot 2D function
figure(1);
oARD2 = cARD;
oARD2.readFromFile(ARD_File);
% Can use (km or m) (m/s or Hz)
oARD2.plot2D('m', 'Hz', 0, -40);

title(sprintf('ARD at T=83s (CPI %d)', TargetCPIIndex));

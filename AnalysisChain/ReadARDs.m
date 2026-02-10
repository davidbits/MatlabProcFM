addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

ARD_File = 'Ref_Outputs/NoiseFMTx1/1970-01-01T02.01.00.000000.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget/16.ard';
ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget/16.ard';

% something funky happens at ard index 38 or 152s

% Plot 2D function
figure(1);
oARD2 = cARD;
oARD2.readFromFile(ARD_File);
% Can use (km or m) (m/s or Hz)
oARD2.plot2D('m', 'Hz', 0, -30);

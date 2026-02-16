addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

%ARD_File = 'Ref_Outputs/NoiseFMTx1/1970-01-01T02.01.00.000000.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_tone_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_tone_stationary_jam/16.ard';
%ARD_File = 'Ref_Outputs/CleanSingleTarget/1970-01-01T02.01.00.000000.ard';
%ARD_File = 'Ref_Outputs/JamSingleTarget_oldest_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/JamSingleTarget_oldest_no_rand_stationary/16.ard';
%ARD_File = 'Output/7.ard';

ARD_File = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget_fers_latest/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_no_rand/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_fers_latest/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_stationary_jam/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_fers_latest_low_power_1mw/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_low_power_1mw/16.ard';
%ARD_File = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_low_power_100uw/16.ard';

% something funky happens at ard index 38 or 152s

% Plot 2D function
figure(1);
oARD2 = cARD;
oARD2.readFromFile(ARD_File);
% Can use (km or m) (m/s or Hz)
oARD2.plot2D('m', 'Hz', 0, -10);

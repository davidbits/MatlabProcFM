addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

% Simple Animation Script
figure;
for i = 0:44
    %filename = sprintf('Ref_Outputs/Latest_FIXED_CleanSingleTarget/%d.ard', i);
    filename = sprintf('Output/%d.ard', i);
    if exist(filename, 'file')
        oARD = cARD;
        oARD.readFromFile(filename);
        oARD.plot2D('m', 'Hz', 0, -20);
        title(sprintf('CPI: %d', i));
        drawnow;
    end
end
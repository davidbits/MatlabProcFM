addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

% Simple Animation Script
figure;
for i = 0:359
    filename = sprintf('Output/%d.ard', i);
    if exist(filename, 'file')
        oARD = cARD;
        oARD.readFromFile(filename);
        oARD.plot2D('m', 'Hz', 0, -60); % Adjust -60 based on your noise floor
        title(sprintf('CPI: %d', i));
        drawnow;
    end
end
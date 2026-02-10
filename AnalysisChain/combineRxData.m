% Script: combineRxData.m
% Purpose: Merges FERS HDF5 outputs into a single RCF for the ProcServer
clear; clc;

% Add necessary paths for classes and HDF5 loaders
addpath('Classes');
addpath('ARDMakers');

% Configuration
% Ensure these paths match where you saved your FERS output files
refFile = 'Input/ArmasuisseRefRxClean.h5';
surFile = 'Input/ArmasuisseSurRxClean.h5';
outFile = 'Input/ArmasuisseClean.rcf';

% Parameters from your scenario
Fs = 204800;
Fc = 89e6;

% Create Output Directory if it doesn't exist
if ~exist('Input', 'dir')
    mkdir('Input');
end

fprintf('Loading Simulation HDF5 files...\n');

% 1. Load Reference
if ~exist(refFile, 'file')
    error('Reference file not found: %s', refFile);
end
[I_ref, Q_ref, scale_ref] = loadfersHDF5(refFile);
refData = complex(I_ref, Q_ref) * scale_ref;

% 2. Load Surveillance
if ~exist(surFile, 'file')
    error('Surveillance file not found: %s', surFile);
end
[I_sur, Q_sur, scale_sur] = loadfersHDF5(surFile);
surData = complex(I_sur, Q_sur) * scale_sur;

% 3. Create RCF Object
fprintf('Creating RCF object...\n');
oRCF = cRCF;
oRCF.setFs_Hz(Fs);
oRCF.setFc_Hz(Fc);
oRCF.setBw_Hz(Fs);
oRCF.setTimeStamp_us(0); % Simulation starts at 0

% 4. Assign Data
% Ensure lengths match (truncate to shortest)
len = min(length(refData), length(surData));
oRCF.setReferenceData(refData(1:len));
oRCF.setSurveillanceData(surData(1:len));

% 5. Write to Disk
fprintf('Writing to %s...\n', outFile);
oRCF.writeToFile(outFile);
fprintf('Conversion Complete. Ready for ProcServer.\n');

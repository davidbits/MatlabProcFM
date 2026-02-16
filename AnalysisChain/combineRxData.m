% Script: combineRxData.m
% Purpose: Merges FERS HDF5 outputs into a single RCF for the ProcServer
clear; clc;

% Add necessary paths for classes and HDF5 loaders
addpath('Classes');
addpath('ARDMakers');

% Configuration
% Ensure these paths match where you saved your FERS output files
refFile = 'Input/JamSingleTarget_oldest_no_rand/ArmasuisseRefRx.h5';
surFile = 'Input/JamSingleTarget_oldest_no_rand/ArmasuisseSurRx.h5';
outFile = 'Input/JamSingleTarget_oldest_no_rand/ArmasuisseJam.rcf';

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

% --- VERIFICATION BLOCK ---
power_Q_ref = var(imag(refData));
fprintf('Power in Reference Q-channel after loading: %e\n', power_Q_ref);
% Do the same but for the real part
power_I_ref = var(real(refData));
fprintf('Power in Reference I-channel after loading: %e\n', power_I_ref);
% --- END VERIFICATION BLOCK ---

% 2. Load Surveillance
if ~exist(surFile, 'file')
    error('Surveillance file not found: %s', surFile);
end
[I_sur, Q_sur, scale_sur] = loadfersHDF5(surFile);
surData = complex(I_sur, Q_sur) * scale_sur;

% --- VERIFICATION BLOCK ---
power_Q_sur = var(imag(surData));
fprintf('Power in Surveillance Q-channel after loading: %e\n', power_Q_sur);
power_I_sur = var(real(surData));
fprintf('Power in Surveillance I-channel after loading: %e\n', power_I_sur);
% --- END VERIFICATION BLOCK ---

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

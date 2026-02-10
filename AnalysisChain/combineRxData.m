% Script: Combine_Sim_to_RCF.m
% Purpose: Merges FERS HDF5 outputs into a single RCF for the ProcServer
addpath('classes');
addpath('pr_illuminators/ardMakers'); % For loadfersHDF5

% Configuration
refFile = '../Output/ArmasuisseRefRxClean.h5';
surFile = '../Output/ArmasuisseSurRxClean.h5';
outFile = '../Output/ArmasuisseClean.rcf';
Fs = 204800;
Fc = 89e6;

fprintf('Loading Simulation HDF5 files...\n');

% 1. Load Reference
[I_ref, Q_ref, scale_ref] = loadfersHDF5(refFile);
refData = complex(I_ref, Q_ref) * scale_ref;

% 2. Load Surveillance
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
% Ensure lengths match
len = min(length(refData), length(surData));
oRCF.setReferenceData(refData(1:len));
oRCF.setSurveillanceData(surData(1:len));

% 5. Write to Disk
fprintf('Writing to %s...\n', outFile);
oRCF.writeToFile(outFile);
fprintf('Conversion Complete. Ready for ProcServer.\n');

addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')
addpath('./Input');

clear;
clc;
close all;

%% Processing Parameters:
hdf5_input = 1;
InputRCFFilename = '';
InputHDF5Filename = '';

CPI_s = 4.0; % Increased from 0.5s to 4.0s for Integration Gain
EnableCancellation = 1;

% Geometry
TxToReferenceRxDistance_m = 74483;

% Cancellation: Cancel Direct signal + ~3.5km of clutter
CancellationMaxRange_m = 78000;

% ARD Range: Target moves between 95km and 142km.
% We set Max to 150km to ensure we capture the start of the track.
ARDMaxRange_m = 150000;

% Doppler: Target expected at 87Hz, window set to 200Hz
CancallationMaxDoppler_Hz = 200;
CancellationNInterations = 30; % Increased from 10 to 30
CancellationNSegments = 8;

ARDMaxDoppler_Hz = 200;
outputARDPath = './Output';

if hdf5_input == 1
    fprintf('Reading FERS HDF5 Files..\n');

    % Define FERS filenames
    RefFile = 'ArmasuisseRefRxClean.h5';
    SurvFile = 'ArmasuisseSurRxClean.h5';

    % Load Reference Data
    try
        % Note: loadfersHDF5 must be in ./ARDMakers/
        [I_ref, Q_ref, scale_ref] = loadfersHDF5(RefFile);
        RefData = complex(I_ref, Q_ref) * scale_ref;
    catch
        error('Could not read Reference HDF5. Check filename or path.');
    end

    % Load Surveillance Data
    try
        [I_sur, Q_sur, scale_sur] = loadfersHDF5(SurvFile);
        SurvData = complex(I_sur, Q_sur) * scale_sur;
    catch
        error('Could not read Surveillance HDF5. Check filename or path.');
    end

    fprintf('HDF5 file read completed\n');

    % Hardcode parameters from SingleTargetClean.fersxml
    SR_uHz = 204800 * 1e6;
    GCF_uHz = 89e6 * 1e6;
    GCBW_uHz = 100e3 * 1e6;

    % Compute samples per CPI
    CPISize_nSamp = floor((double(SR_uHz) / 1000000) * CPI_s);

    % Ensure data lengths match and truncate to multiple of CPI
    minLen = min(length(RefData), length(SurvData));
    TotalNumSamples = floor(minLen / CPISize_nSamp) * CPISize_nSamp;

    RefData = RefData(1:TotalNumSamples);
    SurvData = SurvData(1:TotalNumSamples);
else
    oInputRCFHeader = cRCF;
    oInputRCFHeader.readHeaderFromFile(InputRCFFilename);

    CPISize_nSamp = oInputRCFHeader.getFs_Hz() * CPI_s;
    TotalNumSamples = oInputRCFHeader.getNSamples();
end

%% Loop per CPI:
nCPIs = floor(TotalNumSamples / CPISize_nSamp);
CPIStartSampleNumber =  0;
CGLSAlpha = 0;

for CPINo = 0:nCPIs - 1

    fprintf('Processing CPI %i of %i:\n', CPINo + 1, nCPIs);

    % Create RCF Object for this CPI
    oCPIRCF = cRCF;
    if hdf5_input == 1
        idxStart = CPIStartSampleNumber + 1;
        idxEnd = CPIStartSampleNumber + CPISize_nSamp;

        oCPIRCF.m_fvReferenceData = RefData(idxStart : idxEnd);
        oCPIRCF.m_fvSurveillanceData = SurvData(idxStart : idxEnd);
        oCPIRCF.m_NSamples = CPISize_nSamp;
        oCPIRCF.m_Fs_Hz = double(SR_uHz) / 1000000;
        oCPIRCF.m_Fc_Hz = (GCF_uHz(1)) / 1000000;
        oCPIRCF.m_Bw_Hz = double(GCBW_uHz) / 1000000;
        oCPIRCF.m_TimeStamp_us = CPIStartSampleNumber * 1000000 / oCPIRCF.m_Fs_Hz;
    else
        oCPIRCF = oInputRCFHeader.readFromFile(InputRCFFilename, CPIStartSampleNumber+1, CPISize_nSamp);
    end

    % Advance sample counter
    CPIStartSampleNumber = CPIStartSampleNumber + CPISize_nSamp;

    if(EnableCancellation)
        fprintf('Doing cancellation (Iter: %d)...\n', CancellationNInterations);
        tic
        [oCPIRCF, CGLSAlpha] = CGLS_Cancellation(oCPIRCF, CancellationMaxRange_m, CancallationMaxDoppler_Hz, TxToReferenceRxDistance_m, CancellationNSegments, CancellationNInterations, CGLSAlpha);
        toc
    end

    fprintf('Doing range/Doppler processing (FX)...\n');
    tic

    oARD = FX_ARD(oCPIRCF, ARDMaxRange_m, ARDMaxDoppler_Hz, TxToReferenceRxDistance_m);
    toc

    % Write ARD to file
    ARDFilename = outputARDPath;
    if(ARDFilename(length(ARDFilename)) ~= '/')
        ARDFilename = [ARDFilename '/'];
    end

    ARDFilename = [ARDFilename num2str(CPINo), '.ard'];

    oARD.writeToFile(ARDFilename);

    fprintf('\n');

end
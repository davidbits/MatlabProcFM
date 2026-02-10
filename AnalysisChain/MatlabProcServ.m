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

CPI_s = 0.5; % Integration time (0.5s is standard for FM)
EnableCancellation = 1;

% The actual distance between Tx and Rx from your XML
TxToReferenceRxDistance_m = 74483;

% Cancellation Range: Must be GREATER than TxToReferenceRxDistance_m.
% This defines how far past the direct signal we want to cancel clutter.
% 74483 + 3000m buffer = 77500
CancellationMaxRange_m = 77500;

% ARD Range: Must be large enough to see the target.
% Target is at ~10km altitude, moving.
% Let's look out to 120km bistatic range to be safe.
ARDMaxRange_m = 120000;

CancallationMaxDoppler_Hz = 200; % Increased to catch the moving target
CancellationNInterations = 10;
CancellationNSegments = 8;

ARDMaxDoppler_Hz = 300;
outputARDPath = './Output';

if hdf5_input == 1
    fprintf('Reading FERS HDF5 Files..\n');

    % Define FERS filenames
    RefFile = 'ArmasuisseRefRxClean.h5';
    SurvFile = 'ArmasuisseSurRxClean.h5';

    % FERS outputs data in chunks. For a single run, it is usually chunk_000000.
    % We read I and Q separately and combine them.

    % Load Reference Data
    try
        RefI = h5read(RefFile, '/chunk_000000_I');
        RefQ = h5read(RefFile, '/chunk_000000_Q');
        RefData = complex(single(RefI), single(RefQ));
    catch
        error('Could not read Reference HDF5. Check filename or chunk name.');
    end

    % Load Surveillance Data
    try
        SurvI = h5read(SurvFile, '/chunk_000000_I');
        SurvQ = h5read(SurvFile, '/chunk_000000_Q');
        SurvData = complex(single(SurvI), single(SurvQ));
    catch
        error('Could not read Surveillance HDF5. Check filename or chunk name.');
    end

    fprintf('HDF5 file read completed\n');

    % Hardcode parameters from your SingleTargetClean.fersxml
    % The script expects uHz (microHertz), so we multiply Hz by 1e6
    SR_uHz = 204800 * 1e6;   % Sample Rate from XML
    GCF_uHz = 89e6 * 1e6;    % Carrier Frequency from XML
    GCBW_uHz = 100e3 * 1e6;  % Bandwidth (Approx for FM)

    % Compute the number of samples in the CPI
    % (SR_uHz / 1e6) converts back to Hz for calculation
    CPISize_nSamp = floor((double(SR_uHz) / 1000000) * CPI_s);
    TotalNumSamples = min(length(RefData), length(SurvData));

    % Ensure data lengths match
    RefData = RefData(1:TotalNumSamples);
    SurvData = SurvData(1:TotalNumSamples);
else
    oInputRCFHeader = cRCF;
    oInputRCFHeader.readHeaderFromFile(InputRCFFilename);

    CPISize_nSamp = oInputRCFHeader.getFs_Hz() * 4;
    TotalNumSamples = oInputRCFHeader.getNSamples();
end

%% Loop per CPI:
nCPIs = floor(TotalNumSamples / CPISize_nSamp);
CPIStartSampleNumber =  0;
CGLSAlpha = 0;

for CPINo = 0:nCPIs - 1

fprintf('Processing CPI %i of %i:\n', CPINo + 1, nCPIs);

%Read data from the RCF or construct a dummy RCF object from the parsed HDF5 data
if hdf5_input == 1
    oCPIRCF = cRCF;
    oCPIRCF.m_fvReferenceData = RefData(CPIStartSampleNumber + 1 : CPIStartSampleNumber + CPISize_nSamp);
    oCPIRCF.m_fvSurveillanceData = SurvData(CPIStartSampleNumber + 1 : CPIStartSampleNumber + CPISize_nSamp);
    oCPIRCF.m_NSamples = CPISize_nSamp;
    oCPIRCF.m_Fs_Hz = double(SR_uHz) / 1000000;
    oCPIRCF.m_Fc_Hz = (GCF_uHz(1)) / 1000000;
    oCPIRCF.m_Bw_Hz = double(GCBW_uHz) / 1000000;
    oCPIRCF.m_TimeStamp_us = CPIStartSampleNumber * 1000000 / oCPIRCF.m_Fs_Hz;
else
    oCPIRCF = oInputRCFHeader.readFromFile(InputRCFFilename, CPIStartSampleNumber+1, CPISize_nSamp);
end

%Now advance starting sample by 1 CPI for next interation
CPIStartSampleNumber = CPIStartSampleNumber + CPISize_nSamp;

if(EnableCancellation)
    fprintf('Doing cancellation\n');
    tic
    [oCPIRCF, CGLSAlpha] = CGLS_Cancellation(oCPIRCF, CancellationMaxRange_m, CancallationMaxDoppler_Hz, TxToReferenceRxDistance_m, CancellationNSegments, CancellationNInterations, CGLSAlpha);
    %oCPIRCF = ECA_Cancellation(oCPIRCF, CancellationMaxRange_m, CancallationMaxDoppler_Hz, TxToReferenceRxDistance_m, CancellationNSegments);
    toc
end

fprintf('Doing range/Doppler processing\n');
tic
%oARD = Batches_ARD(oCPIRCF, ARDMaxRange_m, ARDMaxDoppler_Hz, TxToReferenceRxDistance_m);
oARD = FX_ARD(oCPIRCF, ARDMaxRange_m, ARDMaxDoppler_Hz, TxToReferenceRxDistance_m);
toc

%Write ARD to file:
ARDFilename = outputARDPath;
if(ARDFilename(length(ARDFilename)) ~= '/')
    ARDFilename = [ARDFilename '/'];
end

% ARDFilename = [ARDFilename oARD.timeStampToString(), '.ard'];
ARDFilename = [ARDFilename num2str(CPINo), '.ard'];

oARD.writeToFile(ARDFilename);

fprintf('\n\n');

end
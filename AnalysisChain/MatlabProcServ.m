addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')
addpath('./Input');

clear;
clc;
close all;

%% Processing Parameters:
hdf5_input = 1; % 0 to provide a rcf input, 1 to provide a HDF5 input
InputRCFFilename = 'RecordingName.rcf';
InputHDF5Filename = 'RecordingName.h5';

CPI_s = 0.25; % The CPI in seconds
EnableCancellation = 1; % Enable or disable cancellation
CancellationMaxRange_m = 15000; % The cancellation range extent in metres
CancallationMaxDoppler_Hz = 0; % The cancellation Doppler extent in Hertz (ranges from - to + of this value)
CancellationNInterations = 5; % The number of CGLS cancellation iterations
CancellationNSegments = 8; %Number segments each CPI is split into for cancellation

ARDMaxRange_m = 15000; % The range extent of the ARD
ARDMaxDoppler_Hz = 88; % The Doppler extent of the ARD (from - to + of this value)
TxToReferenceRxDistance_m = 0; % The baseline distance
outputARDPath = './Output'; % The path in which to store the resultant ARD maps

if hdf5_input == 1
    % Run the line below to determine which GSNC chunk (GSNC_dataX) to extract
    % whos('-file', InputHDF5Filename)
    fprintf('Reading HDF5 File..\n')
    % Read the data chunk
    load(InputHDF5Filename, 'GSNC_data2', '-mat');
    % Read the sample rate
    load(InputHDF5Filename, 'SR_uHz', '-mat');
    % Read the centre frequency
    load(InputHDF5Filename, 'GCF_uHz', '-mat');
    % Read the bandwidth
    load(InputHDF5Filename, 'GCBW_uHz', '-mat');
    fprintf('HDF5 file read completed\n');

    % Specify the indices of the reference and surveillance channel
    RefChannelIndex = 1;
    SurvChannelIndex = 2;
    RefData = single(GSNC_data2(:,RefChannelIndex));
    SurvData = single(GSNC_data2(:,SurvChannelIndex));
    clear GSNC_data2;

    % Compute the number of samples in the CPI
    CPISize_nSamp = (double(SR_uHz) / 1000000) * CPI_s;
    TotalNumSamples = length(RefData);
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
addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')
addpath('./Input');

clear;
clc;
close all;

% The input file created by combineRxData.m
InputRCFFilename = 'Input/CleanSingleTarget/ArmasuisseClean.rcf';

CPI_s = 4.000; % CPI Duration

% --- Cancellation Settings ---
EnableCancellation = 1;
CancellationMaxRange_m = 85000;
CancallationMaxDoppler_Hz = 5;
CancellationNInterations = 15;
CancellationNSegments = 4;

% --- DSI Metric Settings ---
EnableDSIMetrics = 1;
EnableCAFMetric = 0;
DSI_EPS = 1e-30;
CAF_NearZeroBins = 128;

% --- ARD Coverage Parameters ---
ARDMaxRange_m = 250100;
ARDMaxDoppler_Hz = 200;
TxToReferenceRxDistance_m = 74460;

outputARDPath = './Output';

% Ensure output directory exists
if ~exist(outputARDPath, 'dir')
    mkdir(outputARDPath);
end

fprintf('Opening RCF File: %s\n', InputRCFFilename);
oInputRCFHeader = cRCF;
oInputRCFHeader.readHeaderFromFile(InputRCFFilename);

% Calculate samples per CPI based on the file's actual sample rate
CPISize_nSamp = floor(oInputRCFHeader.getFs_Hz() * CPI_s);
TotalNumSamples = oInputRCFHeader.getNSamples();

%% Loop per CPI:
nCPIs = floor(TotalNumSamples / CPISize_nSamp);
CPIStartSampleNumber =  0;
CGLSAlpha = 0;

fprintf('Total CPIs to process: %d\n', nCPIs);

total_power_reduction_history = zeros(nCPIs, 1);
dsi_projection_suppression_history = zeros(nCPIs, 1);
rho_pre_history = zeros(nCPIs, 1);
rho_post_history = zeros(nCPIs, 1);
rho_drop_history = zeros(nCPIs, 1);
caf_nearzero_suppression_history = zeros(nCPIs, 1);

for CPINo = 0:nCPIs - 1

    fprintf('Processing CPI %i of %i (Time: %.2fs):\n', CPINo + 1, nCPIs, CPINo * CPI_s);

    oCPIRCF = oInputRCFHeader.readFromFile(InputRCFFilename, CPIStartSampleNumber+1, CPISize_nSamp);

    %Now advance starting sample by 1 CPI for next interation
    CPIStartSampleNumber = CPIStartSampleNumber + CPISize_nSamp;

    if(EnableCancellation)
        fprintf('\tDoing cancellation\n');

        % Store pre-cancellation reference and surveillance data
        ref = oCPIRCF.m_fvReferenceData;
        surv_pre = oCPIRCF.m_fvSurveillanceData;

        % Calculate pre-cancellation power
        preCancelPower = mean(abs(surv_pre).^2);

        tic
        [oCPIRCF, CGLSAlpha] = CGLS_Cancellation(oCPIRCF, CancellationMaxRange_m, CancallationMaxDoppler_Hz, TxToReferenceRxDistance_m, CancellationNSegments, CancellationNInterations, CGLSAlpha);
        toc

        % Store post-cancellation surveillance data
        surv_post = oCPIRCF.m_fvSurveillanceData;

        % Calculate post-cancellation power
        postCancelPower = mean(abs(surv_post).^2);

        if EnableDSIMetrics
            ref0 = ref - mean(ref);
            pre0 = surv_pre - mean(surv_pre);
            post0 = surv_post - mean(surv_post);

            total_power_reduction_history(CPINo + 1) = safe_db_ratio(preCancelPower, postCancelPower, DSI_EPS);

            dsi_projection_suppression_history(CPINo + 1) = compute_proj_suppression(surv_pre, surv_post, ref, DSI_EPS);

            [rho_pre_val, rho_post_val] = compute_complex_rho(surv_pre, surv_post, ref, DSI_EPS);
            rho_pre_history(CPINo + 1) = rho_pre_val;
            rho_post_history(CPINo + 1) = rho_post_val;
            rho_drop_history(CPINo + 1) = safe_db_ratio(rho_pre_val, rho_post_val, DSI_EPS);

            if EnableCAFMetric
                caf_nearzero_suppression_history(CPINo + 1) = compute_caf_nearzero_suppression(surv_pre, surv_post, ref, CAF_NearZeroBins, DSI_EPS);
            end
        else
            total_power_reduction_history(CPINo + 1) = 10 * log10(preCancelPower / postCancelPower);
        end
    end

    fprintf('\tDoing range/Doppler processing\n');
    tic
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

fprintf('\n========== METRIC SUMMARY ==========\n');
fprintf('Mean Total Power Reduction: %.2f dB (Std: %.2f dB)\n', mean(total_power_reduction_history), std(total_power_reduction_history));
fprintf('Mean DSI Projection Suppression: %.2f dB (Std: %.2f dB)\n', mean(dsi_projection_suppression_history), std(dsi_projection_suppression_history));
fprintf('Mean Correlation Drop: %.2f dB (Std: %.2f dB)\n', mean(rho_drop_history), std(rho_drop_history));
fprintf('Rho Pre: %.4f, Rho Post: %.4f\n', mean(rho_pre_history), mean(rho_post_history));
if EnableCAFMetric
    fprintf('Mean CAF Near-Zero Suppression: %.2f dB (Std: %.2f dB)\n', mean(caf_nearzero_suppression_history), std(caf_nearzero_suppression_history));
end
fprintf('=====================================\n');

fprintf('\nTotal Power Reduction per CPI:\n');
for i = 1:length(total_power_reduction_history)
    fprintf('CPI %d: %.2f dB\n', i, total_power_reduction_history(i));
end

fprintf('\nDSI Projection Suppression per CPI:\n');
for i = 1:length(dsi_projection_suppression_history)
    fprintf('CPI %d: %.2f dB\n', i, dsi_projection_suppression_history(i));
end

fprintf('\nCorrelation Drop per CPI:\n');
for i = 1:length(rho_drop_history)
    fprintf('CPI %d: %.2f dB (rho_pre=%.4f, rho_post=%.4f)\n', i, rho_drop_history(i), rho_pre_history(i), rho_post_history(i));
end

if EnableCAFMetric
    fprintf('\nCAF Near-Zero Suppression per CPI:\n');
    for i = 1:length(caf_nearzero_suppression_history)
        fprintf('CPI %d: %.2f dB\n', i, caf_nearzero_suppression_history(i));
    end
end

metricsStruct = struct();
metricsStruct.cpi_index = (1:nCPIs)';
metricsStruct.total_power_reduction_dB = total_power_reduction_history;
metricsStruct.dsi_projection_suppression_dB = dsi_projection_suppression_history;
metricsStruct.rho_pre = rho_pre_history;
metricsStruct.rho_post = rho_post_history;
metricsStruct.rho_drop_dB = rho_drop_history;
if EnableCAFMetric
    metricsStruct.caf_nearzero_suppression_dB = caf_nearzero_suppression_history;
end

metricsStruct.config = struct();
metricsStruct.config.CancellationMaxRange_m = CancellationMaxRange_m;
metricsStruct.config.CancellationMaxDoppler_Hz = CancallationMaxDoppler_Hz;
metricsStruct.config.CancellationNInterations = CancellationNInterations;
metricsStruct.config.CancellationNSegments = CancellationNSegments;
metricsStruct.config.CPI_s = CPI_s;
metricsStruct.config.CPISize_nSamp = CPISize_nSamp;

save(fullfile(outputARDPath, 'dsi_metrics_summary.mat'), 'metricsStruct');

metricHeaders = {'CPI', 'total_power_reduction_dB', 'dsi_projection_suppression_dB', 'rho_pre', 'rho_post', 'rho_drop_dB'};
if EnableCAFMetric
    metricHeaders{end+1} = 'caf_nearzero_suppression_dB';
end
metricData = [(1:nCPIs)', total_power_reduction_history, dsi_projection_suppression_history, rho_pre_history, rho_post_history, rho_drop_history];
if EnableCAFMetric
    metricData = [metricData, caf_nearzero_suppression_history];
end
csvwrite(fullfile(outputARDPath, 'dsi_metrics_summary.csv'), metricData);
fprintf('\nMetrics saved to %s/dsi_metrics_summary.mat and .csv\n', outputARDPath);


%% Helper Functions

function dbVal = safe_db_ratio(num, den, epsVal)
    if nargin < 3
        epsVal = 1e-30;
    end
    num = max(abs(num), epsVal);
    den = max(abs(den), epsVal);
    dbVal = 10 * log10(num / den);
end

function powerRatio = compute_projection_power(sig, ref, epsVal)
    if nargin < 3
        epsVal = 1e-30;
    end
    ref = ref(:);
    sig = sig(:);
    refHerm = ref';
    numerator = abs(refHerm * sig)^2;
    denominator = real(refHerm * ref);
    denominator = max(denominator, epsVal);
    powerRatio = numerator / denominator;
end

function projSupp = compute_proj_suppression(preSig, postSig, refSig, epsVal)
    if nargin < 4
        epsVal = 1e-30;
    end
    preSig = preSig(:);
    postSig = postSig(:);
    refSig = refSig(:);
    
    preSig0 = preSig - mean(preSig);
    postSig0 = postSig - mean(postSig);
    refSig0 = refSig - mean(refSig);
    
    prePower = compute_projection_power(preSig0, refSig0, epsVal);
    postPower = compute_projection_power(postSig0, refSig0, epsVal);
    
    projSupp = safe_db_ratio(prePower, postPower, epsVal);
end

function [rho_pre, rho_post] = compute_complex_rho(preSig, postSig, refSig, epsVal)
    if nargin < 4
        epsVal = 1e-30;
    end
    refSig = refSig(:);
    preSig = preSig(:);
    postSig = postSig(:);
    
    ref0 = refSig - mean(refSig);
    pre0 = preSig - mean(preSig);
    post0 = postSig - mean(postSig);
    
    refHerm = refSig';
    
    num_pre = abs(refHerm * pre0);
    den_pre = norm(ref0) * norm(pre0);
    den_pre = max(den_pre, epsVal);
    rho_pre = min(num_pre / den_pre, 1.0);
    
    num_post = abs(refHerm * post0);
    den_post = norm(ref0) * norm(post0);
    den_post = max(den_post, epsVal);
    rho_post = min(num_post / den_post, 1.0);
end

function cafSupp = compute_caf_nearzero_suppression(preSig, postSig, refSig, nBins, epsVal)
    if nargin < 5
        epsVal = 1e-30;
    end
    
    nSamples = min(length(preSig), length(postSig), length(refSig));
    preSig = preSig(1:nSamples);
    postSig = postSig(1:nSamples);
    refSig = refSig(1:nSamples);
    
    nBins = min(nBins, floor(nSamples/2));
    
    preSig0 = preSig - mean(preSig);
    postSig0 = postSig - mean(postSig);
    refSig0 = refSig - mean(refSig);
    
    preCorr = zeros(nBins, 1);
    postCorr = zeros(nBins, 1);
    
    for k = 1:nBins
        if k == 1
            preCorr(k) = preSig0' * preSig0;
            postCorr(k) = postSig0' * postSig0;
        else
            preCorr(k) = preSig0(k:end)' * preSig0(1:end-k+1);
            postCorr(k) = postSig0(k:end)' * postSig0(1:end-k+1);
        end
    end
    
    preEnergy = sum(abs(preCorr).^2);
    postEnergy = sum(abs(postCorr).^2);
    
    preEnergy = max(preEnergy, epsVal);
    postEnergy = max(postEnergy, epsVal);
    
    cafSupp = 10 * log10(preEnergy / postEnergy);
end
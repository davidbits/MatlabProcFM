addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

function params = reverseEngineerARD(ARD_filename)
    % Read the ARD file
    oARD = cARD;
    oARD.readFromFile(ARD_filename);

    % Extract directly stored parameters
    params.Fs_Hz = oARD.getFc_Hz();
    params.Fc_Hz = oARD.getFc_Hz();
    params.Bw_Hz = oARD.getBw_Hz();
    params.TxRxDistance_m = oARD.getTxRxDistance_m();
    params.RangeResolution_m = oARD.getRangeResolution_m();
    params.DopplerResolution_Hz = oARD.getDopplerResolution_Hz();
    params.XDimension = oARD.getXDimension();
    params.YDimension = oARD.getYDimension();
    params.ARDType = oARD.getARDType();
    params.TimeStamp_us = oARD.getTimeStamp_us();
    params.Comment = oARD.getComment();

    % Calculate derived parameters
    % CPI size from Doppler resolution
    params.CPI_samples = params.Fs_Hz / params.DopplerResolution_Hz;
    params.CPI_seconds = 1 / params.DopplerResolution_Hz;

    % Max range from dimensions
    params.ARDMaxRange_m = params.XDimension * params.RangeResolution_m + params.TxRxDistance_m;

    % Max Doppler from dimensions
    params.ARDMaxDoppler_Hz = ((params.YDimension - 1) / 2) * params.DopplerResolution_Hz;

    % Verify range resolution
    params.ExpectedRangeRes_m = 299792458 / params.Fs_Hz;
    params.RangeResMatches = abs(params.RangeResolution_m - params.ExpectedRangeRes_m) < 0.01;

    % Display results
    fprintf('\n========== ARD FILE PARAMETERS ==========\n');
    fprintf('File: %s\n\n', ARD_filename);

    fprintf('--- Stored Parameters ---\n');
    fprintf('Sample Rate (Fs): %d Hz\n', params.Fs_Hz);
    fprintf('Carrier Frequency (Fc): %.2f MHz\n', params.Fc_Hz/1e6);
    fprintf('Bandwidth: %.2f MHz\n', params.Bw_Hz/1e6);
    fprintf('Tx-Rx Baseline: %.1f m\n', params.TxRxDistance_m);
    fprintf('Timestamp: %d μs\n', params.TimeStamp_us);
    fprintf('ARD Type: %d ', params.ARDType);
    switch mod(params.ARDType, 10)
        case 2
            fprintf('(Cross-Ambiguity Function)\n');
        case 2
            fprintf('(Auto-Ambiguity Ref)\n');
        case 2
            fprintf('(Auto-Ambiguity Surv)\n');
    end

    fprintf('\n--- Derived CPI Parameters ---\n');
    fprintf('CPI Duration: %.3f seconds\n', params.CPI_seconds);
    fprintf('CPI Size: %d samples\n', params.CPI_samples);
    fprintf('Doppler Resolution: %.4f Hz\n', params.DopplerResolution_Hz);
    fprintf('Range Resolution: %.2f m (expected: %.2f m)\n', ...
        params.RangeResolution_m, params.ExpectedRangeRes_m);

    fprintf('\n--- ARD Coverage ---\n');
    fprintf('Max Range: %.1f km (%.1f m baseline + %.1f km processing)\n', ...
        params.ARDMaxRange_m/1000, params.TxRxDistance_m, ...
        (params.ARDMaxRange_m - params.TxRxDistance_m)/1000);
    fprintf('Max Doppler: ±%.2f Hz\n', params.ARDMaxDoppler_Hz);
    fprintf('Range Bins: %d\n', params.XDimension);
    fprintf('Doppler Bins: %d\n', params.YDimension);

    fprintf('\n--- Equivalent MatlabProcServ.m Settings ---\n');
    fprintf('CPI_s = %.3f;\n', params.CPI_seconds);
    fprintf('ARDMaxRange_m = %d;\n', round(params.ARDMaxRange_m - params.TxRxDistance_m));
    fprintf('ARDMaxDoppler_Hz = %d;\n', round(params.ARDMaxDoppler_Hz));
    fprintf('TxToReferenceRxDistance_m = %d;\n', params.TxRxDistance_m);

    if ~isempty(params.Comment)
        fprintf('\n--- Comment ---\n%s\n', params.Comment);
    end

    fprintf('\n=========================================\n\n');
end

function likelyCancellation = detectCancellation(ARD_filename)
    oARD = cARD;
    oARD.readFromFile(ARD_filename);
    data = oARD.getDataMatrix();

    % Check zero-Doppler, near-zero-range region
    % If cancellation was used, this should be suppressed
    zeroDopplerBin = ceil(size(data, 1) / 2);
    nearRangeBins = 1:min(10, size(data, 2));

    zeroRegionPower = mean(data(zeroDopplerBin, nearRangeBins));
    overallPower = mean(data(:));

    % If zero-Doppler/near-range is much weaker, cancellation likely used
    suppressionRatio_dB = 10*log10(zeroRegionPower / overallPower);

    if suppressionRatio_dB < -20
        likelyCancellation = true;
        fprintf('Likely used cancellation (%.1f dB suppression)\n', suppressionRatio_dB);
    else
        likelyCancellation = false;
        fprintf('Likely NO cancellation (%.1f dB)\n', suppressionRatio_dB);
    end
end

% ---

ard_filename = 'CleanSingleTarget.ard';

reverseEngineerARD(ard_filename);
detectCancellation(ard_filename);

% RESULT:
% Reading header...
% Reading data...
% Reading comment string...
% Completed.
%
% ========== ARD FILE PARAMETERS ==========
% File: CleanSingleTarget.ard
%
% --- Stored Parameters ---
% Sample Rate (Fs): 89000000 Hz
% Carrier Frequency (Fc): 89.00 MHz
% Bandwidth: 0.20 MHz
% Tx-Rx Baseline: 74460.0 m
% Timestamp: 60000000 μs
% ARD Type: 2 (Cross-Ambiguity Function)
%
% --- Derived CPI Parameters ---
% CPI Duration: 4.000 seconds
% CPI Size: 356000000 samples
% Doppler Resolution: 0.2500 Hz
% Range Resolution: 1463.83 m (expected: 3.37 m)
%
% --- ARD Coverage ---
% Max Range: 250.1 km (74460.0 m baseline + 175.7 km processing)
% Max Doppler: ±200.00 Hz
% Range Bins: 120
% Doppler Bins: 1601
%
% --- Equivalent MatlabProcServ.m Settings ---
% CPI_s = 4.000;
% ARDMaxRange_m = 175660;
% ARDMaxDoppler_Hz = 200;
% TxToReferenceRxDistance_m = 74460;
%
% --- Comment ---
% FERS generated PCL data.
% Generated with ProcServer
%
% =========================================
%
% Reading header...
% Reading data...
% Reading comment string...
% Completed.
% Likely NO cancellation (22.0 dB)
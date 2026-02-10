% Script: verify_makeTxData.m
% Purpose: To validate the output of makeTxData.m by comparing the contents
%          of txWaveFormNormalised.h5 against a freshly generated "ground truth"
%          from the source RCF file.

clear; clc; close all;

fprintf('--- Verification of txWaveFormNormalised.h5 ---\n\n');

% Add path to the cRCF class definition
addpath('AnalysisChain/Classes');

% --- Configuration (Should match makeTxData.m) ---
sourceRcfFile = 'Scripts/Malmesbury_1.rcf';
outputH5File  = 'Scripts/txWaveFormNormalised.h5';
Fs            = 204800;
tStart_s      = 360;
tLength_s     = 180;

allChecksPassed = true;

%% Step 1: Generate the "Ground Truth" data from the source RCF
% This section replicates the logic of makeTxData.m to create the expected result.
fprintf('Step 1: Generating ground truth data from %s...\n', sourceRcfFile);
try
    oRCF_source = cRCF;
    startSample = (tStart_s * Fs) + 1; % RCF class is 1-indexed
    numSamples = tLength_s * Fs;
    oRCF_source.readFromFile(sourceRcfFile, startSample, numSamples);

    ref_source = oRCF_source.getReferenceData();

    % Perform normalization exactly as in the original script
    refPower = var(ref_source);
    expected_data = ref_source .* (1 / sqrt(refPower));

    fprintf(' -> Ground truth data generated successfully.\n\n');
catch ME
    fprintf('[FATAL ERROR] Could not read or process the source file %s.\n', sourceRcfFile);
    fprintf('Please ensure the file exists and is in the correct path.\n');
    rethrow(ME);
end

%% Step 2: Load the data from the HDF5 file being tested
fprintf('Step 2: Loading test data from %s...\n', outputH5File);
if ~exist(outputH5File, 'file')
    fprintf('[FATAL ERROR] The HDF5 file does not exist: %s\n', outputH5File);
    return;
end

try
    I_h5 = h5read(outputH5File, '/I/value');
    Q_h5 = h5read(outputH5File, '/Q/value');
    loaded_data = complex(I_h5, Q_h5);
    fprintf(' -> HDF5 data loaded successfully.\n\n');
catch ME
    fprintf('[FATAL ERROR] Could not read data from the HDF5 file.\n');
    fprintf('The file might be corrupt or have an incorrect internal structure.\n');
    fprintf('It should contain datasets "/I/value" and "/Q/value".\n');
    rethrow(ME);
end

%% Step 3: Perform Numerical Checks
fprintf('Step 3: Performing numerical validation checks...\n');

% Check 3.1: Data Length
expected_length = tLength_s * Fs;
if length(loaded_data) == expected_length
    fprintf(' [PASS] Data length is correct (%d samples).\n', expected_length);
else
    fprintf(' [FAIL] Data length is INCORRECT. Expected: %d, Got: %d.\n', expected_length, length(loaded_data));
    allChecksPassed = false;
end

% Check 3.2: Data Complexity (Q-channel is not zero)
power_Q_loaded = var(imag(loaded_data));
if power_Q_loaded > 1e-10
    fprintf(' [PASS] Data is complex (Q-channel has significant power: %e).\n', power_Q_loaded);
else
    fprintf(' [FAIL] Data appears to be REAL. Q-channel power is negligible (%e).\n', power_Q_loaded);
    allChecksPassed = false;
end

% Check 3.3: Normalization
power_loaded = var(loaded_data);
if abs(power_loaded - 1.0) < 1e-6 % Use a small tolerance for floating point math
    fprintf(' [PASS] Data is correctly normalized (Power = %f).\n', power_loaded);
else
    fprintf(' [FAIL] Data is NOT correctly normalized. Expected Power=1.0, Got: %f.\n', power_loaded);
    allChecksPassed = false;
end

% Check 3.4: Data Integrity (Bit-for-bit comparison)
mse = mean(abs(loaded_data - expected_data).^2);
if mse < 1e-12 % Use a very small tolerance for floating point precision
    fprintf(' [PASS] Data integrity confirmed. Loaded data matches ground truth (MSE = %e).\n', mse);
else
    fprintf(' [FAIL] Data integrity check failed. Loaded data does NOT match ground truth (MSE = %e).\n', mse);
    allChecksPassed = false;
end
fprintf('\n');

%% Step 4: Visual Verification
fprintf('Step 4: Generating plots for visual verification...\n');

% Plot 1: Time Domain Overlay (first 1000 samples)
figure('Name', 'Verification Plots for txWaveFormNormalised.h5', 'NumberTitle', 'off');
subplot(2,2,1);
plot(real(expected_data(1:1000)), 'b-', 'LineWidth', 1.5);
hold on;
plot(real(loaded_data(1:1000)), 'r--');
grid on;
title('Time Domain: Real (I) Component');
xlabel('Sample'); ylabel('Amplitude');
legend('Expected', 'Loaded');

subplot(2,2,2);
plot(imag(expected_data(1:1000)), 'b-', 'LineWidth', 1.5);
hold on;
plot(imag(loaded_data(1:1000)), 'r--');
grid on;
title('Time Domain: Imaginary (Q) Component');
xlabel('Sample'); ylabel('Amplitude');
legend('Expected', 'Loaded');

% Plot 2: Spectrum Comparison
subplot(2,2,3);
plot(abs(fftshift(fft(expected_data))), 'b-', 'LineWidth', 1.5);
hold on;
plot(abs(fftshift(fft(loaded_data))), 'r--');
grid on;
title('Frequency Spectrum');
xlabel('Frequency Bin'); ylabel('Magnitude');
legend('Expected', 'Loaded');

% Plot 3: Error Plot
subplot(2,2,4);
plot(abs(expected_data - loaded_data));
grid on;
title('Absolute Error |Expected - Loaded|');
xlabel('Sample'); ylabel('Error Magnitude');
axis tight;

fprintf(' -> Plots generated. Check for perfect overlays in top and left plots.\n\n');

%% Final Verdict
fprintf('--- FINAL VERDICT ---\n');
if allChecksPassed
    fprintf('SUCCESS: The file "txWaveFormNormalised.h5" is valid and correctly generated.\n');
    fprintf('It accurately represents the normalized 180s segment from Malmesbury_1.rcf.\n');
else
    fprintf('FAILURE: The file "txWaveFormNormalised.h5" is INVALID or was generated incorrectly.\n');
    fprintf('Review the [FAIL] messages above to diagnose the specific problem.\n');
end
fprintf('---------------------\n');
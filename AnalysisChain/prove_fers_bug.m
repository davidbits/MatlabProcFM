% Script: prove_fers_bug.m
clear; clc;

file_clean = 'Input/CleanSingleTarget/ArmasuisseRefRxClean.h5'; % From the 16kW only run
file_jammer = 'Input/JamSingleTarget/ArmasuisseRefRxJam.h5';   % From the 16kW + 1W Jammer run

fprintf('--- FERS Simulator Bug Detection ---\n');

% Load first chunk from both
data_clean = h5read(file_clean, '/chunk_000000_I');
data_jammer = h5read(file_jammer, '/chunk_000000_I');

% Calculate Power
pwr_clean = var(data_clean);
pwr_jammer = var(data_jammer);

% Calculate Correlation between the two simulation outputs
% They SHOULD be almost 1.0 if FERS is adding signals correctly.
rho = corrcoef(data_clean, data_jammer);
rho = rho(1,2);

fprintf('Power (Clean Run):  %.6e\n', pwr_clean);
fprintf('Power (Jammer Run): %.6e\n', pwr_jammer);
fprintf('Correlation (rho):  %.6f\n', rho);

if rho < 0.99
    fprintf('\n[!!!] BUG CONFIRMED: The simulator output changed drastically\n');
    fprintf('when a 1W jammer was added. The 16kW signal is being corrupted.\n');
else
    fprintf('\n[PASS] The simulator is summing signals correctly.\n');
end

% Check for Clipping/Wrapping
if max(abs(data_jammer)) > 0.99 % Assuming FERS normalizes to 1.0
     fprintf('[!!!] BUG SUSPECTED: Signal is hitting the rails (Clipping).\n');
end
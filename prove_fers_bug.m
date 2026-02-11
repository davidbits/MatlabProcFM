% Script: prove_fers_bug.m
% Purpose: Rigorous FERS multi-transmitter bug detection using physically-scaled complex IQ data via loadfersHDF5.

clear; clc;
addpath('AnalysisChain/ARDMakers');  % For loadfersHDF5

%% ========================================================================
%  FILE PATHS
%  ========================================================================
% Clean (FM transmitter only)
files.clean.ref = 'AnalysisChain/Input/CleanSingleTarget_fers_latest/ArmasuisseRefRx_results.h5';
files.clean.sur = 'AnalysisChain/Input/CleanSingleTarget_fers_latest/ArmasuisseSurRx_results.h5';

% Wideband FM Jammer (FM transmitter + 1W wideband jammer)
files.wbjam.ref = 'AnalysisChain/Input/JamSingleTarget_fers_latest/ArmasuisseRefRx_results.h5';
files.wbjam.sur = 'AnalysisChain/Input/JamSingleTarget_fers_latest/ArmasuisseSurRx_results.h5';

%% ========================================================================
%  HELPER: Load and scale a FERS HDF5 file into a complex signal
%  ========================================================================
load_complex = @(filepath) load_fers_complex(filepath);

%% ========================================================================
%  LOAD ALL DATA
%  ========================================================================
fprintf('===================================================================\n');
fprintf('  FERS Simulator Bug Detection (fullscale-corrected, complex IQ)\n');
fprintf('===================================================================\n\n');

fprintf('Loading Clean scenario...\n');
[clean_ref, clean_ref_meta] = load_complex(files.clean.ref);
[clean_sur, clean_sur_meta] = load_complex(files.clean.sur);

fprintf('Loading Wideband Jammer scenario...\n');
[wbjam_ref, wbjam_ref_meta] = load_complex(files.wbjam.ref);
[wbjam_sur, wbjam_sur_meta] = load_complex(files.wbjam.sur);

%% ========================================================================
%  REPORT FULLSCALE FACTORS
%  ========================================================================
fprintf('\n--- Fullscale Attributes (ADC-to-Physical Scaling) ---\n');
fprintf('  Clean   Ref: %.6e    Sur: %.6e\n', clean_ref_meta.scale, clean_sur_meta.scale);
fprintf('  WB Jam  Ref: %.6e    Sur: %.6e\n', wbjam_ref_meta.scale, wbjam_sur_meta.scale);

if abs(clean_ref_meta.scale - wbjam_ref_meta.scale) / clean_ref_meta.scale > 0.01
    fprintf('  [NOTE] Ref fullscale differs between Clean and WB Jammer by %.1f%%\n', ...
        100 * abs(clean_ref_meta.scale - wbjam_ref_meta.scale) / clean_ref_meta.scale);
end

%% ========================================================================
%  TRUNCATE TO COMMON LENGTH (safety)
%  ========================================================================
len_ref_wb   = min(length(clean_ref), length(wbjam_ref));
len_sur_wb   = min(length(clean_sur), length(wbjam_sur));

%% ========================================================================
%  POWER ANALYSIS (fullscale-corrected complex power)
%  ========================================================================
fprintf('\n===================================================================\n');
fprintf('  POWER ANALYSIS (fullscale-corrected, complex magnitude)\n');
fprintf('===================================================================\n');
fprintf('  Power = var(real) + var(imag) of the scaled complex signal\n\n');

% --- Reference Channel ---
pwr_clean_ref     = complex_power(clean_ref);
pwr_wbjam_ref     = complex_power(wbjam_ref);

% --- Surveillance Channel ---
pwr_clean_sur     = complex_power(clean_sur);
pwr_wbjam_sur     = complex_power(wbjam_sur);

fprintf('  %-30s  %14s  %14s\n', '', 'Reference', 'Surveillance');
fprintf('  %-30s  %14s  %14s\n', '', '---------', '------------');
fprintf('  %-30s  %14.6e  %14.6e\n', 'Clean (FM only)',        pwr_clean_ref,   pwr_clean_sur);
fprintf('  %-30s  %14.6e  %14.6e\n', 'Wideband Jammer (FM+1W)', pwr_wbjam_ref,   pwr_wbjam_sur);
fprintf('\n');

delta_pwr_ref_wb   = pwr_wbjam_ref   - pwr_clean_ref;
delta_pwr_sur_wb   = pwr_wbjam_sur   - pwr_clean_sur;

fprintf('  Delta Power (Jammer - Clean):\n');
fprintf('  %-30s  %+14.6e  %+14.6e\n', 'Wideband Jammer', delta_pwr_ref_wb,   delta_pwr_sur_wb);
fprintf('\n');

fprintf('  Percentage Change:\n');
fprintf('  %-30s  %+13.2f%%  %+14.2f%%\n', 'Wideband Jammer', ...
    100 * delta_pwr_ref_wb / pwr_clean_ref, 100 * delta_pwr_sur_wb / pwr_clean_sur);

% Superposition check
fprintf('\n  Superposition Check:\n');
if delta_pwr_ref_wb < 0
    fprintf('  [FAIL] Ref power DECREASED by %.2f%% with wideband jammer (violates P_total = P1 + P2)\n', ...
        abs(100 * delta_pwr_ref_wb / pwr_clean_ref));
else
    fprintf('  [PASS] Ref power increased or unchanged with wideband jammer\n');
end
if delta_pwr_sur_wb < 0
    fprintf('  [FAIL] Sur power DECREASED by %.2f%% with wideband jammer (violates P_total = P1 + P2)\n', ...
        abs(100 * delta_pwr_sur_wb / pwr_clean_sur));
else
    fprintf('  [PASS] Sur power increased or unchanged with wideband jammer\n');
end

%% ========================================================================
%  CORRELATION ANALYSIS (complex signals)
%  ========================================================================
fprintf('\n===================================================================\n');
fprintf('  CORRELATION ANALYSIS (fullscale-corrected)\n');
fprintf('===================================================================\n');
fprintf('  Expected: rho > 0.99 if FERS sums signals correctly\n');
fprintf('  (16kW FM dominates; 1W jammer is negligible at Ref Rx)\n\n');

% Complex correlation: rho = |<x,y>| / (||x|| * ||y||)
% Also compute real-part-only correlation for comparison with original script

% --- Wideband Jammer vs Clean ---
rho_ref_wb_complex = complex_corr(clean_ref(1:len_ref_wb), wbjam_ref(1:len_ref_wb));
rho_sur_wb_complex = complex_corr(clean_sur(1:len_sur_wb), wbjam_sur(1:len_sur_wb));
rho_ref_wb_real    = real_corr(clean_ref(1:len_ref_wb), wbjam_ref(1:len_ref_wb));
rho_sur_wb_real    = real_corr(clean_sur(1:len_sur_wb), wbjam_sur(1:len_sur_wb));

fprintf('  %-35s  %10s  %10s\n', 'Comparison', 'Ref rho', 'Sur rho');
fprintf('  %-35s  %10s  %10s\n', '', '-------', '-------');
fprintf('  %-35s  %+10.6f  %+10.6f\n', 'WB Jam vs Clean (complex |rho|)',  rho_ref_wb_complex,   rho_sur_wb_complex);
fprintf('  %-35s  %+10.6f  %+10.6f\n', 'WB Jam vs Clean (real-part rho)',  rho_ref_wb_real,      rho_sur_wb_real);

fprintf('\n  Decorrelation Assessment:\n');
rho_threshold = 0.99;
test_cases = { ...
    'Ref (WB Jammer, complex)',   rho_ref_wb_complex; ...
    'Sur (WB Jammer, complex)',   rho_sur_wb_complex; ...
};
for i = 1:size(test_cases, 1)
    if test_cases{i, 2} < rho_threshold
        fprintf('  [FAIL] %s: rho = %.6f  (expected > %.2f)\n', ...
            test_cases{i, 1}, test_cases{i, 2}, rho_threshold);
    else
        fprintf('  [PASS] %s: rho = %.6f\n', test_cases{i, 1}, test_cases{i, 2});
    end
end

%% ========================================================================
%  Q-CHANNEL ANALYSIS (Q=0 / real-valued signal hypothesis)
%  ========================================================================
fprintf('\n===================================================================\n');
fprintf('  Q-CHANNEL ANALYSIS (I/Q integrity check)\n');
fprintf('===================================================================\n');
fprintf('  If Q=0 in jammer runs, the signal is real-valued and will\n');
fprintf('  produce mirrored +/- Doppler lines in the ARD.\n\n');

% Power in I and Q channels separately (after fullscale scaling)
channels = { ...
    'Clean Ref',    clean_ref; ...
    'Clean Sur',    clean_sur; ...
    'WB Jam Ref',   wbjam_ref; ...
    'WB Jam Sur',   wbjam_sur; ...
};

fprintf('  %-18s  %14s  %14s  %10s\n', 'Signal', 'P(I)', 'P(Q)', 'Q/I Ratio');
fprintf('  %-18s  %14s  %14s  %10s\n', '------', '----', '----', '---------');

for i = 1:size(channels, 1)
    sig = channels{i, 2};
    pI = var(real(sig));
    pQ = var(imag(sig));
    if pI > 0
        ratio = pQ / pI;
    else
        ratio = NaN;
    end
    fprintf('  %-18s  %14.6e  %14.6e  %10.6f\n', channels{i, 1}, pI, pQ, ratio);

    % Flag anomalies
    if ratio < 0.01
        fprintf('  [!!!] %s: Q-channel power is <1%% of I-channel (effectively real-valued)\n', channels{i, 1});
    elseif ratio < 0.5 || ratio > 2.0
        fprintf('  [WARN] %s: I/Q power imbalance (ratio = %.4f, expected ~1.0 for complex baseband)\n', ...
            channels{i, 1}, ratio);
    end
end

%% ========================================================================
%  CLIPPING / SATURATION CHECK
%  ========================================================================
fprintf('\n===================================================================\n');
fprintf('  CLIPPING / SATURATION CHECK\n');
fprintf('===================================================================\n\n');

signals = { ...
    'Clean Ref',    clean_ref; ...
    'Clean Sur',    clean_sur; ...
    'WB Jam Ref',   wbjam_ref; ...
    'WB Jam Sur',   wbjam_sur; ...
};

for i = 1:size(signals, 1)
    sig = signals{i, 2};
    peak_I = max(abs(real(sig)));
    peak_Q = max(abs(imag(sig)));
    fprintf('  %-18s  Peak |I|: %.6e   Peak |Q|: %.6e\n', signals{i, 1}, peak_I, peak_Q);
end

%% ========================================================================
%  LOCAL FUNCTIONS
%  ========================================================================

function [sig, meta] = load_fers_complex(filepath)
    % Load a FERS HDF5 file and return the fullscale-corrected complex signal
    % along with metadata (scale factor, lengths).
    if ~exist(filepath, 'file')
        error('File not found: %s', filepath);
    end
    [I, Q, scale] = loadfersHDF5(filepath);
    sig = complex(double(I), double(Q)) * double(scale);
    meta.scale = double(scale);
    meta.nSamples = length(sig);
    meta.filepath = filepath;
    fprintf('  Loaded %s  (%d samples, fullscale = %.6e)\n', filepath, meta.nSamples, meta.scale);
end

function pwr = complex_power(sig)
    % Total power of a complex signal: var(I) + var(Q)
    pwr = var(real(sig)) + var(imag(sig));
end

function rho = complex_corr(x, y)
    % Normalised complex cross-correlation magnitude:
    %   |rho| = |sum(x .* conj(y))| / (norm(x) * norm(y))
    % This is invariant to phase offset and linear scaling.
    x = x - mean(x);
    y = y - mean(y);
    rho = abs(sum(x .* conj(y))) / (norm(x) * norm(y));
end

function rho = real_corr(x, y)
    % Standard Pearson correlation on the real parts only
    % (for direct comparison with the original prove_fers_bug.m)
    rx = real(x);
    ry = real(y);
    C = corrcoef(rx, ry);
    rho = C(1, 2);
end

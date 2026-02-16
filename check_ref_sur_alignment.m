% check_ref_sur_alignment.m
% Purpose:
%   Verify Ref/Sur time alignment and confirm that enabling jammer does not
%   shift sample indices/timestamps.
%
% Method:
%   For each CPI, estimate the integer-sample lag that maximizes the
%   normalized cross-correlation between Sur and Ref (after mean removal).
%   Compare lag estimates between Clean and Jam runs.
%
% Assumptions:
%   - Ref and Sur are same sample rate.
%   - A strong common FM component exists (DSI/leakage), so correlation peak is clear.
%   - Jammer signal is largely uncorrelated with Ref (FM), so it should not move the peak.

clear; clc;

addpath('AnalysisChain/ARDMakers'); % for loadfersHDF5

% =========================
% USER CONFIG
% =========================
Fs = 204800;
CPI_s = 4.0;
CPISize = round(Fs * CPI_s);

% Limit the correlation search window (in samples) to keep it fast.
% Choose wide enough to cover expected ref-sur delay differences.
maxLag_samp = 6000;  % ~29 ms at 204.8 kHz

% Point these at your actual FERS outputs (Clean vs Jam)
clean_ref_h5 = 'AnalysisChain/Input/CleanSingleTarget_fers_latest/ArmasuisseRefRx_results.h5';
clean_sur_h5 = 'AnalysisChain/Input/CleanSingleTarget_fers_latest/ArmasuisseSurRx_results.h5';

jam_ref_h5   = 'AnalysisChain/Input/JamSingleTarget_fers_latest/ArmasuisseRefRx_results.h5';
jam_sur_h5   = 'AnalysisChain/Input/JamSingleTarget_fers_latest/ArmasuisseSurRx_results.h5';

% =========================
% LOAD
% =========================
[clean_ref, ~] = load_complex(clean_ref_h5);
[clean_sur, ~] = load_complex(clean_sur_h5);

[jam_ref, ~]   = load_complex(jam_ref_h5);
[jam_sur, ~]   = load_complex(jam_sur_h5);

% Truncate to common lengths
L_clean = min(length(clean_ref), length(clean_sur));
L_jam   = min(length(jam_ref),   length(jam_sur));

nCPI_clean = floor(L_clean / CPISize);
nCPI_jam   = floor(L_jam   / CPISize);
nCPI = min(nCPI_clean, nCPI_jam);

fprintf('CPIs available: clean=%d, jam=%d, using nCPI=%d\n', nCPI_clean, nCPI_jam, nCPI);

lags_clean = zeros(nCPI,1);
lags_jam   = zeros(nCPI,1);
peak_clean = zeros(nCPI,1);
peak_jam   = zeros(nCPI,1);

% =========================
% ESTIMATE LAG PER CPI
% =========================
for k = 1:nCPI
    idx = (k-1)*CPISize + (1:CPISize);

    rC = clean_ref(idx);
    sC = clean_sur(idx);
    [lags_clean(k), peak_clean(k)] = estimate_lag(rC, sC, maxLag_samp);

    rJ = jam_ref(idx);
    sJ = jam_sur(idx);
    [lags_jam(k), peak_jam(k)] = estimate_lag(rJ, sJ, maxLag_samp);

    if mod(k,10)==0 || k==1
        fprintf('CPI %4d: lag_clean=%6d  lag_jam=%6d  (Δ=%+d)  peakC=%.3g peakJ=%.3g\n', ...
            k, lags_clean(k), lags_jam(k), (lags_jam(k)-lags_clean(k)), peak_clean(k), peak_jam(k));
    end
end

% =========================
% ANALYZE DIFFERENCE
% =========================
dLag = lags_jam - lags_clean;

fprintf('\n=== Alignment Summary ===\n');
fprintf('lag_clean: mean=%.2f samp, std=%.2f\n', mean(lags_clean), std(lags_clean));
fprintf('lag_jam:   mean=%.2f samp, std=%.2f\n', mean(lags_jam), std(lags_jam));
fprintf('Δlag (jam-clean): mean=%.2f samp, std=%.2f, min=%d, max=%d\n', ...
    mean(dLag), std(dLag), min(dLag), max(dLag));

% Simple pass/fail rule:
% If jammer causes shifting indices, you'd typically see Δlag jump by O(1..1000) samples,
% not just occasional ±1 jitter.
tol_samp = 1;  % tighten/relax depending on numerics
nBad = sum(abs(dLag) > tol_samp);

fprintf('Alignment check (|Δlag| > %d samples): %d / %d CPIs flagged\n', tol_samp, nBad, nCPI);

if nBad == 0
    fprintf('[PASS] No evidence that enabling jammer shifts Ref/Sur sample alignment.\n');
else
    fprintf('[WARN] Some CPIs show lag changes beyond tolerance. Investigate export alignment/timestamps.\n');
end

% =========================
% Helper functions
% =========================
function [sig, meta] = load_complex(filepath)
    [I,Q,scale] = loadfersHDF5(filepath);
    sig = complex(double(I), double(Q)) * double(scale);
    meta.scale = double(scale);
    meta.nSamples = length(sig);
end

function [bestLag, bestPeak] = estimate_lag(ref, sur, maxLag)
    % Mean remove (important)
    ref0 = ref(:) - mean(ref);
    sur0 = sur(:) - mean(sur);

    % Normalized cross-correlation within [-maxLag, +maxLag]
    % xcorr(sur, ref): positive lag means sur is delayed relative to ref (MATLAB convention)
    [c, lags] = xcorr(sur0, ref0, maxLag, 'coeff');

    % Find max magnitude peak
    [bestPeak, idx] = max(abs(c));
    bestLag = lags(idx);
end

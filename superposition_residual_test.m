% superposition_residual_test.m
%
% Purpose
% -------
% Rigorous A/B/C superposition residual test for FERS multi-transmitter behavior:
%
%   A = Clean (FM-only)
%   B = Jam-only (jammer-only)
%   C = FM + Jam (both on)
%
% For each channel (Reference, Surveillance), compute:
%   err = C - (A + B)
%
% Report:
%   - Relative residual norm: ||err|| / ||C||
%   - Max absolute residual:  max(|err|)
%   - Optional spectral diagnostics (PSD plots) for err
%
% Data Sources (as requested)
% ---------------------------
%   AnalysisChain/Input/CleanSingleTarget_fers_latest
%   AnalysisChain/Input/JamSingleTarget_fers_latest_jam_only
%   AnalysisChain/Input/JamSingleTarget_fers_latest
%
% NOTES
% -----
% 1) This script assumes the FERS HDF5 files are exported as:
%       ArmasuisseRefRx_results.h5
%       ArmasuisseSurRx_results.h5
%
% 2) Signals are loaded using AnalysisChain/ARDMakers/loadfersHDF5.m
%    which applies the robust "fullscale" attribute handling.
%
% 3) Any mismatch in length is handled by truncating to the shortest
%    within each (A,B,C) set, per channel.
%
% 4) A perfect linear superposition model would yield err ~ numerical noise.
%    Significant structured residuals indicate one of:
%       - overwrite instead of sum
%       - wrong association/export stream
%       - nonlinear scaling/ADC effects applied per-source
%       - metadata inconsistencies (e.g., fullscale differences)
%
% Output
% ------
% Console report, plus optional figures.
%
% David Young / FERS investigation
% -------------------------------------------------------------------------

clear; clc;

%% Configuration
cfg = struct();

% Input directories (relative to project root)
cfg.dirA = 'AnalysisChain/Input/CleanSingleTarget_no_rand';
cfg.dirB = 'AnalysisChain/Input/JamSingleTarget_jam_only';
cfg.dirC = 'AnalysisChain/Input/JamSingleTarget_no_rand';

% Expected filenames
cfg.refName = 'ArmasuisseRefRx.h5';
cfg.surName = 'ArmasuisseSurRx.h5';

% Diagnostics toggles
cfg.enablePlots = true;        % time domain overview plots
cfg.enableSpectra = true;      % PSD plots for C, (A+B), err
cfg.spectrumNFFT = 2^18;       % FFT size for PSD (will be clipped to signal length)
cfg.spectrumWindow = @hann;    % window for PSD
cfg.spectrumOverlap = 0.5;     % fraction overlap
cfg.removeMean = true;         % subtract mean before norms/spectra

% Optional: set this if you know the sample rate (Hz). If empty, the PSD x-axis is "normalized bins".
cfg.Fs_Hz = [];  % e.g., 204800

% Add required paths
addpath('AnalysisChain/ARDMakers');  % loadfersHDF5.m lives here

%% Resolve file paths
paths = struct();
paths.A.ref = fullfile(cfg.dirA, cfg.refName);
paths.A.sur = fullfile(cfg.dirA, cfg.surName);
paths.B.ref = fullfile(cfg.dirB, cfg.refName);
paths.B.sur = fullfile(cfg.dirB, cfg.surName);
paths.C.ref = fullfile(cfg.dirC, cfg.refName);
paths.C.sur = fullfile(cfg.dirC, cfg.surName);

%% Load all signals (fullscale-corrected complex IQ)
fprintf('============================================================\n');
fprintf('  Superposition Residual Test: err = C - (A + B)\n');
fprintf('============================================================\n\n');

[A_ref, meta.A.ref] = load_fers_complex(paths.A.ref);
[A_sur, meta.A.sur] = load_fers_complex(paths.A.sur);

[B_ref, meta.B.ref] = load_fers_complex(paths.B.ref);
[B_sur, meta.B.sur] = load_fers_complex(paths.B.sur);

[C_ref, meta.C.ref] = load_fers_complex(paths.C.ref);
[C_sur, meta.C.sur] = load_fers_complex(paths.C.sur);

%% Print fullscale / length summary
fprintf('\n--- File metadata summary (fullscale + length) ---\n');
print_meta('A Ref (Clean)', meta.A.ref);
print_meta('A Sur (Clean)', meta.A.sur);
print_meta('B Ref (JamOnly)', meta.B.ref);
print_meta('B Sur (JamOnly)', meta.B.sur);
print_meta('C Ref (FM+Jam)', meta.C.ref);
print_meta('C Sur (FM+Jam)', meta.C.sur);

%% Compute residuals per channel
results = struct();
[results.ref, diag_ref] = compute_residual_metrics(A_ref, B_ref, C_ref, cfg);
[results.sur, diag_sur] = compute_residual_metrics(A_sur, B_sur, C_sur, cfg);

%% Report
fprintf('\n============================================================\n');
fprintf('  Residual Metrics\n');
fprintf('============================================================\n');

report_channel('REFERENCE', results.ref);
report_channel('SURVEILLANCE', results.sur);

fprintf('\nInterpretation guidance:\n');
fprintf('  - If ||err||/||C|| is near machine precision (e.g., < 1e-6 to 1e-4), superposition holds.\n');
fprintf('  - If ||err||/||C|| is O(1) or err PSD shows strong structure, suspect overwrite/selection/nonlinearity.\n');
fprintf('  - Compare also ||C|| vs ||A+B||: large mismatch indicates non-summation or scaling differences.\n');

%% Optional plots
if cfg.enablePlots
    plot_overview(diag_ref, 'Reference', cfg);
    plot_overview(diag_sur, 'Surveillance', cfg);
end

if cfg.enableSpectra
    plot_psd_triplet(diag_ref, 'Reference', cfg);
    plot_psd_triplet(diag_sur, 'Surveillance', cfg);
end

fprintf('\nDone.\n');

%% ========================= Local Functions ==============================

function [sig, meta] = load_fers_complex(filepath)
    % Load FERS HDF5 and apply fullscale; return complex(double) vector.

    if exist(filepath, 'file') ~= 2
        error('File not found: %s', filepath);
    end

    [I, Q, scale] = loadfersHDF5(filepath);
    sig = complex(double(I), double(Q)) * double(scale);

    meta = struct();
    meta.filepath = filepath;
    meta.scale = double(scale);
    meta.nSamples = numel(sig);

    % Basic I/Q power sanity
    meta.pI = var(real(sig));
    meta.pQ = var(imag(sig));
    meta.pTotal = meta.pI + meta.pQ;

    fprintf('Loaded %-70s  N=%d  fullscale=%.6e\n', filepath, meta.nSamples, meta.scale);
end

function print_meta(label, m)
    fprintf('  %-16s  N=%-10d  fullscale=%-12.6e  P(I)=%.3e  P(Q)=%.3e  Ptot=%.3e\n', ...
        label, m.nSamples, m.scale, m.pI, m.pQ, m.pTotal);
end

function [out, diag] = compute_residual_metrics(A, B, C, cfg)
    % Computes err = C - (A + B) with truncation to common length.

    n = min([numel(A), numel(B), numel(C)]);
    A = A(1:n);
    B = B(1:n);
    C = C(1:n);

    AB = A + B;
    err = C - AB;

    if cfg.removeMean
        A0 = A - mean(A);
        B0 = B - mean(B);
        C0 = C - mean(C);
        AB0 = AB - mean(AB);
        err0 = err - mean(err);
    else
        A0 = A; B0 = B; C0 = C; AB0 = AB; err0 = err;
    end

    % Norms
    nC = norm(C0);
    nAB = norm(AB0);
    nErr = norm(err0);

    % Relative residual
    rel = safe_div(nErr, nC);

    % Max abs residual (using mean-removed err0 by default; also report raw)
    maxAbsErr0 = max(abs(err0));
    maxAbsErr = max(abs(err));

    % Additional useful ratios
    rel_AB_vs_C = safe_div(norm(C0 - AB0), nC); % identical to rel if mean-removed consistently
    rel_norm_AB_to_C = safe_div(nAB, nC);

    out = struct();
    out.nSamples = n;
    out.normC = nC;
    out.normAB = nAB;
    out.normErr = nErr;
    out.relErr = rel;
    out.maxAbsErr = maxAbsErr;
    out.maxAbsErr0 = maxAbsErr0;
    out.relNormABtoC = rel_norm_AB_to_C;
    out.relABminusC_overC = rel_AB_vs_C;

    diag = struct();
    diag.A = A0;
    diag.B = B0;
    diag.C = C0;
    diag.AB = AB0;
    diag.err = err0;
end

function report_channel(name, r)
    fprintf('\n--- %s ---\n', name);
    fprintf('  N samples:                 %d\n', r.nSamples);
    fprintf('  ||C||:                     %.6e\n', r.normC);
    fprintf('  ||A+B||:                   %.6e\n', r.normAB);
    fprintf('  ||err||:                   %.6e\n', r.normErr);
    fprintf('  ||err||/||C||:             %.6e\n', r.relErr);
    fprintf('  ||A+B||/||C||:             %.6e   (should be ~1)\n', r.relNormABtoC);
    fprintf('  max(|err|) (raw):          %.6e\n', r.maxAbsErr);
    fprintf('  max(|err|) (mean-removed): %.6e\n', r.maxAbsErr0);
end

function y = safe_div(a, b)
    if b == 0
        y = NaN;
    else
        y = a / b;
    end
end

function plot_overview(diag, label, cfg)
    % Simple time-domain magnitude overview (first few ms worth of samples).
    n = numel(diag.C);
    nShow = min(n, 20000);

    figure('Name', ['Superposition Overview - ' label], 'Color', 'w');

    subplot(3,1,1);
    plot(abs(diag.C(1:nShow)));
    grid on; title([label ' |C|']); xlabel('Sample'); ylabel('|C|');

    subplot(3,1,2);
    plot(abs(diag.AB(1:nShow)));
    grid on; title([label ' |A+B|']); xlabel('Sample'); ylabel('|A+B|');

    subplot(3,1,3);
    plot(abs(diag.err(1:nShow)));
    grid on; title([label ' |err| = |C-(A+B)|']); xlabel('Sample'); ylabel('|err|');
end

function plot_psd_triplet(diag, label, cfg)
    % Welch PSD of C, (A+B), and err to check if residual is structured.

    xC = diag.C;
    xAB = diag.AB;
    xE = diag.err;

    n = numel(xC);
    nfft = min(cfg.spectrumNFFT, 2^nextpow2(n));
    winLen = min(n, max(1024, floor(nfft/4)));
    win = cfg.spectrumWindow(winLen);
    nover = floor(winLen * cfg.spectrumOverlap);

    if isempty(cfg.Fs_Hz)
        Fs = 1;   % normalized
        xlab = 'Normalized Frequency (cycles/sample)';
    else
        Fs = cfg.Fs_Hz;
        xlab = 'Frequency (Hz)';
    end

    [PC, f]  = pwelch(xC, win, nover, nfft, Fs, 'centered');
    [PAB, ~] = pwelch(xAB, win, nover, nfft, Fs, 'centered');
    [PE, ~]  = pwelch(xE, win, nover, nfft, Fs, 'centered');

    figure('Name', ['Residual PSD - ' label], 'Color', 'w');
    plot(f, 10*log10(PC + eps), 'LineWidth', 1.1); hold on;
    plot(f, 10*log10(PAB + eps), 'LineWidth', 1.1);
    plot(f, 10*log10(PE + eps), 'LineWidth', 1.1);
    grid on;
    title([label ' Welch PSD: C vs (A+B) vs err']);
    xlabel(xlab);
    ylabel('PSD (dB)');
    legend('C', 'A+B', 'err', 'Location', 'best');
end

% Script: inspect_fers_outputs.m
% Purpose: Direct inspection of FERS HDF5 output files to verify simulation
%          integrity, signal power, and attribute correctness.

clear; clc; close all;

% --- Configuration ---
refFile = '../Input/ArmasuisseRefRxClean.h5';
surFile = '../Input/ArmasuisseSurRxClean.h5';
txFile  = '../../Waveforms/txWaveFormNormalised.h5'; % For cross-correlation check

files = {refFile, surFile};
labels = {'Reference Receiver', 'Surveillance Receiver'};

fprintf('--- FERS Output Deep Inspection ---\n\n');

for f = 1:length(files)
    currentFile = files{f};
    fprintf('Checking %s: %s\n', labels{f}, currentFile);

    if ~exist(currentFile, 'file')
        fprintf(' [ERROR] File not found!\n\n');
        continue;
    end

    % 1. Inspect Structure and Attributes of the first chunk
    try
        % We use h5info to get metadata without loading the whole file
        info = h5info(currentFile);
        firstDatasetName = info.Groups.Datasets(1).Name; % e.g., /chunk_000000_I

        % Read Attributes directly
        time = h5readatt(currentFile, ['/' firstDatasetName], 'time');
        rate = h5readatt(currentFile, ['/' firstDatasetName], 'rate');
        fullscale = h5readatt(currentFile, ['/' firstDatasetName], 'fullscale');

        fprintf('  [META] First Dataset: %s\n', firstDatasetName);
        fprintf('  [META] Sample Rate:   %.1f Hz\n', rate);
        fprintf('  [META] Start Time:    %.6f s\n', time);
        fprintf('  [META] Fullscale:     %.6e\n', fullscale);

        if fullscale == 0
            fprintf('  [!!] WARNING: Fullscale is ZERO. Data will be nullified during loading.\n');
        end
    catch ME
        fprintf('  [ERROR] Failed to read attributes: %s\n', ME.message);
    end

    % 2. Read Raw Data from Chunk 0
    try
        % Construct names for I and Q
        % Note: FERS usually names them chunk_000000_I and chunk_000000_Q
        baseName = '/chunk_000000';
        I_raw = h5read(currentFile, [baseName '_I']);
        Q_raw = h5read(currentFile, [baseName '_Q']);

        % Assemble complex signal
        sig = complex(I_raw, Q_raw);

        % Calculate Statistics
        pwr_I = var(I_raw);
        pwr_Q = var(Q_raw);
        max_val = max(abs(sig));

        fprintf('  [DATA] Raw I-channel Power: %.6e\n', pwr_I);
        fprintf('  [DATA] Raw Q-channel Power: %.6e\n', pwr_Q);
        fprintf('  [DATA] Peak Magnitude:      %.6e\n', max_val);

        if pwr_I < 1e-15 && pwr_Q < 1e-15
            fprintf('  [!!] FAILURE: Dataset is effectively EMPTY (all zeros or noise floor).\n');
        else
            fprintf('  [PASS] Dataset contains non-zero signal data.\n');
        end

        % 3. Cross-Correlation with Transmit Waveform (The "Direct Path" Test)
        % If this is the Reference receiver, it MUST correlate with the TX signal.
        if exist(txFile, 'file')
            tx_I = h5read(txFile, '/I/value');
            tx_Q = h5read(txFile, '/Q/value');
            tx_sig = complex(tx_I, tx_Q);

            % Match lengths for correlation
            n = min(length(sig), 10000); % Check first 10k samples
            [xc, lags] = xcorr(sig(1:n), tx_sig(1:n));
            [max_xc, idx] = max(abs(xc));

            % Normalized correlation coefficient
            rho = max_xc / (norm(sig(1:n)) * norm(tx_sig(1:n)));

            fprintf('  [XCORR] Correlation with TX Waveform: %.4f\n', rho);
            if rho < 0.01
                fprintf('  [!!] FAILURE: No correlation with TX. Receiver is not seeing the signal.\n');
            else
                fprintf('  [PASS] Signal is coherent with Transmit waveform.\n');
            end
        end

    catch ME
        fprintf('  [ERROR] Failed to read data: %s\n', ME.message);
    end
    fprintf('\n');
end

% Visual Check of the first 500 samples
figure('Name', 'FERS Output Raw Inspection');
subplot(2,1,1);
I_ref = h5read(refFile, '/chunk_000000_I');
plot(I_ref(1:500)); title('Reference Rx: Raw I (Chunk 0)'); grid on;
subplot(2,1,2);
I_sur = h5read(surFile, '/chunk_000000_I');
plot(I_sur(1:500)); title('Surveillance Rx: Raw I (Chunk 0)'); grid on;
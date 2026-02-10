% Script: verifySourceWaveform.m
clear; clc; close all;
addpath('./AnalysisChain/Classes');

try
    fprintf('Loading source waveform from Malmesbury_1.rcf...\n');
    oRCF_source = cRCF;
    % Read the first 8192 samples from the file
    oRCF_source.readFromFile('Scripts/Malmesbury_1.rcf', 1, 8192);

    ref_data = oRCF_source.getReferenceData();

    % --- Analysis ---

    % 1. Check power in I vs Q channels
    power_I = var(real(ref_data));
    power_Q = var(imag(ref_data));

    fprintf('Power in I channel: %e\n', power_I);
    fprintf('Power in Q channel: %e\n', power_Q);

    if power_Q < power_I / 1000 % If Q power is less than 0.1% of I power
        fprintf('\n*** VERDICT: The source waveform appears to be REAL-VALUED. ***\n');
        fprintf('The Q-channel power is negligible compared to the I-channel.\n');
    else
        fprintf('\n*** VERDICT: The source waveform appears to be COMPLEX. ***\n');
    end

    % 2. Plot I and Q components
    figure(1);
    subplot(2,1,1);
    plot(real(ref_data));
    title('Source Waveform: Real (I) Component');
    xlabel('Sample');
    ylabel('Amplitude');
    grid on;

    subplot(2,1,2);
    plot(imag(ref_data));
    title('Source Waveform: Imaginary (Q) Component');
    xlabel('Sample');
    ylabel('Amplitude');
    grid on;

    % 3. Plot Spectrum
    figure(2);
    spectrum = abs(fftshift(fft(ref_data)));
    plot(spectrum);
    title('Spectrum of Source Waveform (Reference Channel)');
    xlabel('Frequency Bin');
    ylabel('Magnitude');
    grid on;
    fprintf('\nCheck the spectrum plot. If it is perfectly symmetric, the signal is real.\n');

catch ME
    fprintf('Error reading or processing Malmesbury_1.rcf.\n');
    fprintf('Please ensure the file is in the parent directory.\n');
    rethrow(ME);
end
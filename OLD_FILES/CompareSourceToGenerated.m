% CompareSourceToGenerated.m
addpath('AnalysisChain/Classes');

% 1. Load Original Source (Malmesbury)
oRCF_Source = cRCF;
oRCF_Source.readFromFile('Scripts/Malmesbury_1.rcf', 360*204800 + 1, 8192); % Load from the snippet start
Ref_Source = oRCF_Source.getReferenceData();

% 2. Load Generated Input (ArmasuisseClean)
oRCF_Gen = cRCF;
oRCF_Gen.readFromFile('AnalysisChain/Input/ArmasuisseClean.rcf', 1, 8192);
Ref_Gen = oRCF_Gen.getReferenceData();

% 2b. Numerical analyses
x = Ref_Source(:);
y = Ref_Gen(:);
n = min(numel(x), numel(y));
x = x(1:n);
y = y(1:n);

rms_x = sqrt(mean(abs(x).^2));
rms_y = sqrt(mean(abs(y).^2));
power_x = mean(abs(x).^2);
power_y = mean(abs(y).^2);

mu_Ix = mean(real(x));
mu_Qx = mean(imag(x));
mu_Iy = mean(real(y));
mu_Qy = mean(imag(y));

corr_complex = (x' * y) / (norm(x) * norm(y));
mag_corr = corrcoef(abs(x), abs(y));
mag_corr = mag_corr(1,2);
real_corr = corrcoef(real(x), real(y));
real_corr = real_corr(1,2);
imag_corr = corrcoef(imag(x), imag(y));
imag_corr = imag_corr(1,2);

phase_diff = angle(x .* conj(y));
phase_mean = angle(mean(exp(1j * phase_diff)));
phase_spread = 1 - abs(mean(exp(1j * phase_diff)));

corr_conj = abs((x' * conj(y)) / (norm(x) * norm(y)));
xy_swap = 1j * conj(y);
corr_swap = abs((x' * xy_swap) / (norm(x) * norm(y)));

fprintf('NUMERICAL ANALYSES (n = %d)\n', n);
fprintf('RMS: source=%.6g, gen=%.6g\n', rms_x, rms_y);
fprintf('Mean I/Q: source=(%.6g, %.6g), gen=(%.6g, %.6g)\n', mu_Ix, mu_Qx, mu_Iy, mu_Qy);
fprintf('Power: source=%.6g, gen=%.6g\n', power_x, power_y);
fprintf('Correlation: complex |r|=%.6g, angle=%.6g rad\n', abs(corr_complex), angle(corr_complex));
fprintf('Correlation: magnitude=%.6g, real=%.6g, imag=%.6g\n', mag_corr, real_corr, imag_corr);
fprintf('Phase diff: mean=%.6g rad, spread=%.6g (0 tight, 1 broad)\n', phase_mean, phase_spread);
fprintf('Swap checks: |corr(conj)|=%.6g, |corr(IQ swap)|=%.6g\n', corr_conj, corr_swap);

% 3. Plot Spectra
figure;
subplot(2,1,1);
plot(abs(fftshift(fft(Ref_Source))));
title('Original Source Spectrum (Malmesbury)');
grid on;

subplot(2,1,2);
plot(abs(fftshift(fft(Ref_Gen))));
title('Generated Input Spectrum (ArmasuisseClean)');
grid on;

fprintf('DIAGNOSIS:\n');
fprintf('If the bottom plot is a MIRROR IMAGE (left-right flip) of the top plot,\n');
fprintf('then I and Q are swapped in loadfersHDF5.m.\n');
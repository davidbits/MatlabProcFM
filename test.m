addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

oRCF = cRCF;
oRCF.readFromFile('Input/ArmasuisseClean.rcf', 1, 4096);
%oRCF.readFromFile('Input/ArmasuisseClean_pre_loadfershdf5_fix.rcf', 1, 4096);
% Plot spectrum of Reference channel
figure; plot(abs(fftshift(fft(oRCF.getReferenceData)))); title('Ref Spectrum');
% If this plot is perfectly symmetric around the center, the data is still Real-only (Broken).
% If it is asymmetric (different left vs right), the I/Q data is loaded correctly.
function oARD = FX_ARD(oRCF,MaxRange_m, MaxDoppler_Hz,TxToRefRxDistance_m)

%Generates an ARD plot for the reference and scattered signals using the
%frequency domain implementation. 
  
C = 299792458;                    %speed of the light (m/s)
nRangeBins = ceil((MaxRange_m - TxToRefRxDistance_m) * oRCF.getFs_Hz() / C);
nDopplerBins = MaxDoppler_Hz / (oRCF.getFs_Hz() / oRCF.getNSamples()); % Number of bins of 1 side of the Doppler spectrum without DC bin

fprintf('\t\t* ARD: Starting calculation:\n')
fprintf('\t\t* Range:   %g to %g km, %g bins\n', TxToRefRxDistance_m / 1000, MaxRange_m / 1000, nRangeBins)
fprintf('\t\t* Doppler: %g to %g Hz, %g bins\n', -MaxDoppler_Hz, MaxDoppler_Hz, nDopplerBins * 2 + 1)

%initialisation of temporary variables
FFTInput = zeros(oRCF.getNSamples(), 1, 'single');
FFTOutput = zeros(oRCF.getNSamples(), 1, 'single');

ARDMatrix = zeros(nRangeBins, 2 * nDopplerBins + 1, 'single');

RefFFT = fft( oRCF.m_fvReferenceData.*blackman(oRCF.getNSamples()) );
SurvFFT = fft( oRCF.m_fvSurveillanceData.*blackman(oRCF.getNSamples()) );

zeroDopplerBinNo = nDopplerBins + 1;
IFFTOutput = zeros(1,nRangeBins, 'single');

%Negative Doppler:
for DopplerShift = 1:nDopplerBins
    IFFTInput = zeros(1,nRangeBins, 'single'); %For padding
    IFFTInput(1:oRCF.getNSamples() - DopplerShift) = SurvFFT(1:oRCF.getNSamples() - DopplerShift).* conj(RefFFT(1 + DopplerShift:oRCF.getNSamples()));
    IFFTOutput = ifft(IFFTInput);
    ARDMatrix(:, zeroDopplerBinNo - DopplerShift) = IFFTOutput(1:nRangeBins);
end

%Zero Doppler
IFFTInput = SurvFFT.* conj(RefFFT);
IFFTOutput = ifft(IFFTInput);
ARDMatrix(:, zeroDopplerBinNo) = IFFTOutput(1:nRangeBins);

%Positive Doppler
for DopplerShift = 1:nDopplerBins 
    IFFTInput = zeros(1,nRangeBins, 'single'); %For padding
    IFFTInput(1 + DopplerShift:oRCF.getNSamples()) = SurvFFT(1 + DopplerShift:oRCF.getNSamples()).* conj(RefFFT(1:oRCF.getNSamples() - DopplerShift));
    IFFTOutput = ifft(IFFTInput);
    ARDMatrix(:, zeroDopplerBinNo + DopplerShift) = IFFTOutput(1:nRangeBins);
end

ARDMatrix = abs(ARDMatrix).^2;  %Square law detector

oARD = cARD;
oARD.setDataMatrix(transpose(ARDMatrix));
oARD.setRangeResolution_m(C / oRCF.getFs_Hz());
oARD.setDopplerResolution_Hz(oRCF.getFs_Hz() / oRCF.getNSamples());
oARD.setTimeStamp_us(oRCF.getTimeStamp_us());
oARD.setFc_Hz(oRCF.getFc_Hz());
oARD.setFs_Hz(oRCF.getFs_Hz());
oARD.setBw_Hz(oRCF.getBw_Hz());
oARD.setTxRxDistance_m(TxToRefRxDistance_m);
oARD.setFilename(oARD.timeStampToString());
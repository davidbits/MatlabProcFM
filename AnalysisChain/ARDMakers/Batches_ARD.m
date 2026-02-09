function oARD = Batches_ARD(oRCF,MaxRange_m, MaxDoppler_Hz,TxToRefRxDistance_m)
%Generates an ARD plot for the reference and scattered signals using the
%frequency domain implementation. 
  
nBatches = 2048; %The number of batches
batchStrideNSamples = oRCF.getNSamples() / nBatches; %The stride between the starting sample of each batch
batchNSamples = batchStrideNSamples * 5; %The number of samples in each batch. No if this is bigger that the stride then the batches overlap. (It shouldn't ever be smaller)

C = 299792458;                    %speed of the light (m/s)
nRangeBins = ceil((MaxRange_m - TxToRefRxDistance_m) * oRCF.getFs_Hz() / C);
nDopplerBins = ceil(MaxDoppler_Hz / ((oRCF.getFs_Hz() / batchStrideNSamples) / nBatches)); % Number of bins of 1 side of the Doppler spectrum without DC bin

fprintf('\t\t* ARD: Starting calculation:\n')
fprintf('\t\t* Range:   %g to %g km, %g bins\n', TxToRefRxDistance_m / 1000, MaxRange_m / 1000, nRangeBins)
fprintf('\t\t* Doppler: %g to %g Hz, %g bins\n', -MaxDoppler_Hz, MaxDoppler_Hz, nDopplerBins * 2 + 1)

CorrelationMatrix = zeros(nRangeBins, nBatches, 'single');

%Correlation using FFT for each Batch:
for batchNo = 0:nBatches - 1
    
    %Indexes of this batch in the RCF structure
    batchStartSample = 1 + batchNo * batchStrideNSamples;
    batchStopSample = batchStartSample + batchNSamples;
    
    %Check for goinging beyond the end of the data set
    if(batchStopSample <= oRCF.getNSamples())
        
    
    else
        %We can't us the full batch size here as it would extend past the
        %end of the RCF sample block so zero pad and read as many samples
        %what are available:
        batchStopSample = oRCF.getNSamples();
    end
    
    %second argument of FFTs here creates zero padding as necessary.
    RefFFT = fft( oRCF.m_fvReferenceData(batchStartSample:batchStopSample), batchNSamples);
    SurvFFT = fft( oRCF.m_fvSurveillanceData(batchStartSample:batchStopSample), batchNSamples);
    
    IFFTOutput = ifft(SurvFFT .* conj(RefFFT));
 
    CorrelationMatrix(:,batchNo + 1) = IFFTOutput(1:nRangeBins);
end

ARDMatrix = zeros(nRangeBins, 2 * nDopplerBins + 1, 'single');

for rangeBinNo = 1:nRangeBins
    
    RangeBin = fftshift(fft(CorrelationMatrix(rangeBinNo,:).*blackman(nBatches)'));
    ARDMatrix(rangeBinNo,:) = RangeBin(2048 / 2 + 1 - nDopplerBins:2048 / 2 + 1 + nDopplerBins);   
end

ARDMatrix = abs(ARDMatrix.^2);  %Square law detector

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
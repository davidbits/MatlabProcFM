function oARD = XF_ARD(oRCF,MaxRange_m, MaxDoppler_Hz,TxToRefRxDistance_m, strWindowType)

%Generates an ARD plot for the reference and scattered signals using the
%frequency domain implementation.

C = 299792458;                    %speed of the light (m/s)
nRangeBins = ceil((MaxRange_m - TxToRefRxDistance_m) * oRCF.getFs_Hz() / C);
nDopplerBins = MaxDoppler_Hz / (oRCF.getFs_Hz() / oRCF.getNSamples()); % Number of bins of 1 side of the Doppler spectrum without DC bin

fprintf('\t\t* ARD: Starting calculation:\n')
fprintf('\t\t* Range:   %g to %g km, %g bins\n', TxToRefRxDistance_m / 1000, MaxRange_m / 1000, nRangeBins)
fprintf('\t\t* Doppler: %g to %g Hz, %g bins\n', -MaxDoppler_Hz, MaxDoppler_Hz, nDopplerBins * 2 + 1)

ARDMatrix = zeros(nRangeBins, 2 * nDopplerBins + 1, 'single');

if(nargin == 5)
    
    %Set the window according to the argument
    if(strcmp(strWindowType, 'Blackman'))
        Window = blackmanWindow(oRCF.getNSamples());
    elseif(strcmp(strWindowType, 'Hanning'))
        Window = hanningWindow(oRCF.getNSamples());
    elseif(strcmp(strWindowType, 'None'))
        Window(1:oRCF.getNSamples()) = 1;
        Window = transpose(Window);
    else
        fprintf('Warning unknown window type: %s\n', strWindowType)
        fprintf('Options are:\n\tBlackman\n\tHanning\n\tNone\n')
        fprintf('Defaulting to Blackman\n')
        Window = blackmanWindow(oRCF.getNSamples());
    end
    
elseif(nargin == 4)
    fprintf('Defaulting to Blackman window\n')
    Window = blackmanWindow(oRCF.getNSamples());
end


for shift = 0:nRangeBins - 1
    
    FFTInput = zeros(oRCF.getNSamples(), 1, 'single');
    FFTOutput = zeros(oRCF.getNSamples(), 1, 'single');
    
    FFTInput(1 + shift:oRCF.getNSamples()) = ...
        oRCF.m_fvSurveillanceData(1 + shift:oRCF.getNSamples()) .* conj(oRCF.m_fvReferenceData(1:oRCF.getNSamples() - shift));
    
    FFTInput = FFTInput .* Window; %window the result
    
    FFTOutput = fftshift(fft(FFTInput)); %FFT of the above product
    
    %Discard frequency bins not of interest
    ARDMatrix(shift + 1,:) = FFTOutput(floor(oRCF.getNSamples() / 2) + 1 - nDopplerBins:floor(oRCF.getNSamples() / 2 ) + 1 + nDopplerBins);
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

function oOutputRCF = ECA_Cancellation(oInputRCF, cancellationMaxRange_m, cancellationMaxDoppler_Hz, txToRefRxDistance_m, nSegments)

%% Usage: oOutputRCF = ECA_Cancellation(oInputRCF, cancellationMaxRange_m, cancellationMaxDoppler_Hz, txToRefRxDistance_m)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters:
% The follow specify over what range the ECA should be applied
% oInputRCF The RCF object on which cancellation is to be applied
% cancellationMaxRange_m: (in m <- Note this is bistatic range) The range
%       up to which to perform cancellation
% cancellationMaxDopppler_Hz: (in Hz <- Note that the cancellation will be
%       applied from negative to positive of this value
% txToRefRxDinstance_m: The distance from the tx antenna to the reference
%       antenna used to calculate bistatic range in m
% nSegments: The number of segments to split the the specific RCF object
%       into for doing cancellation.
%Returned:
%oOutputRCF: A new RCF object with cancelled surveillance channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%The number of samples per segment
segmentSize_nSamp = floor(oInputRCF.getNSamples() /  nSegments);

%The number of range and Doppler bins over which cancellation will be
%applied
nRangeBins = ceil((cancellationMaxRange_m - txToRefRxDistance_m)/(3e8/oInputRCF.getFs_Hz()));
nDopplerBinds = ceil(cancellationMaxDoppler_Hz/(oInputRCF.getFs_Hz()/segmentSize_nSamp)) * 2 + 1;

%The delay in seconds to each sample from the begining of the CPI
sampleTimes_s = 0:1/oInputRCF.getFs_Hz():(segmentSize_nSamp - 1)/oInputRCF.getFs_Hz();

%Note use of copy constructor here. 
%You can't just use '=' because cRCF derives handle and it would result in
%pointer type behavior.
oOutputRCF = cRCF(oInputRCF); 

for segmentNo = 0:nSegments - 1
    
    fprintf('\t\t* ECA: Starting cancellation on segment %i of %i:\n', segmentNo, nSegments)
    fprintf('\t\t* Range:   %g to %g m, %g bins\n', txToRefRxDistance_m, cancellationMaxRange_m, nRangeBins)
    fprintf('\t\t* Doppler: %g to %g Hz, %g bins\n', -cancellationMaxDoppler_Hz, cancellationMaxDoppler_Hz, nDopplerBinds)
    tic
    
    %Start and end sample numbers for this segment
    segStartSampleNo = segmentNo * segmentSize_nSamp + 1;
    segStopSampleNo = segStartSampleNo + segmentSize_nSamp - 1;
    
    %A matrix (As in Ax = b) with only the zero Doppler rows
    ZeroDopplerA=zeros(segmentSize_nSamp, nRangeBins, 'single');
    
    %Create ZeroDoppler A matrix from RCF object.
    %Each row is the surveillance channel left zero padded 
    for i=1:nRangeBins
        ZeroDopplerA(i:segmentSize_nSamp, i)=oInputRCF.m_fvReferenceData((segStartSampleNo:segStopSampleNo - (i - 1)));
    end
    
    %The complete A matrix
    A = zeros(segmentSize_nSamp, nRangeBins * nDopplerBinds, 'single');
    K = nRangeBins;
    Pos = 0;
    
    %Create Doppler shifted versions of ZeroDopplerA in  A
    for i=-floor(nDopplerBinds / 2):floor(nDopplerBinds / 2)
        for l=1:K
            A(:,l+Pos)=ZeroDopplerA(:,l).* exp(i * 1j * 2 * pi * sampleTimes_s');
        end
        Pos = Pos + K;
    end
    
    clear ZeroDopplerA
    
    alpha = (A'*A)\A'*oInputRCF.m_fvSurveillanceData(segStartSampleNo:segStopSampleNo);
    
    oOutputRCF.m_fvSurveillanceData(segStartSampleNo:segStopSampleNo) = ...
        oInputRCF.m_fvSurveillanceData(segStartSampleNo:segStopSampleNo) - (A * alpha);
    
    clear d A Pos K x i l alpha
    fprintf('\t\tCompleted. ')
    toc
    fprintf('\n')

end

clear sampleTimes_s



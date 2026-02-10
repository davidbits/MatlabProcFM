%Make HDF5 file with Tx data for FERS from RCF data.

addpath('../AnalysisChain/Classes');
clc; clear all;
oRCF = cRCF;
filename = 'Malmesbury_1.rcf';

% Select where to start from in the recorded data (This data is about 10 min long so anything from 0 to 500s+ works)
Fs=204800;
t_start = 540; % input('\nStart time [s]: ');
t_length = 180; % input('Signal length [s]: ');
t_end = t_start+t_length;

fprintf('Reading RCF data from file...\n');

%180 seconds at a sample rate of 204800 Hz (180*204800=36864000)
oRCF.readFromFile(filename, (t_start * Fs) + 1, t_length * Fs); % +1 to t_start as RCF class is 1-indexed

%Normalise ref data
ref = oRCF.getReferenceData;
refPower = var(ref);
ref = ref .* (1 / sqrt(refPower));

fprintf('Writing HDF5 data...\n');
hdf5write('jammerWaveFormNormalised.h5', '/I/value', real(ref), '/Q/value', imag(ref));
fprintf('Complete.\n');

%fprintf('\nPlotting histogram of noise...\n')
%histogram(real(ref));
%saveas(1,'Histogram','png');
%saveas(1,'Histogram','svg');
%fprintf('Complete.\n')
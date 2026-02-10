h5disp('Input/ArmasuisseRefRxClean.h5');

% ---

% Read the first I and Q chunks directly from the HDF5 file
I_data = h5read('Input/ArmasuisseRefRxClean.h5', '/chunk_000000_I');
Q_data = h5read('Input/ArmasuisseRefRxClean.h5', '/chunk_000000_Q');

% Calculate the power (variance) of the Q channel
power_Q = var(Q_data);

fprintf('Power in manually read Q-channel: %e\n', power_Q);

if power_Q < 1e-10 % Check against a small threshold for floating point noise
    disp('*** DIAGNOSIS: The Q-channel dataset in the HDF5 file is effectively ZERO. The problem is in the FERS simulation output.');
else
    disp('*** DIAGNOSIS: The Q-channel dataset in the HDF5 file contains valid data. The problem is in the loadfersHDF5.m script.');
end
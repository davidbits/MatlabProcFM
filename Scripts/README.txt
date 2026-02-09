README

To use the simulation files, go to https://github.com/stpaine/FERS and download the latest version of FERS.
Follow the instructions in the git Wiki to get installed and up and running.

Note:

1. FERS outputs raw ADC data, not fully processed data.

2. The processed data provided in this repo was processed according to the parameters in the paper

3. The ARD file format is a custom wrapper to hold the output range-Doppler maps. This can be read using the readARD.py
script (or you can write your own reader using the matlab cARD.m class that is also provided). The script will also print
out all the processing parameters used to produce the output plots.

4. The waveform data is recorded from CPT and is storred as a .rcf (raw capture format) file. To use this with FERS,
you need to convert it to an .hdf5 file using the makeTxData.m file.

5. The transmit waveforms used are provided and the jammer waveforms can be extracted from the Malmesbury_1.rcf file,
where the number after the name indicates the start time of the sample within the main Malmesbury_1.rcf file. e.g.
TxNormalised360.hf is a 180 second long snippit, starting from 360 seconds into the Malmesbury_1.rcf file.
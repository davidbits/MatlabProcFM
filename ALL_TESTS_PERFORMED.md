# All Tests Performed

## General Notes

- Old fers commit used: `526d41` (all tests except those with `_fers_latest` in the name)
- Latest fers commit used: `a6facb`
- All Clean tests used the same FM Waveform for the transmitter: `txWaveFormNormalised.h5` generated from `Malmesbury_1.rcf` (360s-540s segment)
- All Jam tests used the same FM Waveform for the jammer: `txWaveFormNormalised.h5` generated from `Malmesbury_1.rcf` (540s-720s segment)
- All tests used the same scenario XML base.
- All tests used the same MATLAB processing chain and parameters for ARD generation.
- ARDs are a 2D histogram of Bistatic Doppler vs Bistatic Range with power represented in dB (a Range-Doppler Map).
- All plots are at the 16th CPI

## No Jammer Simulations

### CleanSingleTarget

#### Notes:
- Used an ideal scenario with no jamming signals.
- Used random_freq_offset and noise_temp randomness.

#### Results:
- Entire ARD plot is noisy with no visible target.
- 0 dB areas are around 0 Hz and +-50 Hz within <120km range

### CleanSingleTarget_fers_latest

#### Notes:
- Used an ideal scenario with no jamming signals.
- No random_freq_offset and no noise_temp.

#### Results:
- Target clearly visible at ~85 Hz Doppler and ~120 km range.
- The rest of the plot is very low noise floor around -30 dB.

### CleanSingleTarget_no_rand

#### Notes:
- Same as CleanSingleTarget_fers_latest

#### Results:
- Essentially identical results to CleanSingleTarget_fers_latest, but the noise floor is very slightly higher, maybe 2 dB.

## FM Noise Jammer Simulations

### JamSingleTarget

#### Notes:
- Used random_freq_offset and noise_temp randomness.
- Jammer was co-located with the target.
- Jammer power was set to 1 W.

#### Results:
- Target is not visible in the ARD plot.
- Plot just appears as noise similar to CleanSingleTarget but with a lower average power level (maybe -5 dB).

### JamSingleTarget_fers_latest

#### Notes:
- Using the latest fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 1 W.
- No random_freq_offset and no noise_temp.

#### Results:
- Entire plot is very high average power noise with the average being around maybe -7 dB for all ranges and dopplers

### JamSingleTarget_fers_latest_low_power

#### Notes:
- Using the latest fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.01 W (10 mW).
- No random_freq_offset and no noise_temp.

#### Results:
- Essentially no difference to JamSingleTarget_fers_latest

### JamSingleTarget_fers_latest_low_power_1mw

#### Notes:
- Using the latest fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.001 W (1 mW).
- No random_freq_offset and no noise_temp.

#### Results:
- No major difference to JamSingleTarget_fers_latest other than the average power level is lower, maybe -10 dB.

### JamSingleTarget_fers_latest_low_power_1uw

#### Notes:
- Using the latest fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.000001 W (1 µW).
- No random_freq_offset and no noise_temp.

#### Results:
- Plot is essentially identical to CleanSingleTarget_fers_latest with the target visible at ~85 Hz Doppler and ~120 km range.

### JamSingleTarget_low_power

#### Notes:
- Using the old fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.01 W (10 mW).
- No random_freq_offset and no noise_temp.

#### Results:
- Basically identical to JamSingleTarget_low_power with some minor differences in power levels.

### JamSingleTarget_low_power_1mw

#### Notes:
- Using the old fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.001 W (1 mW).
- No random_freq_offset and no noise_temp.

#### Results:
- Average power level is 10 dB higher than JamSingleTarget_fers_latest_low_power_1mw but otherwise similar.

### JamSingleTarget_low_power_1uw

#### Notes:
- Using the old fers commit.
- Jammer was co-located with the target.
- Jammer power was set to 0.000001 W (1 µW).
- No random_freq_offset and no noise_temp.

#### Results:
- Basically identical to JamSingleTarget_fers_latest_low_power_1uw with very few minor differences in power levels in the plot.

### JamSingleTarget_no_rand

#### Notes:
- Using the old fers commit.
- No random_freq_offset and no noise_temp.
- Jammer was co-located with the target.
- Jammer power was set to 1 W.

#### Results:
- Average power level is around -20 dB with no visible target, just noise

### JamSingleTarget_stationary_jam

#### Notes:
- Using the old fers commit.
- The target was moving but the jammer was stationary at the starting point of the target.
- Jammer power was set to 1 W.
- No random_freq_offset and no noise_temp.

#### Results:
- No notable differences to JamSingleTarget_no_rand other than slightly higher power levels in the plot in some areas

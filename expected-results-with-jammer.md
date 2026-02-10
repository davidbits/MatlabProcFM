### Executive Summary

You should expect to **successfully detect the target** at the same location (~120 km, +85 Hz) as before. The jammer,
despite being co-located with the target, will **not** create a second, distinct target-like peak. Instead, its energy
will be smeared across all range bins at the target's Doppler frequency, manifesting as a **faint, horizontal line of
elevated noise passing through the target's Doppler bin**. The overall background noise floor of the entire ARD plot
will also be slightly higher.

---

### Detailed Analysis and Predictions

The outcome is governed by the fundamental principle of your processing chain: it is a **matched filter**. The entire
system is "tuned" to find signals that correlate with the waveform captured by the reference receiver.

#### 1. The Role of the Reference Channel

* The `ArmasuisseRefRx` (Reference Receiver) is pointed at the main transmitter (`ConstantiabergTx`). It will receive a
  very strong signal from this transmitter.
* The jammer is a very weak (1 W) transmitter located far away on the target. The signal from the jammer arriving at the
  reference receiver will be thousands of times weaker than the main transmitter's signal and will be completely buried
  in the noise.
* **Conclusion:** The `refData` loaded into the processing chain will be almost entirely composed of the main
  transmitter's waveform (`txWaveFormNormalised.h5`). The jammer's waveform will have no meaningful presence in the
  reference signal.

#### 2. The Nature of Uncorrelated Signals

* The main transmitter uses the waveform from 360s-540s of the recording.
* The jammer uses the waveform from 540s-720s of the recording.
* These two segments of a real-world FM broadcast are, for all practical purposes, **uncorrelated**. They are
  statistically independent noise-like signals.
* **Conclusion:** The matched filter, which cross-correlates the surveillance data with the reference data, will see the
  jammer's signal as noise.

#### 3. Predicted Manifestation in the ARD Plot

Given these principles, here is what will happen to each signal component in the `ArmasuisseSurRx` (Surveillance
Receiver) during processing:

* **The Target Echo:**
    * This is the main transmitter's signal bouncing off the target. It is a delayed, Doppler-shifted version of the
      reference signal.
    * The matched filter will find a very high correlation.
    * **Prediction:** The target will be detected and compressed into a **bright, sharp peak at approximately +85 Hz
      Doppler and 120 km range**, just as in the clean scenario.

* **The Jammer Signal:**
    * This signal arrives directly at the surveillance receiver from the target's location. It therefore has the **same
      Doppler shift (+85 Hz)** as the target echo.
    * However, its waveform is **uncorrelated** with the reference signal.
    * When an uncorrelated signal is passed through a matched filter, its energy is not compressed into a single range
      bin. Instead, it is spread out across all range bins.
    * **Prediction:** The jammer's energy will appear as a **faint, horizontal line (a "noise ridge" or "smear") across
      the entire range axis, precisely at the +85 Hz Doppler frequency**. The intensity of this line will be low, as the
      jammer's 1W of power is spread across hundreds of range bins instead of being focused into one.

* **The Overall Noise Floor:**
    * The jammer is adding extra, wideband energy into the surveillance channel.
    * **Prediction:** The background noise level (the deep indigo/blue parts of the plot) will be slightly elevated
      compared to the clean scenario. For example, the floor might rise from -30 dB to -28 dB.

* **Clutter Cancellation:**
    * The `CGLS_Cancellation` algorithm uses the reference signal to subtract the direct path interference from the
      surveillance channel.
    * Since the reference signal is almost purely the main transmitter's waveform, the cancellation of the main
      transmitter's direct path will be just as effective as before.
    * **Prediction:** The strong clutter at 0 Hz Doppler and short range will be effectively suppressed.

### What to Look For in Your New ARD Plot:

1. **Confirm the Target:** Look for the bright yellow peak at the familiar coordinates.
2. **Find the Jammer's "Smear":** Look closely at the +85 Hz Doppler line. You should see a faint but distinct
   horizontal line of slightly brighter blue/cyan pixels extending across the plot, with the bright yellow target peak
   sitting on top of it.
3. **Check the Noise Floor:** Compare the color of the darkest parts of the new plot to the old one. The new plot should
   appear slightly "brighter" or less contrasted overall.

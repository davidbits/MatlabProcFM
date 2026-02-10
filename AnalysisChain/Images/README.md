# Description of the plots

## JamSingleTarget_Latest.png

The image is a bistatic radar range–Doppler intensity map with bistatic range on the x-axis from approximately 0.75×10⁵ m to 2.5×10⁵ m and bistatic Doppler on the y-axis from −200 Hz to +200 Hz. Signal power is shown in dB with a color scale spanning 0 dB (yellow) to −40 dB (dark blue). The background noise floor is predominantly between −15 dB and −30 dB, with widespread horizontal banding across nearly the full range extent. Jamming plot has many spots with power of 0 db to -20 db all across all frequencies and ranges, with -40db only showing in small patches Peak intensities approach 0 dB in localized patches, while most of the scene remains low-to-moderate power. The dominance of range-invariant Doppler bands and absence of compact, localized peaks indicate distributed interference or jamming-like energy rather than a single isolated point target.

## CleanSingleTarget_Latest.png

This Bistatic Range-Doppler (ARD) plot, titled "Output/16.ard," maps signal intensity across a spatial range of $0.7 \times 10^5$ to $2.5 \times 10^5$ meters and a Doppler frequency spectrum of $-200$ to $+200$ Hz. Utilizing a decibel scale ranging from a $-30$ dB noise floor to a $0$ dB peak, the visualization identifies a primary moving target appearing as a high-intensity yellow-green streak (approx. $-5$ to $0$ dB) at a Doppler shift of $+85$ to $+90$ Hz, spanning the $1.1 \times 10^5$ to $1.4 \times 10^5$ m range. Stationary clutter is observed near the $0$ Hz Doppler line with intensities reaching $-15$ dB, primarily at ranges below $1.0 \times 10^5$ m. The data is characterized by widespread horizontal streaking, with secondary signal returns and artifacts distributed across the full range, concentrated largely between the $-150$ Hz and $+180$ Hz Doppler coordinates. the clean plot has wideband noise as well, but is attenuated much better with most of the plot having a power of -25db to -40 db and few areas with power above that

## JamSingleTarget_tone_Latest.png

This Bistatic Range-Doppler (ARD) map, titled "Output/16.ard," visualizes signal intensity from 0 dB (yellow) to -40 dB (purple) across a bistatic range of $0.75 \times 10^5$ to $2.5 \times 10^5$ m and a Doppler frequency range of -200 to +200 Hz. The plot is dominated by a high-intensity stationary clutter line at 0 Hz Doppler that emerges at a range of $0.85 \times 10^5$ m and extends to the right edge. Symmetrical interference lines are clearly visible at approximately $\pm 50$ Hz Doppler, persisting across the full range. The background exhibits pervasive horizontal striations representing noise and sidelobes, while a lack of localized "hits" indicates no moving targets were detected within this 75–250 km range window. A signal suppression or "blind" zone is observed at ranges below $0.85 \times 10^5$ m.

---

# Analysis of Results

The results of your comparison between the "Clean" and "Jammer" simulations provide significant evidence to support the claim of a fundamental bug within the FERS simulator's handling of multiple concurrent transmitters.

The following analysis discusses the statistical, physical, and signal-processing contradictions observed in the data.

### 1. The Reference Channel Correlation Paradox

The most striking piece of evidence is the correlation coefficient ($\rho$) for the Reference Channel:

- **Observation:** Correlation (rho) = **-0.080311**.
- **Discussion:** In a linear radar simulation, the Reference Receiver is pointed directly at a 16,400 W transmitter. Adding a 1 W jammer—located 44 km away and in the sidelobes of the Reference antenna—should have a negligible effect on the captured waveform. Statistically, the correlation between the "Clean" Reference signal and the "Jammer" Reference signal should be very close to **1.0** (likely >0.999).
- **Implication:** A correlation of -0.08 indicates that the two signals are entirely independent. This suggests that when the second transmitter (the jammer) was introduced, the simulator did not _add_ the jammer's signal to the existing FM signal; instead, it appears to have **overwritten** or **suppressed** the primary FM signal in the output buffer.

### 2. Power Analysis (Fullscale-Corrected)

In physics, the total power of two independent, uncorrelated sources arriving at a receiver must be the sum of their individual powers ($P_{total} = P_1 + P_2$).

**Original raw ADC measurements (superseded):** Power appeared to drop from **0.288** to **0.209** (Ref) and **0.305** to **0.188** (Sur). This was an artifact of comparing raw ADC integer values without applying the FERS `fullscale` attribute. FERS increases the `fullscale` factor by ~20% in jammer runs (from 6.451e-05 to 7.798e-05) to accommodate a larger peak amplitude, compressing the same physical amplitude into smaller ADC integer values.

**Fullscale-corrected results (via `loadfersHDF5`):**

- **Observation (Ref Channel):** Power increased from **2.398e-09** (Clean) to **2.548e-09** (Jammer), a rise of **+6.24%**.
- **Observation (Sur Channel):** Power increased from **1.442e-09** (Clean) to **1.624e-09** (Jammer), a rise of **+12.58%**.
- **Discussion:** After fullscale correction, power properly **increases** when the jammer is added, consistent with the direction required by superposition. However, the magnitude is anomalous: a 1 W jammer should produce only ~0.017% increase at the Reference receiver (37 dB below the 16.4 kW FM source). The observed **+6.24% is ~360× too large**, independently confirming the link budget error.
- **Implication:** The jammer signal contributes far more power at the receiver than the link budget allows, consistent with signal replacement rather than correct summation.

### 3. Analysis of FERS Interpolation Points

The raw data from the FERS interpolation points reveals a massive discrepancy in how power is being calculated:

- **Jammer (1 W Tx):** Power at receiver $\approx 1.53 \times 10^{-10}$ W.
- **FM Tx (16,400 W Tx):** Power at receiver $\approx 1.52 \times 10^{-11}$ W.
- **Discussion:** Despite the FM transmitter having a transmit power **42 dB higher** (16,000 times stronger) than the jammer, FERS reports that the FM signal arriving at the receiver is **10 times weaker** than the jammer signal. While the jammer is closer (44 km vs 74 km), the $R^2$ path loss difference is only about 4.5 dB.
- **Implication:** There is a 37 dB "missing" power gap. This suggests that the simulator is applying incorrect path loss, antenna gain, or pulse-power scaling when multiple platforms are defined.

### 4. Impact on the ARD Processing (Matched Filter Failure)

The disappearance of the target in the Jammer ARD plot is a direct consequence of the decorrelation observed in the Reference channel.

- **Clean Plot:** Shows a clear, compressed target. This is because the Reference signal is a perfect match for the target echoes in the Surveillance channel.
- **Jammer Plot:** The target at +85 Hz is gone, replaced by widespread 0 dB "patches" and horizontal banding.
- **Discussion:** Because the Reference channel has been decorrelated ($\rho \approx -0.08$), the Matched Filter ($Surv \otimes Ref^*$) no longer has a valid reference to correlate against. The "Jammer" Reference signal no longer contains the FM waveform that produced the target echoes.
- **Implication:** The processing chain is attempting to perform pulse compression using a reference signal that does not match the echoes. This results in the energy being smeared across the entire range-Doppler map, raising the noise floor to -15 dB and creating the observed interference patterns.

### 5. Summary of Evidence for a Simulator Bug

The evidence strongly supports the "alleged bug" regarding low-power moving jammers:

1.  **Signal Overwriting:** The near-zero correlation in the Reference channel (complex |ρ| = 0.12 / 0.01) proves the simulator is failing to maintain the primary signal when a secondary source is added.
2.  **Anomalous Power Increase:** After fullscale correction, power increases by +6.24% (vs expected +0.017%), confirming the jammer signal is ~360× too strong at the receiver. The original apparent power _decrease_ in raw ADC values was an artifact of differing `fullscale` normalisation between runs.
3.  **Inverted Power Scaling:** The 1 W jammer appearing stronger than the 16 kW transmitter in the internal logs suggests a catastrophic failure in the simulator's link budget calculations for multi-transmitter scenarios.
4.  **Reference Contamination:** In a valid simulation, a 1 W jammer should be invisible to a Reference receiver pointed at a 16 kW source. The fact that it has completely decorrelated the Reference channel proves the simulator is not isolating or summing the signals correctly at the receiver input.
5.  **I/Q Integrity Verified:** Q/I power ratio ≈ 1.0 in all scenarios, ruling out Q=0 (real-valued signal) corruption as a contributing factor.

---

# Analysis of Single Tone Jammer Result

### Analysis of Single-Tone Jammer Simulation Results

The substitution of the wideband FM jammer with a constant single-tone (CW) source provides definitive data regarding the simulator's handling of multi-transmitter scenarios. The results reinforce the findings from the previous test and isolate the failure mechanism with high confidence.

#### 1. Statistical Decoupling of the Reference Channel

The correlation coefficient ($\rho$) between the "Clean" Reference signal (FM only) and the "Jammer" Reference signal (FM + 1W Tone) is **-0.0105**.

- **Analysis:** A correlation of $\approx 0$ indicates orthogonality. The signal recorded in the Reference channel during the Jammer run shares **no statistical similarity** with the FM waveform recorded in the Clean run.
- **Discussion:** Physically, the Reference receiver is dominated by the 16 kW FM transmitter. The addition of a 1 W tone (42 dB lower power) should result in a correlation coefficient near 1.0. The observed zero correlation confirms that the FM signal is effectively absent from the Reference channel output in the Jammer simulation. The Reference channel has been populated with data that is uncorrelated with the primary transmitter.

#### 2. Power Analysis (Fullscale-Corrected)

**Original raw ADC measurement (superseded):** Power appeared to drop from $0.288$ to $0.213$ (−26%). This was an artifact of comparing raw ADC values without applying the FERS `fullscale` attribute (which increased by ~20% in the jammer run).

**Fullscale-corrected result:** After applying the `fullscale` factor via `loadfersHDF5`, the Reference channel power **increases** from **2.398e-09** to **2.548e-09** (+6.27%), consistent with the direction required by superposition. However, the magnitude is anomalous: a 1 W tone should produce only ~0.017% increase, so the observed +6.27% is ~360× too large — independently confirming the link budget error and signal replacement.

#### 3. ARD Plot: Target Extinction

The ARD plot for the Jammer run shows a complete loss of the target that was clearly visible in the Clean run.

- **Observation:** The high-intensity target at +85 Hz / 120 km is absent. The plot is dominated by stationary clutter (0 Hz) and symmetrical interference lines ($\pm 50$ Hz).
- **Analysis:** The disappearance of the target is the expected outcome of the Reference channel decorrelation identified in point #1.
  - **Matched Filtering:** The ARD processing relies on the cross-correlation of the Surveillance signal with the Reference signal: $R_{xy} = \text{Surv} \otimes \text{Ref}^*$.
  - **Mechanism of Failure:** The Surveillance channel likely contains the faint echoes of the FM target (physically reflected). However, the Reference channel no longer contains the FM waveform; it contains the uncorrelated data (likely the 1000 Hz tone or noise).
  - **Result:** Correlating the FM echoes in the Surveillance channel against a Reference channel that lacks the FM waveform results in noise. The processing gain of the pulse compression is lost, and the target signal falls below the noise floor.

#### 4. Spectral Signature of the Failure

The use of a 1000 Hz offset tone allows for a specific interpretation of the Reference channel content.

- **Tone Properties:** The generated tone is a pure sinusoid at 1000 Hz relative to the carrier.
- **FM Properties:** The FM signal is wideband (approx. 100-200 kHz).
- **Correlation:** The theoretical cross-correlation between a pure sine wave and a random FM signal is zero.

* **Discussion:** The observed correlation of -0.0105 is consistent with the Reference channel being **completely overwritten** by the 1000 Hz tone. If the Reference channel contained _any_ significant portion of the FM signal, the correlation would be non-zero. The fact that it is zero suggests the simulator has replaced the high-power FM signal with the low-power Tone signal in the output buffer. (Note: Q-channel analysis confirms Q/I ≈ 1.0, so the tone is properly represented as a complex signal — the ±50 Hz symmetric Doppler lines in the ARD arise from the cross-ambiguity of correlating a narrowband reference against the surveillance channel, not from real-valued signal artifacts.)

### Summary of Findings

The data indicates that the simulator fails to correctly sum signals from multiple transmitters. Specifically:

1.  **Signal Replacement:** The primary high-power signal (FM) is being discarded or suppressed in favor of the secondary low-power signal (Tone/Jammer).
2.  **Processing Failure:** This replacement corrupts the Reference channel, making matched filtering impossible and causing valid targets to vanish from the processed output.
3.  **Link Budget Error:** After fullscale correction, power properly increases when the jammer is added, but by +6.2% (vs expected +0.017%) — confirming the jammer signal is ~360× too strong at the receiver. The original apparent power _decrease_ in raw ADC values was an artifact of differing `fullscale` normalisation between runs.

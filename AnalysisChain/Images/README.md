# Description of the plots

## JamSingleTarget_Latest.png

The image is a bistatic radar range–Doppler intensity map with bistatic range on the x-axis from approximately 0.75×10⁵ m to 2.5×10⁵ m and bistatic Doppler on the y-axis from −200 Hz to +200 Hz. Signal power is shown in dB with a color scale spanning 0 dB (yellow) to −40 dB (dark blue). The background noise floor is predominantly between −25 dB and −35 dB, with widespread horizontal banding across nearly the full range extent. Stronger returns (approximately −5 to −15 dB) appear as persistent horizontal streaks at Doppler frequencies near 0 Hz, ±50 Hz, and ±100 Hz, indicating Doppler-localized energy that is largely invariant with range. Peak intensities approach 0 dB in localized patches, while most of the scene remains low-to-moderate power. The dominance of range-invariant Doppler bands and absence of compact, localized peaks indicate distributed interference or jamming-like energy rather than a single isolated point target.

## CleanSingleTarget_Latest.png

This Bistatic Range-Doppler (ARD) plot, titled "Output/16.ard," maps signal intensity across a spatial range of $0.7 \times 10^5$ to $2.5 \times 10^5$ meters and a Doppler frequency spectrum of $-200$ to $+200$ Hz. Utilizing a decibel scale ranging from a $-30$ dB noise floor to a $0$ dB peak, the visualization identifies a primary moving target appearing as a high-intensity yellow-green streak (approx. $-5$ to $0$ dB) at a Doppler shift of $+85$ to $+90$ Hz, spanning the $1.1 \times 10^5$ to $1.4 \times 10^5$ m range. Stationary clutter is observed near the $0$ Hz Doppler line with intensities reaching $-15$ dB, primarily at ranges below $1.0 \times 10^5$ m. The data is characterized by widespread horizontal streaking, with secondary signal returns and artifacts distributed across the full range, concentrated largely between the $-150$ Hz and $+180$ Hz Doppler coordinates.

---

# Analysis between the two plots

Based on the simulation data, the interpolation logs, and the resulting ARD plots, here is the analysis and discussion regarding the alleged simulator bug.

### 1. Quantitative Analysis of Signal Power

The most critical insight comes from the interpolation points provided for $t=60s$. These values represent the "ground truth" of what the simulator calculated at the receiver antenna terminals before any signal processing occurred.

*   **Target Echo Power ($P_{echo}$):** $1.53 \times 10^{-11}$ Watts
*   **Jammer Signal Power ($P_{jammer}$):** $1.54 \times 10^{-10}$ Watts

**Observation:**
Despite the Jammer transmitting only 1 Watt (compared to the FM Transmitter's 10 kW), the Jammer signal arriving at the Surveillance Receiver is **10 times stronger (10 dB)** than the Target Echo.

**Physics Verification:**
This is physically consistent with the radar equation.
*   **Target Echo:** Suffers two-way path loss ($R_{tx \to target}^2 \times R_{target \to rx}^2 \approx R^4$) and scattering loss from the target's RCS.
*   **Jammer:** Suffers only one-way path loss ($R_{target \to rx}^2 \approx R^2$).
*   The massive difference between $1/R^4$ and $1/R^2$ propagation losses allows a 1 Watt source to dominate a 10,000 Watt reflection.

### 2. Analysis of the ARD Plot Degradation

The "Clean" plot showed a distinct target with a noise floor of -30 dB. The "Jammer" plot shows a noise floor rising to -20 dB or higher, with "spots" and "banding" obscuring the target.

**Mechanism of Degradation:**
The ARD processing utilizes a Matched Filter (Cross-Correlation).
$$ Output = \text{Corr}(S_{surv}, S_{ref}) $$
$$ S_{surv} = S_{echo} + S_{jammer} + \text{Noise} $$

Therefore, the output contains two distinct correlation components:
1.  **$\text{Corr}(S_{echo}, S_{ref})$:** This produces the sharp peak (the target) because $S_{echo}$ is a copy of $S_{ref}$.
2.  **$\text{Corr}(S_{jammer}, S_{ref})$:** This is the cross-correlation of two different FM radio snippets.

**The "Bug" vs. Reality:**
The "alleged bug" likely stems from the expectation that because the Jammer and Reference waveforms are uncorrelated, the Jammer energy should disappear or average out to zero.

**Reality:**
FM radio waveforms are not perfectly orthogonal. When you cross-correlate two different segments of FM audio, the result is not zero; it is a complex "noise-like" structure with many sidelobes and peaks. This is known as **Cross-Correlation Noise**.

Because the Jammer signal is **10 dB stronger** than the Echo at the input:
1.  The "Cross-Correlation Noise" (Jammer vs Ref) is generated at a level significantly higher than the system noise floor.
2.  If the peak-to-sidelobe ratio of the FM waveform cross-correlation is poor, this "noise" can easily exceed the processing gain achieved by compressing the weaker Target Echo.

The "spots" and "range-invariant Doppler bands" observed in the ARD plot are the visual manifestation of this cross-correlation function. The Jammer is effectively raising the noise floor of the detection process above the energy of the target return.

### 3. Discussion of the Alleged Simulator Bug

**Evidence Supporting the Simulator's Correctness:**
1.  **Valid Interpolation Data:** The XML logs show that the simulator is correctly calculating the physics. It is generating valid I/Q samples with phases and amplitudes that adhere to the Friis transmission equation for both the one-way (Jammer) and two-way (Radar) paths.
2.  **Coherent Phase:** The interpolation logs show distinct, valid phase values for both signals, indicating the simulator is maintaining coherence.
3.  **Plausible Output:** The "destruction" of the ARD plot is a mathematically predictable result of mixing a stronger uncorrelated signal with a weaker target signal in a correlation processor that lacks infinite orthogonality.

**Assessment of the Claim:**
The claim that this represents a bug in the simulator appears **unfounded** based on this data. The results suggest that the simulation is accurately modeling the high lethality of a co-located noise jammer against a passive radar system.

The "failure" to see the target is not a failure of the simulator to generate data, but a failure of the signal processing chain (specifically the matched filter) to reject the interference caused by the Jammer. The Jammer has successfully denied detection by injecting enough energy to raise the correlation noise floor above the target's compressed peak.

### 4. Conclusion

The simulation is functioning correctly. The observation that a 1 Watt jammer obscures the target is a valid physical outcome of the scenario geometry and the signal processing properties of FM waveforms. The "spots" and "bands" are not digital artifacts or bugs, but the cross-correlation signature of the jamming waveform against the reference waveform.

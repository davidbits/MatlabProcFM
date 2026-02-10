### 1. **Reference and Surveillance Channel Statistics**

#### Fullscale-Corrected Power (Physical Units)

Using `loadfersHDF5` to apply the FERS `fullscale` attribute (ADC-to-physical scaling):

| Scenario                   | Ref Power | Sur Power | Ref ΔPower | Sur ΔPower | Ref % Δ | Sur % Δ |
| -------------------------- | --------- | --------- | ---------- | ---------- | ------- | ------- |
| Clean (FM only)            | 2.398e-09 | 1.442e-09 | —          | —          | —       | —       |
| Wideband Jammer (FM+1W)    | 2.548e-09 | 1.624e-09 | +1.50e-10  | +1.82e-10  | +6.24%  | +12.58% |
| Single-Tone Jammer (FM+1W) | 2.548e-09 | 1.623e-09 | +1.50e-10  | +1.81e-10  | +6.27%  | +12.54% |

#### Correlation

| Comparison                  | Ref ρ (complex) | Sur ρ (complex) | Ref ρ (real-part) | Sur ρ (real-part) |
| --------------------------- | --------------- | --------------- | ----------------- | ----------------- |
| Wideband Jammer vs Clean    | 0.124           | 0.786           | −0.080            | +0.409            |
| Single-Tone Jammer vs Clean | 0.012           | 0.021           | −0.011            | −0.020            |

**Note on original raw ADC measurements:** Earlier power comparisons using raw ADC integer values (without the `fullscale` attribute) showed an apparent power _decrease_ of 26–27%. This was an artifact of FERS increasing the `fullscale` normalisation factor by ~20% in jammer runs to accommodate a larger peak amplitude. After fullscale correction, power properly **increases**, consistent with the direction required by superposition. Correlation values were unaffected (Pearson ρ is scale-invariant).

**Implications:**

- After fullscale correction, total received power **increases** when the jammer is added, as superposition requires. However, the magnitude of the increase is anomalous: a 1 W jammer should produce ~0.017% increase at the Reference receiver (37 dB below the 16.4 kW FM source). The observed **+6.2% is ~360× too large**, independently confirming the link budget error.

* Reference channel correlations near zero (complex |ρ| = 0.12 / 0.01) indicate **complete decorrelation**, i.e., the primary FM signal is **overwritten or suppressed**, not superimposed.

- Surveillance channel maintains partial correlation for the wideband jammer (~0.79 complex), but drops to near zero (~0.02) for the single-tone jammer, indicating the corruption extends to both channels in varying degrees.

---

### 2. **Range-Doppler (ARD) Observations**

Plot,Range (m),Doppler (Hz),Noise Floor (dB),Peak Power (dB),Features
CleanSingleTarget,0.7–2.5×10⁵,−200 → +200,−30,0,Target at 1.1–1.4×10⁵ m, +85→+90 Hz, stationary clutter −15 dB at <1×10⁵ m, wideband low-level noise −25→−40 dB
JamSingleTarget,0.75–2.5×10⁵,−200 → +200,−15→−30,0,Horizontal banding; 0→−20 dB across frequencies/ranges; no discrete target; energy smeared; peak 0 dB localized patches
JamSingleTarget_Tone,0.75–2.5×10⁵,−200 → +200,−40,0,Dominant clutter line at 0 Hz; symmetrical ±50 Hz lines; range-invariant horizontal smear; "blind zone" <0.85×10⁵ m; target disappears

**Observations:**

- Clean run shows coherent target echo localized in both range and Doppler.
- Jammer runs show **loss of target** due to Reference channel corruption.

* Single-tone Jammer reveals **±mirror Doppler lines**. Q-channel analysis confirms Q/I power ratio ≈ 1.0 in all scenarios, ruling out the Q=0 (real-valued signal) hypothesis. The symmetric lines instead result from the **cross-ambiguity structure** of correlating a narrowband reference (the CW tone that replaced the FM signal) against the surveillance channel.

---

### 3. **Signal Power and Link-Budget Analysis**

- FM transmitter: 16.4 kW → received ~1.52×10⁻¹¹ W.
- Jammer: 1 W → received ~1.53×10⁻¹⁰ W.
- Path-loss difference (74 km vs 44 km) ~4.5 dB.
- Observed: Jammer power **10× greater** than FM at receiver → **~37 dB missing power for FM**.
- Confirms **simulator mis-scaling / overwriting** of multi-transmitter fields.

---

### 4. **Correlation vs Physics**

- Reference Receiver pointed at 16 kW FM source; 1 W jammer ~60–70 dB weaker.
- Expected correlation: >0.9999; observed: complex |ρ| = 0.12 / 0.01 → **statistical independence**.
- Fullscale-corrected power increases by +6.2% (vs expected +0.017%), confirming the jammer signal is **~360× too strong** at the receiver — consistent with a link budget / signal replacement error in FERS.

---

### 5. **Matched Filter Failure**

- ARD processing: (R\_{xy} = Surv \otimes Ref^\*).
- Jammer run: Ref channel contains uncorrelated waveform → matched filter fails → target signal is smeared across range bins, forming horizontal "noise ridge" at target Doppler.
- Single-tone: Correlation with FM signal ≈ 0 → confirms FM waveform missing in Reference channel.

---

### 6. **Spectral Signature of Reference Corruption**

- Symmetrical ±Doppler lines in the single-tone jammer ARD result from the **cross-ambiguity function** between the narrowband tone (which has replaced the FM signal in the Reference channel) and the Surveillance channel. Q-channel analysis confirms Q/I ≈ 1.0 in all scenarios, **ruling out** the previously hypothesised Q=0 (real-valued signal) mechanism.
- Lines track actual bistatic Doppler shift of the jammer platform.
- Horizontal, range-invariant smear confirms **Reference channel corruption**, preventing pulse compression.

---

### 7. **Simulator Bug Characterization**

1. **Reference Channel Overwriting:** High-power FM signal replaced by low-power jammer in Ref output (ρ ≈ 0).
2. **Link Budget Error:** Fullscale-corrected power shows the 1 W jammer contributes +6.2% at the Reference receiver, ~360× more than the expected +0.017%. The jammer signal dominates where it should be negligible.
3. **ADC Normalisation Side-Effect:** FERS increases the `fullscale` factor by ~20% in jammer runs. The original apparent power _decrease_ in raw ADC values was an artifact of this renormalisation, not a physics violation. After correction, superposition holds in direction but not in magnitude.
4. **Processing Chain Effect:** Matched filtering fails, ARD target disappears, horizontal smears appear.
5. **I/Q Integrity Verified:** Q/I power ratio ≈ 1.0 in all scenarios. The ±Doppler mirror lines are not caused by Q=0 corruption but by cross-ambiguity with a narrowband corrupted reference.
6. **Cause Hypotheses:**
   - Pulse/Waveform buffer overwrite
   - Incomplete transmitter summation
   - Clock/timing race condition

---

### 8. **Predictions and ARD Behavior**

- Target should appear in clean scenario: 120 km range, +85 Hz Doppler.
- Jammer energy appears as low-power horizontal line at +85 Hz Doppler, spread across full range.
- Slight noise floor elevation (~−30 dB → −28 dB).
- Clutter cancellation (CGLS/ECA) unaffected for main transmitter.

---

### 9. **Supporting Technical Data**

- MATLAB Processing Chain: `MatlabProcServ.m` orchestrates CPI processing → optional clutter cancellation → ARD generation (FX/XF methods).
- Cancellation algorithms: CGLS (iterative) and ECA (direct LS) applied per segment.
- Windowing: Blackman-Harris, Hann used to reduce spectral leakage.
- Data classes: `cRCF` (raw IQ), `cARD` (range-Doppler), `cARDCell`/`cARDCellSelection` (target points).
- Utility scripts: `ComparePowers.m`, `ReadARDs.m` for verification/visualization.

---

### **Cohesive Technical Summary**

The FERS simulator exhibits a **critical multi-transmitter bug**: adding a low-power jammer corrupts the Reference channel by overwriting the primary 16 kW FM signal, producing near-zero correlation (complex |ρ| = 0.01–0.12) and failure of matched filtering. After applying the FERS `fullscale` attribute to convert from ADC to physical units, total received power properly increases when the jammer is added — the previously reported power _decrease_ was an artifact of comparing raw ADC values across runs with different normalisation factors. However, the magnitude of the increase (+6.2%) is ~360× larger than expected from a 1 W source at 37 dB below the FM transmitter, independently confirming the link budget error. Q-channel analysis shows Q/I ≈ 1.0 in all scenarios, ruling out the previously hypothesised I/Q corruption; the ±Doppler mirror lines in the single-tone test arise from cross-ambiguity with the narrowband corrupted reference, not from real-valued signal artifacts. The ARD outputs show horizontal range-invariant smears and complete disappearance of coherent target echoes. The simulator's output indicates **signal replacement/overwriting with incorrect link budget scaling** in multi-transmitter scenarios, preventing correct passive radar processing. Clean runs validate the processing chain; only multi-transmitter scenarios reveal the functional defect.

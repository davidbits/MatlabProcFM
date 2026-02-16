# Final Report: Investigation of the Alleged "Moving Transmitter Bug" in FERS

## 1. Introduction

This report presents the findings of a systematic investigation into an alleged software defect in FERS (Fast
Electromagnetic Radar Simulator), referred to in project documentation as the "moving transmitter bug." The bug was
reportedly triggered when a transmitter moved independently of the receiver — specifically in scenarios involving a
target-mounted jammer — and was cited as the root cause of a retracted academic paper. Meeting records spanning May 2025
to January 2026 describe the defect as producing "completely corrupted" simulation output visible only after
post-processing through a passive FM radar analysis chain.

The investigation was conducted using a controlled set of FERS simulation scenarios, two FERS software versions (old:
commit `526d41`; new: commit `a6facb`), and a MATLAB-based FM passive radar processing pipeline comprising CGLS adaptive
cancellation and frequency-domain cross-ambiguity function (FX-ARD) generation.

---

## 2. Test Environment

### 2.1 Scenario Geometry

All scenarios are variants of the "Malmesbury" bistatic FM passive radar configuration:

| Element         | Description                                               | Position / Parameters                                                |
|-----------------|-----------------------------------------------------------|----------------------------------------------------------------------|
| FM Transmitter  | Constantiaberg Tx, isotropic, 16.4 kW                     | Static; (258804, 6228721, 397 m)                                     |
| Reference Rx    | Yagi (sinc pattern, 7.2 dBi peak), boresight 204.2°       | Static; (287942, 6297267, 241 m)                                     |
| Surveillance Rx | Yagi (sinc pattern, 7.2 dBi peak), boresight 125°, 10° el | Static; 6 m east of Ref Rx                                           |
| Target          | Isotropic RCS = 200 m², moving linearly                   | 10 km → 5 km altitude over 180 s                                     |
| Jammer          | Isotropic, 1 W (nominal), FM-band noise waveform          | Co-located with target (0.5 m offset); moving or stationary per test |

Key parameters: `f_c` = 89 MHz (λ = 3.37 m), `f_s` = 204.8 kHz, 16-bit ADC, baseline Tx→Ref Rx ≈ 74.46 km, target range
from Rx ≈ 44–52 km.

### 2.2 Scenario Test Matrix

Ten `.fersxml` scenario files were used across the investigation:

| Scenario                                     | FERS | FM Tx | Jammer | Jammer Motion | Jammer Power | Notes                        |
|----------------------------------------------|------|-------|--------|---------------|--------------|------------------------------|
| `SingleTargetClean`                          | Old  | ✓     | ✗      | —             | —            | Baseline (no jammer)         |
| `CleanSingleTarget_fers_latest`              | New  | ✓     | ✗      | —             | —            | Baseline (no jammer)         |
| `JamSingleTarget`                            | Old  | ✓     | ✓      | Moving        | 1 W          | Primary old-FERS jammer test |
| `JamSingleTarget_fers_latest`                | New  | ✓     | ✓      | Moving        | 1 W          | Primary new-FERS jammer test |
| `JamSingleTarget_stationary_jam`             | Old  | ✓     | ✓      | Stationary    | 1 W          | Motion-independence test     |
| `JamSingleTarget_fers_latest_stationary_jam` | New  | ✓     | ✓      | Stationary    | 1 W          | Motion-independence test     |
| `JamSingleTarget_low_power`                  | Old  | ✓     | ✓      | Moving        | 100 µW       | Power sweep                  |
| `JamSingleTarget_fers_latest_low_power`      | New  | ✓     | ✓      | Moving        | 100 µW       | Power sweep                  |
| `JamSingleTarget_jam_only`                   | Old  | ✗     | ✓      | Moving        | 1 W          | Superposition component B    |
| `JamSingleTarget_fers_latest_jam_only`       | New  | ✗     | ✓      | Moving        | 1 W          | Superposition component B    |

Additional variants with 1 mW and 1 µW jammer power, and "proper co-location" (echo path disabled) were also tested but
are not represented as separate scenario files.

### 2.3 Processing Pipeline

The analysis chain consists of three stages:

1. **Data Ingest** (`combineRxData.m`): Loads FERS HDF5 exports (I/Q per receiver), applies `fullscale` correction, and
   writes interleaved Reference/Surveillance data to an RCF (Raw Capture Format) binary file.

2. **CGLS Adaptive Cancellation** (`CGLS_Cancellation.m`): Suppresses the Direct Signal Interference (DSI) from the
   surveillance channel. The algorithm constructs a clutter matrix from time-delayed, Doppler-shifted copies of the
   reference signal and solves via Conjugate Gradient Least Squares. Parameters: max range 85 km, max Doppler ±5 Hz, 15
   iterations, 4 segments per CPI.

3. **Cross-Ambiguity Function** (`FX_ARD.m`): Computes the range-Doppler map via frequency-domain cross-correlation with
   Blackman windowing. CPI duration = 4.0 s (819,200 samples), yielding a theoretical processing gain of ~53.5 dB.
   Output: Ambiguity Range-Doppler (ARD) maps up to 250 km range, ±200 Hz Doppler.

Three DSI suppression metrics were computed per CPI:

- **Total Power Reduction:** `10·log₁₀(P_pre / P_post)` — bulk power change.
- **DSI Projection Suppression:** Ratio of reference-projected power before/after cancellation — isolates DSI removal.
- **Correlation Drop:** Change in normalised |ρ| between surveillance and reference — measures decorrelation.

---

## 3. Results

### 3.1 Antenna Gain Bug — Confirmed and Quantified

Comparison of FERS link logs against analytic Friis-equation calculations revealed a gain computation error in old FERS:

| Path            | Old FERS G_r (dBi) | New FERS G_r (dBi) | Analytic (dBi) | Error              |
|-----------------|--------------------|--------------------|----------------|--------------------|
| FM Tx → Ref Rx  | −19.5              | +7.20              | +7.19          | **−26.7 dB** (old) |
| Jammer → Ref Rx | +6.5               | −23.15             | −23.2          | **+29.7 dB** (old) |

The error pattern — high gain far off-boresight, low gain near-boresight — is consistent with a radians/degrees mix-up
in the sinc antenna model. The net effect is a ~56 dB gain inversion at the Reference Rx, confirmed independently via IQ
power analysis: the new FERS reference channel is 26.7 dB (463×) stronger than old FERS in the clean scenario, matching
the corrected antenna gain exactly. The new FERS gains agree with hand calculations to within 0.1 dB.

The old FERS Reference Rx shows 6.2% jammer power contamination versus 0.01% in the new FERS. The bug is fixed in new
FERS (commit `a6facb`).

### 3.2 Moving Transmitter Bug — Not Confirmed

The central claim — that transmitter motion corrupts the simulation — was tested via a full 2×2 factorial design:

|              | Moving Jammer      | Stationary Jammer              |
|--------------|--------------------|--------------------------------|
| **Old FERS** | Target not visible | Target not visible — identical |
| **New FERS** | Target not visible | Target not visible — identical |

All four cells produce results indistinguishable within each FERS version. **Transmitter motion has zero measurable
effect on the output.** The original claim is not supported.

### 3.3 Jammer Echo Hypothesis — Eliminated

The original link budget identified the jammer echo via the target (R_tx = 0.5 m) as the dominant interference mechanism
at −81.7 dBW. To test this, the echo path was explicitly disabled:

| Configuration                                | Result                             |
|----------------------------------------------|------------------------------------|
| Echo enabled, 1 W jammer                     | Target not visible                 |
| Echo disabled, 1 W jammer (direct path only) | Target not visible — **identical** |

The jammer's **direct path alone** (−99.75 dBW new FERS, −101.4 dBW old FERS at Sur Rx) is sufficient to obscure the
target. The echo, while energetically significant, is not the limiting factor.

### 3.4 Detection Threshold — Physically Correct

A jammer power sweep from 1 W to 1 µW produces a smooth, continuous detection curve:

| Jammer Power | Jammer/Target Ratio | Est. Post-Proc SNR | Observed      |
|--------------|---------------------|--------------------|---------------|
| 1 W          | +63.6 dB            | ≈ −10 dB           | Not visible ✓ |
| 1 mW         | +33.6 dB            | ≈ +20 dB           | Marginal ✓    |
| 100 µW       | +23.6 dB            | ≈ +30 dB           | Visible ✓     |
| 1 µW         | +3.6 dB             | ≈ +50 dB           | Clear ✓       |

The transition is a monotonic power-law consistent with the bistatic radar equation and the ~53.5 dB available
processing gain. There is no discontinuity indicative of a software fault.

### 3.5 DSI Cancellation Performance

Initial metrics reported a 19.5 dB cancellation gap between old and new FERS. Refined DSI-specific metrics corrected
this:

| Metric                     | Old FERS              | New FERS              |
|----------------------------|-----------------------|-----------------------|
| Total Power Reduction      | 69.06 dB (σ = 8.51)   | 49.56 dB (σ = 3.41)   |
| DSI Projection Suppression | 120.99 dB (σ = 14.61) | 113.66 dB (σ = 12.47) |
| Correlation Drop           | 25.86 dB (σ = 4.01)   | 32.05 dB (σ = 5.46)   |
| ρ post-cancellation        | 0.0041                | 0.0022                |

The total power reduction gap (19.5 dB) is a measurement artefact: the new FERS post-cancellation residual retains more
correctly-scaled non-DSI power (target echoes, multipath). The DSI-specific projection suppression gap narrows to 7.3
dB, and the new FERS achieves **better** decorrelation (ρ = 0.0022 vs 0.0041). Both versions achieve >113 dB DSI
suppression and ρ < 0.005, indicating comparable cancellation quality. No re-tuning of the CGLS parameters is required.

### 3.6 Signal Integrity Verification

Three additional verification tests were performed:

**A/B/C Superposition Linearity.** The combined scenario (C = FM + Jammer) was decomposed into components (A = FM-only,
B = Jammer-only) and the residual ‖C − (A+B)‖/‖C‖ measured:

|          | Reference    | Surveillance |
|----------|--------------|--------------|
| New FERS | 2.335 × 10⁻⁵ | 2.832 × 10⁻⁵ |
| Old FERS | 2.591 × 10⁻⁵ | 2.638 × 10⁻⁵ |

All residuals are < 10⁻⁴, attributable to 16-bit ADC quantisation across differing per-export fullscale grids (~3 LSB).
**Both FERS versions perform perfect linear superposition.**

**Ref/Sur Time Alignment.** Cross-correlation lag estimates between clean and jammer runs showed Δlag ≤ ±1 sample,
consistent with numerical precision. Enabling additional transmitters does not shift export alignment.

**Moving-Transmitter Doppler.** CW tone tests on the moving jammer platform produced Doppler lines consistent with
expected values from the scenario geometry. The kinematics engine computes correct Doppler for independently-moving
transmitters.

---

## 4. Discussion

### 4.1 Root Cause of the Originally Observed Failure

The phenomenon originally attributed to the "moving transmitter bug" is the result of two independent, compounding
factors:

1. **Antenna gain bug (old FERS only):** A radians/degrees error in the sinc antenna model produces a ~56 dB gain
   inversion at the Reference Rx, contaminating the reference channel with 6.2% jammer power and attenuating the FM
   illuminator signal by 26.7 dB. This degrades both DSI cancellation quality and cross-correlation processing.

2. **Physically correct jammer obscuration (both FERS versions):** A 1 W isotropic jammer at ~50 km range produces a
   direct-path interference level 45–68 dB above the FM echo from a 200 m² target at the same range. With ~53.5 dB of
   cross-correlation processing gain available, the target is unrecoverable. This is not a defect; it is the expected
   physics.

Neither factor is related to transmitter motion. The "moving transmitter bug" label is a misattribution arising from the
fact that the original test scenario happened to use a moving jammer, and the antenna gain bug happened to amplify the
jammer's effect on the reference channel.

### 4.2 Assessment of Claims from Meeting Transcripts

| Claim                                                          | Assessment                                                                                                                                                 |
|----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Simulation breaks down when a transmitter moves independently  | **Not confirmed.** 2×2 factorial: motion has zero effect.                                                                                                  |
| Output becomes completely corrupted, showing only noise        | **Misleading.** The elevated noise floor is physically correct.                                                                                            |
| Bug is not visible in raw ADC data, only after post-processing | **True but not a bug.** Post-processing correctly reveals that the jammer dominates.                                                                       |
| Radians/degrees fix inadvertently resolved this bug            | **Not confirmed.** Both FERS versions produce identical qualitative results.                                                                               |
| Bug severity led to paper retraction                           | **Plausible but misdiagnosed.** The retraction was likely driven by the antenna gain error degrading reference channel quality, not by transmitter motion. |

### 4.3 Implications for the Paper Retraction

The evidence indicates the retraction was likely precipitated by the combined effect of the antenna gain bug (delivering
a 26.7 dB weaker reference and 30 dB stronger jammer to the Reference Rx) and a physically powerful jammer overwhelming
the target. With the antenna bug now fixed, the reference channel integrity is restored, but the 1 W jammer still
obscures the target — which is physically correct.

---

## 5. Conclusions

| Finding                                            | Status                                                       |
|----------------------------------------------------|--------------------------------------------------------------|
| Antenna gain bug in old FERS (sinc model, rad/deg) | **Confirmed** — 56 dB inversion at Ref Rx; fixed in new FERS |
| "Moving transmitter bug"                           | **Not confirmed** — 2×2 factorial proves motion irrelevant   |
| Jammer echo as dominant interference               | **Eliminated** — direct path alone sufficient                |
| Target obscuration at 1 W jammer power             | **Physically correct** — 45–68 dB deficit vs ~53.5 dB PG     |
| Detection threshold (1 W → 1 µW sweep)             | **Continuous, theory-consistent** — no discontinuity         |
| Multi-transmitter superposition                    | **Linear** — residual < 3 × 10⁻⁵ (quantisation-limited)      |
| CGLS cancellation (old vs new FERS)                | **Comparable** — >113 dB DSI suppression, ρ < 0.005 both     |
| Moving-transmitter Doppler computation             | **Correct** — verified with coherent CW test                 |
| Ref/Sur export alignment                           | **Unaffected** by number of active transmitters              |

**The alleged "moving transmitter bug" does not exist.** The investigation tested every plausible failure mode
attributable to transmitter motion or multi-transmitter interaction and found all functioning correctly. The only
confirmed software defect is the antenna gain computation error in old FERS, which is a separate issue unrelated to
transmitter kinematics and is already corrected in the current codebase.

---

## 6. Recommendations

1. **Close the "moving transmitter bug" investigation.** The evidence is conclusive across 10+ scenarios, two FERS
   versions, and multiple independent verification methods.

2. **Document the antenna gain fix** (commit `a6facb`) as a standalone, confirmed bug fix with its own regression test.
   The sinc antenna model should be validated against analytic gain calculations at a range of off-boresight angles.

3. **No processing chain re-tuning is required.** The CGLS cancellation performs comparably on both FERS versions when
   measured with DSI-specific metrics.

4. **Optional further work:**
    - Parametric jammer power sweep (1 µW–1 mW) to precisely characterise the detection threshold and validate the SNR
      model.
    - Multi-carrier frequency offset testing as a general FERS validation item (not specific to this investigation).

---

## Appendix A: Processing Pipeline Parameters

| Parameter                   | Value                                            |
|-----------------------------|--------------------------------------------------|
| Sample rate (f_s)           | 204,800 Hz                                       |
| Centre frequency (f_c)      | 89 MHz                                           |
| CPI duration                | 4.0 s                                            |
| Samples per CPI             | 819,200                                          |
| Theoretical processing gain | 59.1 dB (53.5 dB effective with Blackman window) |
| CGLS max range              | 85,000 m                                         |
| CGLS max Doppler            | ±5 Hz                                            |
| CGLS iterations             | 15                                               |
| CGLS segments               | 4                                                |
| ARD max range               | 250,100 m                                        |
| ARD max Doppler             | ±200 Hz                                          |
| Tx–Ref Rx baseline          | 74,460 m                                         |

## Appendix B: Software Components

| Component               | Function                                                         |
|-------------------------|------------------------------------------------------------------|
| `combineRxData.m`       | Merges FERS HDF5 I/Q exports into RCF binary format              |
| `loadfersHDF5.m`        | Reads FERS HDF5 output with robust `fullscale` attribute lookup  |
| `cRCF.m`                | Raw Capture Format class (Reference + Surveillance IQ, file I/O) |
| `CGLS_Cancellation.m`   | Adaptive DSI cancellation via Conjugate Gradient Least Squares   |
| `FX_ARD.m`              | Frequency-domain cross-ambiguity function (range-Doppler map)    |
| `cARD.m` / `cARDCell.m` | Ambiguity Range-Doppler map class and cell accessor              |
| `MatlabProcServ.m`      | Top-level processing orchestrator with per-CPI metric logging    |

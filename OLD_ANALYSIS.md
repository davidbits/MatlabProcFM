# FERS Multi-Transmitter Bug: Final Analysis

## Executive Summary

An investigation into the FERS (Flexible Extensible Radar Simulator) passive bistatic radar simulator has identified a **link budget / received power scaling error** that manifests when multiple transmitters are defined in a single scenario. The 1 W jammer signal arrives at the receivers approximately **26 dB too strong** (assuming isotropic antennas) or **79 dB too strong** (with the configured directional Yagi pattern), causing it to overwhelm the 16.4 kW FM transmitter's contribution and destroy the passive radar processing chain's ability to detect targets.

Critically, the signal **summation mechanism itself is working correctly** — FERS does perform a valid linear superposition of the two transmitter signals at each receiver. The defect is that the relative power levels of the summed signals are wrong: the jammer's received power is inflated by orders of magnitude beyond what the link budget predicts.

This conclusion was reached after a multi-phase investigation that corrected several initial misdiagnoses. The original analysis incorrectly attributed the problem to buffer overwriting, superposition violation, and I/Q channel corruption. Each of these was systematically ruled out through improved measurement methodology. The final diagnosis is supported by three independent lines of evidence: correlation analysis, power measurements, and an analytic link budget — all of which converge on the same ~26 dB (isotropic bound) discrepancy.

---

## Table of Contents

1. [Background](#1-background)
2. [Simulation Scenarios](#2-simulation-scenarios)
3. [Processing Chain](#3-processing-chain)
4. [Investigation Timeline](#4-investigation-timeline)
   - [Phase 1: Initial Observations](#phase-1-initial-observations-with-random-effects)
   - [Phase 2: Fullscale Correction](#phase-2-fullscale-correction)
   - [Phase 3: Removing Random Effects](#phase-3-removing-random-effects)
5. [Final Quantitative Results](#5-final-quantitative-results)
6. [Theoretical Verification](#6-theoretical-verification)
7. [Link Budget Analysis](#7-link-budget-analysis-summary)
8. [ARD Observations](#8-ard-observations)
9. [Root Cause Diagnosis](#9-root-cause-diagnosis)
10. [Errata: Corrected Misdiagnoses](#10-errata-corrected-misdiagnoses)
11. [Recommendations](#11-recommendations)

---

## 1. Background

### FERS Simulator

FERS (Flexible Extensible Radar Simulator) is an open-source radar environment simulator ([github.com/stpaine/FERS](https://github.com/stpaine/FERS)). It models transmitters, receivers, targets, and propagation to generate raw ADC-level IQ data in HDF5 format. The simulator supports multiple simultaneous transmitters, directional antenna patterns, moving platforms, and continuous waveform operation — making it suitable for passive bistatic radar (PBR) simulation.

### Passive Bistatic Radar

In an FM passive radar system, a dedicated **Reference receiver** captures the direct-path signal from a commercial FM transmitter (the "illuminator of opportunity"). A separate **Surveillance receiver** captures echoes of that FM signal reflected from targets. The processing chain cross-correlates the Surveillance signal with the Reference signal to produce a **Range-Doppler map** (referred to as an ARD — Amplitude/Range/Doppler map), where target echoes appear as localised peaks.

The cross-correlation acts as a matched filter: it compresses the wideband FM signal into sharp range-Doppler cells, providing processing gain proportional to the time-bandwidth product. This processing fundamentally depends on the Reference channel containing a clean copy of the transmitted FM waveform. If the Reference channel is corrupted, the matched filter fails and targets become undetectable.

### Objective

The investigation aimed to determine whether FERS correctly handles scenarios with **multiple concurrent transmitters** — specifically, a high-power FM illuminator (16.4 kW) plus a low-power jammer (1 W) co-located with a moving target. The jammer is expected to be negligible at the Reference receiver, which is pointed directly at the FM transmitter and away from the jammer.

---

## 2. Simulation Scenarios

Three FERS scenarios were defined, sharing identical geometry, timing, and receiver configurations. The only difference is the presence and type of jammer transmitter.

### Common Parameters

| Parameter | Value |
|---|---|
| Simulation duration | 180 s |
| Sample rate | 204 800 Hz |
| ADC resolution | 16 bits |
| Carrier frequency | 89 MHz (λ = 3.368 m) |
| Interpolation rate | 1000 Hz |
| FM Transmitter power | 16 400 W (isotropic antenna) |
| FM Transmitter location | Constantiaberg (258804, 6228721, 397 m) |
| Reference Rx location | Armasuisse (287942, 6297267, 241 m) |
| Surveillance Rx location | Armasuisse (287946, 6297267, 241 m) — 4 m east of Ref |
| Reference Rx pointing | Azimuth 204.2°, Elevation 0° (toward FM Tx) |
| Surveillance Rx pointing | Azimuth 125°, Elevation 10° (toward target area) |
| Rx antenna | Sinc-pattern Yagi (α=5.2481, β=2, γ=3.6 → 7.2 dBi peak) |
| Target RCS | 200 m² (isotropic) |
| Target trajectory | Linear: (331996, 6291261, 10000m) → (305243, 6267172, 5000m) |
| TX-to-Ref Rx baseline | ~74.5 km |

### Scenario Variants

| Scenario | Jammer | Jammer Power | Jammer Waveform | Jammer Location |
|---|---|---|---|---|
| **CleanSingleTarget** | None | — | — | — |
| **JamSingleTarget** | Wideband FM | 1 W (isotropic) | FM recording (different segment) | Co-located with target (0.5 m offset) |
| **JamSingleTarget_tone** | CW Tone | 1 W (isotropic) | 1000 Hz single tone | Co-located with target (0.5 m offset) |

For the final deterministic runs, both `noise_temp` and `random_freq_offset` were disabled across all scenarios to eliminate run-to-run random variability.

### Key Geometric Facts

| Path | Distance |
|---|---|
| FM Tx → Ref Rx | 74 482 m |
| Jammer → Ref Rx | 45 520 m |
| FM Tx → Target | 96 751 m |
| Jammer → Sur Rx | ~45 520 m |

| Receiver | Source | Angular offset from boresight |
|---|---|---|
| Ref Rx | FM Tx | Δaz = 1.2°, Δel = 0.1° **(on-boresight)** |
| Ref Rx | Jammer | Δaz = 106.4°, Δel = 12.4° **(far off-boresight)** |
| Sur Rx | FM Tx | Δaz = 78.0°, Δel = 9.9° |
| Sur Rx | Jammer | Δaz = 27.2°, Δel = 2.4° |

---

## 3. Processing Chain

### FERS Output → ARD Workflow

```
FERS Simulator
  ├─ Reference Rx HDF5 (I/Q chunks + fullscale attribute)
  └─ Surveillance Rx HDF5 (I/Q chunks + fullscale attribute)
         │
         ▼
  loadfersHDF5.m          — Reads I, Q, and fullscale attribute
         │
         ▼
  combineRxData.m         — Forms complex(I,Q) × scale, writes RCF file
         │
         ▼
  MatlabProcServ.m        — Per-CPI loop:
    ├─ CGLS_Cancellation.m  — Clutter cancellation (optional)
    └─ FX_ARD.m             — Cross-correlation → Range-Doppler map
         │
         ▼
  .ard files              — Viewed in ARDView or ReadARDs.m
```

### Key Files

| File | Purpose |
|---|---|
| `loadfersHDF5.m` | Loads FERS HDF5, reads I/Q data and `fullscale` attribute for ADC→physical conversion |
| `combineRxData.m` | Combines Ref and Sur into an RCF file; includes Q-channel verification blocks |
| `MatlabProcServ.m` | Main processing orchestrator: CPI segmentation → cancellation → ARD |
| `FX_ARD.m` | Frequency-domain cross-correlation: `SurvFFT × conj(RefFFT)` with Doppler shifts |
| `prove_fers_bug.m` | Diagnostic script for power, correlation, and I/Q analysis |
| `FULL_LINK_BUDGET_ANALYSIS.md` | Analytic link budget from scenario geometry |

### ARD Cross-Correlation (FX Method)

The FX_ARD function computes the cross-ambiguity function:

```
ARD(range, Doppler) = |IFFT{ Surv_FFT(f + f_d) × conj(Ref_FFT(f)) }|²
```

This depends critically on the Reference channel containing the FM waveform. If the Reference is contaminated with uncorrelated energy, the matched filter's processing gain is degraded and targets can fall below the raised noise floor.

---

## 4. Investigation Timeline

The investigation proceeded through three phases, each correcting misunderstandings from the previous phase.

### Phase 1: Initial Observations (with Random Effects)

**Methodology:** Compared FERS outputs from Clean and Jammer simulations. The original `prove_fers_bug.m` script read raw I-channel ADC values using `h5read()` without applying the `fullscale` attribute. Scenarios included `random_freq_offset = 0.01` (Hz) on the receiver clock and `noise_temp = 438.4` (K) on the jammer-scenario receivers (but not the clean scenario).

**Observations:**

| Measurement | Ref (WB Jammer) | Ref (Tone Jammer) |
|---|---|---|
| Power (Clean) | 0.2880 | 0.2880 |
| Power (Jammer) | 0.2095 | 0.2131 |
| ΔPower | −27.3% | −26.0% |
| Correlation ρ | −0.080 | −0.011 |

**Initial conclusions drawn (later revised):**

1. ~~**Signal overwriting:** ρ ≈ 0 indicated the FM signal was completely replaced by the jammer.~~
2. ~~**Superposition violation:** Power *decreased* when adding a second source.~~
3. ~~**I/Q corruption (Q=0):** Symmetric ±Doppler lines in the tone jammer ARD suggested a real-valued signal artefact.~~
4. **Link budget inversion:** FERS interpolation points showed the 1 W jammer arriving 10× stronger than the 16.4 kW FM transmitter.

### Phase 2: Fullscale Correction

**Methodology:** Rewrote `prove_fers_bug.m` to use `loadfersHDF5()`, which applies the `fullscale` attribute to convert ADC integers to physical-unit amplitudes. Extended analysis to full complex IQ signals (not just I-channel), all three scenarios, and both channels.

**Key discovery — fullscale differs between runs:**

| Scenario | Ref Fullscale | Change vs Clean |
|---|---|---|
| Clean | 6.451 × 10⁻⁵ | — |
| WB Jammer | 7.798 × 10⁻⁵ | +20.9% |
| Tone Jammer | 7.730 × 10⁻⁵ | +19.8% |

FERS sets `fullscale` to the peak absolute sample value, normalising the signal to fill the 16-bit ADC range. Jammer runs have a larger peak amplitude (more total energy), so the fullscale increases. Comparing raw ADC integers without this correction made the jammer runs *appear* to have less power, when in reality they had more.

**Corrected power results:**

| Scenario | Ref Power (W) | ΔRef | Sur Power (W) | ΔSur |
|---|---|---|---|---|
| Clean | 2.398 × 10⁻⁹ | — | 1.442 × 10⁻⁹ | — |
| WB Jammer | 2.548 × 10⁻⁹ | **+6.24%** | 1.624 × 10⁻⁹ | **+12.58%** |
| Tone Jammer | 2.548 × 10⁻⁹ | **+6.27%** | 1.623 × 10⁻⁹ | **+12.54%** |

**Result:** Superposition violation **overturned**. Power correctly increases when adding a jammer. However, the magnitude of increase (6.2% at Ref) is ~360× larger than the expected 0.017% from link budget.

**Q-channel analysis:**

| Signal | Q/I Power Ratio |
|---|---|
| Clean Ref | 1.0006 |
| WB Jam Ref | 1.0002 |
| Tone Jam Ref | 1.0010 |

**Result:** Q=0 hypothesis **ruled out**. All signals are properly complex with balanced I/Q channels.

**Correlation (still with random effects):**

| Comparison | Ref ρ (complex) | Sur ρ (complex) |
|---|---|---|
| WB Jammer vs Clean | 0.124 | 0.786 |
| Tone Jammer vs Clean | 0.012 | 0.021 |

Correlations remained near-zero, but the power and Q-channel corrections raised the question: if signals are correctly summed and properly complex, why is correlation so low?

### Phase 3: Removing Random Effects

**Methodology:** Re-ran all three simulations with `random_freq_offset` and `noise_temp` disabled in every scenario. This eliminated run-to-run random variability, making the comparison purely deterministic.

**The critical insight:** `random_freq_offset = 0.01` assigns a *different* random clock frequency offset to each simulation run. Over 180 seconds of simulation, even a 0.01 Hz offset causes ~1.8 samples of cumulative timing drift. For a wideband FM signal, this progressive sample misalignment completely decorrelates the outputs when compared between runs. The near-zero correlations observed in Phase 1 were caused by **different random seeds between the clean and jammer runs**, not by signal corruption within FERS.

**Deterministic results:**

| Comparison | Ref ρ (complex) | Sur ρ (complex) |
|---|---|---|
| WB Jammer vs Clean | **0.9700** | **0.9425** |
| Tone Jammer vs Clean | **0.9700** | **0.9427** |

Correlation jumped from ~0.01–0.12 to ~0.97. This proves the FM signal is **preserved** in the jammer runs and the jammer is **added on top** via correct linear superposition — but with too much power.

---

## 5. Final Quantitative Results

All values from the deterministic (no-random) simulation runs, using fullscale-corrected complex IQ data.

### Power Analysis

| | Reference (W) | Surveillance (W) |
|---|---|---|
| Clean (FM only) | 2.3979 × 10⁻⁹ | 1.4424 × 10⁻⁹ |
| WB Jammer (FM + 1W) | 2.5476 × 10⁻⁹ | 1.6239 × 10⁻⁹ |
| Tone Jammer (FM + 1W) | 2.5484 × 10⁻⁹ | 1.6233 × 10⁻⁹ |
| **ΔP (WB Jammer)** | **+6.24%** | **+12.58%** |
| **ΔP (Tone Jammer)** | **+6.27%** | **+12.54%** |

Both jammer types produce nearly identical power increases, confirming the issue is geometry/path-loss related and independent of waveform content.

### Correlation Analysis

| Comparison | Ref ρ (complex) | Ref ρ (real) | Sur ρ (complex) | Sur ρ (real) |
|---|---|---|---|---|
| WB Jammer vs Clean | 0.970032 | 0.970031 | 0.942538 | 0.942540 |
| Tone Jammer vs Clean | 0.969974 | 0.969969 | 0.942679 | 0.942633 |

Complex and real-part correlations agree to 5+ significant figures, confirming no phase rotation artefacts.

### Q-Channel Integrity

| Signal | P(I) | P(Q) | Q/I Ratio |
|---|---|---|---|
| Clean Ref | 1.199 × 10⁻⁹ | 1.199 × 10⁻⁹ | 0.9997 |
| Clean Sur | 7.214 × 10⁻¹⁰ | 7.210 × 10⁻¹⁰ | 0.9995 |
| WB Jam Ref | 1.274 × 10⁻⁹ | 1.274 × 10⁻⁹ | 1.0000 |
| WB Jam Sur | 8.122 × 10⁻¹⁰ | 8.117 × 10⁻¹⁰ | 0.9995 |
| Tone Jam Ref | 1.274 × 10⁻⁹ | 1.274 × 10⁻⁹ | 0.9995 |
| Tone Jam Sur | 8.119 × 10⁻¹⁰ | 8.114 × 10⁻¹⁰ | 0.9994 |

All Q/I ratios are within 0.06% of unity. Signals are properly complex in all cases.

### Fullscale Attributes

| Scenario | Ref Fullscale | Sur Fullscale |
|---|---|---|
| Clean | 6.600 × 10⁻⁵ | 5.002 × 10⁻⁵ |
| WB Jammer | 7.873 × 10⁻⁵ (+19.3%) | 6.500 × 10⁻⁵ (+30.0%) |
| Tone Jammer | 7.746 × 10⁻⁵ (+17.4%) | 6.384 × 10⁻⁵ (+27.6%) |

The fullscale is set to the peak absolute sample, confirming the ADC is driven to full scale in every run. The ~20% increase in jammer runs is consistent with additional signal energy.

---

## 6. Theoretical Verification

If FERS performs correct linear superposition, adding an uncorrelated jammer signal with power P_j to an FM signal with power P_FM, the expected cross-run correlation is:

```
ρ_expected = 1 / √(1 + P_j/P_FM)
```

This is because the clean signal x and the jammed signal z = x + y (where y is uncorrelated jammer) have:

```
corr(x, z) = cov(x, x+y) / (σ_x · σ_{x+y})
           = σ_x² / (σ_x · √(σ_x² + σ_y²))
           = 1 / √(1 + σ_y²/σ_x²)
           = 1 / √(1 + P_j/P_FM)
```

### Predicted vs Observed

| Channel | ΔP/P_FM | Predicted ρ | Observed ρ | Match |
|---|---|---|---|---|
| **Reference** | 6.24% | 1/√1.0624 = **0.97018** | **0.97003** | ✅ 4 sig. figs |
| **Surveillance** | 12.58% | 1/√1.1258 = **0.94249** | **0.94254** | ✅ 4 sig. figs |

The agreement to 4–5 significant figures is conclusive proof that:

1. **The FM signal is fully preserved** in the jammer runs (not overwritten or corrupted).
2. **The jammer signal is added via textbook-correct linear superposition** as an independent, uncorrelated component.
3. **The jammer's received power is the sole anomaly** — it is present at the correct phase and frequency but at the wrong amplitude.

---

## 7. Link Budget Analysis Summary

Full derivation in [`FULL_LINK_BUDGET_ANALYSIS.md`](FULL_LINK_BUDGET_ANALYSIS.md). Key results reproduced here.

### Expected Jammer-to-FM Power Ratio at Reference Rx

| Assumption | P_FM (W) | P_Jammer (W) | Ratio | dB |
|---|---|---|---|---|
| Sinc Yagi antenna | 1.070 × 10⁻⁶ | 7.95 × 10⁻¹⁶ | 7.4 × 10⁻¹⁰ | −91.3 |
| Isotropic Rx (worst case) | 2.119 × 10⁻⁷ | 3.462 × 10⁻¹¹ | 1.63 × 10⁻⁴ | −37.9 |
| **FERS observed** | — | — | **0.0624** | **−12.1** |

### Link Budget Decomposition (Reference Rx)

```
                                    FM Tx        Jammer       Difference
                                    -----        ------       ----------
Transmit power:                  +42.1 dBW      0 dBW        +42.1 dB  (FM advantage)
Free-space path loss:
  (λ/4πR)² @74.5 km:            −108.9 dB
  (λ/4πR)² @45.5 km:                          −104.6 dB     −4.3 dB   (jammer closer)

Tx antenna gain (both iso):         0 dBi        0 dBi         0 dB

Rx antenna gain (sinc Yagi):
  On-boresight (→FM):             +7.0 dBi
  106° off-boresight (→Jam):                   −46.4 dBi    +53.4 dB  (FM advantage)
                                                              ─────────
Net FM advantage (sinc Yagi):                                 91.2 dB
Net FM advantage (isotropic):                                 37.8 dB
```

### Discrepancy

| Scenario | Expected ΔP/P | FERS Observed ΔP/P | Over-reporting Factor |
|---|---|---|---|
| Ref Rx (sinc Yagi) | 0.000000074% | 6.2% | **~83 million × (79 dB)** |
| Ref Rx (isotropic) | 0.016% | 6.2% | **~380 × (26 dB)** |
| Sur Rx (sinc Yagi) | 1.7% | 12.6% | ~7.4 × (8.7 dB) |
| Sur Rx (isotropic) | 0.016% | 12.6% | ~770 × (29 dB) |

Even under the most conservative assumption (isotropic receivers, ignoring all antenna discrimination), FERS over-reports the jammer contribution at the Reference receiver by a factor of **~380 (26 dB)**.

---

## 8. ARD Observations

### Clean Scenario (no-random runs)

- Clear, coherent target echo localised at ~+85 Hz Doppler, 1.1–1.4 × 10⁵ m bistatic range.
- Target track visible across CPIs with decreasing range and Doppler, consistent with the defined flight path.
- Stationary clutter at 0 Hz Doppler, primarily at ranges < 1.0 × 10⁵ m.
- Background noise floor at −25 to −40 dB.
- **Validates the processing chain**: `combineRxData.m` → `MatlabProcServ.m` → `FX_ARD.m` produces correct results with a single transmitter.

### Wideband Jammer Scenario (no-random runs)

- **Target is not detectable** in any CPI.
- Two faint lines visible near the lower range bound (<80 km), moving from ±75 Hz toward 0 Hz at CPI ~36, then flipping sides.
- These lines track the **jammer platform's bistatic Doppler** (which follows the target trajectory). The convergence to 0 Hz and sign change is consistent with the platform's radial velocity passing through zero.
- Lines are confined to short ranges because the wideband jammer signal retains some range structure in the cross-correlation, concentrating energy near the direct-path bistatic range.
- The target echo is masked by the jammer's coherent contribution at the same Doppler (since jammer and target are co-located).

### Single-Tone Jammer Scenario (no-random runs)

- **Target is not detectable.**
- Dominant 0 Hz clutter line extending across the full range.
- Two prominent symmetric lines at approximately ±50 Hz, extending across the **entire range extent** (range-invariant).
- The range-invariance is characteristic of a narrowband reference: cross-correlating a CW tone (in the contaminated Reference) with any signal produces no range compression, spreading energy uniformly across all range bins.
- Background noise floor is lower than the wideband jammer case (−25 to −35 dB), because the tone contamination is spectrally concentrated rather than spread.
- Signal suppression / "blind zone" at ranges below ~0.85 × 10⁵ m.

### Why the Target Disappears

Despite ρ ≈ 0.97 (indicating 97% of FM energy is preserved), the target vanishes because:

1. **The jammer is co-located with the target**, so it shares the same Doppler frequency.
2. The jammer signal appears in **both** Reference and Surveillance channels. The cross-correlation `Surv × conj(Ref)` therefore produces a **coherent jammer response** at the target's Doppler.
3. Unlike a target echo (which has range structure), the jammer's direct-path contribution is **spread across range bins**, creating horizontal lines that raise the local noise floor at the target's Doppler.
4. At the FERS-reported power level (6.2% of FM in Reference, 12.6% in Surveillance), the jammer's cross-correlation energy is sufficient to mask the much weaker target echo.
5. If the jammer were at its correct power level (0.016% of FM at Reference, isotropic bound), its contribution to the ARD would be ~37 dB below the FM noise floor and invisible.

---

## 9. Root Cause Diagnosis

### What the Bug Is

**FERS has a power scaling / link budget error in multi-transmitter scenarios.** When multiple transmitters contribute to a single receiver, the relative received power levels are incorrect. The low-power jammer arrives approximately 26 dB (isotropic bound) to 79 dB (directional antenna) stronger than physics predicts.

### What the Bug Is NOT

- ❌ **Not signal overwriting / buffer replacement.** The FM signal is fully preserved (ρ = 0.970, matching theory to 4 significant figures).
- ❌ **Not a superposition violation.** Signals are correctly summed linearly; total power increases as expected.
- ❌ **Not I/Q corruption.** Q/I power ratios are unity across all scenarios.
- ❌ **Not a processing chain issue.** The MATLAB chain produces correct ARDs from clean FERS data.

### Likely Mechanism

The exact location of the ~26 dB error within FERS has not been identified via source code inspection, but the measured data constrains the possibilities:

1. **Path loss miscalculation for secondary transmitters:** FERS may apply an incorrect R² scaling to the jammer signal, or fail to account for the path loss difference between the two transmitter-to-receiver paths.

2. **Antenna pattern not applied to secondary transmitter:** If FERS applies the Rx antenna gain only to the primary transmitter's direction and uses isotropic gain for additional transmitters, this would explain the Reference Rx discrepancy shrinking from 79 dB (sinc) to 26 dB (isotropic). The 26 dB residual would then come from a separate power-scaling error.

3. **Waveform normalisation interaction with `<power>` tag:** The transmit waveform files are normalised. FERS applies the `<power>` tag to set the transmit power. If this scaling is applied once globally rather than per-transmitter-per-receiver-path, the power ratio between transmitters could be corrupted.

4. **Per-pulse vs per-transmitter accumulation error:** FERS processes signals on a per-pulse basis internally. For continuous waveform mode, the `<prf>` tag defines the pulse structure. If the accumulation logic has an indexing or scaling error that manifests only with multiple transmitters, this could produce the observed effect.

### Supporting Evidence for the Link Budget Hypothesis

- Both jammer types (wideband FM and CW tone) produce **identical power increases** (+6.24% and +6.27% at Reference, +12.58% and +12.54% at Surveillance). This rules out waveform-dependent bugs and points to a geometry/power calculation issue.
- The Surveillance channel shows a larger power increase (12.6%) than the Reference channel (6.2%), consistent with the Surveillance antenna being more favourably oriented toward the jammer (Δaz = 27° vs 106° off-boresight). This confirms FERS is applying *some* antenna discrimination, but insufficiently.
- The fullscale attribute correctly increases in jammer runs, indicating FERS is aware of the additional signal energy — it is just computing the wrong amount.

---

## 10. Errata: Corrected Misdiagnoses

This section documents conclusions from earlier analyses that were subsequently found to be incorrect, along with the reason for the error.

### 10.1. "Signal Overwriting / Buffer Replacement"

**Original claim:** Near-zero correlation (ρ ≈ −0.08 to +0.12) proved the FM signal was completely overwritten by the jammer in the Reference channel.

**Correction:** The near-zero correlations were caused by **different random clock offsets between simulation runs**. The `random_freq_offset = 0.01` parameter assigns a unique random frequency perturbation to each run. Over 180 seconds, even 0.01 Hz of clock drift causes ~1.8 samples of cumulative timing misalignment, completely decorrelating a wideband FM signal in sample-by-sample comparison. Removing this parameter revealed ρ = 0.970, proving the FM signal is fully preserved.

**Lesson:** When comparing outputs from different simulation runs, all random/stochastic parameters must be either disabled or controlled (same seed) to enable valid inter-run comparison.

### 10.2. "Superposition Violation (Power Decrease)"

**Original claim:** Total received power decreased by 26–27% when adding the jammer, violating P_total = P₁ + P₂.

**Correction:** The power comparison was performed on raw ADC integer values without applying the `fullscale` HDF5 attribute. FERS normalises output to fill the ADC dynamic range, and the `fullscale` factor differs by ~20% between runs. After applying `fullscale`, power correctly increases (+6.2% at Reference, +12.6% at Surveillance).

**Lesson:** FERS HDF5 outputs must always be scaled by the `fullscale` attribute before any power comparison. Raw ADC values are normalised to the ADC range and are not comparable across runs with different signal amplitudes.

### 10.3. "I/Q Channel Corruption (Q=0)"

**Original claim:** Symmetric ±Doppler lines in the tone jammer ARD indicated the jammer signal was real-valued (Q=0), producing spectral mirroring.

**Correction:** Q/I power ratios are within 0.06% of unity across all scenarios. The signals are properly complex. The symmetric Doppler lines are instead a consequence of the jammer platform's Doppler changing sign as it flies past the receivers (converging toward 0 Hz and then diverging with opposite sign), combined with the narrowband tone's lack of range resolution causing range-invariant horizontal lines.

**Lesson:** Symmetric Doppler features can arise from platform kinematics (Doppler sign change during flyby), not only from signal representation errors.

### 10.4. Correlation Values from Runs with Random Effects

**Original claim:** Correlation values of ρ = −0.08 (wideband) and ρ = −0.01 (tone) between clean and jammer Reference channels.

**Correction:** These values are artefacts of run-to-run random variability, not measurements of signal corruption. The true (deterministic) correlations are ρ = 0.970 for both jammer types. The original values happen to match what one would expect from two independent random FM signals, which is exactly what the random clock offset creates.

**Note:** The original values were accurately measured — the measurement methodology was flawed, not the measurement itself. The data was correct; the interpretation was wrong.

---

## 11. Recommendations

### Immediate: Confirm the Bug in FERS Source Code

1. **Inspect the multi-transmitter signal accumulation path** in FERS, specifically how received power is computed for each transmitter-receiver pair. Look for missing or incorrect R² path loss scaling when iterating over multiple transmitters.

2. **Check antenna gain application** for secondary transmitters. Verify that the Rx antenna pattern is evaluated independently for each transmitter's angle of arrival, not just for the first or primary transmitter.

3. **Examine the `<power>` tag interaction** with file-based waveforms. Both transmitters use normalised waveform files with different `<power>` values (16400 W vs 1 W). Ensure the power scaling is applied per-transmitter and propagated correctly through path loss and antenna gain calculations.

### Validation Test

Run a controlled experiment with the jammer at **equal power** (16 400 W, same as FM) and **same distance** as the FM transmitter. With isotropic antennas, this should produce:

- ΔP/P = 100% (doubling of power)
- ρ = 1/√2 ≈ 0.707 (equal uncorrelated sources)

If ρ ≠ 0.707 or ΔP ≠ 100%, the summation mechanism itself has an error. If they match, the bug is purely in the path loss / antenna gain computation.

### Longer Term

- Add regression tests to FERS for multi-transmitter scenarios with known analytic solutions.
- Provide a diagnostic mode that logs per-transmitter received power at each receiver, broken down into transmit power, path loss, Tx antenna gain, and Rx antenna gain components. This would have immediately revealed the discrepancy without requiring the extensive external analysis documented here.

---

## Appendix A: Tool and Script Versions

| Tool | Version / Source |
|---|---|
| FERS | [github.com/stpaine/FERS](https://github.com/stpaine/FERS) (latest at time of testing) |
| MATLAB Processing Chain | `MatlabProcFM/AnalysisChain/` |
| Diagnostic Script | `prove_fers_bug.m` (fullscale-corrected, complex IQ version) |
| Link Budget Analysis | `FULL_LINK_BUDGET_ANALYSIS.md` |
| FM Waveform | `Malmesbury_1.rcf` (normalised 180 s segment, 360–540 s) |
| Jammer Waveform (WB) | `Malmesbury_1.rcf` (normalised 180 s segment, 540–720 s) |
| Jammer Waveform (Tone) | `tone_jammer.h5` (1000 Hz CW) |

## Appendix B: Summary of All Measured Values

### Phase 2 Results (with random effects, fullscale-corrected)

| Metric | Ref (WB Jam) | Sur (WB Jam) | Ref (Tone) | Sur (Tone) |
|---|---|---|---|---|
| ρ (complex) | 0.124 | 0.786 | 0.012 | 0.021 |
| ρ (real) | −0.080 | +0.409 | −0.011 | −0.020 |
| ΔP | +6.24% | +12.58% | +6.27% | +12.54% |
| Q/I ratio | 1.0002 | 0.9995 | 1.0010 | 0.9989 |

### Phase 3 Results (no random effects, fullscale-corrected) — FINAL

| Metric | Ref (WB Jam) | Sur (WB Jam) | Ref (Tone) | Sur (Tone) |
|---|---|---|---|---|
| ρ (complex) | **0.9700** | **0.9425** | **0.9700** | **0.9427** |
| ρ (real) | 0.9700 | 0.9425 | 0.9700 | 0.9426 |
| ΔP | +6.24% | +12.58% | +6.27% | +12.54% |
| Q/I ratio | 1.0000 | 0.9995 | 0.9995 | 0.9994 |
| Predicted ρ from ΔP | 0.97018 | 0.94249 | 0.97017 | 0.94252 |
| ρ residual (obs − pred) | −0.00015 | +0.00005 | −0.00017 | +0.00018 |

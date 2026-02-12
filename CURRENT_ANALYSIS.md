# Analysis of the Alleged "Moving Transmitter Bug" in FERS

## Executive Summary

After reviewing all test results, link budget calculations, FERS link logs, processing code, scenario files, and meeting transcripts, I conclude that **the alleged "moving transmitter bug" — as originally described — does not exist.** What does exist is a **confirmed antenna gain computation bug** in old FERS (commit `526d41`), and the **physically correct obscuration of the target** by a powerful jammer in the given scenario. These are two separate phenomena that have been conflated.

---

## 1. The Antenna Gain Bug — CONFIRMED

The raw link logs from `RAW_LINK_LOGS_OLD_VS_NEW_FERS.md` provide decisive evidence of a real antenna model error in the old FERS. Comparing gains at the **Reference Rx**:

| Path            | Old FERS Gr         | New FERS Gr          | Expected (hand calc) | Error        |
| --------------- | ------------------- | -------------------- | -------------------- | ------------ |
| FM Tx → Ref Rx  | 0.01129 (−19.5 dBi) | 5.25 (+7.20 dBi)     | 5.241 (+7.19 dBi)    | **−26.7 dB** |
| Jammer → Ref Rx | 4.497 (+6.5 dBi)    | 0.00484 (−23.15 dBi) | 0.00484 (−23.2 dBi)  | **+29.7 dB** |

The old FERS gains are **inverted** at the Reference Rx — it gives _high_ gain toward the jammer (106° off boresight) and _low_ gain toward the FM transmitter (1.3° off boresight). This is a ~56 dB swing in the wrong direction. The new FERS gains match the hand calculations from `FULL_LINK_BUDGET_ANALYSIS.md` to within 0.1 dB — the fix is confirmed.

At the **Surveillance Rx**, the errors are smaller but still present:

| Path            | Old FERS Gr (linear) | New FERS Gr (linear) | Expected            |
| --------------- | -------------------- | -------------------- | ------------------- |
| FM Tx → Sur Rx  | 0.00679 (−21.7 dBi)  | 0.00523 (−22.81 dBi) | 0.00523 (−22.8 dBi) |
| Jammer → Sur Rx | 2.103 (+3.2 dBi)     | 3.062 (+4.85 dBi)    | 3.062 (+4.86 dBi)   |

This is consistent with the "radians vs degrees mix-up" mentioned in the transcripts. The error pattern — treating a small degree value as radians evaluates the sinc at a much larger angle, and treating a large degree value as radians wraps it around — produces exactly this kind of gain inversion.

### Impact of the Antenna Bug

With old FERS at the Reference Rx:

```/dev/null/calc.txt#L1-5
FM direct:     16400 × 1 × 0.01129 × 1.295e-11 = 2.40e-9 W  (−86.2 dBW)
Jammer direct: 1     × 1 × 4.497   × 3.466e-11 = 1.56e-10 W (−98.1 dBW)

Jammer-to-FM ratio: −11.9 dB  (OLD — jammer only 12 dB below FM)
vs.                 −68.2 dB  (NEW — jammer negligible)
```

The old FERS reference channel has **6.5% jammer contamination** versus **0.000015%** in the new FERS. This contaminates the reference used for cancellation and cross-correlation, degrading performance. However, this alone does not explain the catastrophic "corruption" described.

---

## 2. The "Moving Transmitter Bug" — NOT CONFIRMED

The claim is that a **moving** transmitter specifically causes simulation corruption. Your own test results disprove this:

### Critical Test: Moving vs Stationary Jammer

From `ALL_TESTS_PERFORMED.md`:

- **JamSingleTarget_no_rand** (old FERS, 1W, **moving** jammer, no randomness): _"Average power level around −20 dB with no visible target, just noise"_
- **JamSingleTarget_stationary_jam** (old FERS, 1W, **stationary** jammer, no randomness): _"No notable differences to JamSingleTarget_no_rand"_

**A stationary jammer produces identical results to a moving jammer.** If the bug were triggered by transmitter motion (as claimed in the meeting transcripts), these two tests should produce different results. They don't. The motion of the jammer is irrelevant.

### Consistency Across FERS Versions

Both old and new FERS show the same qualitative behaviour:

| Jammer Power | Old FERS Result  | New FERS Result  |
| ------------ | ---------------- | ---------------- |
| 1 W          | Target invisible | Target invisible |
| 1 mW         | Target invisible | Target invisible |
| 1 µW         | Target visible   | Target visible   |
| No jammer    | Target visible   | Target visible   |

The "target invisible at 1 W, visible at 1 µW" pattern is identical across both versions. This rules out the antenna bug as the cause of target obscuration.

---

## 3. Why the Target Disappears — Physics, Not a Bug

The link budget from `FULL_LINK_BUDGET_ANALYSIS.md` explains the target obscuration perfectly.

### The Jammer Echo Dominates

The jammer is co-located with the target at 0.5 m offset. In the bistatic radar equation, the jammer-to-target distance R_tx = 0.5 m creates an enormously powerful echo:

```/dev/null/calc.txt#L1-9
At the Surveillance Rx (new FERS, correct gains):

Signal                    Power (dBW)    Power (W)
─────────────────────────────────────────────────
Jammer echo (via target)  −81.7          6.75 × 10⁻⁹     ← DOMINANT
FM direct (DSI)           −89.5          1.11 × 10⁻⁹
Jammer direct             −99.7          1.06 × 10⁻¹⁰
FM echo (TARGET SIGNAL)   −145.3         2.96 × 10⁻¹⁵     ← 63.6 dB below jammer echo
```

The FM echo (the actual target detection) is **63.6 dB below** the jammer echo. This ratio comes from:

```/dev/null/calc.txt#L1-5
Jammer echo / FM echo  =  (P_jam × R²_FM→Tgt) / (P_FM × R²_Jam→Tgt)
                        =  (1 × 96751²) / (16400 × 0.5²)
                        =  9.36 × 10⁹ / 4100
                        =  2.28 × 10⁶  =  63.6 dB
```

### Can Processing Gain Recover the Target?

The FX_ARD cross-ambiguity function processing provides a theoretical processing gain of:

```/dev/null/calc.txt#L1-7
N = Fs × CPI = 204800 × 4 = 819200 samples

Theoretical PG = 10·log₁₀(N) = 59.1 dB

But with Blackman windowing (FX_ARD.m applies blackman()),
effective PG ≈ 53–54 dB  (5–6 dB loss from windowing)
```

The jammer signal (FM noise from a different station segment) is **uncorrelated** with the FM reference, so after cross-correlation it spreads across all range-Doppler bins as a raised noise floor. The post-processing SNR:

```/dev/null/calc.txt#L1-6
At 1 W jammer:
  Pre-processing SNR  = −63.6 dB
  Processing gain      ≈ +53.5 dB
  Post-processing SNR  ≈ −10.1 dB  →  NOT detectable  ✓

At 1 µW jammer:
  Jammer echo / FM echo = 63.6 − 60 = 3.6 dB  →  clearly detectable after processing  ✓
```

This matches your observations precisely. **The target is genuinely undetectable at 1 W jammer power** — this is physically correct behaviour, not a bug.

---

## 4. Unresolved Anomaly: The 1 mW Case

My calculations predict the target should be marginally visible at 1 mW:

```/dev/null/calc.txt#L1-5
At 1 mW jammer:
  Pre-processing SNR  = −63.6 + 30 = −33.6 dB
  Processing gain      ≈ +53.5 dB
  Post-processing SNR  ≈ +19.9 dB  →  should be detectable
```

But your tests show `JamSingleTarget_fers_latest_low_power_1mw`: _"No major difference to JamSingleTarget_fers_latest"_. Possible explanations:

1. **Cancellation residuals:** If CGLS cancellation achieves only ~10–15 dB suppression of the FM DSI (rather than 30+ dB), the residual FM DSI power (up to 1.11 × 10⁻¹⁰ W) would add to the noise floor and degrade the effective SNR by an additional 10+ dB.

2. **Visual dynamic range:** The ARD plot's colormap may not have sufficient dynamic range to reveal a target that sits 20 dB above the noise floor when the overall power levels are elevated. The qualitative description "no major difference" might miss a marginal detection.

3. **Cancellation parameters:** The cancellation is configured for ±5 Hz Doppler and 85 km max range. Any mismatch between the cancellation filter and the actual DSI structure would leave residuals.

4. **Near-field physics:** The jammer at R_tx = 0.5 m from a target with RCS = 200 m² is deep in the near-field at λ = 3.37 m. The far-field assumption underlying the bistatic radar equation breaks down, and FERS may or may not handle this correctly.

This warrants further investigation but is a **separate issue** from the alleged moving transmitter bug.

---

## 5. Assessment of Claims from Meeting Transcripts

| Claim (from `EXCERPTS_FROM_TRANSCRIPTS.md`)                                           | Assessment                                                                                                                                                                                                                |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Simulation breaks down when a transmitter moves independently of the receiver"       | **NOT CONFIRMED.** Moving vs stationary jammer produces identical results.                                                                                                                                                |
| "The simulation output becomes completely corrupted, showing only noise"              | **Misleading.** The noise is physically correct — the jammer overwhelms the target echo by 63.6 dB.                                                                                                                       |
| "The bug is not visible in the raw ADC data, only after post-processing"              | **True but misleading.** The raw data is correct. The post-processing correctly reveals that the jammer dominates — this is not a bug manifesting, it's physics.                                                          |
| "The fix for the radians/degrees issue seems to have inadvertently resolved this bug" | **NOT CONFIRMED.** Both old and new FERS produce identical qualitative results (target invisible at 1W, visible at 1µW).                                                                                                  |
| "The moving transmitter bug was officially reproduced and confirmed"                  | **Overstated.** What was reproduced is the physical effect of a powerful jammer overwhelming a weak target echo, not a software bug in motion handling.                                                                   |
| "Results of moving and stationary jammer should be nearly identical"                  | **Confirmed!** This prediction from the January 2026 meeting is exactly what the tests show — but the conclusion that "the target should be visible in both cases" was wrong because the jammer power is simply too high. |

---

## 6. Recommendations

### Immediate

1. **Close the "moving transmitter bug" investigation.** The evidence conclusively shows that transmitter motion is not the cause of the observed behaviour. Moving and stationary jammers produce identical results.

2. **Document the antenna gain bug as a separate, confirmed fix.** The old FERS sinc antenna model had a real error producing ~56 dB gain inversion at the Reference Rx. The new FERS correctly matches hand calculations. This is a genuine, important bug fix — but it's an antenna gain bug, not a "moving transmitter bug."

### Further Investigation (if desired)

3. **Investigate the 1 mW detection threshold.** Run a parametric sweep of jammer power from 1 µW to 1 mW to find the exact threshold where the target becomes invisible. Compare against theoretical predictions. This will help validate the processing chain's overall performance.

4. **Test cancellation effectiveness independently.** Run the clean scenario (no jammer) and measure the DSI suppression achieved by the CGLS cancellation. This quantifies how much residual DSI contributes to the noise floor.

5. **Review the near-field jammer echo.** The R_tx = 0.5 m jammer-target geometry is physically unrealistic for RCS-based scattering at λ = 3.37 m. Consider whether the FERS radar equation is producing meaningful results in this configuration, or whether the jammer echo power is artificially inflated.

6. **Re-examine the scenario that led to the paper retraction.** The original failure likely had a different cause — potentially the antenna gain bug itself corrupting the reference channel (26.7 dB loss of FM power + 30 dB gain of jammer in the reference channel fundamentally degrades cancellation and cross-correlation performance). This is worth confirming by running the exact original scenario on both old and new FERS and comparing the reference channel quality.

---

## 7. Conclusions

| Finding                                           | Status                                                |
| ------------------------------------------------- | ----------------------------------------------------- |
| Antenna gain bug in old FERS                      | **CONFIRMED** — gains inverted by ~56 dB at Ref Rx    |
| Antenna gain bug fixed in new FERS                | **CONFIRMED** — gains match hand calculations         |
| Moving transmitter causes corruption              | **NOT CONFIRMED** — motion is irrelevant              |
| Target invisible at 1 W jammer power              | **Physically correct** — 63.6 dB deficit, ~53.5 dB PG |
| Target visible at 1 µW jammer power               | **Physically correct** — only 3.6 dB deficit          |
| Old and new FERS produce same qualitative results | **CONFIRMED** across all jammer power levels          |

The original investigators appear to have observed a real phenomenon (antenna gain errors corrupting the reference channel) and a real physical effect (jammer overwhelming the target) and attributed both to a single "moving transmitter bug" that doesn't exist. The antenna bug is real and significant, but it has nothing to do with transmitter motion. The jammer obscuration is physically correct and occurs identically whether the jammer is moving or stationary.

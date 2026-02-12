# Analysis of the Alleged "Moving Transmitter Bug" in FERS

After reading all the documents, I have a thorough understanding of the scenario, the claims, and your test results. Here is my analysis.

---

## 1. The Antenna Gain Bug — Confirmed and Fixed

The most concrete finding from your raw link logs is that **old FERS had a severe antenna gain calculation error**, and **new FERS matches the hand-calculated link budget exactly**.

### Evidence from the Raw Logs

Comparing the receive antenna gain (`Gr`) for the **Reference Rx** across old and new FERS for the same scenario:

| Path (at Ref Rx)    | Correct θ off boresight | Old FERS Gr        | New FERS Gr          | Hand Calc Gr        |
| ------------------- | ----------------------- | ------------------ | -------------------- | ------------------- |
| **→ FM Tx**         | 1.33° (nearly on-axis)  | 0.0113 (−19.5 dBi) | 5.248 (+7.20 dBi)    | 5.241 (+7.19 dBi)   |
| **→ Jammer/Target** | 106.1° (deep sidelobe)  | 4.497 (+6.5 dBi)   | 0.00484 (−23.15 dBi) | 0.00484 (−23.2 dBi) |

The old FERS gains are **inverted in character**: a source 1.33° off boresight (which should see near-peak gain of +7.2 dBi) instead got −19.5 dBi, while a source 106° off boresight (deep sidelobe, should be −23 dBi) instead got +6.5 dBi. This is a ~27–30 dB error in each direction, and the errors compound.

The new FERS values match your Section 4 hand calculations to within rounding precision. The FSPL values are identical between old and new FERS — only the antenna gains differ. This is consistent with the meeting transcript's hypothesis of a **radians-vs-degrees mix-up** (or similar coordinate error) in the angle-off-boresight calculation feeding the sinc gain model.

### Impact on the Reference Channel

This gain bug had a devastating effect specifically on the **reference receiver channel** in old FERS:

```/dev/null/comparison.txt#L1-10
                        Old FERS         New FERS (correct)
                        --------         ------------------
FM direct → Ref Rx:     2.40e-9 W        1.113e-6 W        (old is 26.7 dB too LOW)
Jammer direct → Ref Rx: 1.56e-10 W       1.68e-13 W        (old is 29.7 dB too HIGH)

FM-to-Jammer ratio
at Reference Rx:        ~12 dB           ~68 dB
```

In old FERS, the reference channel had only **12 dB** of FM-to-jammer discrimination. In reality (new FERS / hand calc), it should be **68 dB**. A contaminated reference channel is catastrophic for passive bistatic radar processing, because the reference signal serves as the matched filter for cross-correlation. Any jammer content leaking into the reference will spread across the entire range-Doppler map as correlated noise.

---

## 2. The "Moving Transmitter Bug" Is a Misnomer

Your test `JamSingleTarget_stationary_jam` (old FERS, stationary jammer at target start position, 1W) produced:

> "No notable differences to JamSingleTarget_no_rand other than slightly higher power levels in some areas"

This is a critical finding. **Moving the jammer vs. keeping it stationary produced essentially the same corrupted output.** The Doppler shift of the jammer signal is irrelevant — uncorrelated noise Doppler-shifted is still uncorrelated noise. This confirms that:

1. The corruption was **never caused by transmitter motion per se**.
2. The root cause was the **antenna gain bug** artificially amplifying the jammer's contribution to the reference channel.
3. The name "moving transmitter bug" was a misleading characterisation — the bug manifested whenever a secondary transmitter was present, regardless of motion.

The meeting transcript from 28 January 2026 correctly hypothesised this: _"suspected to be the result of a previously identified and fixed bug related to incorrect angle calculations"_.

---

## 3. Is the 1W Jammer Corruption in New FERS a Bug?

**No — it is physically expected behaviour.** Your link budget proves this conclusively.

The jammer is placed 0.5 m from the target with an RCS of σ = 200 m². The bistatic radar equation gives a jammer echo power at the **Surveillance Rx** of:

```/dev/null/calc.txt#L1-8
Jammer echo (via target) → Sur Rx:
  R_tx = 0.5 m,  R_rx = 45,516 m,  σ = 200 m²
  P = 6.75 × 10⁻⁹ W  =  −81.7 dBW

FM direct → Sur Rx:
  P = 1.11 × 10⁻⁹ W  =  −89.5 dBW

→ Jammer echo is 7.8 dB ABOVE the FM direct signal
```

After DSI (Direct Signal Interference) cancellation removes the FM direct path, the surveillance channel is dominated by the jammer echo at −81.7 dBW, while the FM echo from the target (the signal of interest) is at −145.3 dBW — a deficit of **63.6 dB**. Even with passive radar processing gain of ~53 dB (assuming BT ≈ 200,000), the post-processing SNR is approximately:

```/dev/null/calc.txt#L1-2
SNR_post ≈ −63.6 + 53 ≈ −10.6 dB
```

The target is **not detectable**. This is not a bug — it is the correct physical simulation of a 1W jammer at point-blank range to a 200 m² target.

The reason the jammer echo is so powerful is the **0.5 m jammer-to-target separation**: the (4π)³R_tx²R_rx² denominator in the bistatic equation has R_tx = 0.5 m, making the effective path loss from jammer to target essentially zero. The target acts like a 200 m² "relay antenna" for the jammer signal.

---

## 4. The Power Sweep Results Are Consistent with Physics

Your power sweep across jammer levels tells a coherent story:

| Jammer Power | Jammer Echo at Sur Rx | FM Direct at Sur Rx | J/FM Ratio | Post-Processing SNR (est.) | Test Result             |
| ------------ | --------------------- | ------------------- | ---------- | -------------------------- | ----------------------- |
| 1 W          | −81.7 dBW             | −89.5 dBW           | +7.8 dB    | ~−10.6 dB                  | Corrupted ✓             |
| 10 mW        | −101.7 dBW            | −89.5 dBW           | −12.2 dB   | ~+9.4 dB                   | "No difference" ⚠️      |
| 1 mW         | −111.7 dBW            | −89.5 dBW           | −22.2 dB   | ~+19.4 dB                  | "Lower power" ✓         |
| 1 µW         | −141.7 dBW            | −89.5 dBW           | −52.2 dB   | ~+49.4 dB                  | Clean, target visible ✓ |

The 1W and 1µW cases are unambiguous. The **10 mW case** is the only one that warrants scrutiny: the link budget predicts ~+9 dB post-processing SNR (marginally detectable), yet you report "essentially no difference" from the 1W case. However, there are several explanations that don't require a bug:

1. **Imperfect DSI cancellation:** If the processing chain doesn't perfectly cancel the FM direct signal (−89.5 dBW), its residual will raise the effective noise floor, pushing the 10 mW case below detectability.
2. **FM waveform cross-correlation:** The jammer waveform (`540s–720s` of the same FM recording) and the transmitter waveform (`360s–540s`) are from the **same radio station**. FM signals have structural self-similarity (music patterns, station IDs, modulation characteristics). Partial cross-correlation between these segments creates spurious peaks across the entire range-Doppler map — a more pernicious interference than white noise.
3. **Visual assessment subjectivity:** "Essentially no difference" is qualitative. Both 1W and 10 mW may produce "noisy-looking" ARDs that appear similar to the eye even if the noise floor differs by 8–10 dB.
4. **CPI length / processing gain:** My estimate of 53 dB processing gain assumed a 1-second CPI. If the actual CPI is shorter, the margin shrinks.

---

## 5. Old FERS vs New FERS — Both Versions Agree Where They Should

An important cross-check: for scenarios **without** a jammer, and for extreme low-power jammer cases, old and new FERS produce essentially identical results:

- `CleanSingleTarget_no_rand` (old) ≈ `CleanSingleTarget_fers_latest` (new) — target visible, low noise floor
- `JamSingleTarget_low_power_1uw` (old) ≈ `JamSingleTarget_fers_latest_low_power_1uw` (new) — target visible

This confirms the core simulation engine (propagation, Doppler, signal generation, waveform convolution) works correctly in both versions. The divergence only appears when antenna gain discrimination matters — i.e., when a jammer arrives from a different direction than the intended source.

---

## Conclusions

1. **The antenna gain bug was real and is now fixed.** Old FERS had a systematic error in the angle-off-boresight calculation that corrupted antenna gain values by up to ±30 dB. New FERS matches hand calculations to within 0.1 dB. This was the root cause of the historically observed corruption.

2. **The "moving transmitter bug" label is incorrect.** The corruption was caused by incorrect antenna gain calculations, not by transmitter motion. Your stationary jammer test proves this — a stationary jammer produced the same corruption in old FERS.

3. **There is no remaining bug in new FERS for the jammer scenarios tested.** The 1W jammer producing a corrupted ARD is the **physically correct result** given:
   - A 0.5 m jammer-to-target distance creating a massive jammer echo via the bistatic radar equation
   - The jammer echo being 7.8 dB above the FM direct at the surveillance receiver
   - The FM target echo being 63.6 dB below the jammer echo — unrecoverable even with processing gain

4. **The 10 mW ≈ 1 W observation is not conclusive evidence of a bug.** It is likely explained by imperfect DSI cancellation, FM waveform partial self-correlation, and/or the marginal SNR being below the visual detection threshold in the ARD.

---

## Recommendations

1. **Quantitative ARD comparison:** Instead of visual inspection, extract the peak SNR at the expected target location (85 Hz Doppler, 120 km range) from each ARD numerically. Plot peak SNR vs. jammer power. This will reveal whether the 10 mW case truly equals 1W, or whether there's a measurable improvement that's just not visible.

2. **Increase jammer-to-target separation:** The 0.5 m offset creates a pathological geometry that violates the far-field assumption of the radar equation (far-field requires R >> √(2D²/λ) where D is the target dimension). Try 1 km or 5 km separation. This will make the jammer echo power more realistic and allow the jammer power to be the primary variable, not the R_tx² near-field amplification.

3. **Use a truly uncorrelated jammer waveform:** Generate a synthetic white Gaussian noise waveform instead of a second segment of the same FM recording. This eliminates the FM self-correlation confound and isolates the link budget physics.

4. **Validate the proposed moving-vs-stationary test on new FERS:** Run `JamSingleTarget_fers_latest` with the jammer stationary. If the result matches the moving-jammer case (as it should), this definitively closes the "moving transmitter" hypothesis for new FERS as well.

5. **Consider closing this bug as "fixed in commit `a6facb`"** with the root cause documented as: _incorrect angle-off-boresight calculation in the sinc antenna gain model (radians/degrees or coordinate system error), causing up to 30 dB gain errors that destroyed reference channel purity when a secondary transmitter was present at a different bearing from the primary._

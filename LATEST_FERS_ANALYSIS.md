These numbers are _dramatically_ better. Your new FERS is behaving exactly as physics predicts. Let me walk through why.

## Reference Channel: Fixed ✅

| Metric          | Old FERS (no rand) | New FERS     | Expected |
| --------------- | ------------------ | ------------ | -------- |
| ρ (Ref, WB Jam) | 0.970              | **0.999907** | ~0.99999 |
| ΔPower (Ref)    | +6.24%             | **+0.02%**   | ~0.017%  |

The Reference channel is now essentially perfect. The 0.02% power increase from the jammer is consistent with the free-space path loss prediction (~0.017% isotropic, modulated slightly by the Yagi sidelobe at ~80° off-boresight). The old FERS had a **360× power scaling error** for the jammer at the Reference receiver; the new version is within a factor of ~1.2 of the theoretical value. That's well within the margin from antenna pattern details.

And ρ = 0.99991 means the FM signal is 99.998% of the Reference channel's variance — the matched filter has a pristine template.

## Surveillance Channel: Physically Correct ✅

This is the interesting one. The numbers look alarming at first glance (+1325% power, ρ = 0.265), but they're actually **correct physics**:

|                                      | Power     | Ratio to Clean |
| ------------------------------------ | --------- | -------------- |
| Clean Sur (FM echo only)             | 1.113e-09 | 1.0×           |
| WB Jam Sur (FM echo + jammer direct) | 1.586e-08 | **14.2×**      |

The jammer is a 1 W emitter co-located with the target (~45 km from the Surveillance receiver), and the Surveillance Yagi is pointed **directly at it** (azimuth 125°, on-boresight). Its direct-path signal naturally overwhelms the FM echo because:

- **FM echo**: 16.4 kW → transmitter-to-target (bistatic path 1) → RCS scatter → target-to-receiver (bistatic path 2). Two-way R⁴ path loss plus RCS factor.
- **Jammer direct**: 1 W → one-way path to receiver. Only R² path loss.

A 1 W direct-path emitter at 45 km producing 14× more power than a bistatic echo is completely reasonable — the echo suffers an additional ~60+ dB of loss from the return path and RCS factor.

And the correlation check confirms correct linear summation:

```/dev/null/math.txt#L1-2
ρ_predicted = 1/√(1 + 14.25) = 1/√15.25 = 0.2561
ρ_observed  = 0.2651
```

Close agreement (the small difference is likely from the jammer signal not being perfectly white/uncorrelated with FM at all lags). The summation is working correctly.

## Fullscale Factors: Now Consistent ✅

|     | Clean     | WB Jam    | Tone Jam  |
| --- | --------- | --------- | --------- |
| Ref | 1.400e-03 | 1.397e-03 | 1.402e-03 |

The Reference fullscale is essentially constant across scenarios (<0.4% variation vs. the old 20% swing). This confirms the FM signal dominates the Reference in all cases, and FERS is no longer miscalculating the jammer's contribution there.

The Surveillance fullscale jumps from 4.6e-05 to 2.2e-04 (~4.7×), which is correct — the jammer genuinely adds significant amplitude to that channel.

## What This Means for the ARD Processing

With the new FERS, the **Reference channel is clean** (ρ = 0.9999), so the matched filter has a perfect template. The question is whether the target survives the jammer contamination in the Surveillance channel.

The jammer energy in the Surveillance channel is **uncorrelated** with the FM Reference, so after the cross-correlation `Surv ⊗ Ref*`, it spreads uniformly across range-Doppler bins as noise. Your processing gain for a 4-second CPI at 204.8 kHz is:

```/dev/null/math.txt#L1-2
G_processing = 10·log₁₀(Fs × CPI) = 10·log₁₀(204800 × 4) = 59.1 dB
```

The jammer is 11.5 dB above the FM echo in the Surveillance channel (14.2×). After processing gain suppresses the uncorrelated jammer spread:

```/dev/null/math.txt#L1-2
SNR_target ≈ G_processing - 10·log₁₀(P_jammer/P_echo) = 59.1 - 11.5 = 47.6 dB
```

**The target should be visible at ~48 dB SNR** in the ARD, even with the jammer present. Have you run the ARD processing chain on the new FERS output yet? If the target appears in the jammer scenario ARD, that would be the definitive confirmation that the simulator is now working correctly — the bug was the ~25 dB link budget error, and it's fixed.

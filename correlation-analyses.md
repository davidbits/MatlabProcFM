# Correlation and Power Analyses

## Fullscale-Corrected Results (Physical Units)

Using [prove_fers_bug.m](AnalysisChain/prove_fers_bug.m) with `loadfersHDF5` to apply the FERS `fullscale` attribute
(ADC-to-physical scaling), the following results were obtained across all scenarios and both channels.

### Fullscale Attributes

| Scenario                   | Ref Fullscale | Sur Fullscale |
| -------------------------- | ------------- | ------------- |
| Clean (FM only)            | 6.450913e-05  | 4.854755e-05  |
| Wideband Jammer (FM+1W)    | 7.797916e-05  | 6.561829e-05  |
| Single-Tone Jammer (FM+1W) | 7.730110e-05  | 6.385036e-05  |

**Note:** The fullscale factor increases by ~20% in jammer runs, indicating FERS rescales the ADC dynamic range to
accommodate a larger peak amplitude when multiple transmitters are present.

### Power (Fullscale-Corrected, Complex)

Power = var(I) + var(Q) of the scaled complex signal.

| Scenario                   | Reference Power | Surveillance Power |
| -------------------------- | --------------- | ------------------ |
| Clean (FM only)            | 2.397941e-09    | 1.442379e-09       |
| Wideband Jammer (FM+1W)    | 2.547649e-09    | 1.623896e-09       |
| Single-Tone Jammer (FM+1W) | 2.548358e-09    | 1.623270e-09       |

| Scenario           | Ref ΔPower    | Sur ΔPower    | Ref % Change | Sur % Change |
| ------------------ | ------------- | ------------- | ------------ | ------------ |
| Wideband Jammer    | +1.497079e-10 | +1.815164e-10 | +6.24%       | +12.58%      |
| Single-Tone Jammer | +1.504169e-10 | +1.808907e-10 | +6.27%       | +12.54%      |

After fullscale correction, power **increases** when the jammer is added, consistent with the direction required by
superposition ($P_{total} = P_1 + P_2$). However, the magnitude of the increase is anomalous: a 1 W jammer should
produce only ~0.017% increase at the Reference receiver (37 dB below the 16.4 kW FM source). The observed +6.2%
increase is ~360× too large, independently confirming the link budget error.

### Correlation

| Comparison                  | Ref ρ (complex \|ρ\|) | Sur ρ (complex \|ρ\|) | Ref ρ (real-part) | Sur ρ (real-part) |
| --------------------------- | --------------------- | --------------------- | ----------------- | ----------------- |
| Wideband Jammer vs Clean    | 0.124077              | 0.785528              | −0.080311         | +0.408777         |
| Single-Tone Jammer vs Clean | 0.011724              | 0.020744              | −0.010548         | −0.020254         |

All Reference channel correlations are catastrophically below the expected >0.99, confirming the FM signal is
effectively absent from the Reference channel in jammer runs.

### Q-Channel Integrity (I/Q Balance)

| Signal       | P(I)         | P(Q)         | Q/I Ratio |
| ------------ | ------------ | ------------ | --------- |
| Clean Ref    | 1.198621e-09 | 1.199320e-09 | 1.000583  |
| Clean Sur    | 7.210146e-10 | 7.213646e-10 | 1.000485  |
| WB Jam Ref   | 1.273713e-09 | 1.273936e-09 | 1.000175  |
| WB Jam Sur   | 8.121379e-10 | 8.117577e-10 | 0.999532  |
| Tone Jam Ref | 1.273536e-09 | 1.274822e-09 | 1.001010  |
| Tone Jam Sur | 8.121000e-10 | 8.111700e-10 | 0.998855  |

All Q/I ratios are within 0.1% of 1.0, confirming that the I/Q channels are properly balanced in all scenarios.
The signals are fully complex; the Q=0 (real-valued signal) hypothesis is **ruled out**.

---

## Original Raw ADC Measurements (Uncorrected — Superseded)

The following measurements were taken from raw ADC integer values **without** applying the FERS `fullscale` attribute.
They are retained here for traceability. The apparent power decrease was an artifact of the differing fullscale
normalisation between clean and jammer runs (see above). The correlation values remain valid, as Pearson correlation
is invariant to linear scaling.

```
FOR REF CHANNEL (Wideband Jammer):
Power (Clean Run):  2.880312e-01  ← raw ADC variance, fullscale = 6.451e-05
Power (Jammer Run): 2.094665e-01  ← raw ADC variance, fullscale = 7.798e-05
Correlation (rho):  -0.080311     ← valid (scale-invariant)

FOR SURV CHANNEL (Wideband Jammer):
Power (Clean Run):  3.059211e-01  ← raw ADC variance, fullscale = 4.855e-05
Power (Jammer Run): 1.886166e-01  ← raw ADC variance, fullscale = 6.562e-05
Correlation (rho):  0.408777      ← valid (scale-invariant)

REF CHANNEL WITH SINGLE TONE JAMMER:
Power (Clean Run):  2.880312e-01  ← raw ADC variance, fullscale = 6.451e-05
Power (Jammer Run): 2.131277e-01  ← raw ADC variance, fullscale = 7.730e-05
Correlation (rho):  -0.010548     ← valid (scale-invariant)
```

**Why the raw power values were misleading:** FERS sets the `fullscale` attribute to the peak absolute sample value,
normalising the signal to fill the 16-bit ADC range. When a second transmitter increases the peak amplitude, FERS
increases `fullscale` (by ~20% in these runs), which compresses the same physical amplitude into smaller ADC integer
values. Comparing raw `var()` of ADC integers without multiplying by `fullscale` therefore produces a spurious power
decrease. After correction, power increases as physics requires.

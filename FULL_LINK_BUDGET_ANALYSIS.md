Here's the complete link budget analysis, working from the scenario XML parameters.

---

## 1. Geometry: Distances and Bearings at t = 0

All positions from the `.fersxml` files, in UTM metres:

| Node                    | X                     | Y            | Z (alt) |
| ----------------------- | --------------------- | ------------ | ------- |
| FM Tx (Constantiaberg)  | 258 804.41            | 6 228 720.84 | 397     |
| Ref Rx (Armasuisse)     | 287 942.01            | 6 297 267.09 | 241     |
| Sur Rx (Armasuisse)     | 287 946.01            | 6 297 267.09 | 241     |
| Target / Jammer (t = 0) | 331 995.8 / 331 995.3 | 6 291 261.10 | 10 000  |

### Slant-range distances

**FM Tx → Ref Rx:**

```/dev/null/calc.txt#L1-5
Δx = 287942.01 − 258804.41 = 29 137.60 m
Δy = 6297267.09 − 6228720.84 = 68 546.25 m
Δz = 241 − 397 = −156 m

R_FM→Ref = √(29137.6² + 68546.25² + 156²) = 74 482 m ≈ 74.5 km
```

**Target/Jammer → Ref Rx:**

```/dev/null/calc.txt#L1-5
Δx = 287942.01 − 331995.8 = −44 053.8 m
Δy = 6297267.09 − 6291261.1 = 6 006.0 m
Δz = 241 − 10000 = −9 759 m

R_Jam→Ref = √(44053.8² + 6006.0² + 9759²) = 45 520 m ≈ 45.5 km
```

**FM Tx → Target:**

```/dev/null/calc.txt#L1-5
Δx = 331995.8 − 258804.41 = 73 191.4 m
Δy = 6291261.1 − 6228720.84 = 62 540.3 m
Δz = 10000 − 397 = 9 603 m

R_FM→Tgt = √(73191.4² + 62540.3² + 9603²) = 96 751 m ≈ 96.8 km
```

**Target/Jammer → Sur Rx:**

```/dev/null/calc.txt#L1-2
R_Jam→Sur ≈ 45 520 m  (Sur Rx is 4 m from Ref Rx — negligible difference)
```

---

## 2. Bearing Angles from Receivers to Sources

### Reference Rx → FM Tx

```/dev/null/calc.txt#L1-5
east  = −29 137.6 m  (west)
north = −68 546.3 m  (south)

Azimuth = atan2(east, north) = 180° + arctan(29137.6/68546.3) = 180° + 23.0° = 203.0°
Elevation = arctan(156 / 74 482) = 0.12°
```

Ref Rx boresight: **az = 204.2°, el = 0°**
→ Offset: **Δaz = 1.2°, Δel = 0.12°** — nearly on-boresight.

### Reference Rx → Target/Jammer

```/dev/null/calc.txt#L1-5
east  = +44 053.8 m  (east)
north = −6 006.0 m   (south)

Azimuth = 180° − arctan(44053.8/6006.0) = 180° − 82.2° = 97.8°
Elevation = arctan(9759 / 44 462) = 12.4°
```

Ref Rx boresight: **az = 204.2°, el = 0°**
→ Offset: **Δaz = 106.4°, Δel = 12.4°** — massively off-boresight.

### Surveillance Rx → FM Tx

```/dev/null/calc.txt#L1-3
Azimuth to FM Tx ≈ 203.0°  (same as from Ref Rx)
Elevation ≈ 0.12°
```

Sur Rx boresight: **az = 125°, el = 10°**
→ Offset: **Δaz = 78.0°, Δel = 9.9°**

### Surveillance Rx → Target/Jammer

```/dev/null/calc.txt#L1-3
Azimuth ≈ 97.8°
Elevation ≈ 12.4°
```

Sur Rx boresight: **az = 125°, el = 10°**
→ Offset: **Δaz = 27.2°, Δel = 2.4°**

---

## 3. Antenna Gain Estimates

The Yagi antenna uses a `sinc` pattern with α = 5.2481, β = 2, γ = 3.6, peak = 7.2 dBi. I'll use the standard separable sinc model:

```/dev/null/calc.txt#L1-3
G(Δaz, Δel) = G_peak × |sinc(α·sin(Δaz))|^β × |sinc(γ·sin(Δel))|^β

where sinc(x) = sin(πx)/(πx),  G_peak = 10^(7.2/10) = 5.248
```

| Receiver   | Toward        | Δaz    | Δel   | G (linear) | G (dBi)   |
| ---------- | ------------- | ------ | ----- | ---------- | --------- |
| **Ref Rx** | FM Tx         | 1.2°   | 0.12° | 5.05       | **+7.0**  |
| **Ref Rx** | Jammer        | 106.4° | 12.4° | 2.3 × 10⁻⁵ | **−46.4** |
| **Sur Rx** | FM Tx         | 78.0°  | 9.9°  | 7.5 × 10⁻⁴ | **−31.3** |
| **Sur Rx** | Target/Jammer | 27.2°  | 2.4°  | 0.078      | **−11.1** |

The Reference Rx provides **53.4 dB of antenna discrimination** between the FM source and the jammer direction (7.0 − (−46.4) = 53.4 dB).

> **Caveat:** I don't know the exact FERS sinc model, so below I present results for both the sinc antenna and the worst-case isotropic (0 dBi everywhere) assumption.

---

## 4. Received Power Calculations

### Fundamental equations

**Direct path** (Friis):

```/dev/null/calc.txt#L1-1
P_r = P_t · G_t · G_r · (λ / 4πR)²
```

**Reflected path** (Bistatic radar equation):

```/dev/null/calc.txt#L1-1
P_r = (P_t · G_t · G_r · σ · λ²) / ((4π)³ · R_t² · R_r²)
```

Common values: **λ = c/f = 299 792 458 / 89 × 10⁶ = 3.3684 m**, σ = 200 m².

---

### 4a. Signals at the Reference Rx

#### FM Direct → Ref Rx

```/dev/null/calc.txt#L1-9
P_t = 16 400 W,  G_t = 1 (isotropic Tx),  R = 74 482 m

(λ/4πR)² = (3.3684 / (4π × 74482))² = (3.594 × 10⁻⁶)² = 1.292 × 10⁻¹¹

With sinc Yagi (G_r = 5.05):
  P_FM_direct_ref = 16400 × 1 × 5.05 × 1.292e−11 = 1.070 × 10⁻⁶ W

With isotropic Rx (G_r = 1):
  P_FM_direct_ref = 16400 × 1 × 1 × 1.292e−11 = 2.119 × 10⁻⁷ W
```

#### Jammer Direct → Ref Rx

```/dev/null/calc.txt#L1-9
P_t = 1 W,  G_t = 1 (isotropic Tx),  R = 45 520 m

(λ/4πR)² = (3.3684 / (4π × 45520))² = (5.884 × 10⁻⁶)² = 3.462 × 10⁻¹¹

With sinc Yagi (G_r = 2.30 × 10⁻⁵):
  P_Jam_direct_ref = 1 × 1 × 2.30e−5 × 3.462e−11 = 7.95 × 10⁻¹⁶ W

With isotropic Rx (G_r = 1):
  P_Jam_direct_ref = 1 × 1 × 1 × 3.462e−11 = 3.462 × 10⁻¹¹ W
```

#### FM Echo (via target) → Ref Rx

```/dev/null/calc.txt#L1-7
R_t = 96 751 m (FM→Target),  R_r = 45 520 m (Target→Ref),  σ = 200 m²
G_r toward target = 2.30 × 10⁻⁵ (same direction as jammer)

(4π)³ = 1984.4

P_echo_ref = (16400 × 1 × 2.30e−5 × 200 × 3.3684²) / (1984.4 × 96751² × 45520²)
           = 0.0521 / (3.85 × 10²²) = 1.35 × 10⁻²⁴ W   [negligible]
```

#### Summary at Reference Rx

| Signal        | Sinc Yagi (W)    | Isotropic Rx (W) |
| ------------- | ---------------- | ---------------- |
| **FM direct** | **1.070 × 10⁻⁶** | **2.119 × 10⁻⁷** |
| Jammer direct | 7.95 × 10⁻¹⁶     | 3.462 × 10⁻¹¹    |
| FM echo       | ~10⁻²⁴           | ~10⁻²⁰           |

**Jammer-to-FM ratio at Ref Rx:**

```/dev/null/calc.txt#L1-2
With sinc Yagi:  7.95e−16 / 1.070e−6  = 7.4 × 10⁻¹⁰  →  −91.3 dB
With isotropic:  3.462e−11 / 2.119e−7 = 1.63 × 10⁻⁴  →  −37.9 dB
```

---

### 4b. Signals at the Surveillance Rx

#### FM Direct → Sur Rx

```/dev/null/calc.txt#L1-5
G_r toward FM Tx = 7.5 × 10⁻⁴

P_FM_direct_sur = 16400 × 1 × 7.5e−4 × 1.292e−11 = 1.589 × 10⁻¹⁰ W

Isotropic: 2.119 × 10⁻⁷ W  (same as Ref, antennas are co-located)
```

#### Jammer Direct → Sur Rx

```/dev/null/calc.txt#L1-5
G_r toward jammer = 0.078

P_Jam_direct_sur = 1 × 1 × 0.078 × 3.462e−11 = 2.686 × 10⁻¹² W

Isotropic: 3.462 × 10⁻¹¹ W
```

#### FM Echo (via target) → Sur Rx

```/dev/null/calc.txt#L1-4
G_r toward target = 0.078

P_echo_sur = (16400 × 1 × 0.078 × 200 × 11.346) / (1984.4 × 96751² × 45520²)
           = 2905 / (3.85 × 10²²) = 7.5 × 10⁻²⁰ W   [very weak]
```

#### Summary at Surveillance Rx

| Signal              | Sinc Yagi (W)     | Isotropic Rx (W) |
| ------------------- | ----------------- | ---------------- |
| **FM direct (DSI)** | **1.589 × 10⁻¹⁰** | **2.119 × 10⁻⁷** |
| Jammer direct       | 2.686 × 10⁻¹²     | 3.462 × 10⁻¹¹    |
| FM echo (target)    | 7.5 × 10⁻²⁰       | ~10⁻¹⁷           |

**Jammer-to-FM ratio at Sur Rx:**

```/dev/null/calc.txt#L1-2
With sinc Yagi:  2.686e−12 / 1.589e−10 = 0.0169  →  −17.7 dB
With isotropic:  3.462e−11 / 2.119e−7  = 1.63e−4 →  −37.9 dB
```

---

## 5. Expected vs Observed Power Increase

The expected fractional power increase when the jammer is added:

```/dev/null/calc.txt#L1-1
ΔP/P_clean = P_jammer / P_FM  (since FM and jammer are uncorrelated)
```

| Channel          | Sinc Antenna               | Isotropic            | **FERS Observed** |
| ---------------- | -------------------------- | -------------------- | ----------------- |
| **Reference**    | 7.4 × 10⁻¹⁰ (0.000000074%) | 1.63 × 10⁻⁴ (0.016%) | **6.2%**          |
| **Surveillance** | 0.0169 (1.7%)              | 1.63 × 10⁻⁴ (0.016%) | **12.6%**         |

The Reference Rx discrepancy is staggering:

```/dev/null/calc.txt#L1-3
With sinc antenna: FERS over-reports jammer contribution by factor ~83 million (79 dB)
With isotropic Rx: FERS over-reports jammer contribution by factor ~380 (26 dB)
Even the most conservative isotropic bound cannot explain the observed 6.2%.
```

---

## 6. Link Budget Decomposition

```/dev/null/calc.txt#L1-13
                                           FM Tx          Jammer         Difference
                                           -----          ------         ----------
Transmit power:                         +42.1 dBW        0 dBW          +42.1 dB  (FM advantage)
Free-space path loss to Ref Rx:
  (λ/4πR)²  @74.5 km:                  −108.9 dB
  (λ/4πR)²  @45.5 km:                                  −104.6 dB       −4.3 dB   (Jammer closer)

Tx antenna gain (both isotropic):          0 dBi          0 dBi           0 dB

Rx antenna gain (sinc Yagi):
  On-boresight (→FM):                    +7.0 dBi
  106° off-boresight (→Jammer):                         −46.4 dBi      +53.4 dB  (FM advantage)
                                                                        ─────────
Net FM advantage at Ref Rx:                                              91.2 dB
Net FM advantage (isotropic Rx):                                         37.8 dB
```

---

## 7. Verdict

The claim is **correct**, and the math confirms it emphatically:

- **With the directional Yagi:** The FM signal is **91 dB** (1.3 billion ×) stronger than the jammer at the Reference Rx. A 1 W jammer at 45.5 km, arriving 106° off the Yagi's boresight, is utterly invisible next to a 16.4 kW FM transmitter arriving on-boresight.

- **Even with isotropic receivers** (worst case — ignoring all antenna discrimination): The FM signal is still **38 dB** (6 000 ×) stronger. The expected power increase from adding the jammer is 0.016%, yet FERS produces **6.2%** — a factor of **380× too much** in the most generous interpretation.

- The **correlation result** (ρ ≈ 0.01–0.12) is consistent with the FM signal being almost entirely absent and the jammer dominating the Reference output. For ρ = 0.124, only about **1.5% of the signal variance** is shared with the FM waveform (ρ² ≈ 0.015). This is physically impossible when the FM source should account for >99.98% of the received power.

The three independent measurements — power ratio, correlation coefficient, and analytic link budget — all converge on the same conclusion: FERS is not correctly summing the two transmitter contributions at the Reference receiver. The jammer appears approximately **26–79 dB stronger** than it should be (depending on whether FERS implements the antenna pattern or not), which is consistent with the jammer signal replacing or overwhelming the FM signal in the output buffer.

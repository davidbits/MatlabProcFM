# Full Link Budget Analysis V3

Complete link budget analysis for the `JamSingleTarget.fersxml` scenario, calculating the
expected received signal power at each receiver for the jammer signal, FM direct signal, and
reflected FM signal. Antenna gain calculations use the exact FERS sinc antenna model as
implemented in the simulator source code.

---

## 1. Scenario Overview

### Nodes and Positions (UTM coordinates, metres)

| Node                         | X          | Y            | Altitude (m) | Role                        |
| ---------------------------- | ---------- | ------------ | ------------- | --------------------------- |
| **Constantiaberg FM Tx**     | 258 804.41 | 6 228 720.84 | 397           | FM transmitter (continuous) |
| **Armasuisse Ref Rx**        | 287 942.01 | 6 297 267.09 | 241           | Reference receiver          |
| **Armasuisse Sur Rx**        | 287 946.01 | 6 297 267.09 | 241           | Surveillance receiver       |
| **Target** (t = 0)           | 331 995.77 | 6 291 261.10 | 10 000        | Bistatic target (σ = 200 m²)|
| **Jammer** (t = 0)           | 331 995.27 | 6 291 261.10 | 10 000        | Co-located with target      |

### Transmitter Parameters

| Transmitter    | Power (W) | Power (dBW) | Carrier (MHz) | Tx Antenna    |
| -------------- | --------- | ----------- | ------------- | ------------- |
| FM Tx          | 16 400    | +42.15      | 89            | Isotropic     |
| Jammer Tx      | 1         | 0           | 89            | Isotropic     |

### Receiver Antenna Parameters

Both receivers use the same `sinc` pattern antenna (`RxYagiAntenna`):

| Parameter   | Value   | Meaning                          |
| ----------- | ------- | -------------------------------- |
| `alpha` (α) | 5.2481  | Peak gain (linear) ≈ 7.2 dBi    |
| `beta` (β)  | 2       | Beamwidth parameter              |
| `gamma` (γ) | 3.6     | Sidelobe roll-off exponent       |
| efficiency  | 1.0     | No ohmic losses                  |

### Receiver Boresight Directions

| Receiver   | Azimuth (°) | Elevation (°) | Points toward                    |
| ---------- | ----------- | ------------- | -------------------------------- |
| **Ref Rx** | 204.2       | 0.0           | FM Tx (Constantiaberg)           |
| **Sur Rx** | 125.0       | 10.0          | Middle of target flight path     |

### Derived Constants

```/dev/null/calc.txt#L1-3
Wavelength:  λ = c / f = 299 792 458 / 89 000 000 = 3.3684 m
λ²          = 11.346 m²
(4π)³       = 1984.4
```

---

## 2. Geometry

### 2.1 Slant-Range Distances

**FM Tx → Ref Rx:**

```/dev/null/calc.txt#L1-5
Δx = 287 942.01 − 258 804.41 = 29 137.60 m
Δy = 6 297 267.09 − 6 228 720.84 = 68 546.25 m
Δz = 241 − 397 = −156 m

R_FM→Ref = √(29137.60² + 68546.25² + 156²) = 74 483 m ≈ 74.5 km
```

**FM Tx → Sur Rx:**

```/dev/null/calc.txt#L1-2
Δx = 29 141.60 m  (4 m more than to Ref Rx — negligible difference)

R_FM→Sur = 74 484 m ≈ 74.5 km
```

**Target → Ref Rx:**

```/dev/null/calc.txt#L1-5
Δx = 287 942.01 − 331 995.77 = −44 053.76 m
Δy = 6 297 267.09 − 6 291 261.10 = 6 005.99 m
Δz = 241 − 10 000 = −9 759 m

R_Tgt→Ref = √(44053.76² + 6005.99² + 9759²) = 45 519 m ≈ 45.5 km
```

**Jammer → Ref Rx:**

```/dev/null/calc.txt#L1-2
Jammer is 0.5 m from target — negligible difference at 45.5 km.

R_Jam→Ref ≈ 45 519 m
```

**Target → Sur Rx:**

```/dev/null/calc.txt#L1-4
Δx = 287 946.01 − 331 995.77 = −44 049.76 m
(remaining components identical to Ref Rx case within 4 m)

R_Tgt→Sur = 45 516 m ≈ 45.5 km
```

**FM Tx → Target:**

```/dev/null/calc.txt#L1-5
Δx = 331 995.77 − 258 804.41 = 73 191.36 m
Δy = 6 291 261.10 − 6 228 720.84 = 62 540.26 m
Δz = 10 000 − 397 = 9 603 m

R_FM→Tgt = √(73191.36² + 62540.26² + 9603²) = 96 751 m ≈ 96.8 km
```

### Distance Summary

| Path                | Distance (m) | Distance (km) |
| ------------------- | ------------ | -------------- |
| FM Tx → Ref Rx      | 74 483       | 74.5           |
| FM Tx → Sur Rx      | 74 484       | 74.5           |
| Jammer → Ref Rx     | 45 519       | 45.5           |
| Jammer → Sur Rx     | 45 516       | 45.5           |
| FM Tx → Target      | 96 751       | 96.8           |
| Target → Ref Rx     | 45 519       | 45.5           |
| Target → Sur Rx     | 45 516       | 45.5           |

### 2.2 Azimuth and Elevation from Receivers to Sources

Using the standard navigation convention: azimuth from North (positive Y-axis), clockwise; elevation positive upward from horizontal.

**From Ref Rx to FM Tx:**

```/dev/null/calc.txt#L1-5
east  = −29 137.60 m  (west)
north = −68 546.25 m  (south)

Azimuth = 180° + arctan(29137.60 / 68546.25) = 180° + 23.04° = 203.04°
Elevation = arctan(156 / 74 481) = 0.12°
```

**From Ref Rx to Target/Jammer:**

```/dev/null/calc.txt#L1-5
east  = +44 053.76 m  (east)
north = −6 005.99 m   (south)

Azimuth = 180° − arctan(44053.76 / 6005.99) = 180° − 82.24° = 97.76°
Elevation = arctan(9759 / 44 459) = 12.38°
```

**From Sur Rx to FM Tx:**

```/dev/null/calc.txt#L1-3
Effectively identical to Ref Rx (4 m separation):
Azimuth = 203.05°,  Elevation = 0.12°
```

**From Sur Rx to Target/Jammer:**

```/dev/null/calc.txt#L1-3
Effectively identical to Ref Rx:
Azimuth = 97.77°,  Elevation = 12.38°
```

---

## 3. FERS Sinc Antenna Gain Model

### 3.1 Source Code Implementation

The sinc antenna gain in FERS is computed as follows (shown from the current codebase,
`antenna_factory.cpp`; the legacy codebase `rsantenna.cpp` produces identical results):

```/dev/null/fers_sinc.cpp#L1-19
// Helper sinc function (UNNORMALIZED: sin(x)/x, NOT sin(πx)/(πx))
RealType sinc(const RealType theta) noexcept
{
    if (std::abs(theta) < EPSILON) { return 1.0; }
    return std::sin(theta) / theta;
}

// Sinc antenna gain computation
RealType Sinc::getGain(const SVec3& angle, const SVec3& refangle,
                       RealType /*wavelength*/) const noexcept
{
    // Single conical angle off boresight (radians), computed via
    // 3D dot product of unit direction vectors:
    const RealType theta = getAngle(angle, refangle);

    const RealType sinc_val = sinc(_beta * theta);
    const RealType gain_pattern = std::pow(std::abs(sinc_val), _gamma);
    return _alpha * gain_pattern * getEfficiencyFactor();
}
```

### 3.2 Mathematical Formula

The antenna gain is a function of a **single scalar angle off boresight** θ (not separable azimuth/elevation):

```/dev/null/calc.txt#L1-3
G(θ) = α × | sin(β·θ) / (β·θ) |^γ × η

where θ = arccos( v̂_source · v̂_boresight )  [radians]
```

The sinc function here is the **unnormalized** sinc: sin(x)/x (not sin(πx)/(πx)).

With the scenario parameters α = 5.2481, β = 2, γ = 3.6, η = 1.0:

```/dev/null/calc.txt#L1-3
G(θ) = 5.2481 × | sin(2θ) / (2θ) |^3.6

Peak gain at θ = 0:  G(0) = 5.2481 = 10^(7.2/10) → 7.2 dBi  ✓
```

### 3.3 Key Design Feature — Single Conical Angle

The FERS sinc antenna computes the angle off boresight θ as the **3D angle between two unit
direction vectors** via:

```/dev/null/calc.txt#L1-4
θ = arccos( v̂_source · v̂_boresight )

where v̂ = ( cos(el)·sin(az),  cos(el)·cos(az),  sin(el) )
```

This is a **rotationally symmetric pattern** around the boresight axis — the gain depends
only on the total angular displacement from boresight, not separately on azimuth and
elevation offsets.

---

## 4. Antenna Gain Calculations

### 4.1 Angle Off Boresight (θ)

For each receiver–source pair, the boresight and source direction are converted to unit
Cartesian vectors, and θ is obtained from their dot product.

**Ref Rx → FM Tx:**

```/dev/null/calc.txt#L1-12
Boresight: az = 204.20°, el = 0.00°
  v̂_bore = (sin(204.20°), cos(204.20°), 0)
         = (−0.41004, −0.91213, 0)

Source:    az = 203.04°, el = 0.12°
  v̂_src  = (cos(0.12°)·sin(203.04°), cos(0.12°)·cos(203.04°), sin(0.12°))
         = (−0.39122, −0.92028, 0.00209)

dot = (−0.41004)(−0.39122) + (−0.91213)(−0.92028) + 0
    = 0.16044 + 0.83942 = 0.99986

θ = arccos(0.99986) = 0.01675 rad  →  but let me be more precise...
```

Let me compute this precisely:

```/dev/null/calc.txt#L1-14
sin(204.20°) = −sin(24.20°) = −0.41015
cos(204.20°) = −cos(24.20°) = −0.91199
sin(203.04°) = −sin(23.04°) = −0.39122
cos(203.04°) = −cos(23.04°) = −0.92028
cos(0.12°)   = 0.999998
sin(0.12°)   = 0.002094

v̂_bore = (−0.41015, −0.91199, 0)
v̂_src  = (−0.39122, −0.92026, 0.002094)

dot = 0.16044 + 0.83929 = 0.99973

θ = arccos(0.99973) = 0.02324 rad = 1.33°
```

**Ref Rx → Target/Jammer:**

```/dev/null/calc.txt#L1-14
Source: az = 97.76°, el = 12.38°

sin(97.76°)  = cos(7.76°)  = 0.99086
cos(97.76°)  = −sin(7.76°) = −0.13502
cos(12.38°)  = 0.97684
sin(12.38°)  = 0.21438

v̂_jam = (0.97684 × 0.99086, 0.97684 × (−0.13502), 0.21438)
       = (0.96791, −0.13189, 0.21438)

v̂_bore = (−0.41015, −0.91199, 0)

dot = (−0.41015)(0.96791) + (−0.91199)(−0.13189) + 0
    = −0.39689 + 0.12031 = −0.27658

θ = arccos(−0.27658) = 1.8510 rad = 106.1°
```

**Sur Rx → FM Tx:**

```/dev/null/calc.txt#L1-14
Boresight: az = 125.00°, el = 10.00°

sin(125°) = 0.81915,  cos(125°) = −0.57358
cos(10°)  = 0.98481,  sin(10°)  = 0.17365

v̂_bore = (0.98481 × 0.81915, 0.98481 × (−0.57358), 0.17365)
        = (0.80672, −0.56487, 0.17365)

v̂_fm = (−0.39122, −0.92026, 0.002094)   [same as above]

dot = (0.80672)(−0.39122) + (−0.56487)(−0.92026) + (0.17365)(0.002094)
    = −0.31560 + 0.51977 + 0.00036 = 0.20453

θ = arccos(0.20453) = 1.3649 rad = 78.2°
```

**Sur Rx → Target/Jammer:**

```/dev/null/calc.txt#L1-10
v̂_bore = (0.80672, −0.56487, 0.17365)   [Sur Rx boresight]
v̂_jam  = (0.96791, −0.13189, 0.21438)   [same direction as from Ref Rx]

dot = (0.80672)(0.96791) + (−0.56487)(−0.13189) + (0.17365)(0.21438)
    = 0.78068 + 0.07451 + 0.03723 = 0.89242

θ = arccos(0.89242) = 0.4676 rad = 26.8°
```

### 4.2 Antenna Gain Values

Using G(θ) = 5.2481 × |sin(2θ) / (2θ)|^3.6:

**Ref Rx → FM Tx (θ = 0.02324 rad):**

```/dev/null/calc.txt#L1-5
argument = 2 × 0.02324 = 0.04648
sin(0.04648) / 0.04648 = 0.99964
|0.99964|^3.6 = 0.99870

G = 5.2481 × 0.99870 = 5.241   →   7.19 dBi
```

**Ref Rx → Target/Jammer (θ = 1.8510 rad):**

```/dev/null/calc.txt#L1-8
argument = 2 × 1.8510 = 3.7020

3.7020 − π = 0.5604 rad
sin(3.7020) = −sin(0.5604) = −0.5310

sin(3.7020) / 3.7020 = −0.5310 / 3.7020 = −0.14344
|−0.14344|^3.6 = 0.14344^3.6 = 9.218 × 10⁻⁴

G = 5.2481 × 9.218 × 10⁻⁴ = 0.004837   →   −23.2 dBi
```

**Sur Rx → FM Tx (θ = 1.3649 rad):**

```/dev/null/calc.txt#L1-8
argument = 2 × 1.3649 = 2.7298

π − 2.7298 = 0.4118 rad
sin(2.7298) = sin(0.4118) = 0.4003

sin(2.7298) / 2.7298 = 0.4003 / 2.7298 = 0.14665
|0.14665|^3.6 = 9.961 × 10⁻⁴

G = 5.2481 × 9.961 × 10⁻⁴ = 0.005227   →   −22.8 dBi
```

**Sur Rx → Target/Jammer (θ = 0.4676 rad):**

```/dev/null/calc.txt#L1-6
argument = 2 × 0.4676 = 0.9352

sin(0.9352) / 0.9352 = 0.8041 / 0.9352 = 0.8598
|0.8598|^3.6 = 0.5834

G = 5.2481 × 0.5834 = 3.062   →   +4.86 dBi
```

### 4.3 Antenna Gain Summary

| Receiver   | Toward          | θ (rad) | θ (deg) | G (linear) | G (dBi)   |
| ---------- | --------------- | ------- | ------- | ---------- | --------- |
| **Ref Rx** | FM Tx           | 0.0232  | 1.3     | 5.241      | **+7.19** |
| **Ref Rx** | Target / Jammer | 1.851   | 106.1   | 0.004837   | **−23.2** |
| **Sur Rx** | FM Tx           | 1.365   | 78.2    | 0.005227   | **−22.8** |
| **Sur Rx** | Target / Jammer | 0.468   | 26.8    | 3.062      | **+4.86** |

The Reference Rx provides **30.4 dB of antenna discrimination** between the FM Tx direction
and the Jammer direction (+7.19 − (−23.2) = 30.4 dB).

The Surveillance Rx provides **27.7 dB of antenna discrimination** favouring the
Target/Jammer direction over the FM Tx direction (+4.86 − (−22.8) = 27.7 dB).

---

## 5. Free-Space Path Loss

**FSPL = (λ / 4πR)²**

| Path              | R (m)  | (λ/4πR)²       | FSPL (dB)  |
| ----------------- | ------ | --------------- | ---------- |
| FM Tx → Ref Rx    | 74 483 | 1.295 × 10⁻¹¹  | −108.88    |
| FM Tx → Sur Rx    | 74 484 | 1.295 × 10⁻¹¹  | −108.88    |
| Jammer → Ref Rx   | 45 519 | 3.466 × 10⁻¹¹  | −104.60    |
| Jammer → Sur Rx   | 45 516 | 3.466 × 10⁻¹¹  | −104.60    |

```/dev/null/calc.txt#L1-5
Example calculation for FM Tx → Ref Rx:
  4π × 74483 = 936 139
  λ / (4πR) = 3.3684 / 936139 = 3.598 × 10⁻⁶
  (λ/4πR)² = 1.295 × 10⁻¹¹
  10 × log₁₀(1.295 × 10⁻¹¹) = −108.88 dB
```

---

## 6. Received Power Calculations

### Fundamental Equations

**Direct path** (Friis transmission equation):

```/dev/null/calc.txt#L1-1
P_r = P_t · G_t · G_r · (λ / 4πR)²
```

**Reflected path** (Bistatic radar equation):

```/dev/null/calc.txt#L1-1
P_r = (P_t · G_t · G_r · σ · λ²) / ((4π)³ · R_tx² · R_rx²)
```

where R_tx = FM Tx → Target distance, R_rx = Target → Rx distance, σ = 200 m² (isotropic RCS).

---

### 6a. Signals at the Reference Rx

#### FM Direct → Ref Rx

```/dev/null/calc.txt#L1-8
P_t = 16 400 W,  G_t = 1  (isotropic Tx)
G_r = 5.241  (Ref Rx toward FM Tx, 7.19 dBi)
R = 74 483 m  →  (λ/4πR)² = 1.295 × 10⁻¹¹

P_FM_direct_ref = 16 400 × 1 × 5.241 × 1.295 × 10⁻¹¹
                = 85 952 × 1.295 × 10⁻¹¹
                = 1.113 × 10⁻⁶ W

                = −59.5 dBW
```

#### Jammer Direct → Ref Rx

```/dev/null/calc.txt#L1-8
P_t = 1 W,  G_t = 1  (isotropic Tx)
G_r = 0.004837  (Ref Rx toward Jammer, −23.2 dBi)
R = 45 519 m  →  (λ/4πR)² = 3.466 × 10⁻¹¹

P_Jam_direct_ref = 1 × 1 × 0.004837 × 3.466 × 10⁻¹¹
                 = 1.676 × 10⁻¹³ W

                 = −127.8 dBW
```

#### FM Echo (via Target) → Ref Rx

```/dev/null/calc.txt#L1-15
P_t = 16 400 W,  G_t = 1,  σ = 200 m²
G_r = 0.004837  (Ref Rx toward Target, same direction as Jammer)
R_tx = 96 751 m  (FM Tx → Target)
R_rx = 45 519 m  (Target → Ref Rx)

Numerator:
  16 400 × 1 × 0.004837 × 200 × 11.346 = 179 850

Denominator:
  (4π)³ × R_tx² × R_rx²
  = 1984.4 × (96 751)² × (45 519)²
  = 1984.4 × 9.361 × 10⁹ × 2.072 × 10⁹
  = 3.849 × 10²²

P_echo_ref = 179 850 / 3.849 × 10²² = 4.67 × 10⁻¹⁸ W

             = −173.3 dBW    [negligible]
```

#### Reference Rx Summary

| Signal              | Power (W)          | Power (dBW) |
| ------------------- | ------------------ | ----------- |
| **FM direct**       | **1.113 × 10⁻⁶**  | **−59.5**   |
| **Jammer direct**   | **1.676 × 10⁻¹³** | **−127.8**  |
| **FM echo (target)**| **4.67 × 10⁻¹⁸**  | **−173.3**  |

**Jammer-to-FM ratio at Reference Rx:**

```/dev/null/calc.txt#L1-3
1.676 × 10⁻¹³  /  1.113 × 10⁻⁶  =  1.506 × 10⁻⁷

→  −68.2 dB     (FM signal is 68 dB stronger than the jammer)
```

---

### 6b. Signals at the Surveillance Rx

#### FM Direct → Sur Rx

```/dev/null/calc.txt#L1-8
P_t = 16 400 W,  G_t = 1  (isotropic Tx)
G_r = 0.005227  (Sur Rx toward FM Tx, −22.8 dBi)
R = 74 484 m  →  (λ/4πR)² = 1.295 × 10⁻¹¹

P_FM_direct_sur = 16 400 × 1 × 0.005227 × 1.295 × 10⁻¹¹
                = 85.72 × 1.295 × 10⁻¹¹
                = 1.110 × 10⁻⁹ W

                = −89.5 dBW
```

#### Jammer Direct → Sur Rx

```/dev/null/calc.txt#L1-8
P_t = 1 W,  G_t = 1  (isotropic Tx)
G_r = 3.062  (Sur Rx toward Jammer, +4.86 dBi)
R = 45 516 m  →  (λ/4πR)² = 3.466 × 10⁻¹¹

P_Jam_direct_sur = 1 × 1 × 3.062 × 3.466 × 10⁻¹¹
                 = 1.061 × 10⁻¹⁰ W

                 = −99.7 dBW
```

#### FM Echo (via Target) → Sur Rx

```/dev/null/calc.txt#L1-15
P_t = 16 400 W,  G_t = 1,  σ = 200 m²
G_r = 3.062  (Sur Rx toward Target, same direction as Jammer)
R_tx = 96 751 m  (FM Tx → Target)
R_rx = 45 516 m  (Target → Sur Rx)

Numerator:
  16 400 × 1 × 3.062 × 200 × 11.346 = 1.140 × 10⁸

Denominator:
  1984.4 × (96 751)² × (45 516)²
  = 1984.4 × 9.361 × 10⁹ × 2.072 × 10⁹
  = 3.849 × 10²²

P_echo_sur = 1.140 × 10⁸ / 3.849 × 10²² = 2.96 × 10⁻¹⁵ W

             = −145.3 dBW
```

#### Surveillance Rx Summary

| Signal              | Power (W)          | Power (dBW) |
| ------------------- | ------------------ | ----------- |
| **FM direct (DSI)** | **1.110 × 10⁻⁹**  | **−89.5**   |
| **Jammer direct**   | **1.061 × 10⁻¹⁰** | **−99.7**   |
| **FM echo (target)**| **2.96 × 10⁻¹⁵**  | **−145.3**  |

**Jammer-to-FM ratio at Surveillance Rx:**

```/dev/null/calc.txt#L1-3
1.061 × 10⁻¹⁰  /  1.110 × 10⁻⁹  =  0.0956

→  −10.2 dB     (FM signal is ~10 dB stronger than the jammer)
```

---

## 7. Link Budget Decomposition

### 7.1 Reference Rx — FM vs Jammer

```/dev/null/calc.txt#L1-17
                                    FM Tx           Jammer          Difference
                                    -----           ------          ----------
Transmit power:                   +42.15 dBW       0 dBW           +42.15 dB (FM advantage)

Free-space path loss (λ/4πR)²:
  @ 74.5 km (FM):                −108.88 dB
  @ 45.5 km (Jammer):                            −104.60 dB        −4.28 dB (Jammer closer)

Tx antenna gain (both iso):         0 dBi           0 dBi            0 dB

Rx antenna gain (sinc Yagi):
  θ = 1.33° (→ FM):               +7.19 dBi
  θ = 106.1° (→ Jammer):                          −23.15 dBi      +30.34 dB (FM advantage)
                                                                    ─────────
Net FM advantage at Ref Rx:                                         68.2 dB
```

### 7.2 Surveillance Rx — FM vs Jammer

```/dev/null/calc.txt#L1-17
                                    FM Tx           Jammer          Difference
                                    -----           ------          ----------
Transmit power:                   +42.15 dBW       0 dBW           +42.15 dB (FM advantage)

Free-space path loss (λ/4πR)²:
  @ 74.5 km (FM):                −108.88 dB
  @ 45.5 km (Jammer):                            −104.60 dB        −4.28 dB (Jammer closer)

Tx antenna gain (both iso):         0 dBi           0 dBi            0 dB

Rx antenna gain (sinc Yagi):
  θ = 78.2° (→ FM):              −22.82 dBi
  θ = 26.8° (→ Jammer):                            +4.86 dBi     −27.68 dB (Jammer advantage)
                                                                    ─────────
Net FM advantage at Sur Rx:                                         10.2 dB
```

---

## 8. Complete Signal-Level Summary

### All Six Signal Powers

| Signal                     | Ref Rx (dBW) | Ref Rx (W)          | Sur Rx (dBW) | Sur Rx (W)          |
| -------------------------- | ------------ | ------------------- | ------------ | ------------------- |
| **FM direct**              | **−59.5**    | **1.113 × 10⁻⁶**   | **−89.5**    | **1.110 × 10⁻⁹**   |
| **Jammer direct**          | **−127.8**   | **1.676 × 10⁻¹³**  | **−99.7**    | **1.061 × 10⁻¹⁰**  |
| **FM echo (via target)**   | **−173.3**   | **4.67 × 10⁻¹⁸**   | **−145.3**   | **2.96 × 10⁻¹⁵**   |

### Signal Ratios

| Ratio                         | Reference Rx | Surveillance Rx |
| ----------------------------- | ------------ | --------------- |
| FM direct / Jammer direct     | +68.2 dB     | +10.2 dB        |
| FM direct / FM echo           | +113.8 dB    | +55.8 dB        |
| Jammer direct / FM echo       | +45.5 dB     | +45.6 dB        |

### Fractional Power Contribution of Jammer

Since the FM and jammer signals are uncorrelated, total power is additive:

```/dev/null/calc.txt#L1-8
P_jammer / P_FM = jammer-to-signal ratio

Reference Rx:
  P_jam / P_FM = 1.506 × 10⁻⁷  →  0.0000151%  of the FM power

Surveillance Rx:
  P_jam / P_FM = 0.0956  →  9.56%  of the FM power
```

---

## 9. Physical Interpretation

**Reference Rx:** The antenna is pointed directly at the FM transmitter (1.3° off
boresight → 7.2 dBi gain). The jammer arrives from 106° off boresight, deep in the
sidelobe region at −23.2 dBi. Combined with the FM transmitter's 42 dB power advantage,
the jammer signal is **68 dB below** the FM direct signal. The jammer is completely
negligible on the reference channel — it contributes only 0.000015% additional power.

**Surveillance Rx:** The antenna points roughly toward the target area (26.8° off
boresight → +4.9 dBi toward Jammer), while the FM transmitter is far off boresight
(78.2° → −22.8 dBi). The 42 dB FM transmit power advantage is substantially eroded by
the 27.7 dB of antenna discrimination favouring the jammer direction, plus the 4.3 dB
shorter path to the jammer. The net result is the FM signal only **10 dB above** the
jammer, with the jammer contributing nearly 10% of the total received power.

**FM Echo:** The reflected signal from the target (σ = 200 m²) is negligibly weak in both
channels. At the Surveillance Rx it arrives at −145.3 dBW, which is 45.6 dB below the
jammer and 55.8 dB below the FM direct signal. At the Reference Rx it is weaker still at
−173.3 dBW. The bistatic path loss over the 96.8 km + 45.5 km two-way propagation path
overwhelms the large FM transmit power and target RCS.

---

## Appendix A: Detailed Sinc Gain Curve

For reference, the FERS sinc antenna gain G(θ) = 5.2481 × |sin(2θ)/(2θ)|^3.6 at selected
angles off boresight:

| θ (deg) | θ (rad) | sin(2θ)/(2θ) | G (linear) | G (dBi) |
| ------- | ------- | ------------- | ---------- | -------- |
| 0       | 0       | 1.000         | 5.248      | +7.20    |
| 1       | 0.0175  | 0.9998        | 5.244      | +7.20    |
| 5       | 0.0873  | 0.9949        | 5.153      | +7.12    |
| 10      | 0.1745  | 0.9797        | 4.876      | +6.88    |
| 20      | 0.3491  | 0.9194        | 3.864      | +5.87    |
| 30      | 0.5236  | 0.8270        | 2.676      | +4.27    |
| 45      | 0.7854  | 0.6496        | 1.098      | +0.41    |
| 60      | 1.0472  | 0.4546        | 0.303      | −5.19    |
| 75      | 1.3090  | 0.2728        | 0.058      | −12.4    |
| 90      | 1.5708  | 0.1273        | 0.00462    | −23.4    |
| 106     | 1.8500  | 0.1436        | 0.00486    | −23.1    |
| 120     | 2.0944  | 0.2081        | 0.0257     | −15.9    |
| 135     | 2.3562  | 0.1667        | 0.0109     | −19.6    |
| 150     | 2.6180  | 0.0620        | 0.000303   | −35.2    |
| 180     | 3.1416  | 0.0000        | 0.000      | −∞       |

Note: The sinc pattern has sidelobes, so the gain is not monotonically decreasing. At
θ ≈ 106°, the gain is approximately the same magnitude as at θ ≈ 90° — both sit in the
deep sidelobe region around −23 dBi.

---

## Appendix B: Verification — Power Balance Cross-Check

Independent verification via dB arithmetic:

```/dev/null/calc.txt#L1-18
FM Direct → Ref Rx:
  +42.15 (Pt) + 0 (Gt) + 7.19 (Gr) − 108.88 (FSPL)  =  −59.54 dBW  ✓

Jammer Direct → Ref Rx:
  +0 (Pt)     + 0 (Gt) − 23.15 (Gr) − 104.60 (FSPL)  =  −127.75 dBW ✓

FM Direct → Sur Rx:
  +42.15 (Pt) + 0 (Gt) − 22.82 (Gr) − 108.88 (FSPL)  =  −89.55 dBW  ✓

Jammer Direct → Sur Rx:
  +0 (Pt)     + 0 (Gt) + 4.86 (Gr)  − 104.60 (FSPL)  =  −99.74 dBW  ✓

FM Echo → Ref Rx:
  +42.15 (Pt) + 0 (Gt) − 23.15 (Gr) + 23.01 (σ dBsm) + 10.55 (λ² dB)
  − 32.98 ((4π)³ dB) − 99.71 (R_tx² dB) − 93.17 (R_rx² dB)
  = −173.30 dBW  ✓

FM Echo → Sur Rx:
  +42.15 (Pt) + 0 (Gt) + 4.86 (Gr) + 23.01 (σ dBsm) + 10.55 (λ² dB)
  − 32.98 ((4π)³ dB) − 99.71 (R_tx² dB) − 93.16 (R_rx² dB)
  = −145.28 dBW  ✓
```

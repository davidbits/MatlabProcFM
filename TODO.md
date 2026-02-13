I realized that I made a mistake with my DSI suppression tracking methods. I wasn't measuring true DSI suppression, instead I was measuring total power reduction. Below are my updated DSI suppression metrics:

---

IN OLD FERS using CleanSingleTarget_no_rand Scenario:
Mean Total Power Reduction: 69.06 dB (Std: 8.51 dB)
Mean DSI Projection Suppression: 120.99 dB (Std: 14.61 dB)
Mean Correlation Drop: 25.86 dB (Std: 4.01 dB)
Rho Pre: 1.0000, Rho Post: 0.0041

IN NEW FERS using CleanSingleTarget_fers_latest (no rand) Scenario:
Mean Total Power Reduction: 49.56 dB (Std: 3.41 dB)
Mean DSI Projection Suppression: 113.66 dB (Std: 12.47 dB)
Mean Correlation Drop: 32.05 dB (Std: 5.46 dB)
Rho Pre: 1.0000, Rho Post: 0.0022

---

AND:

- I did another test using a stationary jammer on the NEW FERS simulation data and can say the following:

### JamSingleTarget_fers_latest_stationary_jam

#### Notes:

- Using the new fers commit.
- The target was moving but the jammer was stationary at the starting point of the target.
- Jammer power was set to 1 W.
- No random_freq_offset and no noise_temp.

#### Results:

- Higher and more noise than JamSingleTarget_stationary_jam all throughout the plots
- Basically identical to JamSingleTarget_fers_latest (i.e., the latest fers commit with no randomness and a moving jammer)

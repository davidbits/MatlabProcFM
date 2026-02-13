# Multi-transmitter **linearity / superposition** in the actual Malmesbury waveform regime

You did superposition checks (and even have a dedicated `prove_fers_bug.m` style approach), but the most bulletproof multi-Tx check is this **A/B/C decomposition** at the *sample level*:

- **A:** FM-only run (Tx on, jammer off)
- **B:** Jammer-only run (Tx off, jammer on)
- **C:** FM+jammer run (both on)

Then validate (after scaling) that:

- `C ≈ A + B` in complex IQ (per channel, per CPI)
- residual `C - (A+B)` is near numerical/quantization noise floor

Why it matters: many multi-emitter bugs are not about kinematics—they’re about **incorrect mixing, normalisation, ADC quantisation application per-source vs post-sum, clipping/saturation applied per-source**, or incorrect handling of “fullscale”.

You’ve done pieces of this (power/correlation checks), but I’d still call this a “gap” unless you’ve explicitly done this *with the exact Malmesbury FM waveform inputs and the same export settings* and checked the residual error distribution.

**Minimal pass criteria**
- `‖C-(A+B)‖ / ‖C‖` is tiny (e.g., <1e-6 to 1e-4 depending on pipeline quantisation)
- residual is spectrally white-ish / not structured in delay/Doppler

---

# “Moving transmitter” kinematics corner cases: **Doppler correctness** isolated from processing

Your Malmesbury chain is passive-style (surv × conj(ref) CAF), and you’ve now shown motion doesn’t cause qualitative failure. But there’s still one meaningful gap:

### Validate Doppler sign/magnitude for a moving transmitter in a **coherent** setting
In Malmesbury you intentionally use an **incoherent FM-noise jammer** (as demanded by prior claims). Incoherent signals hide Doppler bugs because you won’t see a clean line.

So if you want to rule out a *pure kinematics Doppler bug* in moving transmitters:

- Use a jammer waveform that **is coherent and narrowband** (CW tone or single complex sinusoid) on the moving platform.
- Process with a pipeline that will show a **Doppler line** from that transmitter at the receivers (not matched to FM).
- Compare expected Doppler from geometry vs observed.

This doesn’t contradict your earlier conclusion (that the Malmesbury failure is physical). It just closes the loop on “is FERS solving Doppler correctly for moving emitters at all?”

This is exactly the style of test in your separate ideal bistatic pulsed radar verification report—except you’d focus on the **jammer direct path** Doppler line rather than radar echoes.

---

# Cross-channel consistency: ref/sur export alignment and metadata

A subtle but real “multi-transmitter bug” class is **channel export misalignment**:
- reference and surveillance files start at different timestamps
- one has an extra initial block
- dataset chunk ordering differs when multi-source enabled

Your combine script truncates to min length, which hides some issues. A gap to close:

- Explicitly verify **time alignment** between ref and surv exports (e.g., using a strong deterministic feature: direct FM, or a calibration tone).
- Check that enabling jammer does **not** change the effective start sample/time for one channel relative to the other.

If a misalignment existed only when a second transmitter is enabled, it would absolutely appear like “post-processing corruption” while raw IQ still “looks fine.”

---

# What I would do next (minimal set)

If you want the shortest path to “no important gaps remain”:

1. **A/B/C linearity test** on the Malmesbury inputs (`FM-only`, `Jam-only`, `Both`) and verify `Both ≈ sum`.
2. **Ref/sur time alignment check**: confirm enabling jammer doesn’t shift timestamps/sample indices.
3. **Coherent moving-transmitter Doppler sanity test** with a CW tone emitter (separate from FM passive chain).

If these pass, then within the scope of “moving transmitter bug / multi-transmitter bug,” you’ve essentially exhaustively ruled out the plausible remaining failure modes.

If you want, I can also suggest concrete numeric checks (norms, tolerances, plots) that fit cleanly into your existing `MatlabProcServ.m` metric output workflow—without changing the main processing.


# Post-Mortem Analysis: FERS Radar Signal Processing Pipeline Repair

## Executive Summary
A critical failure was identified in the radar signal processing pipeline where the final Ambiguity Range-Doppler (ARD) plots exhibited severe signal loss, "striped" noise artifacts, and a lack of target detection. Through a systematic isolation process, the root cause was identified as a data loading error within the `loadfersHDF5.m` script. The script incorrectly indexed HDF5 attributes, reading a timestamp value of `0.0` instead of the `fullscale` normalization factor, effectively zeroing out the simulation data.

Following the implementation of a robust, name-based attribute lookup, the pipeline now produces ARD plots that match the "Known Good" reference, exhibiting high-SNR targets, correct range/Doppler positioning, and effective clutter suppression.

---

## 1. Problem Definition
The objective was to recreate a "Known Good" ARD plot (`CleanSingleTarget.ard`) using raw source recordings and the FERS simulation chain.

### Symptoms
The initial output (`Output/16.ard`) presented the following anomalies:
*   **Visuals:** A "Blue/Cyan" heatmap dominated by noise with vertical and horizontal striping textures.
*   **Signal Power:** Extremely low intensity (-40 dB range).
*   **Target:** No distinct point target was visible.
*   **Artifacts:** A bright horizontal smear at 0 Hz Doppler (Direct Path) that was not correctly cancelled or compressed.

### Initial Hypotheses
1.  **Spectral Inversion:** The Reference channel might have been conjugated (I/Q swapped), causing the Matched Filter to fail.
2.  **Simulation Failure:** The FERS engine might have failed to generate valid physics data due to incorrect XML parameters (e.g., ADC bits, power).
3.  **Data Corruption:** The signal was being lost or corrupted during the conversion from FERS HDF5 format to the internal RCF format.

---

## 2. Investigation & Isolation Process

### Phase 1: Input Verification (`makeTxData.m`)
The first step was to ensure the input waveform fed into the simulation was valid. A verification script (`verify_makeTxData.m`) was created to compare the generated `txWaveFormNormalised.h5` against the raw source `Malmesbury_1.rcf`.

*   **Tests Performed:** Bit-for-bit comparison, Power Spectral Density analysis, and I/Q power balance checks.
*   **Result:** **PASS**. The input file was bit-perfect, correctly normalized (Power=1.0), and spectrally correct.
*   **Conclusion:** The error was not in the source data or the input generation script.

### Phase 2: Intermediate Data Analysis (`combineRxData.m`)
The next step analyzed the `ArmasuisseClean.rcf` file, which serves as the bridge between the simulation output and the MATLAB processing server. A comparison script (`CompareSourceToGenerated.m`) checked the correlation between the Source waveform and the Receiver waveform.

*   **Tests Performed:** Cross-correlation, RMS power comparison, and I/Q swap detection.
*   **Result:** **FAIL**.
    *   **Power:** The generated RCF power was $\approx 10^{-9}$ (effectively zero).
    *   **Correlation:** The correlation coefficient with the source was $\approx 0$ (uncorrelated noise).
*   **Conclusion:** The signal was being destroyed *after* the simulation but *before* the final processing.

### Phase 3: FERS Output Deep Inspection
To determine if the simulation itself was at fault, a script (`inspect_fers_outputs.m`) was written to bypass the MATLAB loaders and inspect the raw FERS output files (`ArmasuisseRefRxClean.h5`) directly using low-level HDF5 tools.

*   **Tests Performed:** Raw I/Q power measurement, attribute inspection, and cross-correlation with the Transmit waveform.
*   **Result:** **PASS**.
    *   **Correlation:** 0.9973 (Near-perfect physics simulation).
    *   **Power:** ~0.3 (High signal strength).
    *   **Delay:** Observed a ~50-sample delay consistent with the 74km baseline.
*   **Crucial Finding:** The inspection script noted that the HDF5 attributes could not be accessed reliably via dot-indexing, hinting that the attribute structure was not what the loader expected.

---

## 3. Root Cause Analysis

The failure was isolated to **`AnalysisChain/ARDMakers/loadfersHDF5.m`**.

### The Bug
The original script attempted to read the normalization factor (`fullscale`) using a hardcoded index:
```matlab
scale = hinfo.GroupHierarchy.Datasets(1).Attributes(3).Value;
```

### The Mechanism of Failure
1.  **Non-Deterministic Ordering:** MATLAB's `hdf5info` does not guarantee the order in which attributes are returned.
2.  **The Mismatch:** In this specific environment, the attribute at index 3 was **`time`**, not `fullscale`.
3.  **The Zero Factor:** For the first chunk of data, the simulation time is `0.0`.
4.  **The Calculation:** The loader performed the operation: $Data_{loaded} = Data_{raw} \times 0.0$.
5.  **The Consequence:** The resulting RCF file contained valid complex data multiplied by zero (resulting in floating-point underflow/noise). The ARD processor's Matched Filter then attempted to correlate noise with noise, producing the "striped" artifacts characteristic of filter failure.

---

## 4. The Solution

The `loadfersHDF5.m` script was rewritten to implement **Robust Attribute Loading**.

Instead of relying on a fixed index (e.g., `Attributes(3)`), the new logic iterates through the attribute list and performs a case-insensitive string comparison to find the attribute named `'fullscale'`. If found, it uses that value; otherwise, it defaults to `1.0` and issues a warning.

This ensures that regardless of how the HDF5 library sorts the metadata, the correct scaling factor is always applied.

---

## 5. Final Validation

After applying the fix and re-running the full chain (`combineRxData` $\rightarrow$ `MatlabProcServ`), the output `Output/16.ard` was analyzed:

*   **Target Detection:** A high-intensity signal is now clearly visible at **+85 Hz Doppler** and **120 km Range** ($1.2 \times 10^5$ m). This matches the "Known Good" target exactly.
*   **Signal Power:** The target intensity approaches **0 dB**, indicating excellent Pulse Compression gain.
*   **Noise Floor:** The background is stable at **-25 to -30 dB**, providing a healthy Signal-to-Noise Ratio (SNR).
*   **Clutter:** High-energy returns are correctly localized to 0 Hz Doppler at short ranges (Direct Path interference), which is physically correct.

The pipeline is now fully functional and verified.
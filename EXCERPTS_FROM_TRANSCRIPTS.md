Based on all the provided documents, here is a comprehensive summary of every reference to the "moving transmitter bug," also referred to as the "Malmesbury scenario bug" or "stationary jammer bug."

---

### **Meeting Summary - 26th May, 2025**

- **Initial Mention:** A potential, long-standing issue was raised concerning an error in the Doppler frequency algorithm, specifically within the `solveRE` method. It was noted that under certain circumstances, the simulation produced incorrect outputs. This was flagged as a low-priority item to investigate later in the project.

### **Meeting Summary - 31st July, 2025**

- **Bug Clarification:** The issue was described as a major limitation of FERS. The simulation breaks down when a transmitter moves independently of the receiver. A key example scenario is a jamming platform, where a target carries its own moving transmitter. This was identified as a "major issue" that needs to be resolved.

### **Meeting Summary - 28th August, 2025**

- **Replication and Severity:** The bug was discussed in greater detail. A simple method to trigger it is to simulate a moving, low-power noise source.
  - **Effect:** The simulation output becomes completely corrupted, showing only noise. No targets or reflections are visible in the processed data.
  - **Severity:** The problem was highlighted as being so significant that it had previously led to the retraction of a submitted academic paper.
  - **Test Case:** The "Malmesbury" scenario was proposed as the basis for a test case, which would involve adding a transmitter to the moving target.

### **Meeting Summary - 11th September, 2025**

- **Initial Testing Failure:** An attempt to replicate the bug using simple, ideal scenarios failed, with the results matching theoretical calculations.
- **Key Insight:** It was clarified that the bug is subtle and **not visible in the raw ADC data**. It only manifests after the data has been run through a post-processing chain.
- **Refined Test Conditions:** The specific failing scenario was defined as a stationary radar observing a target that is simultaneously transmitting (i.e., jamming). A crucial instruction was given to ensure the moving transmitter emits **non-coherent noise**, not a simple rectangular pulse, as this is essential for triggering the bug.

### **Meeting Summary - 6th November, 2025**

- **Official Test Files:** It was confirmed that the specific simulation file (`.fersxml`) and the corresponding large, real-world waveform file known to reliably trigger the bug had been located. These files were to be provided for definitive testing.

### **Meeting Summary - 20th November, 2025**

- **File Availability:** The test files were confirmed to be available on the network-attached storage (NAS). The specific scenario is named `jam_single_target.fersxml`, which is a modified version of the Malmesbury scenario.

### **Meeting Summary - 4th December, 2025**

- **Processing Roadblock:** Testing began on the provided files. The bug was linked to previous work by "Craig Tom" and the withdrawn paper. A major roadblock was identified: the original post-processing relied on a specific, legacy `CudaProcServer` and MATLAB toolchain that were not available. Attempts to reconstruct the processing chain from other available scripts failed to produce meaningful results.
- **Action Item:** The compiled files for the `CudaProcServer` and the complete MATLAB processing suite were to be provided to enable a proper analysis.

### **Meeting Summary - 28th January, 2026**

- **Bug Successfully Reproduced:** After receiving the necessary files, the MATLAB processing chain was successfully configured. Using this chain, the moving transmitter bug was **officially reproduced and confirmed to exist**.
  - **Visual Confirmation:** The processed range-Doppler map shows the target completely obscured by a high noise floor, matching the previously described failure mode.
- **Root Cause Investigation:** A preliminary investigation into the cause was conducted.
  - **Hypothesis:** The bug appears to be caused by the jammer's signal overpowering the reference receiver, even though the receiver's antenna is not pointed at the jammer. This is suspected to be the result of a previously identified and fixed bug related to incorrect angle calculations (a mix-up between radians and degrees) in the antenna model. The fix for that issue seems to have inadvertently resolved this bug as well.
- **Proposed Validation Test:** A definitive test was proposed to confirm the fix and the nature of the bug:
  1.  Run the simulation with the jammer moving along with the target.
  2.  Run the same simulation but with the jammer being stationary.
  - **Expected Outcome:** The results of both simulations should be nearly identical. The noise floor should be elevated due to the jammer, but the target should be visible in both cases. The Doppler shift of noise should not statistically alter the noise profile. This test will serve as the final validation that the issue is resolved.

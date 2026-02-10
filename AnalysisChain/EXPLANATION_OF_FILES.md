### Files:

-   `MatlabProcServ.m`:
    -   **Purpose:** This is the main executable script that orchestrates the entire passive radar processing chain.
    -   **Details:**
        -   It begins by adding the necessary subdirectories (`ARDMakers`, `Cancellation`, `Classes`) to the MATLAB path.
        -   It defines key processing parameters, such as input file type, Coherent Processing Interval (CPI) duration, cancellation settings (range, Doppler, iterations), and ARD map settings (range, Doppler).
        -   It contains logic to read input data from either HDF5 or RCF files based on the `hdf5_input` flag.
        -   The core of the script is a loop that processes the input data one CPI at a time.
        -   Inside the loop, it optionally calls a cancellation function (`CGLS_Cancellation`) to remove clutter and then calls an ARD generation function (`FX_ARD`) to create the range-Doppler map.
        -   Finally, it saves the resulting ARD map for each CPI to a unique `.ard` file in the `Output` directory.

-   `IQProc.m`:
    -   **Purpose:** Contains a function `ProcLat` that implements the CGLS (Conjugate Gradient Least Squares) cancellation algorithm.
    -   **Details:**
        -   The code structure and comments are nearly identical to `CGLS_Cancellation.m`, suggesting it is either a developmental version, a backup, or an alternative implementation.
        -   It is designed to take raw IQ data (reference and surveillance) and apply a filter to cancel out the direct signal and clutter.
        -   Unlike `CGLS_Cancellation.m`, this function appears to be designed for non-RCF object data, with hardcoded values and commented-out sections for handling different data structures. It is not called by the main `MatlabProcServ.m` script.

-   `ReadARDs.m`:
    -   **Purpose:** A utility script for reading and visualizing a single Amplitude-Range-Doppler (`.ard`) file.
    -   **Details:**
        -   It uses the `cARD` class to read the data from the specified `.ard` file.
        -   It generates a 2D plot of the range-Doppler map and has an option (`plot_all`) to also generate a 3D surface plot.

-   `Cancellation/CGLS_Cancellation.m`:
    -   **Purpose:** A core function that implements the Conjugate Gradient Least Squares (CGLS) algorithm for clutter and direct signal cancellation.
    -   **Details:**
        -   It is an iterative method to solve for the filter that best models the clutter in the surveillance channel based on the reference channel.
        -   The data is processed in smaller `nSegments` to manage memory usage.
        -   It constructs a matrix `A` of delayed and Doppler-shifted versions of the reference signal and solves the system `Ax = b`, where `b` is the surveillance signal.
        -   The final cancelled signal is calculated as `b - Ax`. It returns the modified RCF object and the computed filter weights (`alpha`).

-   `Cancellation/CGLS_Cancellation.m~`:
    -   **Purpose:** This is a backup file, typically created automatically by a text editor (like Emacs or Vi).
    -   **Details:** Its content is identical to `CGLS_Cancellation.m`. It serves no functional purpose in the project.

-   `Cancellation/ECA_Cancellation.m`:
    -   **Purpose:** Implements the Extensive Cancellation Algorithm (ECA), an alternative to CGLS for clutter cancellation.
    -   **Details:**
        -   Like CGLS, it processes data in segments and builds the same `A` matrix of reference signal replicas.
        -   It differs from CGLS by using a direct least-squares solution (`alpha = (A'*A)\A'*b`) instead of an iterative one. This can be faster but potentially less stable or more memory-intensive depending on the matrix properties.

-   `ARDMakers/blackmanWindow.m`:
    -   **Purpose:** A utility function to generate a Blackman-Harris window.
    -   **Details:** This is used in signal processing before performing a Fast Fourier Transform (FFT) to reduce spectral leakage.

-   `ARDMakers/Batches_ARD.m`:
    -   **Purpose:** Implements a range-Doppler processing algorithm using a batch-based method.
    -   **Details:**
        -   It divides the CPI into many small, overlapping batches.
        -   It performs a frequency-domain cross-correlation for each batch to determine range.
        -   It then performs an FFT across the batches for each range bin to determine Doppler shift.

-   `ARDMakers/FX_ARD.m`:
    -   **Purpose:** Implements the "FX" range-Doppler processing algorithm.
    -   **Details:**
        -   The name implies a process of **F**FT first, then **X**-correlation.
        -   It performs an FFT on the entire reference and surveillance signals. It then iterates through each Doppler shift, performing the cross-correlation in the frequency domain for that specific shift before transforming back with an IFFT.

-   `ARDMakers/hanningWindow.m`:
    -   **Purpose:** A utility function to generate a Hanning (or Hann) window.
    -   **Details:** Like the Blackman window, this is used to reduce spectral leakage during FFT operations.

-   `ARDMakers/XF_ARD.m`:
    -   **Purpose:** Implements the "XF" range-Doppler processing algorithm.
    -   **Details:**
        -   The name implies a process of **X**-correlation first, then **F**FT.
        -   It iterates through each possible range delay, performing a time-domain cross-correlation product for that delay.
        -   It then performs an FFT on the resulting time-series product to extract the Doppler information for that specific range bin.

-   `Classes/benchmarkRead.m`:
    -   **Purpose:** A script to benchmark the performance of reading RCF files.
    -   **Details:** It compares the execution time of the fast C++ MEX function (`readRCFFromFile`) against the native MATLAB implementation in the `cRCF.m` class, demonstrating the speed advantage of the MEX approach.

-   `Classes/cRCF.m`:
    -   **Purpose:** The MATLAB class definition for an RCF object.
    -   **Details:**
        -   It encapsulates all the header metadata (timestamp, sample rate, etc.) and the complex IQ data for both the reference and surveillance channels.
        -   Provides methods for reading from and writing to `.rcf` files, including a pure MATLAB implementation and an interface to the faster MEX functions.
        -   This class is the primary data container for the raw and cancelled data as it moves through the processing chain.

-   `Classes/ComparePowers.m`:
    -   **Purpose:** A utility script to load two different RCF files and compare their power spectra.
    -   **Details:** It calculates the FFT of the reference and surveillance channels for both files and plots them on a normalized dB scale for visual comparison.

-   `Classes/cARDCell.m`:
    -   **Purpose:** A MATLAB class to represent a single detection or "cell" within an ARD map.
    -   **Details:** It stores specific information for a point of interest, such as its range/Doppler bin index, its calculated bistatic range and velocity, and its signal strength in dB.

-   `Classes/cARD.m`:
    -   **Purpose:** The MATLAB class definition for an ARD (Amplitude-Range-Doppler) object.
    -   **Details:**
        -   This class represents the final output of the processing chain.
        -   It stores the 2D data matrix of the range-Doppler map, along with all necessary metadata (timestamp, resolutions, etc.).
        -   It includes methods for reading/writing the custom `.ard` file format and for creating 2D and 3D visualizations of the map.

-   `Classes/cARDCellSelection.m`:
    -   **Purpose:** A MATLAB class to manage a collection of `cARDCell` objects.
    -   **Details:**
        -   This is likely used to store the results of a target detection algorithm (like CFAR) that has been run on an ARD map.
        -   It holds a vector of `cARDCell` objects and includes methods to plot these detections as a scatter plot on a range-velocity graph.

import h5py
import numpy as np

def generate_single_tone(filename, sample_rate=204800, duration=180.0, offset_hz=1000.0):
    """
    Generates a constant single-tone (CW) complex baseband signal.

    Parameters:
    filename: Output HDF5 file path
    sample_rate: Should match simulation rate (204800)
    duration: Length of the signal in seconds (180)
    offset_hz: The frequency of the tone relative to the carrier (0 = DC)
    """
    num_samples = int(sample_rate * duration)
    t = np.arange(num_samples) / sample_rate

    # Generate complex exponential: exp(j * 2 * pi * f * t)
    # This creates a tone with a constant power (variance) of 1.0
    i_data = np.cos(2 * np.pi * offset_hz * t).astype(np.float64)
    q_data = np.sin(2 * np.pi * offset_hz * t).astype(np.float64)

    with h5py.File(filename, 'w') as f:
        # Using the path string automatically creates the groups 'I' and 'Q'
        f.create_dataset("I/value", data=i_data)
        f.create_dataset("Q/value", data=q_data)

    print(f"Successfully generated single-tone jammer:")
    print(f"  File: {filename}")
    print(f"  Samples: {num_samples}")
    print(f"  Offset: {offset_hz} Hz")
    print(f"  Power (Variance): {np.var(i_data + 1j*q_data):.2f}")

if __name__ == "__main__":
    generate_single_tone(
        filename="Waveforms/tone_jammer.h5",
        sample_rate=204800,
        duration=180.0,
        offset_hz=1000.0
    )
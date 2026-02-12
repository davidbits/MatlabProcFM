I have now done some further analyses to refine the results. Please add an addendum to the previous discussion and analysis you provided above which discusses and analyzes the following results.

ALSO NOTE:

- On the point `Re-examine the scenario that led to the paper retraction`, all of the scenarios I have been testing on is the scenario that led to paper retraction.

---

On The 1 mW detection threshold:
I was mistaken, the target is detectable (with difficulty) in both the new FERS and old FERS outputs after post-processing.

At a jammer power of 100 µW, the target is very easily identifiable in the plots.

---

DSI suppression achieved by the CGLS cancellation:

IN OLD FERS:
Mean DSI Suppression: 69.06 dB
Std Dev: 8.51 dB

IN NEW FERS:
Mean DSI Suppression: 49.56 dB
Std Dev: 3.41 dB

---

File Path,Q-channel Power,I-channel Power
Input/CleanSingleTarget/ArmasuisseRefRxClean.h5,1.198481e-09,1.199460e-09
Input/CleanSingleTarget/ArmasuisseSurRxClean.h5,7.214349e-10,7.209441e-10
Input/CleanSingleTarget_fers_latest/ArmasuisseRefRx_results.h5,5.568759e-07,5.567605e-07
Input/CleanSingleTarget_fers_latest/ArmasuisseSurRx_results.h5,5.567612e-10,5.565390e-10
Input/CleanSingleTarget_no_rand/ArmasuisseRefRxClean.h5,1.198796e-09,1.199143e-09
Input/CleanSingleTarget_no_rand/ArmasuisseSurRxClean.h5,7.210245e-10,7.213533e-10
Input/JamSingleTarget/ArmasuisseRefRxJam.h5,1.273936e-09,1.273713e-09
Input/JamSingleTarget/ArmasuisseSurRxJam.h5,8.117577e-10,8.121379e-10
Input/JamSingleTarget_fers_latest/ArmasuisseRefRx_results.h5,5.569810e-07,5.568729e-07
Input/JamSingleTarget_fers_latest/ArmasuisseSurRx_results.h5,7.934464e-09,7.927977e-09
Input/JamSingleTarget_no_rand/ArmasuisseRefRxJam.h5,1.273814e-09,1.273836e-09
Input/JamSingleTarget_no_rand/ArmasuisseSurRxJam.h5,8.117384e-10,8.121556e-10
Input/JamSingleTarget_fers_latest_proper_colocation/ArmasuisseRefRx_results.h5,5.568776e-07,5.567635e-07
Input/JamSingleTarget_fers_latest_proper_colocation/ArmasuisseSurRx_results.h5,6.734603e-10,6.731544e-10
Input/JamSingleTarget_proper_colocation/ArmasuisseRefRx.h5,1.253613e-09,1.253729e-09
Input/JamSingleTarget_proper_colocation/ArmasuisseSurRx.h5,8.026201e-10,8.030559e-10

---

RAW_LINK_LOGS UPDATES:

# NEW FERS w/ NO JAMMER ECHO

## WITH JAMMER:

Direct path ConstantiabergTx->ArmasuisseRefRx: Tx=72.15 dBm, FSPL=108.88 dB, Gt=0.00 dB, Gr=7.20 dB, Pr=-29.53 dBm
Echo path ConstantiabergTx->Target1->ArmasuisseRefRx: Tx=72.15 dBm, FSPL=215.75 dB, Gt=0.00 dB, Gr=-23.15 dB, Pr=-143.30 dBm, RCS=200.00 m^2, r_tx=96749.56 m, r_rx=45519.71 m
Direct path ConstantiabergTx->ArmasuisseSurRx: Tx=72.15 dBm, FSPL=108.88 dB, Gt=0.00 dB, Gr=-22.81 dB, Pr=-59.53 dBm
Echo path ConstantiabergTx->Target1->ArmasuisseSurRx: Tx=72.15 dBm, FSPL=215.75 dB, Gt=0.00 dB, Gr=4.85 dB, Pr=-115.30 dBm, RCS=200.00 m^2, r_tx=96749.56 m, r_rx=45515.84 m
Direct path JammerTx->ArmasuisseRefRx: Tx=30.00 dBm, FSPL=104.60 dB, Gt=0.00 dB, Gr=-23.15 dB, Pr=-97.75 dBm
Direct path JammerTx->ArmasuisseSurRx: Tx=30.00 dBm, FSPL=104.60 dB, Gt=0.00 dB, Gr=4.85 dB, Pr=-69.75 dBm

# OLD FERS w/ NO JAMMER ECHO

## WITH JAMMER (NB: RxPower is explicitly zeroed for no echo):

Echo path JammerTx -> ArmasuisseRefRx via Target1: TxPower=1.000000e+00 W, FSPL_leg1=5.41 dB, FSPL_leg2=104.60 dB, TotalFSPL=110.01 dB, TxGain=1.000000e+00, RxGain=6.970860e-04, RCS=2.000000e+02 m^2, Rt=5.000000e-01 m, Rr=4.551971e+04 m, RxPower=0.000000e+00 W
Echo path ConstantiabergTx -> ArmasuisseRefRx via Target1: TxPower=1.640000e+04 W, FSPL_leg1=111.15 dB, FSPL_leg2=104.60 dB, TotalFSPL=215.75 dB, TxGain=1.000000e+00, RxGain=6.970860e-04, RCS=2.000000e+02 m^2, Rt=9.674956e+04 m, Rr=4.551971e+04 m, RxPower=6.740546e-19 W
Echo path JammerTx -> ArmasuisseSurRx via Target1: TxPower=1.000000e+00 W, FSPL_leg1=5.41 dB, FSPL_leg2=104.60 dB, TotalFSPL=110.01 dB, TxGain=1.000000e+00, RxGain=1.176368e-02, RCS=2.000000e+02 m^2, Rt=5.000000e-01 m, Rr=4.551584e+04 m, RxPower=0.000000e+00 W
Echo path ConstantiabergTx -> ArmasuisseSurRx via Target1: TxPower=1.640000e+04 W, FSPL_leg1=111.15 dB, FSPL_leg2=104.60 dB, TotalFSPL=215.75 dB, TxGain=1.000000e+00, RxGain=1.176368e-02, RCS=2.000000e+02 m^2, Rt=9.674956e+04 m, Rr=4.551584e+04 m, RxPower=1.137695e-17 W
Direct path JammerTx -> ArmasuisseSurRx: TxPower=1.000000e+00 W, FSPL=104.60 dB, TxGain=1.000000e+00, RxGain=2.103207e+00, RxPower=7.294705e-11 W
Direct path JammerTx -> ArmasuisseRefRx: TxPower=1.000000e+00 W, FSPL=104.60 dB, TxGain=1.000000e+00, RxGain=4.496700e+00, RxPower=1.559358e-10 W
Direct path ConstantiabergTx -> ArmasuisseSurRx: TxPower=1.640000e+04 W, FSPL=108.88 dB, TxGain=1.000000e+00, RxGain=6.790729e-03, RxPower=1.442373e-09 W
Direct path ConstantiabergTx -> ArmasuisseRefRx: TxPower=1.640000e+04 W, FSPL=108.88 dB, TxGain=1.000000e+00, RxGain=1.128904e-02, RxPower=2.397930e-09 W

---

ALL_TESTS_PERFORMED UPDATES

### JamSingleTarget_proper_colocation

#### Notes:

- Identical to JamSingleTarget_no_rand, but the underlying simulation code was modified to ensure that the jammer does not echo off the target (i.e. only the direct path from jammer to receivers are simulated).

#### Results:

- Identical result to JamSingleTarget_no_rand

### JamSingleTarget_fers_latest_proper_colocation

#### Notes:

- Identical to JamSingleTarget_fers_latest, but the underlying simulation code was modified to ensure that the jammer does not echo off the target (i.e. only the direct path from jammer to receivers are simulated).

#### Results:

- Identical result to JamSingleTarget_fers_latest

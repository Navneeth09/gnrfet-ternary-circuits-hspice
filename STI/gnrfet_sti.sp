******************************************************
* GNRFET Standard Ternary Inverter (STI)
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Fig. 6a — 6 transistors
*
* STI Truth Table:
*   IN = 0 (0.0V)  -> OUT = 0.9V  (Logic 2)
*   IN = 1 (0.45V) -> OUT = 0.45V (Logic 1)
*   IN = 2 (0.9V)  -> OUT = 0.0V  (Logic 0)
*
* SUBCIRCUIT PORT ORDER (FROM gnrfet.lib):
*   .subckt gnrfetnmos  ns  ng  nd  nb  ...
*   .subckt gnrfetpmos  ns  ng  nd  nb  ...
*   ORDER IS: SOURCE  GATE  DRAIN  BODY
*
* TRANSISTOR ASSIGNMENT (from paper Fig. 6a):
*   T1: NMOS n=12, Vth=+0.23V  — source=n1,   gate=IN, drain=GND,  body=GND
*   T2: NMOS n=9,  Vth=+0.30V  — DIODE (gate tied to source=OUT), source=OUT, drain=n1, body=GND
*   T3: NMOS n=6,  Vth=+0.43V  — source=OUT,  gate=IN, drain=GND,  body=GND
*   T4: PMOS n=9,  Vth=-0.30V  — DIODE (gate tied to source=OUT), source=OUT, drain=p1, body=VDD
*   T5: PMOS n=12, Vth=-0.23V  — source=VDD,  gate=IN, drain=p1,   body=VDD
*   T6: PMOS n=6,  Vth=-0.43V  — source=VDD,  gate=IN, drain=OUT,  body=VDD
*
* Circuit topology:
*   VDD --- [T6:PMOS n=6] --- OUT
*   VDD --- [T5:PMOS n=12] --- p1 --- [T4:PMOS n=9 diode] --- OUT
*   OUT --- [T2:NMOS n=9 diode] --- n1 --- [T1:NMOS n=12] --- GND
*   OUT --- [T3:NMOS n=6] --- GND
*
* Expected Results (Table 6, paper):
*   Tp   = 21.03 ps average
*   Pavg = 2.76 uW
******************************************************

.options POST
.options AUTOSTOP
.options INGOLD=2     DCON=1
.options GSHUNT=1e-12 RMIN=1e-15
.options ABSTOL=1e-5  ABSVDC=1e-4
.options RELTOL=1e-2  RELVDC=1e-2
.options NUMDGT=4     PIVOT=13
.param   TEMP=27

* Library files must be in same folder as this .sp file
.lib 'gnrfet.lib' GNRFET

VVdd  Vdd  Gnd  DC  0.9

*------------------------------------------------------
* NMOS Pull-Down Network
*------------------------------------------------------

* T1: NMOS n=12, Vth=+0.23V
* Turns ON when IN > 0.23V (Logic 1 and Logic 2)
* ns=n1, ng=in, nd=Gnd, nb=Gnd
X1  Gnd  in   n1   Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: NMOS n=9, Vth=+0.30V, DIODE-CONNECTED
* Gate tied to DRAIN (=OUT). Correct diode connection.
* ns=n1, ng=out, nd=out, nb=Gnd
X2  n1   out  out  Gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3: NMOS n=6, Vth=+0.43V
* Only turns ON when IN > 0.43V (Logic 2 only), direct pull to GND
* ns=Gnd, ng=in, nd=out, nb=Gnd
X3  Gnd  in   out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

*------------------------------------------------------
* PMOS Pull-Up Network
*------------------------------------------------------

* T4: PMOS n=9, Vth=-0.30V, DIODE-CONNECTED
* Gate tied to DRAIN (=OUT). Correct diode connection.
* ns=p1, ng=out, nd=out, nb=Vdd
X4  p1   out  out  Vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5: PMOS n=12, Vth=-0.23V
* Turns ON when IN < 0.67V (Logic 0 and Logic 1), feeds p1 node
* ns=Vdd, ng=in, nd=p1, nb=Vdd
X5  Vdd  in   p1   Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6: PMOS n=6, Vth=-0.43V
* Only turns ON when IN < 0.47V (Logic 0 only), direct pull to VDD
* ns=Vdd, ng=in, nd=out, nb=Vdd
X6  Vdd  in   out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* Load capacitor (output load)
CL  out  Gnd  3.0fF

*------------------------------------------------------
* Input Signal (PWL) — covers all 6 transitions from Table 6
* 0->1, 1->2, 2->1, 1->0, 0->2, 2->0
* Ramp time = 10ps (0.01ns), each level held 0.49ns
*------------------------------------------------------
Vin  in  Gnd  PWL(
+ 0.0n   0.0
+ 0.5n   0.0
+ 0.51n  0.45
+ 1.0n   0.45
+ 1.01n  0.9
+ 1.5n   0.9
+ 1.51n  0.45
+ 2.0n   0.45
+ 2.01n  0.0
+ 2.5n   0.0
+ 2.51n  0.9
+ 3.0n   0.9
+ 3.01n  0.0
+ 3.5n   0.0
+ )

.tran  1p  3.5n

*------------------------------------------------------
* Propagation Delay Measurements
*
* STI has 3-level output so thresholds are NOT always 0.45V:
*   Transition 0->1 (output falls 2->1): TRIG at 50% of 0->0.45 = 0.225V
*                                         TARG at 50% of 0.9->0.45 = 0.675V (falling)
*   Transition 1->2 (output falls 1->0): TRIG at 50% of 0.45->0.9 = 0.675V
*                                         TARG at 50% of 0.45->0 = 0.225V (falling)
*   Transition 2->1 (output rises 0->1): TRIG at 50% of 0.9->0.45 = 0.675V (fall)
*                                         TARG at 50% of 0->0.45 = 0.225V (rising)
*   Transition 1->0 (output rises 1->2): TRIG at 50% of 0.45->0 = 0.225V (fall)
*                                         TARG at 50% of 0.45->0.9 = 0.675V (rising)
*   Transition 0->2 (full swing down):   TRIG = 0.45V (rise), TARG = 0.45V (fall)
*   Transition 2->0 (full swing up):     TRIG = 0.45V (fall), TARG = 0.45V (rise)
*------------------------------------------------------

* [A] t_01: IN 0->1 at ~0.505ns, OUT falls 2->1
.MEASURE TRAN t_01
+ TRIG V(in)  VAL=0.225  TD=0.45n  RISE=1
+ TARG V(out) VAL=0.675  FALL=1

* [B] t_12: IN 1->2 at ~1.005ns, OUT falls 1->0
.MEASURE TRAN t_12
+ TRIG V(in)  VAL=0.675  TD=0.95n  RISE=1
+ TARG V(out) VAL=0.225  FALL=1

* [C] t_21: IN 2->1 at ~1.505ns, OUT rises 0->1
.MEASURE TRAN t_21
+ TRIG V(in)  VAL=0.675  TD=1.45n  FALL=1
+ TARG V(out) VAL=0.225  RISE=1

* [D] t_10: IN 1->0 at ~2.005ns, OUT rises 1->2
.MEASURE TRAN t_10
+ TRIG V(in)  VAL=0.225  TD=1.95n  FALL=1
+ TARG V(out) VAL=0.675  RISE=1

* [E] t_02: IN 0->2 at ~2.505ns, OUT full swing down
.MEASURE TRAN t_02
+ TRIG V(in)  VAL=0.45   TD=2.45n  RISE=1
+ TARG V(out) VAL=0.45   FALL=1

* [F] t_20: IN 2->0 at ~3.005ns, OUT full swing up
.MEASURE TRAN t_20
+ TRIG V(in)  VAL=0.45   TD=2.95n  FALL=1
+ TARG V(out) VAL=0.45   RISE=1

* Average propagation delay (paper: Tp = 21.03 ps)
.MEASURE TRAN Tp  PARAM='(t_01 + t_12 + t_21 + t_10 + t_02 + t_20) / 6.0'

* Average power (paper: 2.76 uW)
.MEASURE avg_pow  AVG  par('V(Vdd,Gnd)*(-I(VVdd))')  FROM=0.1n  TO=3.5n

.probe V(in)
.probe V(out)
.probe V(n1)
.probe V(p1)
.probe par('V(Vdd,Gnd)*(-I(VVdd))')

.OPTION PROBE POST MEASOUT
.end

******************************************************
* GNRFET Negative Ternary Inverter (NTI)
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Fig. 6c — 2 transistors
*
* NTI Truth Table:
*   IN = 0 (0.0V)  -> OUT = 0.9V  (Logic 2)
*   IN = 1 (0.45V) -> OUT = 0.0V  (Logic 0)  <- LOW for both 1 and 2
*   IN = 2 (0.9V)  -> OUT = 0.0V  (Logic 0)
*
* SUBCIRCUIT PORT ORDER (FROM gnrfet.lib):
*   .subckt gnrfetnmos  ns  ng  nd  nb  ...
*   .subckt gnrfetpmos  ns  ng  nd  nb  ...
*   ORDER IS: SOURCE  GATE  DRAIN  BODY
*
* TRANSISTOR ASSIGNMENT (from paper Fig. 6c):
*   T1: NMOS n=12, Vth=+0.23V — source=GND, gate=IN, drain=OUT, body=GND
*       LOW threshold — turns ON when IN > 0.23V (Logic 1 AND Logic 2)
*       Pulls output DOWN to GND
*   T2: PMOS n=6,  Vth=-0.43V — source=VDD, gate=IN, drain=OUT, body=VDD
*       HIGH threshold — only turns ON when IN < 0.47V (Logic 0 only)
*       Pulls output UP to VDD
*
* NTI vs PTI — the KEY difference:
*   PTI: NMOS n=6 (high Vth) + PMOS n=12 (low Vth) → output HIGH at 0 and 1
*   NTI: NMOS n=12 (low Vth) + PMOS n=6 (high Vth) → output HIGH only at 0
*   Swapping n values (dimer lines) swaps threshold voltages and flips behavior
*
* Circuit topology:
*   VDD --- [T2:PMOS n=6] --- OUT --- [T1:NMOS n=12] --- GND
*
* Expected Results (Table 7, paper):
*   t_01 = 21.57 ps
*   t_10 = 13.75 ps
*   t_02 = 18.50 ps
*   t_20 = 21.37 ps
*   Tp   = 18.79 ps
*   Pavg = 1.318 uW
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
* NTI Circuit
*------------------------------------------------------

* T1: NMOS n=12, Vth=+0.23V — pull-down (LOW Vth, fires at Logic 1 AND 2)
* ns=Gnd, ng=in, nd=out, nb=Gnd
X1  Gnd  in   out  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: PMOS n=6, Vth=-0.43V — pull-up (HIGH |Vth|, only fires at Logic 0)
* ns=Vdd, ng=in, nd=out, nb=Vdd
X2  Vdd  in   out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* Load capacitor
CL  out  Gnd  2.2fF

*------------------------------------------------------
* Input Signal (PWL)
* NTI transitions are 0->1, 1->0 (half swing) and 0->2, 2->0 (full swing)
* Start at Logic 0 (0.0V) so DC gives OUT=0.9V cleanly
*
* Timeline:
*   0.0-1.0ns: IN=0.0V (Logic 0),  OUT=0.9V
*   1.0-1.01ns: IN ramps 0.0->0.45V [0->1]
*   1.01-2.0ns: IN=0.45V (Logic 1), OUT=0V
*   2.0-2.01ns: IN ramps 0.45->0.0V [1->0]
*   2.01-3.0ns: IN=0.0V (Logic 0),  OUT=0.9V
*   3.0-3.01ns: IN ramps 0.0->0.9V  [0->2]
*   3.01-4.0ns: IN=0.9V (Logic 2),  OUT=0V
*   4.0-4.01ns: IN ramps 0.9->0.0V  [2->0]
*   4.01-5.0ns: IN=0.0V (Logic 0),  OUT=0.9V
*------------------------------------------------------
Vin  in  Gnd  PWL(
+ 0n      0.0
+ 1.0n    0.0
+ 1.01n   0.45
+ 2.0n    0.45
+ 2.01n   0.0
+ 3.0n    0.0
+ 3.01n   0.9
+ 4.0n    0.9
+ 4.01n   0.0
+ 5.0n    0.0
+ )

.tran  1p  5.0n

*------------------------------------------------------
* Propagation Delay Measurements
* NTI output is 2-level (only Logic 0 and Logic 2)
* Output threshold is always 50% of full swing = 0.45V
*
* t_01: IN 0->1 (rise from 0->0.45V): TRIG at 50% of half swing = 0.225V (rise)
*        OUT falls 0.9->0V: TARG at 0.45V (fall)
* t_10: IN 1->0 (fall from 0.45->0V): TRIG at 0.225V (fall)
*        OUT rises 0->0.9V: TARG at 0.45V (rise)
* t_02: IN 0->2 (rise from 0->0.9V):  TRIG at 50% of full swing = 0.45V (rise)
*        OUT falls 0.9->0V: TARG at 0.45V (fall)
* t_20: IN 2->0 (fall from 0.9->0V):  TRIG at 0.45V (fall)
*        OUT rises 0->0.9V: TARG at 0.45V (rise)
*------------------------------------------------------

* [A] t_01: IN 0->1 at ~1.005ns
.MEASURE TRAN t_01
+ TRIG V(in)  VAL=0.225  TD=0.5n  RISE=1
+ TARG V(out) VAL=0.45   FALL=1

* [B] t_10: IN 1->0 at ~2.005ns
.MEASURE TRAN t_10
+ TRIG V(in)  VAL=0.225  TD=1.5n  FALL=1
+ TARG V(out) VAL=0.45   RISE=1

* [C] t_02: IN 0->2 at ~3.005ns
.MEASURE TRAN t_02
+ TRIG V(in)  VAL=0.45   TD=2.5n  RISE=1
+ TARG V(out) VAL=0.45   FALL=1

* [D] t_20: IN 2->0 at ~4.005ns
.MEASURE TRAN t_20
+ TRIG V(in)  VAL=0.45   TD=3.5n  FALL=1
+ TARG V(out) VAL=0.45   RISE=1

* Average propagation delay (paper: 18.79 ps)
.MEASURE TRAN Tp  PARAM='(t_01 + t_10 + t_02 + t_20) / 4.0'

* Average power (paper: 1.318 uW)
.MEASURE avg_pow  AVG  par('V(Vdd,Gnd)*(-I(VVdd))')  FROM=0.5n  TO=5.0n

.probe V(in)
.probe V(out)
.probe par('V(Vdd,Gnd)*(-I(VVdd))')

.OPTION PROBE POST MEASOUT
.end

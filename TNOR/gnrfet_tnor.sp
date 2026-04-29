******************************************************
* GNRFET Ternary NOR Gate (T-NOR) — 10 Transistors
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Section 4.2, Fig. 11b
*
* NOR Function: NOR(A,B) = STI( max(A,B) )
*
* Output Truth Table (B=0 fixed, A varies — worst case):
*   A=0, B=0 -> NOR(0,0) = STI(0) = 0.9V  (Logic 2)
*   A=1, B=0 -> NOR(1,0) = STI(1) = 0.45V (Logic 1)
*   A=2, B=0 -> NOR(2,0) = STI(2) = 0.0V  (Logic 0)
*
* SUBCIRCUIT PORT ORDER (FROM gnrfet.lib):
*   .subckt gnrfetnmos  ns  ng  nd  nb  ...
*   .subckt gnrfetpmos  ns  ng  nd  nb  ...
*   ORDER IS: SOURCE  GATE  DRAIN  BODY
*
* TOPOLOGY — EXACT DUAL of NAND:
*   NOR logic requires:
*     NMOS pull-down: PARALLEL  (either A OR B high is sufficient to pull down)
*     PMOS pull-up:  SERIES     (both A AND B must be low to pull up)
*
* 10 transistors total:
*   NMOS side:
*     T2: NMOS n=9  (diode) — midpoint clamp
*     T1a, T1b: NMOS n=12 — PARALLEL pull-down (gates A, B)
*     T3a, T3b: NMOS n=6  — PARALLEL direct pull-down (gates A, B)
*   PMOS side:
*     T4: PMOS n=9  (diode) — midpoint clamp
*     T5a, T5b: PMOS n=12 — SERIES pull-up (gates A, B)
*     T6a, T6b: PMOS n=6  — SERIES direct pull-up (gates A, B)
*
* Node map:
*   n1   = common drain node for parallel NMOS T1a/T1b (connects to diode T2)
*   p1a  = between T5a (gate=A) and T5b (gate=B) in series PMOS chain
*   p1   = between T5b and diode T4
*   p3   = between T6a (gate=A) and T6b (gate=B) in series PMOS chain
*
* Full node connectivity:
*   VDD -- T5a(pmos n=12, gate=A) -- p1a -- T5b(pmos n=12, gate=B) -- p1 -- T4(diode) -- OUT
*   VDD -- T6a(pmos n=6,  gate=A) -- p3  -- T6b(pmos n=6,  gate=B) -- OUT
*   OUT -- T2(nmos n=9, diode) -- n1 -+- T1a(nmos n=12, gate=A) -- GND
*                                     +- T1b(nmos n=12, gate=B) -- GND
*   OUT -- T3a(nmos n=6, gate=A) -- GND   (parallel)
*   OUT -- T3b(nmos n=6, gate=B) -- GND   (parallel)
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
* NMOS Pull-Down Network (PARALLEL = NOR)
*------------------------------------------------------

* T1a: NMOS n=12, ns=Gnd, ng=A, nd=n1, nb=Gnd
X1a  Gnd  A    n1   Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T1b: NMOS n=12, ns=Gnd, ng=B, nd=n1, nb=Gnd
X1b  Gnd  B    n1   Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: NMOS n=9, diode (gate tied to drain=out)
* ns=n1, ng=out, nd=out, nb=Gnd
X2   n1   out  out  Gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3a: NMOS n=6, ns=Gnd, ng=A, nd=out, nb=Gnd
X3a  Gnd  A    out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3b: NMOS n=6, ns=Gnd, ng=B, nd=out, nb=Gnd
X3b  Gnd  B    out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

*------------------------------------------------------
* PMOS Pull-Up Network (SERIES = NOR)
*------------------------------------------------------

* T4: PMOS n=9, diode (gate tied to drain=out)
* ns=p1, ng=out, nd=out, nb=Vdd
X4   p1   out  out  Vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5a: PMOS n=12, Vth=-0.23V, bottom of series chain (gate=A, closest to Vdd)
* ns=Vdd, ng=A, nd=p1a, nb=Vdd
X5a  Vdd  A    p1a  Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5b: PMOS n=12, Vth=-0.23V, top of series chain (gate=B, connects to p1 node)
* ns=p1a, ng=B, nd=p1, nb=Vdd
X5b  p1a  B    p1   Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6a: PMOS n=6, Vth=-0.43V, bottom of direct series chain (gate=A, closest to Vdd)
* ns=Vdd, ng=A, nd=p3, nb=Vdd
X6a  Vdd  A    p3   Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6b: PMOS n=6, Vth=-0.43V, top of direct series chain (gate=B, connects to out)
* ns=p3, ng=B, nd=out, nb=Vdd
X6b  p3   B    out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* Load capacitor
CL  out  Gnd  3.0fF

*------------------------------------------------------
* Input Signals
* B = Logic 0 (0V) constant — worst case for NOR
* (if B is not Logic 0, output stays low regardless of A)
* A sweeps 0->1->2->1->0 to exercise all output levels
*
* Timeline:
*   0.0-0.5ns: A=0V                 OUT=0.9V (Logic 2)
*   0.5-0.51ns: A ramps 0->0.45V   [0->1: output 2->1]
*   0.51-1.0ns: A=0.45V             OUT=0.45V (Logic 1)
*   1.0-1.01ns: A ramps 0.45->0.9V  [1->2: output 1->0]
*   1.01-2.0ns: A=0.9V              OUT=0V (Logic 0)
*   2.0-2.01ns: A ramps 0.9->0.45V  [2->1: output 0->1]
*   2.01-3.0ns: A=0.45V             OUT=0.45V (Logic 1)
*   3.0-3.01ns: A ramps 0.45->0V    [1->0: output 1->2]
*   3.01-4.0ns: A=0V                OUT=0.9V (Logic 2)
*------------------------------------------------------
Va  A  Gnd  PWL(
+ 0.0n  0.0
+ 0.5n  0.0
+ 0.51n 0.45
+ 1.0n  0.45
+ 1.01n 0.9
+ 2.0n  0.9
+ 2.01n 0.45
+ 3.0n  0.45
+ 3.01n 0.0
+ 4.0n  0.0
+ )

Vb  B  Gnd  DC  0.0

.tran  1p  4.0n

*------------------------------------------------------
* Propagation Delay Measurements
* 3-level output (same logic as STI measurements):
*   OUT swing 2->1 (fall): threshold = 0.675V
*   OUT swing 1->0 (fall): threshold = 0.225V
*   OUT swing 0->1 (rise): threshold = 0.225V
*   OUT swing 1->2 (rise): threshold = 0.675V
*------------------------------------------------------

* t_01: A 0->1, OUT falls 2->1
.MEASURE TRAN t_01
+ TRIG V(A)   VAL=0.225  TD=0.45n  RISE=1
+ TARG V(out) VAL=0.675  FALL=1

* t_12: A 1->2, OUT falls 1->0
.MEASURE TRAN t_12
+ TRIG V(A)   VAL=0.675  TD=0.95n  RISE=1
+ TARG V(out) VAL=0.225  FALL=1

* t_21: A 2->1, OUT rises 0->1
.MEASURE TRAN t_21
+ TRIG V(A)   VAL=0.675  TD=1.95n  FALL=1
+ TARG V(out) VAL=0.225  RISE=1

* t_10: A 1->0, OUT rises 1->2
.MEASURE TRAN t_10
+ TRIG V(A)   VAL=0.225  TD=2.95n  FALL=1
+ TARG V(out) VAL=0.675  RISE=1

.MEASURE TRAN Tp  PARAM='(t_01 + t_12 + t_21 + t_10) / 4.0'
.MEASURE avg_pow  AVG  par('V(Vdd,Gnd)*(-I(VVdd))')  FROM=0.1n  TO=4.0n

.probe V(A)
.probe V(B)
.probe V(out)
.probe V(n1)
.probe V(p1)
.probe V(p1a)
.probe V(p3)
.probe par('V(Vdd,Gnd)*(-I(VVdd))')

.OPTION PROBE POST MEASOUT
.end

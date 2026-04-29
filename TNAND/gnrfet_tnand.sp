******************************************************
* GNRFET Ternary NAND Gate (T-NAND) — 10 Transistors
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Section 4.2, Fig. 11a
*
* NAND Function: NAND(A,B) = STI( min(A,B) )
*
* Output Truth Table (B=2 fixed, A varies — worst case):
*   A=0, B=2 -> NAND(0,2) = STI(0) = 0.9V  (Logic 2)
*   A=1, B=2 -> NAND(1,2) = STI(1) = 0.45V (Logic 1)
*   A=2, B=2 -> NAND(2,2) = STI(2) = 0.0V  (Logic 0)
*
* SUBCIRCUIT PORT ORDER (FROM gnrfet.lib):
*   .subckt gnrfetnmos  ns  ng  nd  nb  ...
*   .subckt gnrfetpmos  ns  ng  nd  nb  ...
*   ORDER IS: SOURCE  GATE  DRAIN  BODY
*
* TOPOLOGY — STI extended to 2 inputs:
*   NAND logic requires:
*     NMOS pull-down: SERIES   (both A AND B must be high to pull down)
*     PMOS pull-up:  PARALLEL  (either A OR B low is sufficient to pull up)
*
* 10 transistors total:
*   NMOS side:
*     T2: NMOS n=9  (diode) — midpoint clamp
*     T1a, T1b: NMOS n=12 — series pull-down (gates A, B)
*     T3a, T3b: NMOS n=6  — series direct pull-down (gates A, B)
*   PMOS side:
*     T4: PMOS n=9  (diode) — midpoint clamp
*     T5a, T5b: PMOS n=12 — parallel pull-up (gates A, B)
*     T6a, T6b: PMOS n=6  — parallel direct pull-up (gates A, B)
*
* Node map:
*   n1a = between T1a (gate=A) and T1b (gate=B) in series NMOS chain
*   n1  = between T1b and diode T2
*   n3  = between T3a (gate=A) and T3b (gate=B) in series NMOS chain
*   p1  = between diode T4 and parallel PMOS T5a/T5b
*
* Full node connectivity:
*   VDD -- T6a(pmos n=6, gate=A) -+- OUT   (parallel direct)
*   VDD -- T6b(pmos n=6, gate=B) -+
*   VDD -- T5a(pmos n=12, gate=A) -+- p1 -- T4(pmos n=9, diode) -- OUT
*   VDD -- T5b(pmos n=12, gate=B) -+
*   OUT -- T2(nmos n=9, diode) -- n1 -- T1b(nmos n=12, gate=B) -- n1a -- T1a(nmos n=12, gate=A) -- GND
*   OUT -- T3b(nmos n=6, gate=B) -- n3 -- T3a(nmos n=6, gate=A) -- GND
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
* NMOS Pull-Down Network (SERIES = NAND)
*------------------------------------------------------

* T1a: NMOS n=12, ns=Gnd, ng=A, nd=n1a, nb=Gnd
X1a  Gnd  A    n1a  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T1b: NMOS n=12, ns=n1a, ng=B, nd=n1, nb=Gnd
X1b  n1a  B    n1   Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: NMOS n=9, diode (gate tied to drain=out)
* ns=n1, ng=out, nd=out, nb=Gnd
X2   n1   out  out  Gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3a: NMOS n=6, ns=Gnd, ng=A, nd=n3, nb=Gnd
X3a  Gnd  A    n3   Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3b: NMOS n=6, ns=n3, ng=B, nd=out, nb=Gnd
X3b  n3   B    out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

*------------------------------------------------------
* PMOS Pull-Up Network (PARALLEL = NAND)
*------------------------------------------------------

* T4: PMOS n=9, diode (gate tied to drain=out)
* ns=p1, ng=out, nd=out, nb=Vdd
X4   p1   out  out  Vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5a: PMOS n=12, Vth=-0.23V, parallel pull-up, gate=A
* ns=Vdd, ng=A, nd=p1, nb=Vdd
X5a  Vdd  A    p1   Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5b: PMOS n=12, Vth=-0.23V, parallel pull-up, gate=B
* ns=Vdd, ng=B, nd=p1, nb=Vdd
X5b  Vdd  B    p1   Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6a: PMOS n=6, Vth=-0.43V, direct parallel pull-up (no diode), gate=A
* ns=Vdd, ng=A, nd=out, nb=Vdd
X6a  Vdd  A    out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6b: PMOS n=6, Vth=-0.43V, direct parallel pull-up (no diode), gate=B
* ns=Vdd, ng=B, nd=out, nb=Vdd
X6b  Vdd  B    out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* Load capacitor
CL  out  Gnd  3.0fF

*------------------------------------------------------
* Input Signals
* B = Logic 2 (0.9V) constant — worst case for NAND
* (if B is not Logic 2, output stays high regardless of A)
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

Vb  B  Gnd  DC  0.9

.tran  1p  4.0n

*------------------------------------------------------
* Propagation Delay Measurements
* 3-level output (same logic as STI measurements):
*   OUT swing 2->1 (fall): threshold = 0.675V (50% of 0.9-0.45)
*   OUT swing 1->0 (fall): threshold = 0.225V (50% of 0.45-0)
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
.probe V(n1a)
.probe V(n3)
.probe V(p1)
.probe par('V(Vdd,Gnd)*(-I(VVdd))')

.OPTION PROBE POST MEASOUT
.end

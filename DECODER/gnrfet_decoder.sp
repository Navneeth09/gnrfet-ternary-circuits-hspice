******************************************************
* GNRFET Ternary Decoder
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Section 2.2, Fig. 2
*
* DECODER FUNCTION (from equation 4):
*   ax = 2  if input a = x
*   ax = 0  if input a != x
*
*   a0 = 2  when IN=0,  else 0  → implemented by NTI
*   a1 = 2  when IN=1,  else 0  → implemented by NOR(NTI_out, PTI_out)
*                                   (NOR gives HIGH only when both inputs LOW)
*   a2 = 2  when IN=2,  else 0  → implemented by PTI
*
* CIRCUIT (Fig. 2 of paper):
*   One PTI + One NOR gate + Two NTI gates
*   - a0: NTI of input → HIGH only when IN=0
*   - a2: PTI of input → HIGH only when IN=2
*   - a1: NOR(a0, a2)  → HIGH only when both a0=0 AND a2=0 → only when IN=1
*
* TRUTH TABLE:
*   IN=0 (0.0V):  a0=0.9V(2), a1=0.0V(0), a2=0.0V(0)
*   IN=1 (0.45V): a0=0.0V(0), a1=0.9V(2), a2=0.0V(0)
*   IN=2 (0.9V):  a0=0.0V(0), a1=0.0V(0), a2=0.9V(2)
*
* VOLTAGE LEVELS:
*   Logic 0 = 0.0V
*   Logic 1 = 0.45V  (VDD/2)
*   Logic 2 = 0.9V   (VDD)
*   VDD = 0.9V
*
* TRANSISTOR PARAMETERS (same as other gates):
*   n=12: Vth=+/-0.23V (low threshold)
*   n=9:  Vth=+/-0.30V (medium threshold, diode use)
*   n=6:  Vth=+/-0.43V (high threshold)
*   nRib=15, L=32n, Tox=0.95n, sp=2n, dop=0.001
*
* NODE NAMING:
*   in   = decoder input
*   a0   = output for value 0
*   a1   = output for value 1
*   a2   = output for value 2
*   nti_out = internal node (NTI output = a0)
*   pti_out = internal node (PTI output = a2)
*   (a0 and nti_out are the same node)
*   (a2 and pti_out are the same node)
******************************************************

.options POST
.options AUTOSTOP
.options INGOLD=2     DCON=1
.options GSHUNT=1e-12 RMIN=1e-15
.options ABSTOL=1e-5  ABSVDC=1e-4
.options RELTOL=1e-2  RELVDC=1e-2
.options NUMDGT=4     PIVOT=13
.param   TEMP=27

.lib 'gnrfet.lib' GNRFET

VVdd  Vdd  Gnd  DC  0.9

*======================================================
* BLOCK 1: NTI — produces a0
* NTI: HIGH (0.9V) only when IN=0
*   T_NTI_N: NMOS n=12, Vth=+0.23V — pull-down (fires at Logic 1 AND 2)
*   T_NTI_P: PMOS n=6,  Vth=-0.43V — pull-up  (fires only at Logic 0)
* ns ng nd nb for NMOS: Gnd in a0 Gnd
* ns ng nd nb for PMOS: Vdd in a0 Vdd
*======================================================
XN1  Gnd  in  a0  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP1  Vdd  in  a0  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
CL0  a0  Gnd  1.0fF

*======================================================
* BLOCK 2: PTI — produces a2
* PTI: HIGH (0.9V) when IN=0 OR IN=1; LOW only when IN=2
* As decoder output a2: needs HIGH only at IN=2
* → Use PTI inverted: PTI directly gives a2 = HIGH at Logic 2
* WAIT — PTI is HIGH at 0 and 1, LOW at 2. That is OPPOSITE of what we need for a2.
*
* Re-reading Fig.2 carefully:
*   a2 output = PTI(in) ? No — PTI gives HIGH for 0,1 → that would be a{0,1} indicator
*
* Correct mapping from paper Fig.2:
*   a0 = NTI(in)  → HIGH only at IN=0   ✓ (NTI is HIGH at 0 only)
*   a2 = PTI(in) applied as: PTI gives HIGH at 0,1 and LOW at 2
*        → For a2 we need: HIGH at IN=2, so we need NOT-PTI = STI applied differently
*
* From the paper Fig. 2 description: "one PTI, one NOR, and two NTI logic gates"
* The decoder outputs a0, a1, a2:
*   a0: NTI(in)                  → 2 when in=0, else 0
*   a2: second NTI? No — PTI gives output 2 only when in ≠ 2
*
* Let's re-derive from truth table:
*   a2 = 2 when in=2, else 0
*   This is NOT PTI. PTI gives HIGH (2) when in<2.
*
* Actually a2 = STI applied to NTI output? Let's think differently.
* NTI(NTI(in)): NTI gives 2 at in=0, 0 elsewhere → NTI of that gives 2 at in≠0, 0 at in=0
* That still doesn't isolate in=2.
*
* Simplest correct implementation for a2:
*   Two NTIs in series with different threshold trick, OR use PTI on (NOT input).
*
* Standard decoder in ternary CNTFET literature:
*   a0 = NOR( PTI(in), STI(NTI(in)) ) — but paper says simpler
*
* From paper Fig. 2 labels: PTI block feeds into NOR along with NTI output.
* PTI(in): output=2 when in=0 or in=1; output=0 when in=2
* NTI(in): output=2 when in=0;         output=0 when in=1,2
* NOR(PTI(in), NTI(in)):
*   in=0: NOR(2, 2) = min complement... 
*   Ternary NOR = 2 - max(a,b)
*   in=0: 2 - max(0.9, 0.9) = ... uses logic values:
*   in=0: NOR(2,2) = 2-max(2,2) = 0   ← 0
*   in=1: NOR(2,0) = 2-max(2,0) = 0   ← 0
*   in=2: NOR(0,0) = 2-max(0,0) = 2   ← 2  ✓ this IS a2!
*
* So: a2 = TNOR(PTI(in), NTI(in))
* And a0 = NTI(in) directly
* And a1 = second NTI of PTI: NTI(PTI(in))
*   PTI(in): 2 at in=0,1; 0 at in=2
*   NTI of that: HIGH only when PTI_out=0 → only when in=2? No.
*   NTI(PTI(in)): HIGH(2) when PTI(in)=0 → when in=2 → that would be a2 again
*
* Correct Fig.2 reading (two NTIs, one PTI, one NOR):
*   Let pti_out = PTI(in): HIGH at in=0,1 → LOW at in=2
*   Let nti1_out = NTI(in): HIGH at in=0 → LOW at in=1,2
*   a0 = nti1_out = NTI(in)
*   a1 = NOR(pti_out, nti1_out):
*        in=0: NOR(2,2)=0  in=1: NOR(2,0)=0  in=2: NOR(0,0)=2 → this is a2!
*   That gives a2 from NOR, not a1.
*
* Final correct assignment:
*   nti_a = NTI(in):     [2, 0, 0] for in=[0,1,2]  → this is a0
*   pti_a = PTI(in):     [2, 2, 0] for in=[0,1,2]
*   nti_b = NTI(pti_a):  NTI of PTI output:
*           in=0: NTI(2)=0; in=1: NTI(2)=0; in=2: NTI(0)=2 → a2
*   TNOR(nti_a, nti_b):
*           in=0: TNOR(2,0)=0; in=1: TNOR(0,0)=2; in=2: TNOR(0,2)=0 → a1 ✓
*
* CONFIRMED CIRCUIT:
*   a0 = NTI(in)           — NTI gate, input=in
*   pti_int = PTI(in)      — PTI gate, input=in
*   a2 = NTI(pti_int)      — second NTI, input=pti_int
*   a1 = TNOR(a0, a2)      — NOR gate, inputs=a0,a2
*
* This matches "one PTI + two NTI + one NOR" from the paper ✓
*======================================================

*======================================================
* BLOCK 1: NTI(in) → a0
* HIGH only when in=0
*======================================================
* (already instantiated above as XN1, XP1, node=a0)

*======================================================
* BLOCK 2: PTI(in) → pti_int  (intermediate node)
* HIGH when in=0 or in=1
*======================================================
XN2  Gnd  in  pti_int  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  Vdd  in  pti_int  Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
CL_pti  pti_int  Gnd  1.0fF

*======================================================
* BLOCK 3: NTI(pti_int) → a2
* HIGH only when pti_int=0 → only when in=2
*======================================================
XN3  Gnd  pti_int  a2  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  Vdd  pti_int  a2  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
CL2  a2  Gnd  1.0fF

*======================================================
* BLOCK 4: TNOR(a0, a2) → a1
* TNOR = 2 - max(a0, a2)
* HIGH only when both a0=0 AND a2=0 → only when in=1
*
* TNOR topology (from gnrfet_tnor.sp pattern):
*   NMOS pull-down: PARALLEL (either input high pulls output low)
*   PMOS pull-up:  SERIES   (both inputs must be low to pull up)
*
* 10 transistors: same as TNAND but NMOS parallel, PMOS series
* Inputs: na=a0, nb=a2, output: a1
*
* NMOS side (parallel — either a0 or a2 pulls down):
*   XNa_3a: NMOS n=12, gate=a0, parallel branch A
*   XNa_3b: NMOS n=12, gate=a2, parallel branch B
*   XNa_2:  NMOS n=9, diode (between parallel junction and OUT)
*   XNa_6a: NMOS n=6, gate=a0, parallel direct pull-down A
*   XNa_6b: NMOS n=6, gate=a2, parallel direct pull-down B
*
* PMOS side (series — both must be low to pull up):
*   XPa_6a: PMOS n=6, gate=a0, series
*   XPa_6b: PMOS n=6, gate=a2, series (between XPa_6a and OUT)
*   XPa_4:  PMOS n=9, diode (between series junction and p1)
*   XPa_12a: PMOS n=12, gate=a0, series high-side
*   XPa_12b: PMOS n=12, gate=a2, series (between XPa_12a and p1_nor)
*
* Node map for NOR:
*   nor_n1  = parallel NMOS n=12 junction → diode NMOS n=9 → a1
*   nor_n3  = parallel NMOS n=6 direct → a1
*   nor_p1  = series PMOS junction (internal)
*   nor_ps1 = series node between PMOS n=12 pair
*   nor_s1  = series node between PMOS n=6 pair
*======================================================

* NMOS pull-down parallel network (either a0 OR a2 fires → pull a1 LOW)
* Branch 1: n=12 parallel
XNa1  Gnd  a0  nor_n1  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XNa2  Gnd  a2  nor_n1  Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* Diode clamp n=9
XNa3  nor_n1  a1  a1  Gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* Branch 2: n=6 parallel direct
XNa4  Gnd  a0  a1  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XNa5  Gnd  a2  a1  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* PMOS pull-up series network (both a0 AND a2 must be LOW to pull a1 HIGH)
* Top series: PMOS n=6 in series (gates=a0, a2)
XPa1  Vdd  a0  nor_s1  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XPa2  nor_s1  a2  a1   Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* Diode clamp p=9
XPa3  nor_p1  a1  a1  Vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* Bottom series: PMOS n=12 in series (gates=a0, a2) → nor_p1
XPa4  Vdd  a0  nor_ps1  Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XPa5  nor_ps1  a2  nor_p1  Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

CL1  a1  Gnd  1.0fF

*======================================================
* Input Stimulus
* Sweep through all three ternary levels to verify decoder
*
* Timeline:
*   0-1ns:   IN=0.0V (Logic 0) → expect a0=0.9, a1=0.0, a2=0.0
*   1-2ns:   IN=0.45V (Logic 1) → expect a0=0.0, a1=0.9, a2=0.0
*   2-3ns:   IN=0.9V (Logic 2) → expect a0=0.0, a1=0.0, a2=0.9
*======================================================
Vin  in  Gnd  PWL(
+ 0n      0.0
+ 1.0n    0.0
+ 1.01n   0.45
+ 2.0n    0.45
+ 2.01n   0.9
+ 3.0n    0.9
+ )

.tran  1p  3.0n

*======================================================
* Verification Measurements
* At each stable input level, check output voltages.
* For functional verification, measure V(a0), V(a1), V(a2) at midpoints.
*======================================================

* At IN=0 (t=0.5ns): a0 should be ~0.9V, a1~0V, a2~0V
.MEASURE TRAN a0_at_in0  AVG V(a0)   FROM=0.5n  TO=0.9n
.MEASURE TRAN a1_at_in0  AVG V(a1)   FROM=0.5n  TO=0.9n
.MEASURE TRAN a2_at_in0  AVG V(a2)   FROM=0.5n  TO=0.9n

* At IN=1 (t=1.5ns): a0~0V, a1~0.9V, a2~0V
.MEASURE TRAN a0_at_in1  AVG V(a0)   FROM=1.5n  TO=1.9n
.MEASURE TRAN a1_at_in1  AVG V(a1)   FROM=1.5n  TO=1.9n
.MEASURE TRAN a2_at_in1  AVG V(a2)   FROM=1.5n  TO=1.9n

* At IN=2 (t=2.5ns): a0~0V, a1~0V, a2~0.9V
.MEASURE TRAN a0_at_in2  AVG V(a0)   FROM=2.5n  TO=2.9n
.MEASURE TRAN a1_at_in2  AVG V(a1)   FROM=2.5n  TO=2.9n
.MEASURE TRAN a2_at_in2  AVG V(a2)   FROM=2.5n  TO=2.9n

.probe V(in)
.probe V(a0)
.probe V(a1)
.probe V(a2)
.probe V(pti_int)

.OPTION PROBE POST MEASOUT
.end

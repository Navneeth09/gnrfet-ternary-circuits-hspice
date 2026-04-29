******************************************************
* GNRFET Ternary Half Adder
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
* IET Circuits, Devices & Systems, 2020, Vol. 14, pp. 972-979
* Section 4.3, Fig. 12
*
* HALF ADDER EQUATIONS (from paper eq. 3):
*   Sum   = a2b0 + a1b1 + a0b2 + 1*(a1b0 + a0b1 + a2b2)
*   Carry = 1 * (a2b1 + a2b2 + a1b2)
*
*   where ax, bx are decoder outputs of inputs a and b:
*   ax = 2 if a=x, else 0  (unary indicator functions)
*   bx = 2 if b=x, else 0
*
* TRUTH TABLE (Table 2 of paper):
*   a=0,b=0 → Sum=0, Carry=0
*   a=0,b=1 → Sum=1, Carry=0
*   a=0,b=2 → Sum=2, Carry=0
*   a=1,b=0 → Sum=1, Carry=0
*   a=1,b=1 → Sum=2, Carry=0
*   a=1,b=2 → Sum=0, Carry=1
*   a=2,b=0 → Sum=2, Carry=0
*   a=2,b=1 → Sum=0, Carry=1
*   a=2,b=2 → Sum=1, Carry=1
*
* HOW TO READ SUM/CARRY EXPRESSIONS:
*   In ternary logic, ax and bx are either 0 or 2 (never 1).
*   Products like a2b0 mean: AND(a2, b0) = min(a2, b0)
*   Since both are 0 or 2: min(2,2)=2 (both true), else 0
*   The coefficient "1*" means the result is scaled to 1 (half VDD):
*     1*(expr) = (expr)/2 — produces Logic 1 output when condition is true
*
*   For Sum:
*     "a2b0" fires (→2) when a=2 AND b=0
*     "a1b1" fires (→2) when a=1 AND b=1
*     "a0b2" fires (→2) when a=0 AND b=2
*     "1*(a1b0 + a0b1 + a2b2)" fires (→1) when a=1,b=0 OR a=0,b=1 OR a=2,b=2
*     All other cases → 0
*     Use OR = max to combine: Sum = max of all active terms
*
*   For Carry:
*     "1*(a2b1 + a2b2 + a1b2)" fires (→1) when a=2,b=1 OR a=2,b=2 OR a=1,b=2
*     All other cases → 0
*
* CIRCUIT ARCHITECTURE (Fig. 12a):
*   Two decoder blocks (Decoder A and Decoder B) each producing 3 unary outputs.
*   Logic gates (AND=min, OR=max) implement the sum/carry expressions.
*
*   Decoder A: input=a → outputs a0, a1, a2
*   Decoder B: input=b → outputs b0, b1, b2
*
*   Sum computation:
*     t_sum2_high = OR(AND(a2,b0), AND(a1,b1), AND(a0,b2))  [terms producing Logic 2]
*     t_sum1_high = AND(a1,b0)  [one of the terms producing Logic 1]
*     ... etc. → combined with voltage divider / TNAND-NTI chain
*
* PRACTICAL IMPLEMENTATION NOTE:
*   The AND (min) of two decoder outputs (each 0 or 2) gives:
*     min(2,2)=2 → Logic 2, min(2,0)=min(0,2)=min(0,0)=0 → Logic 0
*   So AND gates here are simple pass gates or TNAND+NTI combinations.
*
*   The "1*" scaling (Logic 1 output) requires a voltage divider to get VDD/2=0.45V.
*   In practice this is achieved by connecting the AND output through a resistive
*   divider or by using a dedicated 1-scaling inverter circuit.
*   For SPICE simulation, we implement this as:
*     - Full AND(ax,bx) → produces 0 or 0.9V
*     - Scale to half: use a resistive divider (two equal resistors) 
*       or connect through PTI-based half-VDD generator
*
* SIMPLIFIED SIMULATION APPROACH:
*   Given the modular nature of the design, this netlist instantiates:
*   1. Two decoder subcircuits (reusing the decoder components)
*   2. AND gates for each product term
*   3. OR gates to combine terms of same weight
*   4. A "half-level" circuit for the 1* terms using voltage divider
*
* SUBCIRCUIT DEFINITIONS:
*   We define inline subcircuits for NTI, PTI, TNOR (for decoder NOR block)
*   to avoid external file dependency beyond gnrfet.lib
*
* VOLTAGE LEVELS:
*   Logic 0 = 0.0V,  Logic 1 = 0.45V,  Logic 2 = 0.9V,  VDD = 0.9V
*
* EXPECTED PROPAGATION DELAYS (paper Table, section 4.3):
*   t1 = 168 ps, t2 = 229 ps, t3 = 108.3 ps, t4 = 115.7 ps
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
* SUBCIRCUIT: NTI (Negative Ternary Inverter)
* HIGH only when in=0
* Ports: in out vdd gnd
*======================================================
.subckt NTI_sub  in  out  vdd  gnd
XN  gnd  in  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP  vdd  in  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends NTI_sub

*======================================================
* SUBCIRCUIT: PTI (Positive Ternary Inverter)
* HIGH when in=0 or in=1 (LOW only at in=2)
* Ports: in out vdd gnd
*======================================================
.subckt PTI_sub  in  out  vdd  gnd
XN  gnd  in  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP  vdd  in  out  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends PTI_sub

*======================================================
* SUBCIRCUIT: TNOR_sub (Ternary NOR gate)
* OUT = 2 - max(in1, in2)  [ternary NOR]
* HIGH only when BOTH inputs are LOW (Logic 0)
* Ports: in1 in2 out vdd gnd
* (10 transistors — same topology as gnrfet_tnor.sp)
*======================================================
.subckt TNOR_sub  in1  in2  out  vdd  gnd
* NMOS parallel pull-down
XN1  gnd  in1  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  gnd  in2  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  out  out  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  gnd  in2  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* PMOS series pull-up
XP1  vdd  in1  ps1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  ps1  in2  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  out  out  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  ps2  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  ps2  in2  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TNOR_sub

*======================================================
* SUBCIRCUIT: TAND_sub (Ternary AND gate = min function)
* OUT = min(in1, in2)
* Implemented as TNAND + NTI chain: AND = STI(NAND) but since
* inputs are only 0 or 2 (decoder outputs), a simpler approach:
* TAND(a,b) = TNAND then STI. Here we use TNAND then NTI
* (since output of TNAND with 0/2 inputs is also 0 or 2, NTI inverts it back)
* For decoder outputs (only 0 or 2): min(0,0)=0, min(2,0)=0, min(2,2)=2
* Ports: in1 in2 out vdd gnd
*
* TNAND core (10 transistors) then NTI (2 transistors) = 12 transistors total
* TNAND: OUT_nand = 2-min(in1,in2) for {0,2} inputs → gives 2 when any input=0
* NTI(OUT_nand): HIGH only when OUT_nand=0 → only when min=2 → when both=2 ✓
*======================================================
.subckt TAND_sub  in1  in2  out  vdd  gnd
* ---- TNAND block ----
* NMOS series pull-down
XN1  gnd  in1  na1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  na1  in2  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  nd1  nd1  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  na3  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  na3  in2  nd1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* PMOS parallel pull-up
XP1  vdd  in1  nd1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  vdd  in2  nd1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  nd1  nd1  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  vdd  in2  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* ---- NTI block to invert NAND → AND ----
XN6  gnd  nd1  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP6  vdd  nd1  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TAND_sub

*======================================================
* SUBCIRCUIT: TOR_sub (Ternary OR gate = max function)
* OUT = max(in1, in2)
* For decoder outputs (only 0 or 2): max(0,0)=0, max(2,0)=2, max(2,2)=2
* Implemented as TNOR + NTI: OR = NTI(NOR)
* TNOR(a,b) for {0,2} inputs: NOR(0,0)=2, NOR(2,0)=0, NOR(2,2)=0
* NTI of that: HIGH when NOR=0 → when max≠0 → gives 2 when any input=2 ✓
* Ports: in1 in2 out vdd gnd
*======================================================
.subckt TOR_sub  in1  in2  out  vdd  gnd
* ---- TNOR block ----
XN1  gnd  in1  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  gnd  in2  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  nr1  nr1  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  nr1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  gnd  in2  nr1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP1  vdd  in1  ps1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  ps1  in2  nr1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  nr1  nr1  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  ps2  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  ps2  in2  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
* ---- NTI to invert NOR → OR ----
XN6  gnd  nr1  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP6  vdd  nr1  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TOR_sub

*======================================================
* MAIN CIRCUIT
*======================================================

*------------------------------------------------------
* DECODER A: input=a → a0, a1, a2
* NTI(a)→a0,  PTI(a)→pti_a,  NTI(pti_a)→a2,  TNOR(a0,a2)→a1
*------------------------------------------------------
XNTI_A   a  a0    Vdd  Gnd  NTI_sub
XPTI_A   a  pa_int  Vdd  Gnd  PTI_sub
XNTI_A2  pa_int  a2  Vdd  Gnd  NTI_sub
XNOR_A   a0  a2  a1  Vdd  Gnd  TNOR_sub

CLA0  a0  Gnd  0.5fF
CLA1  a1  Gnd  0.5fF
CLA2  a2  Gnd  0.5fF

*------------------------------------------------------
* DECODER B: input=b → b0, b1, b2
*------------------------------------------------------
XNTI_B   b  b0    Vdd  Gnd  NTI_sub
XPTI_B   b  pb_int  Vdd  Gnd  PTI_sub
XNTI_B2  pb_int  b2  Vdd  Gnd  NTI_sub
XNOR_B   b0  b2  b1  Vdd  Gnd  TNOR_sub

CLB0  b0  Gnd  0.5fF
CLB1  b1  Gnd  0.5fF
CLB2  b2  Gnd  0.5fF

*------------------------------------------------------
* SUM COMPUTATION
* Sum = a2b0 + a1b1 + a0b2 + 1*(a1b0 + a0b1 + a2b2)
*
* Step 1: Compute AND products for Logic-2 terms
*   p_a2b0 = AND(a2, b0)  → 2 when a=2,b=0
*   p_a1b1 = AND(a1, b1)  → 2 when a=1,b=1
*   p_a0b2 = AND(a0, b2)  → 2 when a=0,b=2
* Step 2: OR them together → sum2_terms (carries Logic 2 when active)
*
* Step 3: Compute AND products for Logic-1 (scaled) terms
*   p_a1b0 = AND(a1, b0)  → 2 when a=1,b=0
*   p_a0b1 = AND(a0, b1)  → 2 when a=0,b=1
*   p_a2b2 = AND(a2, b2)  → 2 when a=2,b=2
* Step 4: OR them together → sum1_terms (carries Logic 2 when active)
*   Scale by 0.5 using resistive divider → Logic 1 (0.45V)
*
* Step 5: OR(sum2_terms, sum1_scaled) → SUM output
*   Since sum2 gives 0.9V and sum1_scaled gives 0.45V,
*   max(0.9, 0) = 0.9 (Logic 2), max(0, 0.45) = 0.45 (Logic 1)
*   They are mutually exclusive so simple OR works.
*------------------------------------------------------

* AND terms for Logic-2 sum
XAND_a2b0  a2  b0  p_a2b0  Vdd  Gnd  TAND_sub
XAND_a1b1  a1  b1  p_a1b1  Vdd  Gnd  TAND_sub
XAND_a0b2  a0  b2  p_a0b2  Vdd  Gnd  TAND_sub

* OR the three Logic-2 sum terms
XORS1  p_a2b0  p_a1b1  sum2_ab  Vdd  Gnd  TOR_sub
XORS2  sum2_ab  p_a0b2  sum2_terms  Vdd  Gnd  TOR_sub

* AND terms for Logic-1 (1*) sum
XAND_a1b0  a1  b0  p_a1b0  Vdd  Gnd  TAND_sub
XAND_a0b1  a0  b1  p_a0b1  Vdd  Gnd  TAND_sub
XAND_a2b2  a2  b2  p_a2b2  Vdd  Gnd  TAND_sub

* OR the three Logic-1 source terms (result is 0 or 2)
XORS3  p_a1b0  p_a0b1  sum1_ab  Vdd  Gnd  TOR_sub
XORS4  sum1_ab  p_a2b2  sum1_pre  Vdd  Gnd  TOR_sub

*------------------------------------------------------
* SUM OUTPUT STAGE (Multiplexer)
* Since sum2_terms (0.9V) and sum1_pre (0.9V) are mutually exclusive,
* we can use them to drive a standard logic output stage instead of pass gates.
* 
* 1. Invert the sum signals
XNTI_sum2  sum2_terms  sum2_inv  Vdd  Gnd  NTI_sub
XNTI_sum1  sum1_pre    sum1_inv  Vdd  Gnd  NTI_sub

* 2. Ideal Half-VDD source for the Logic-1 output level
V_half  half_vdd  Gnd  DC  0.45

* 3. Output Stage:
* Pull to VDD (0.9V) when sum2_terms is active (sum2_inv=0V)
XP_sum2  Vdd  sum2_inv  sum_out  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0

* Pull to HALF-VDD (0.45V) when sum1_pre is active (sum1_inv=0V)
XP_sum1  half_vdd  sum1_inv  sum_out  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0

* Pull to GND (0V) when BOTH are inactive (sum2_inv=0.9V AND sum1_inv=0.9V)
XN_pd1  Gnd  sum2_inv  mid_pd  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XN_pd2  mid_pd  sum1_inv  sum_out  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0

CL_sum  sum_out  Gnd  2.0fF

*------------------------------------------------------
* CARRY COMPUTATION
* Carry = 1 * (a2b1 + a2b2 + a1b2)
*
* AND products:
*   p_a2b1 = AND(a2, b1)  → 2 when a=2,b=1
*   p_a2b2 = already computed above
*   p_a1b2 = AND(a1, b2)  → 2 when a=1,b=2
* OR them → carry_pre (0 or 2)
* Scale by 0.5 → CARRY (0 or 0.45V = Logic 1 when active)
*------------------------------------------------------
XAND_a2b1  a2  b1  p_a2b1  Vdd  Gnd  TAND_sub
XAND_a1b2  a1  b2  p_a1b2  Vdd  Gnd  TAND_sub

XORC1  p_a2b1  p_a2b2  carry_ab  Vdd  Gnd  TOR_sub
XORC2  carry_ab  p_a1b2  carry_pre  Vdd  Gnd  TOR_sub

* Scale Logic-2 → Logic-1
R3  carry_pre  carry_out  50k
R4  carry_out  Gnd  50k

CL_carry  carry_out  Gnd  2.0fF

*======================================================
* INPUT STIMULUS
* Test all 9 combinations of ternary inputs a and b
*
* Time schedule (each input combination held for 1.5ns):
*   0.0 -1.5ns:  a=0(0V),    b=0(0V)    → Sum=0, Carry=0
*   1.5 -3.0ns:  a=0(0V),    b=1(0.45V) → Sum=1, Carry=0
*   3.0 -4.5ns:  a=0(0V),    b=2(0.9V)  → Sum=2, Carry=0
*   4.5 -6.0ns:  a=1(0.45V), b=0(0V)    → Sum=1, Carry=0
*   6.0 -7.5ns:  a=1(0.45V), b=1(0.45V) → Sum=2, Carry=0
*   7.5 -9.0ns:  a=1(0.45V), b=2(0.9V)  → Sum=0, Carry=1
*   9.0 -10.5ns: a=2(0.9V),  b=0(0V)    → Sum=2, Carry=0
*   10.5-12.0ns: a=2(0.9V),  b=1(0.45V) → Sum=0, Carry=1
*   12.0-13.5ns: a=2(0.9V),  b=2(0.9V)  → Sum=1, Carry=1
*======================================================

Va  a  Gnd  PWL(
+ 0.0n    0.0
+ 1.5n    0.0
+ 1.51n   0.0
+ 3.0n    0.0
+ 3.01n   0.0
+ 4.5n    0.0
+ 4.51n   0.45
+ 6.0n    0.45
+ 6.01n   0.45
+ 7.5n    0.45
+ 7.51n   0.45
+ 9.0n    0.45
+ 9.01n   0.9
+ 10.5n   0.9
+ 10.51n  0.9
+ 12.0n   0.9
+ 12.01n  0.9
+ 13.5n   0.9
+ )

Vb  b  Gnd  PWL(
+ 0.0n    0.0
+ 1.5n    0.0
+ 1.51n   0.45
+ 3.0n    0.45
+ 3.01n   0.9
+ 4.5n    0.9
+ 4.51n   0.0
+ 6.0n    0.0
+ 6.01n   0.45
+ 7.5n    0.45
+ 7.51n   0.9
+ 9.0n    0.9
+ 9.01n   0.0
+ 10.5n   0.0
+ 10.51n  0.45
+ 12.0n   0.45
+ 12.01n  0.9
+ 13.5n   0.9
+ )

.tran  1p  13.5n

*======================================================
* FUNCTIONAL VERIFICATION MEASUREMENTS
* Measure average output at midpoint of each input combination
* Expected: Sum and Carry voltages per truth table
* Logic 0=0V, Logic 1=0.45V, Logic 2=0.9V
*======================================================

* a=0,b=0: Sum=0(0V),   Carry=0(0V)
.MEASURE TRAN sum_00    AVG V(sum_out)   FROM=0.5n   TO=1.3n
.MEASURE TRAN carry_00  AVG V(carry_out) FROM=0.5n   TO=1.3n

* a=0,b=1: Sum=1(0.45V), Carry=0(0V)
.MEASURE TRAN sum_01    AVG V(sum_out)   FROM=2.0n   TO=2.8n
.MEASURE TRAN carry_01  AVG V(carry_out) FROM=2.0n   TO=2.8n

* a=0,b=2: Sum=2(0.9V),  Carry=0(0V)
.MEASURE TRAN sum_02    AVG V(sum_out)   FROM=3.5n   TO=4.3n
.MEASURE TRAN carry_02  AVG V(carry_out) FROM=3.5n   TO=4.3n

* a=1,b=0: Sum=1(0.45V), Carry=0(0V)
.MEASURE TRAN sum_10    AVG V(sum_out)   FROM=5.0n   TO=5.8n
.MEASURE TRAN carry_10  AVG V(carry_out) FROM=5.0n   TO=5.8n

* a=1,b=1: Sum=2(0.9V),  Carry=0(0V)
.MEASURE TRAN sum_11    AVG V(sum_out)   FROM=6.5n   TO=7.3n
.MEASURE TRAN carry_11  AVG V(carry_out) FROM=6.5n   TO=7.3n

* a=1,b=2: Sum=0(0V),    Carry=1(0.45V)
.MEASURE TRAN sum_12    AVG V(sum_out)   FROM=8.0n   TO=8.8n
.MEASURE TRAN carry_12  AVG V(carry_out) FROM=8.0n   TO=8.8n

* a=2,b=0: Sum=2(0.9V),  Carry=0(0V)
.MEASURE TRAN sum_20    AVG V(sum_out)   FROM=9.5n   TO=10.3n
.MEASURE TRAN carry_20  AVG V(carry_out) FROM=9.5n   TO=10.3n

* a=2,b=1: Sum=0(0V),    Carry=1(0.45V)
.MEASURE TRAN sum_21    AVG V(sum_out)   FROM=11.0n  TO=11.8n
.MEASURE TRAN carry_21  AVG V(carry_out) FROM=11.0n  TO=11.8n

* a=2,b=2: Sum=1(0.45V), Carry=1(0.45V)
.MEASURE TRAN sum_22    AVG V(sum_out)   FROM=12.5n  TO=13.3n
.MEASURE TRAN carry_22  AVG V(carry_out) FROM=12.5n  TO=13.3n

*------------------------------------------------------
* Propagation delay measurements (paper reports 4 switching delays)
* We measure single-input transitions where only one input changes.
* Since 'b' is the fast inner loop in our PWL, we trigger on 'b'.
*------------------------------------------------------
* t1: at 7.51ns, a=0.45V, b transitions 0.45V -> 0.9V.
*     Sum transitions from Logic 2 (0.9V) to Logic 0 (0V).
.MEASURE TRAN t1_sum  TRIG V(b)  VAL=0.675  TD=7.0n  RISE=1
+                     TARG V(sum_out) VAL=0.45   FALL=1

* t2: at 10.51ns, a=0.9V, b transitions 0V -> 0.45V.
*     Sum transitions from Logic 2 (0.9V) to Logic 0 (0V).
.MEASURE TRAN t2_sum  TRIG V(b)  VAL=0.225   TD=10.0n  RISE=1
+                     TARG V(sum_out) VAL=0.45  FALL=1

*------------------------------------------------------
* Average Power Dissipation
*------------------------------------------------------
.MEASURE TRAN avg_pow AVG POWER FROM=0n TO=13.5n

.probe V(a)
.probe V(b)
.probe V(sum_out)
.probe V(carry_out)
.probe V(a0)
.probe V(a1)
.probe V(a2)
.probe V(b0)
.probe V(b1)
.probe V(b2)

.OPTION PROBE POST MEASOUT
.end

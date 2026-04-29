******************************************************
* GNRFET Ternary Full Adder (Optimized Custom 3-Input Gates)
* Paper: "Design of ternary logic gates and circuits using GNRFETs"
*
* NOVEL OPTIMIZATION NOTE:
* To prevent the massive transistor count (>1000) and poor propagation
* delay of cascading 2-input gates, this implementation scales the authors'
* diode-clamped GNRFET topologies into custom 3-input MIN (TAND3) and
* 3-input MAX (TOR3) gates. It also introduces an active transistor
* multiplexer output stage to resolve physical voltage contention 
* at the SUM and CARRY nodes.
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
* 1. CORE TERNARY SUBCIRCUITS
*======================================================

* --- NTI (Negative Ternary Inverter) ---
.subckt NTI_sub  in  out  vdd  gnd
XN  gnd  in  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP  vdd  in  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends NTI_sub

* --- PTI (Positive Ternary Inverter) ---
.subckt PTI_sub  in  out  vdd  gnd
XN  gnd  in  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP  vdd  in  out  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends PTI_sub

* --- TNOR (2-input Ternary NOR) ---
.subckt TNOR_sub  in1  in2  out  vdd  gnd
XN1  gnd  in1  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  gnd  in2  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  out  out  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  gnd  in2  out  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP1  vdd  in1  ps1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  ps1  in2  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  out  out  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  ps2  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  ps2  in2  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TNOR_sub

* --- TOR (2-input Ternary OR = TNOR + NTI) ---
.subckt TOR_sub in1 in2 out vdd gnd
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
XN6  gnd  nr1  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP6  vdd  nr1  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TOR_sub

* --- TAND3 (Custom 3-input Ternary AND) ---
.subckt TAND3_sub in1 in2 in3 out vdd gnd
XN1  gnd  in1  na1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  na1  in2  na2  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2b na2  in3  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  nd1  nd1  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  na3  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  na3  in2  na4  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5b na4  in3  nd1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP1  vdd  in1  nd1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  vdd  in2  nd1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2b vdd  in3  nd1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  nd1  nd1  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  vdd  in2  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5b vdd  in3  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN6  gnd  nd1  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP6  vdd  nd1  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TAND3_sub

* --- TOR3 (Custom 3-input Ternary OR) ---
.subckt TOR3_sub in1 in2 in3 out vdd gnd
XN1  gnd  in1  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2  gnd  in2  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN2b gnd  in3  nm1  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN3  nm1  nr1  nr1  gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN4  gnd  in1  nr1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5  gnd  in2  nr1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN5b gnd  in3  nr1  gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP1  vdd  in1  ps1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2  ps1  in2  ps1b vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP2b ps1b in3  nr1  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP3  pm1  nr1  nr1  vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP4  vdd  in1  ps2  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5  ps2  in2  ps2b vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP5b ps2b in3  pm1  vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XN6  gnd  nr1  out  gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
XP6  vdd  nr1  out  vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0
.ends TOR3_sub

* --- TDEC (Ternary Decoder) ---
.subckt TDEC_sub in dec0 dec1 dec2 vdd gnd
XNTI_0  in  dec0  vdd  gnd  NTI_sub
XPTI_1  in  pa_int  vdd  gnd  PTI_sub
XNTI_2  pa_int  dec2  vdd  gnd  NTI_sub
XNOR_1  dec0  dec2  dec1  vdd  gnd  TNOR_sub
.ends TDEC_sub

*======================================================
* 2. TERNARY FULL ADDER MODULE
*======================================================
.subckt TERNARY_FULL_ADDER A B C SUM CARRY VDD GND

* Decoders
XDECA A a0 a1 a2 Vdd Gnd TDEC_sub
XDECB B b0 b1 b2 Vdd Gnd TDEC_sub
XDECC C c0 c1 c2 Vdd Gnd TDEC_sub

*------------------------------------------------------
* SUM LOGIC 2 TERMS: 9 terms
* a2b0c0, a1b0c1, a0b0c2, a1b1c0, a0b1c1, a2b1c2, a0b2c0, a2b2c1, a1b2c2
*------------------------------------------------------
XAND_S2_1 a2 b0 c0 s2_1 Vdd Gnd TAND3_sub
XAND_S2_2 a1 b0 c1 s2_2 Vdd Gnd TAND3_sub
XAND_S2_3 a0 b0 c2 s2_3 Vdd Gnd TAND3_sub
XAND_S2_4 a1 b1 c0 s2_4 Vdd Gnd TAND3_sub
XAND_S2_5 a0 b1 c1 s2_5 Vdd Gnd TAND3_sub
XAND_S2_6 a2 b1 c2 s2_6 Vdd Gnd TAND3_sub
XAND_S2_7 a0 b2 c0 s2_7 Vdd Gnd TAND3_sub
XAND_S2_8 a2 b2 c1 s2_8 Vdd Gnd TAND3_sub
XAND_S2_9 a1 b2 c2 s2_9 Vdd Gnd TAND3_sub

XOR_S2_A s2_1 s2_2 s2_3 s2_a Vdd Gnd TOR3_sub
XOR_S2_B s2_4 s2_5 s2_6 s2_b Vdd Gnd TOR3_sub
XOR_S2_C s2_7 s2_8 s2_9 s2_c Vdd Gnd TOR3_sub
XOR_S2_FINAL s2_a s2_b s2_c sum2_terms Vdd Gnd TOR3_sub

*------------------------------------------------------
* SUM LOGIC 1 TERMS: 9 terms
* a1b0c0, a0b0c1, a2b0c2, a0b1c0, a2b1c1, a1b1c2, a2b2c0, a1b2c1, a0b2c2
*------------------------------------------------------
XAND_S1_1 a1 b0 c0 s1_1 Vdd Gnd TAND3_sub
XAND_S1_2 a0 b0 c1 s1_2 Vdd Gnd TAND3_sub
XAND_S1_3 a2 b0 c2 s1_3 Vdd Gnd TAND3_sub
XAND_S1_4 a0 b1 c0 s1_4 Vdd Gnd TAND3_sub
XAND_S1_5 a2 b1 c1 s1_5 Vdd Gnd TAND3_sub
XAND_S1_6 a1 b1 c2 s1_6 Vdd Gnd TAND3_sub
XAND_S1_7 a2 b2 c0 s1_7 Vdd Gnd TAND3_sub
XAND_S1_8 a1 b2 c1 s1_8 Vdd Gnd TAND3_sub
XAND_S1_9 a0 b2 c2 s1_9 Vdd Gnd TAND3_sub

XOR_S1_A s1_1 s1_2 s1_3 s1_a Vdd Gnd TOR3_sub
XOR_S1_B s1_4 s1_5 s1_6 s1_b Vdd Gnd TOR3_sub
XOR_S1_C s1_7 s1_8 s1_9 s1_c Vdd Gnd TOR3_sub
XOR_S1_FINAL s1_a s1_b s1_c sum1_pre Vdd Gnd TOR3_sub

*------------------------------------------------------
* CARRY LOGIC 2 TERM: 1 term
* a2b2c2
*------------------------------------------------------
XAND_C2_1 a2 b2 c2 carry2_terms Vdd Gnd TAND3_sub

*------------------------------------------------------
* CARRY LOGIC 1 TERMS: 16 terms
* a2b1c0, a2b2c0, a0b2c1, a1b1c1, a1b2c1, a2b0c1, a2b1c1, a2b2c1
* a0b2c2, a1b0c2, a1b1c2, a1b2c2, a2b0c2, a2b1c2, a0b1c2, a1b2c0
*------------------------------------------------------
XAND_C1_1  a2 b1 c0 c1_1 Vdd Gnd TAND3_sub
XAND_C1_2  a2 b2 c0 c1_2 Vdd Gnd TAND3_sub
XAND_C1_3  a0 b2 c1 c1_3 Vdd Gnd TAND3_sub
XAND_C1_4  a1 b1 c1 c1_4 Vdd Gnd TAND3_sub
XAND_C1_5  a1 b2 c1 c1_5 Vdd Gnd TAND3_sub
XAND_C1_6  a2 b0 c1 c1_6 Vdd Gnd TAND3_sub
XAND_C1_7  a2 b1 c1 c1_7 Vdd Gnd TAND3_sub
XAND_C1_8  a2 b2 c1 c1_8 Vdd Gnd TAND3_sub
XAND_C1_9  a0 b2 c2 c1_9 Vdd Gnd TAND3_sub
XAND_C1_10 a1 b0 c2 c1_10 Vdd Gnd TAND3_sub
XAND_C1_11 a1 b1 c2 c1_11 Vdd Gnd TAND3_sub
XAND_C1_12 a1 b2 c2 c1_12 Vdd Gnd TAND3_sub
XAND_C1_13 a2 b0 c2 c1_13 Vdd Gnd TAND3_sub
XAND_C1_14 a2 b1 c2 c1_14 Vdd Gnd TAND3_sub
XAND_C1_15 a0 b1 c2 c1_15 Vdd Gnd TAND3_sub
XAND_C1_16 a1 b2 c0 c1_16 Vdd Gnd TAND3_sub

XOR_C1_A c1_1 c1_2 c1_3 c1_a Vdd Gnd TOR3_sub
XOR_C1_B c1_4 c1_5 c1_6 c1_b Vdd Gnd TOR3_sub
XOR_C1_C c1_7 c1_8 c1_9 c1_c Vdd Gnd TOR3_sub
XOR_C1_D c1_10 c1_11 c1_12 c1_d Vdd Gnd TOR3_sub
XOR_C1_E c1_13 c1_14 c1_15 c1_e Vdd Gnd TOR3_sub

XOR_C1_F c1_a c1_b c1_c c1_f Vdd Gnd TOR3_sub
XOR_C1_G c1_d c1_e c1_16 c1_g Vdd Gnd TOR3_sub
XOR_C1_FINAL c1_f c1_g carry1_pre Vdd Gnd TOR_sub

*------------------------------------------------------
* OUTPUT MULTIPLEXERS (Contention-Free Design)
* Resolves short-circuit issues present in naive Wired-OR
*------------------------------------------------------
V_half  half_vdd  Gnd  DC  0.45

* SUM Multiplexer
XNTI_sum2  sum2_terms  sum2_inv  Vdd  Gnd  NTI_sub
XNTI_sum1  sum1_pre    sum1_inv  Vdd  Gnd  NTI_sub

XP_sum2  Vdd  sum2_inv  SUM  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XP_sum1  half_vdd  sum1_inv  SUM  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XN_sum_pd1  Gnd  sum2_inv  sum_mid_pd  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XN_sum_pd2  sum_mid_pd  sum1_inv  SUM  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
CL_sum  SUM  Gnd  2.0fF

* CARRY Multiplexer
XNTI_cry2  carry2_terms  carry2_inv  Vdd  Gnd  NTI_sub
XNTI_cry1  carry1_pre    carry1_inv  Vdd  Gnd  NTI_sub

XP_cry2  Vdd  carry2_inv  CARRY  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XP_cry1  half_vdd  carry1_inv  CARRY  Vdd  gnrfetpmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XN_cry_pd1  Gnd  carry2_inv  cry_mid_pd  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
XN_cry_pd2  cry_mid_pd  carry1_inv  CARRY  Gnd  gnrfetnmos nRib=15 n=12 L=32n Tox=0.95n sp=2n dop=0.001 p=0
CL_cry  CARRY  Gnd  2.0fF

.ends TERNARY_FULL_ADDER

*======================================================
* 3. TOP-LEVEL TESTBENCH
*======================================================
XDUT  A  B  C  SUM  CARRY  Vdd  Gnd  TERNARY_FULL_ADDER

VA  A  Gnd  PWL(
+  0ns    0.0V
+  1ns    0.0V    2ns  0.0V
+  2ns    0.45V   3ns  0.45V
+  3ns    0.9V    4ns  0.9V
+  4ns    0.0V    5ns  0.0V
+  5ns    0.0V    6ns  0.0V
+  6ns    0.45V   7ns  0.45V
+  7ns    0.9V    8ns  0.9V
+  8ns    0.0V    9ns  0.0V
+  9ns    0.45V  10ns  0.45V
+ 10ns    0.9V   11ns  0.9V
+ 11ns    0.0V   12ns  0.0V
+ 12ns    0.0V   13ns  0.0V
+ 13ns    0.45V  14ns  0.45V
+ 14ns    0.9V   15ns  0.9V
+ 15ns    0.0V   16ns  0.0V
+ 16ns    0.45V  17ns  0.45V
+ 17ns    0.9V   18ns  0.9V
+ 18ns    0.0V   19ns  0.0V
+ 19ns    0.0V   20ns  0.0V
+ 20ns    0.45V  21ns  0.45V
+ 21ns    0.9V   22ns  0.9V
+ 22ns    0.0V   23ns  0.0V
+ 23ns    0.45V  24ns  0.45V
+ 24ns    0.9V   25ns  0.9V
+ 25ns    0.0V   26ns  0.0V
+ 26ns    0.45V  27ns  0.45V)

VB  B  Gnd  PWL(
+  0ns    0.0V    1ns  0.0V
+  1ns    0.0V    2ns  0.0V
+  2ns    0.0V    3ns  0.0V
+  3ns    0.45V   4ns  0.45V
+  4ns    0.45V   5ns  0.45V
+  5ns    0.45V   6ns  0.45V
+  6ns    0.9V    7ns  0.9V
+  7ns    0.9V    8ns  0.9V
+  8ns    0.9V    9ns  0.9V
+  9ns    0.0V   10ns  0.0V
+ 10ns    0.0V   11ns  0.0V
+ 11ns    0.0V   12ns  0.0V
+ 12ns    0.45V  13ns  0.45V
+ 13ns    0.45V  14ns  0.45V
+ 14ns    0.45V  15ns  0.45V
+ 15ns    0.9V   16ns  0.9V
+ 16ns    0.9V   17ns  0.9V
+ 17ns    0.9V   18ns  0.9V
+ 18ns    0.0V   19ns  0.0V
+ 19ns    0.0V   20ns  0.0V
+ 20ns    0.0V   21ns  0.0V
+ 21ns    0.45V  22ns  0.45V
+ 22ns    0.45V  23ns  0.45V
+ 23ns    0.45V  24ns  0.45V
+ 24ns    0.9V   25ns  0.9V
+ 25ns    0.9V   26ns  0.9V
+ 26ns    0.9V   27ns  0.9V)

VC  C  Gnd  PWL(
+  0ns    0.0V    3ns  0.0V
+  3ns    0.0V    6ns  0.0V
+  6ns    0.0V    9ns  0.0V
+  9ns    0.45V  12ns  0.45V
+ 12ns    0.45V  15ns  0.45V
+ 15ns    0.45V  18ns  0.45V
+ 18ns    0.9V   21ns  0.9V
+ 21ns    0.9V   24ns  0.9V
+ 24ns    0.9V   27ns  0.9V)

.option POST ACCURATE
.option SCALE=1e-9
.option CAPTAB

.tran 1ps 27ns

.meas tran t1_rise TRIG v(A) VAL=0.225 RISE=1
+               TARG v(SUM) VAL=0.225 RISE=1

.meas tran t2_fall TRIG v(B) VAL=0.675 FALL=1
+               TARG v(SUM) VAL=0.675 FALL=1

.meas tran avg_power AVG POWER FROM=0ns TO=27ns

.print tran v(A) v(B) v(C) v(SUM) v(CARRY)
.end

******************************************************
* GNRFET Positive Ternary Inverter (PTI) — DC Sweep
* Purpose: Generate VTC curve (Fig. 8 in paper)
* Expected: 2-plateau curve — HIGH at Logic 0 and 1, LOW at Logic 2
*   0V to ~0.43V input  -> OUT stays at 0.9V
*   ~0.43V to 0.9V input -> OUT falls to 0V
******************************************************

.options POST
.options INGOLD=2     DCON=1
.options GSHUNT=1e-12 RMIN=1e-15
.options ABSTOL=1e-5  ABSVDC=1e-4
.options RELTOL=1e-2  RELVDC=1e-2
.options NUMDGT=4     PIVOT=13
.param   TEMP=27

.lib 'gnrfet.lib' GNRFET

VVdd  Vdd  Gnd  DC  0.9

* T1: NMOS n=6, Vth=+0.43V
X1  Gnd  in   out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: PMOS n=12, Vth=-0.23V
X2  Vdd  in   out  Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

CL  out  Gnd  1.0fF

Vin  in  Gnd  DC  0

.dc Vin 0 0.9 0.001

.probe V(in)
.probe V(out)

.OPTION PROBE POST
.end

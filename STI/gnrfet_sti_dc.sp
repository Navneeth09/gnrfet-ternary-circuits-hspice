******************************************************
* GNRFET Standard Ternary Inverter (STI) — DC Sweep
* Purpose: Generate VTC curve (Fig. 8 in paper)
* Expected: 3-plateau S-curve at 0V, 0.45V, 0.9V
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

*------------------------------------------------------
* STI Circuit — 6 transistors (identical to transient file)
*------------------------------------------------------

* T1: NMOS n=12, Vth=+0.23V
* T1: NMOS n=12, ns=Gnd, ng=in, nd=n1, nb=Gnd
X1  Gnd  in   n1   Gnd  gnrfetnmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T2: NMOS n=9, diode (gate tied to drain=out)
* ns=n1, ng=out, nd=out, nb=Gnd
X2  n1   out  out  Gnd  gnrfetnmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T3: NMOS n=6, ns=Gnd, ng=in, nd=out, nb=Gnd
X3  Gnd  in   out  Gnd  gnrfetnmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T4: PMOS n=9, diode (gate tied to drain=out)
* ns=p1, ng=out, nd=out, nb=Vdd
X4  p1   out  out  Vdd  gnrfetpmos  nRib=15  n=9   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T5: PMOS n=12, Vth=-0.23V
X5  Vdd  in   p1   Vdd  gnrfetpmos  nRib=15  n=12  L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* T6: PMOS n=6, Vth=-0.43V
X6  Vdd  in   out  Vdd  gnrfetpmos  nRib=15  n=6   L=32n  Tox=0.95n  sp=2n  dop=0.001  p=0

* Load capacitor
CL  out  Gnd  3.0fF

*------------------------------------------------------
* DC Input Source — Vin declared as DC for sweep
*------------------------------------------------------
Vin  in  Gnd  DC  0

*------------------------------------------------------
* DC Sweep: sweep Vin from 0V to 0.9V in 1mV steps
*------------------------------------------------------
.dc Vin 0 0.9 0.001

*------------------------------------------------------
* Probes
*------------------------------------------------------
.probe V(in)
.probe V(out)
.probe V(n1)
.probe V(p1)

.OPTION PROBE POST
.end

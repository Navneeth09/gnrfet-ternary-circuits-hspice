# GNRFET-Based Ternary Logic Circuits (HSPICE)

HSPICE-based implementation and validation of GNRFET-based ternary logic circuits including inverters, logic gates, decoder, and arithmetic units.

---

## 📌 Overview

Conventional digital systems use binary logic, which leads to increased transistor count and interconnect complexity at nanoscale technologies. Multi-Valued Logic (MVL), particularly ternary logic, offers an efficient alternative by representing more information per digit.

This work implements ternary logic circuits using Graphene Nanoribbon Field Effect Transistors (GNRFETs), which provide tunable threshold voltage and improved electrical characteristics suitable for MVL design.

---

## 🎯 Contribution

- Implemented GNRFET-based ternary logic circuits using HSPICE  
- Designed and simulated inverters, logic gates, decoder, and arithmetic circuits  
- Verified functionality through transient and DC analysis  
- Reproduced and validated results from existing research literature  

---

## ⚙️ Implemented Circuits

The following ternary circuits are designed and simulated:

### 🔹 Ternary Inverters
- Standard Ternary Inverter (STI)  
- Positive Ternary Inverter (PTI)  
- Negative Ternary Inverter (NTI)  

### 🔹 Universal Logic Gates
- Ternary NAND  
- Ternary NOR  

### 🔹 Arithmetic Circuits
- Ternary Half Adder  
- Ternary Full Adder {still working}

### 🔹 Other Circuits
- Ternary Decoder  

---

## 🧪 Simulation Details

- **Tool Used:** HSPICE  
- **Device Model:** GNRFET SPICE Model (UIUC)  
- **Logic Levels:**
  - Logic 0 → 0 V  
  - Logic 1 → VDD/2  
  - Logic 2 → VDD  

All circuits are verified using transient and DC simulations.

---

## 📁 Repository Structure
gnrfet-ternary-circuits-hspice/
│
├── STI/
├── PTI/
├── NTI/
├── TNAND/
├── TNOR/
├── DECODER/
├── HALF ADDER/
├── FULL ADDER/
│
├── Required Library Files/
├── Report.pdf
├── Reference Paper.pdf


---

## 📚 Reference

This work is based on the following research paper:

> B. D. Madhuri and S. Sunithamani,  
> *“Design of ternary logic gates and circuits using GNRFETs,”*  
> IET Circuits, Devices & Systems, 2020.

The circuit architectures and theoretical formulations are derived from this work. This repository focuses on independent HSPICE-based implementation and validation.

---

## ⚠️ Note

This project is intended for educational and research purposes.  
All credit for the original design concepts belongs to the referenced authors.

---

## 🚀 Future Work

- Power and delay optimization of ternary circuits  
- Layout-level implementation using Cadence/Virtuoso  
- Exploration of MVL architectures for digital systems  

---

## 👤 Author

**Kundrapu Navneeth**  
B.Tech in Electronics and Communication Engineering  
IIIT Naya Raipur  

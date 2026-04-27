---
layout: page
title: CV
permalink: 
---

# Curriculum Vitae

## 👤 Summary

Formal methods researcher and hardware verification engineer with a Ph.D. in Computer Science (IIT Bombay) and 3+ years of industrial formal verification experience. Deep expertise spanning model checking theory, theorem proving, and assertion-based RTL verification — including C++ implementation of reachability solvers for multi-pushdown systems and industrial sign-off experience on RISC-V and PCIe Gen5 designs using JasperGold and VC Formal. Recognized with a Best Paper award (Jasper User Group India 2024), a patent filing in formal model extraction, and peer-reviewed publications at TACAS and FSTTCS. Experienced in bridging the gap between formal proof and simulation through hybrid verification frameworks integrating Lean4 theorem proving with dynamic testbenches.

---

## 💼 Experience

#### Senior Verification Engineer — *Ubitium, Germany* (Dec 2025 – Present)

- Leading the verification strategy for a RISC-V based universal processor, defining methodology across formal and simulation domains.
- Designed and implemented a hybrid verification framework combining Lean4 formally verified golden models with cocotb simulation testbenches and Hypothesis stateful property-based testing.
- Developed Lean4 formal models for RTL designs (address generation unit, ALU, bit-reversal unit), exposed via C FFI to Python testbenches for automated equivalence checking against the DUT.
- Formalized IEEE 754 floating-point arithmetic (Float32/Float64) in Lean4, including correctness properties, using structured case decomposition.
- Architected a modular, TOML-driven regression infrastructure with pytest auto-discovery, a shared common library, and a single-command pipeline from Lean4 compilation through RTL elaboration to simulation sign-off.

#### Formal Verification Engineer — *LUBIS EDA, Germany* (Jun 2025 – Dec 2025)

- Led formal sign-off for the RISC-V Floating Point extension using FPV and DPV flows.
- Developed reusable SystemVerilog assertion templates and checkers for execution units and memory abstractions.

#### Postdoctoral Research Assistant — *TU Clausthal, Germany* (Oct 2024 – May 2025)

- Designed correct-by-construction RTL modules for a RISC-V softcore and implemented them on FPGA.
- Collaborated with international research teams on microarchitecture design and formal verification methodology.

#### Formal Verification Engineer — *Intel, India* (Apr 2022 – Jul 2024)

- Verified PCIe Gen5, GCM-AES, and execution unit RTL using RTL2RTL and C2RTL formal flows.
- Pioneered and led firmware formal verification methodology across the team; authored best practices adopted org-wide.
- Drove formal testbench planning, property coverage closure, and deep bug hunting across security-critical IP blocks.
- Established a CI/CD pipeline for the formal verification flow, enabling continuous firmware regression at scale.
- Filed patent for a semi-automated formal model extraction tool for firmware verification (PGPub: US20240126967A1).

---

## 🛠 Key Projects

- ** Universal Processor verification (Ubitium):** A hybrid hardware verification framework integrating Lean4 formally verified golden models with cocotb/Hypothesis simulation testbenches. Proof and simulation share the same model via FFI — when the testbench finds a mismatch, the RTL is wrong, not the reference.
- **Emptiness Checker for Multi-Pushdown Systems (IIT Bombay PhD):** C++ implementation of underapproximate reachability algorithms for multi-pushdown systems. Work published at TACAS 2020.
- **Firmware and Execution Unit Verification (Intel):** Formally verified firmware and RTL designs including GCM-AES encryption and PCIe Gen5 using C2RTL/RTL2RTL equivalence flows.
- **Correct-by-Construction FPGA Hardware (TU Clausthal):** Correct-by-construction FPGA modules using reactive synthesis and formal specifications targeting reliability in hardware systems.

---

## 🧠 Skills

- **Formal Methods:** Model checking, theorem proving, equivalence checking, reachability analysis, FPV, DPV
- **FV Tools:** JasperGold, VC Formal, Lean4,  UPPAAL, Onespin, Spin, Kind2, Strix
- **Languages:** C/C++, SystemVerilog (SVA), Python, Haskell, TCL
- **Simulation & DV:** cocotb, Hypothesis (property-based testing), Questa/ModelSim
- **Algorithms:** Pushdown systems, timed automata, stochastic games, SAT/SMT-based solvers
- **Engineering:** git, Make/CMake, CI/CD pipelines, pytest, FPGA implementation

---

## 🏆 Achievements

- **Best Paper Award** — Jasper User Group India 2024
- **Patent Pending** — Semi-Automatic Tool to Create Formal Verification Models (PGPub: US20240126967A1)
- **DVCon Author** — "Pioneering Software Formal Verification Methodology for Firmware" (2024)
- **TCS Research Fellowship** — IIT Bombay

---

## 📚 Publications

1. ["Pioneering Software Formal Verification Methodology for Firmware"]() — DVCon India 2024
2. ["Revisiting Underapproximate Reachability for Multipushdown Systems"](https://link.springer.com/chapter/10.1007/978-3-030-45190-5_21) — TACAS 2020
3. ["1½-Player Stochastic StopWatch Games"](https://drops.dagstuhl.de/opus/volltexte/2021/14793/) — TIME 2021
4. ["Resilience of Timed Systems"](https://drops.dagstuhl.de/opus/volltexte/2021/15544/) — FSTTCS 2021

---

## 🎓 Education

- **Ph.D. in Computer Science** — *Indian Institute of Technology Bombay, India*
- **M.E. in Computer Science** — *Indian Institute of Engineering Science and Technology Shibpur, India*
- **B.Tech. in Information Technology** — *RCC Institute of Technology, Kolkata, India*

---

## 🧾 References

Available upon request:

- Prof. Krishna S. (IIT Bombay, Mumbai, India)
- Disha Puri (Synopsys, Bengaluru, India)
- Aravind Shivkumar (Western Digital, USA)

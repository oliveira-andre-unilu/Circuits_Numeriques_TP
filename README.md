# Circuits Numeriques TP: Final TP

<p align="center">
  <img src="DOCS/university_logo.png" alt="University Logo" width="150"/>
</p>

**Course:** Digital Circuits – Microprocessor TP 2025  
**University:** University Of Luxembourg 

**Students:**  
- André MARTINS – ID: 0230991223  
- Leonardo SOUSA – ID: 0232412758  

**Instructor:** Prof. STEENIS Bernard 

---

This repository contains the VHDL implementation of a simple 8-bit CPU system, including memory and an input/output interface, designed to run on the **Basys3 FPGA board**. The project was developed as part of a digital circuits lab (TP) to gain hands-on experience in **synchronous digital design**, memory-mapped I/O, and FPGA implementation.

## Project Overview

The system follows a **Von Neumann architecture** and includes:

- **CPU:** Implements a small instruction set with arithmetic, logic, data transfer, and conditional jump instructions. Instruction sequencing is managed by a finite state machine.
- **Memory:** Stores instructions, data, and a small BIOS for program initialization.
- **Interface:** Connects the CPU to external peripherals (switches, buttons, LEDs, 7-segment display) using memory-mapped I/O.

The top-level module (`top.vhd`) integrates these components and exposes the necessary signals to the Basys3 board. The system is fully synchronous, and clocked logic ensures reliable operation of all modules.

## Repository Structure

├── README.md  
├── Assets/  
│ ├── Device Architecture Images/  
│ └── bitStreamTPFinalExport.bit  
├── SRC/  
│ ├── cpu.vhd  
│ ├── memory.vhd  
│ ├── interface.vhd  
│ ├── top.vhd  
│ └── top.xdc  
└── TB/  
  └── testbench.vhd    

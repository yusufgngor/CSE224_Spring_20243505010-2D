# Register File & ALU Design (P4)

## Project Overview

This project implements a Register File and ALU module integrated into a top-level module. The design demonstrates the basic building blocks of a CPU, focusing on the data path components that handle register storage and arithmetic/logic operations.

## Features

- **32-bit Register File**:
  - 32 general-purpose registers
  - Dual read ports (A1, A2)
  - Single write port (A3)
  - Write enable control signal (WE3)

- **ALU (Arithmetic Logic Unit)**:
  - Supports 4 operations:
    - ADD (opcode 00): Addition
    - SUB (opcode 01): Subtraction 
    - SHIFTL (opcode 10): Left shift
    - SHIFTR (opcode 11): Right shift
  - 32-bit data path width

- **Top Module Integration**:
  - Connect ALU output to Register File input
  - External observation ports for register data and ALU results
  - System clock integration

## Diagram

![P4 Design Layout](image.png)

## Physical Implementation

The design was synthesized, placed and routed using the OpenLane flow with the Sky130 PDK. The implementation includes:

- Die Area: 1500 x 1800 µm
- Core Utilization: 20%
- Target Density: 0.2
- Clock Period: 10 ns

## Module Hierarchy

```
p4 (top_module)
├── register_file
└── alu
```

## Technical Specifications

- Clock frequency: 100 MHz
- Power Domain: Single power domain
- Technology: SKY130 (130nm)
- Design optimization: Area and power focused

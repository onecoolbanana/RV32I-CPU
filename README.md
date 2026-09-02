# RV32I CPU — Single-Cycle & Pipelined Implementations

A RISC-V RV32I CPU implemented two ways: a single-cycle design and a 5-stage pipelined design with hazard detection and forwarding. Both were originally prototyped in Logisim Evolution and converted to Verilog for simulation and eventual FPGA deployment on an Altera Max 10 FPGA.

---

## Repository Structure

```
Verilog/
├── Single-Cycle/
│   ├── alu.v
│   ├── decode.v
│   ├── regfile.v
│   ├── pc_control.v
│   ├── imem.v
│   ├── dmem.v
│   └── cpu.v
├── Pipelined/
│   ├── alu.v
│   ├── decode.v
│   ├── regfile.v
│   ├── pc_control.v
│   ├── imem.v
│   ├── dmem.v
│   ├── jump_calc.v
│   ├── forwarding_unit.v
│   ├── hazard.v
│   ├── if_id_reg.v
│   ├── id_ex_reg.v
│   ├── ex_mem_reg.v
│   ├── mem_wb_reg.v
│   ├── cpu_pipelined.v
│   └── testbenches.v
```

---

# Single-Cycle CPU

A fully functional RISC-V RV32I single-cycle CPU.

## Architecture Overview

- **ISA**: RISC-V RV32I (32-bit, 32 registers)
- **Design**: Single-cycle (no pipelining)
- **Memory architecture**: Harvard (separate instruction and data memory)
- **Addressing**: Byte-addressed, word-wide memory (each memory location holds one 32-bit word)
- **Instruction memory**: 4KB ROM (1024 × 32-bit words)
- **Data memory**: 4KB RAM (1024 × 32-bit words)
- **Simulator**: Icarus Verilog + GTKWave

---

## Implemented Instructions

| Category        | Instructions                                         |
| ---------------- | ----------------------------------------------------- |
| R-type ALU       | add, sub, sll, srl, sra, slt, sltu, xor, or, and      |
| I-type ALU       | addi, slti, sltiu, xori, ori, andi, slli, srli, srai  |
| Loads             | lw, lh, lb, lhu, lbu                                  |
| Stores            | sw, sh, sb                                            |
| Branches          | beq, bne, blt, bge, bltu, bgeu                        |
| Jumps             | jal, jalr                                             |
| Upper immediate   | lui, auipc                                            |

---

## Key Design Decisions

### ALU
- Takes `funct3` and `funct7` directly as inputs rather than a decoded ALU opcode
- `funct7` is masked to `0000000` for all non-R-type instructions to prevent immediate bits being misread as `funct7` — this was a critical bug discovered during development
- `forceADD` signal overrides ALU operation to ADD when `MemLoad` or `MemStore` is active, since address calculation always requires `rs1 + imm12` regardless of `funct3`
- LUI and AUIPC handled directly inside the ALU using dedicated `isLUI` and `isAUIPC` control signals

### Decoder
- Detects instruction type purely from opcode `[6:0]`
- `funct7` is zeroed for all I-type instructions to prevent the forceADD bug
- `WEN1 = ~MemStore & ~isBranch` — everything except stores and branches writes to a register
- Immediate reconstruction:
  - **I-type**: `inst[31:20]`
  - **S-type**: `{inst[31:25], inst[11:7]}`
  - **B-type**: `{inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` (13-bit, sign extended in PC unit)
  - **J-type**: `{inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` (21-bit, sign extended in PC unit)
  - **U-type**: `inst[31:12]` (20-bit)

### Register File
- 32 × 32-bit registers
- 2 combinational read ports, 1 synchronous write port
- x0 write-protected in hardware — writes to address 0 are silently ignored
- x0 reads always return 0 regardless of stored value
- Synchronous write, combinational read — correct for single-cycle design (reads old value within same cycle)

### PC Control Unit
- 4-way next-PC mux with priority: JALR → JAL → branch taken → PC+4
- Branch condition evaluated combinationally using `funct3`, `rs1`, `rs2`
- Dedicated `RetAddr = PC + 4` output for JAL/JALR writeback — separate from the next-PC computation to avoid using the wrong adder output
- Sign extension of branch/jump offsets handled here before adding to PC

### Memory
- **Combinational read** on both instruction and data memory — required for correct single-cycle operation. Synchronous read would cause stale-data issues requiring NOP insertion after every load
- **Byte addressing** with word-wide storage: `mem[addr[11:2]]` maps byte addresses to 32-bit word locations
- Partial word loads use `addr[1:0]` to select the correct byte/halfword within a word
- Partial word stores use bit-range assignment (`mem[addr][7:0] <= din[7:0]`) to write only the target bytes without corrupting adjacent bytes
- Memory is BRAM-friendly for future Quartus synthesis

### Writeback MUX
Located in the top-level `cpu.v`:
```verilog
assign reg_wdata = MemLoad ? MemDout : (isJAL || isJALR) ? RetAddr : ALUOut;
```
Selects between ALU result, data memory output, and PC+4 return address.

---

## Bugs Fixed During Development

| Bug | Symptom | Fix |
|-----|---------|-----|
| `funct7` bits leaking into I-type instructions | ALU performed wrong operation on immediate instructions | Mask `funct7` to 0 for all non-R-type instructions in decoder |
| `WEN1 = NOR(MemStore, MemLoad)` | Load instructions (`lw`) did not write result to register | Changed to `WEN1 = ~MemStore` |
| PC+4 writeback reused next-PC adder | JAL/JALR saved wrong return address when branch/jump target was selected | Added dedicated `PC+4` computation tapped before the next-PC mux |
| Synchronous RAM read | Required NOP after every `lw` to avoid stale data | Switched to combinational (asynchronous) read |

---

## Simulation

### Requirements
- [Icarus Verilog](http://bleyer.org/icarus/) (Windows) or `sudo apt install iverilog` (Linux)
- GTKWave (bundled with Icarus on Windows)

### Running
```bash
cd Verilog/Single-Cycle
iverilog -o cpu.vvp alu.v decode.v regfile.v pc_control.v imem.v dmem.v cpu.v
vvp cpu.vvp
```

### Program format
Programs are loaded via `program.hex` — one 32-bit instruction per line in hex, no `0x` prefix:
```
00500093
00700113
00208133
00302023
```
Program that adds 5 and 7 and stores the result to memory

---

# Pipelined CPU

A 5-stage pipelined implementation of the same RV32I core (IF → ID → EX → MEM → WB), adding hazard detection, data forwarding, and branch resolution on top of the single-cycle datapath above. Same ISA, same ALU/decoder/register-file/memory design decisions as the single-cycle version — this section covers what's new.

## Architecture Overview

- **Pipeline**: 5 stages — IF, ID, EX, MEM, WB
- **Pipeline registers**: `if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`, each carrying data and control signals between stages, with independent stall/flush control
- **Hazard handling**: load-use hazards resolved by stalling; control hazards resolved by flushing
- **Forwarding**: EX/MEM → EX and MEM/WB → EX, resolving most RAW hazards without stalling
- **Branch/jump resolution**: EX stage, giving a fixed 2-cycle penalty on taken branches/jumps

---

## Module Structure (additions over single-cycle)

```
Verilog/Pipelined/
├── cpu_pipelined.v      — Top-level pipeline datapath, wires all stages and pipeline registers together
├── if_id_reg.v           — IF/ID pipeline register (stall + flush-to-NOP support)
├── id_ex_reg.v           — ID/EX pipeline register (stall + flush support)
├── ex_mem_reg.v          — EX/MEM pipeline register
├── mem_wb_reg.v          — MEM/WB pipeline register
├── hazard.v              — Load-use hazard detection, drives PC/IF-ID stall and ID/EX flush
├── forwarding_unit.v     — EX/MEM and MEM/WB forwarding into the EX stage
├── jump_calc.v           — Branch condition evaluation, target address, and return address, resolved in EX
├── testbenches.v         — Standalone unit tests for the ALU and register file
```

---

## Key Design Decisions

### Hazard Detection Unit
- Detects the classic **load-use hazard**: a `lw`-family instruction sitting in EX writes a register that the instruction currently in ID needs to read
- `uses_rs1` is false for instructions that don't actually read `rs1` (LUI, AUIPC, JAL)
- `uses_rs2` is only true for stores, R-type ALU ops, and branches — the only instruction classes that read a second source register
- On a detected hazard: stalls the PC and the IF/ID register (holding their current values for one cycle) and flushes the ID/EX register (inserting a one-cycle bubble)

### Forwarding Unit
- Two forwarding paths feed the EX stage: **EX/MEM → EX** and **MEM/WB → EX**
- EX/MEM forwarding takes priority over MEM/WB when both would apply, since the EX/MEM result is younger
- EX/MEM forwarding only carries ALU results and JAL/JALR return addresses — **not** load data, since a load's value isn't available until the MEM stage completes. This is exactly why the hazard unit above still needs to stall on load-use, rather than relying on forwarding alone
- MEM/WB forwarding does include load data (`MemDout`), since by that stage the memory read has completed

### Branch/Jump Resolution
- Resolved in the EX stage by `jump_calc`, using the (possibly forwarded) operands `fwd_rs1`/`fwd_rs2`
- On a taken branch or jump, `branch_taken_ex` flushes both IF/ID and ID/EX, squashing the two instructions fetched from the wrong path — a fixed 2-cycle branch penalty
- The PC updates directly to `target_pc_ex` the cycle after resolution

### Pipeline Registers
- Each register (`if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`) carries both datapath values and control signals downstream
- `if_id_reg` and `id_ex_reg` support independent **stall** (hold current contents) and **flush** (clear to a bubble) inputs
- On flush, `if_id_reg` inserts the NOP encoding `32'h00000013` (`addi x0, x0, 0`) directly as the bubble instruction
- On flush, `id_ex_reg` zeroes all control signals (`wen1`, `MemStore`, `MemLoad`, `isBranch`, `isJAL`, `isJALR`) so the bubble has no effect on architectural state as it moves through EX/MEM/WB

### Register File / Writeback
- Same combinational-read, synchronous-write design as the single-cycle version, now reading in ID and writing in WB
- RAW hazards between an in-flight instruction and a same-cycle ID-stage read are resolved by the forwarding unit rather than by the register file itself

---

## Simulation

### Requirements
- [Icarus Verilog](http://bleyer.org/icarus/) (Windows) or `sudo apt install iverilog` (Linux)
- GTKWave (bundled with Icarus on Windows)

### Running
The pipeline testbench (`cpu_pipelined_tb`) is defined inside `cpu_pipelined.v` itself:
```bash
cd Verilog/Pipelined
iverilog -o cpu_pipelined.vvp alu.v decode.v regfile.v pc_control.v imem.v dmem.v jump_calc.v forwarding_unit.v hazard.v if_id_reg.v id_ex_reg.v ex_mem_reg.v mem_wb_reg.v cpu_pipelined.v
vvp cpu_pipelined.vvp
```
This strobes pipeline state every cycle and dumps final register/memory contents to `cpu_test.vcd`, viewable in GTKWave.

### Program format
Same as the single-cycle version — programs are loaded via `program.hex`, one 32-bit instruction per line in hex.

---

## Planned Future Work

- [ ] Memory-mapped I/O version with VRAM and peripheral support
- [ ] FPGA deployment on Altera Max 10 via Quartus Prime
- [ ] Byte-enable support on data memory for Quartus BRAM inference
- [ ] UART peripheral for serial output
- [ ] Dedicated hazard-heavy assembly test programs exercising back-to-back load-use stalls and taken-branch flushes
- [ ] Pong Demo

# RV32I Single-Cycle CPU

A fully functional RISC-V RV32I single-cycle CPU, originally designed in Logisim Evolution and converted to Verilog for simulation and eventual FPGA deployment on an Intel Altera Cyclone V.


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

| Category       | Instructions                                      | Status       |
|----------------|---------------------------------------------------|--------------|
| R-type ALU     | add, sub, sll, srl, sra, slt, sltu, xor, or, and | ✅ Working   |
| I-type ALU     | addi, slti, sltiu, xori, ori, andi, slli, srli, srai | ✅ Working |
| Loads          | lw, lh, lb, lhu, lbu                             | ✅ Working   |
| Stores         | sw, sh, sb                                        | ✅ Working   |
| Branches       | beq, bne, blt, bge, bltu, bgeu                   | ✅ Working   |
| Jumps          | jal, jalr                                         | ✅ Working   |
| Upper immediate| lui, auipc                                        | ✅ Working   |

---

## Module Structure

```
RV32CPU/
├── alu.v                — All ALU operations, forceADD, LUI/AUIPC
├── decode.v             — Instruction decoder, control signal generation
├── regfile.v            — 32×32 register file, x0 hardwired to zero
├── pc_control.v         — PC register, branch/jump target computation, next-PC mux
├── instruction_mem.v    — 4KB instruction ROM, combinational read
├── data_mem.v           — 4KB data RAM, combinational read, synchronous write
├── cpu.v                — Top-level datapath, wires all modules together
```

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
iverilog -o cpu.vvp alu.v decode.v regfile.v pc_control.v instruction_mem.v data_mem.v cpu.v cpu_tb.v
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

## Planned Future Work

- [ ] Pipelined version (5-stage: IF, ID, EX, MEM, WB) with hazard detection and forwarding
- [ ] Memory-mapped I/O version with VRAM and peripheral support
- [ ] FPGA deployment on Intel Altera Cyclone V via Quartus Prime
- [ ] Byte-enable support on data memory for Quartus BRAM inference
- [ ] UART peripheral for serial output

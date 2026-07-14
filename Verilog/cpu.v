module cpu(
    input wire clk,
    input wire rst
);
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] ALUOut;
    wire [31:0] reg_wdata;
    wire [31:0] MemDout;
    wire [31:0] RetAddr;
    wire [2:0] func3;
    wire [6:0] func7;
    wire [11:0] imm12;
    wire [19:0] imm20;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [12:0] brOffset;
    wire [20:0] jmpOffset;
    wire isImm, MemStore, MemLoad, isLUI, isAUIPC, wen1, isBranch, isJAL, isJALR;
    assign reg_wdata = MemLoad ? MemDout : (isJAL || isJALR) ? RetAddr : ALUOut;
    

    alu alu_unit(
        .rs1(rs1_data),
        .rs2(rs2_data),
        .func3(func3),
        .func7(func7),
        .imm12(imm12),
        .imm20(imm20),
        .pc_in(pc),
        .isImm(isImm),
        .MemStore(MemStore),
        .MemLoad(MemLoad),
        .isLUI(isLUI),
        .isAUIPC(isAUIPC),
        .ALUOut(ALUOut)
    );

    regfile regfile_unit(
        .clk(clk),
        .rst(rst),
        .wen1(wen1),
        .ad1(rd),
        .ad2(rs1),
        .ad3(rs2),
        .din1(reg_wdata),
        .dout2(rs1_data),
        .dout3(rs2_data)
    );

    decode decode_unit(
        .ins(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .func3(func3),
        .func7(func7),
        .imm12(imm12),
        .imm20(imm20),
        .brOffset(brOffset),
        .jmpOffset(jmpOffset),
        .isImm(isImm),
        .MemStore(MemStore),
        .MemLoad(MemLoad),
        .isLUI(isLUI),
        .isAUIPC(isAUIPC),
        .wen1(wen1),
        .isBranch(isBranch),
        .isJAL(isJAL),
        .isJALR(isJALR)
    );

    pc_control pc_control_unit(
        .clk(clk),
        .rst(rst),
        .isBranch(isBranch),
        .isJAL(isJAL),
        .isJALR(isJALR),
        .BrOffset(brOffset),
        .JalOffset(jmpOffset),
        .JalrTarget(ALUOut),
        .rs1(rs1_data),
        .rs2(rs2_data),
        .funct3(func3),
        .pc_out(pc),
        .RetAddr(RetAddr)        
    );

    instruction_mem instruction_mem (
        .addr(pc),
        .instruction(instruction)
    );

    data_mem data_mem (
        .clk(clk),
        .addr(ALUOut),
        .din(rs2_data),
        .func3(func3),
        .MemStore(MemStore),
        .MemDout(MemDout)
    );
endmodule

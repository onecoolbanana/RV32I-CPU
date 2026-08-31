module cpu_pipelined(
    input wire clk,
    input wire rst
); 

    wire stall_pc, stall_if_id, flush_if_id;
    wire [31:0] ins_if;
    wire [31:0] pc_out_if;
    
    // IF Stage
    instruction_mem instruction_mem (
        .addr(pc_out_if),
        .instruction(ins_if)
    );

    pc_control pc_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall_pc),
        .branch_taken(branch_taken_ex),
        .target_pc(target_pc_ex),
        .pc_out(pc_out_if)
    );

    wire flush_id_ex, hazard_flush_out, branch_taken_id;
    wire wen1_id, isImm_id, MemStore_id, MemLoad_id, isLUI_id, isAUIPC_id, isBranch_id, 
         isJAL_id, isJALR_id;
    assign flush_id_ex = hazard_flush_out | branch_taken_ex;

    wire [31:0] ins_id;
    wire [31:0] pc_out_id;
    wire [4:0] rs1_id;
    wire [31:0] rs1_data_id;
    wire [4:0] rs2_id;
    wire [31:0] rs2_data_id;
    wire [4:0] rd_id;
    wire [31:0] rd_data_id;
    wire [2:0] func3_id;
    wire [6:0] func7_id;
    wire [11:0] imm12_id;
    wire [19:0] imm20_id;
    wire [12:0] brOffset_id;
    wire [20:0] jmpOffset_id;
    wire [6:0] opcode_id;

    // IF/ID Pipeline Register
    if_id_reg if_id (
        .clk(clk),
        .rst(rst),
        .stall(stall_if_id),
        .flush(branch_taken_ex),
        .instruction_in(ins_if),
        .pc_in(pc_out_if),
        .instruction_out(ins_id),
        .pc_out(pc_out_id)
    );

    // ID Stage
    decode decode_unit(
        .ins(ins_id),
        .rs1(rs1_id),
        .rs2(rs2_id),
        .rd(rd_id),
        .func3(func3_id),
        .func7(func7_id),
        .imm12(imm12_id),
        .imm20(imm20_id),
        .brOffset(brOffset_id),
        .jmpOffset(jmpOffset_id),
        .opcode(opcode_id),
        .isImm(isImm_id),
        .MemStore(MemStore_id),
        .MemLoad(MemLoad_id),
        .isLUI(isLUI_id),
        .isAUIPC(isAUIPC_id),
        .wen1(wen1_id),
        .isBranch(isBranch_id),
        .isJAL(isJAL_id),
        .isJALR(isJALR_id)
    );
    
    wire [31:0] reg_wdata;
    assign reg_wdata = MemLoad_wb ? MemDout_wb : 
                       (isJAL_wb || isJALR_wb) ? RetAddr_wb : ALUOut_wb;

    regfile regfile_unit(
        .clk(clk),
        .rst(rst),
        .wen1(wen1_wb),
        .ad1(rd_wb),
        .ad2(rs1_id),
        .ad3(rs2_id),
        .din1(reg_wdata),
        .dout2(rs1_data_id),
        .dout3(rs2_data_id)
    );

    hazard hazard_detector (
        .isLUI(isLUI_id), 
        .isAUIPC(isAUIPC_id),
        .isJAL(isJAL_id), 
        .MemLoad(MemLoad_ex),
        .opcode(opcode_id),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_id_ex(rd_ex),
        .stall_pc_if(stall_pc),
        .stall_if_id(stall_if_id),
        .flush_id_ex(hazard_flush_out)
    );

    wire [31:0] rs1_data_ex;
    wire [31:0] rs2_data_ex;
    wire [4:0] rs1_ex;
    wire [4:0] rs2_ex;
    wire [4:0] rd_ex;
    wire [31:0] ALUOut_ex;
    wire [31:0] pc_ex;
    wire [31:0] target_pc_ex;
    wire [31:0] RetAddr_ex;
    wire [11:0] imm12_ex;
    wire [19:0] imm20_ex;
    wire [2:0] func3_ex;
    wire [6:0] func7_ex;
    wire isImm_ex;
    wire isLUI_ex;
    wire isAUIPC_ex;
    wire wen1_ex;
    wire MemStore_ex;
    wire MemLoad_ex;
    wire isBranch_ex;
    wire isJAL_ex;
    wire isJALR_ex;
    wire branch_taken_ex;
    wire [12:0] brOffset_ex;
    wire [20:0] jmpOffset_ex;

    wire [31:0] fwd_rs1;
    wire [31:0] fwd_rs2;

    // ID/EX Pipeline Register
    id_ex_reg id_ex (
        .clk(clk),
        .rst(rst),
        .flush(flush_id_ex),
        .rs1_data_in(rs1_data_id),
        .rs2_data_in(rs2_data_id),
        .rs1_in(rs1_id),
        .rs2_in(rs2_id),
        .rd_in(rd_id),
        .pc_in(pc_out_id),
        .imm12_in(imm12_id),
        .imm20_in(imm20_id),
        .func3_in(func3_id),
        .func7_in(func7_id),
        .isImm_in(isImm_id),
        .isLUI_in(isLUI_id), 
        .isAUIPC_in(isAUIPC_id),
        .wen1_in(wen1_id),
        .MemStore_in(MemStore_id),
        .MemLoad_in(MemLoad_id),
        .isBranch_in(isBranch_id),
        .isJAL_in(isJAL_id),
        .isJALR_in(isJALR_id),
        .brOffset_in(brOffset_id),
        .jmpOffset_in(jmpOffset_id),
        .rs1_data_out(rs1_data_ex),
        .rs2_data_out(rs2_data_ex),
        .rs1_out(rs1_ex),
        .rs2_out(rs2_ex),
        .rd_out(rd_ex),
        .pc_out(pc_ex),
        .imm12_out(imm12_ex),
        .imm20_out(imm20_ex),
        .func3_out(func3_ex),
        .func7_out(func7_ex),
        .isImm_out(isImm_ex),
        .isLUI_out(isLUI_ex),
        .isAUIPC_out(isAUIPC_ex),
        .wen1_out(wen1_ex),
        .MemStore_out(MemStore_ex),
        .MemLoad_out(MemLoad_ex),
        .isBranch_out(isBranch_ex),
        .isJAL_out(isJAL_ex),
        .isJALR_out(isJALR_ex),
        .brOffset_out(brOffset_ex),
        .jmpOffset_out(jmpOffset_ex)
    );

    // EX Stage
    alu alu_unit (
        .rs1(fwd_rs1),
        .rs2(fwd_rs2),
        .func3(func3_ex),
        .func7(func7_ex),
        .imm12(imm12_ex),
        .imm20(imm20_ex),
        .pc_in(pc_ex),
        .isImm(isImm_ex),
        .MemStore(MemStore_ex),
        .MemLoad(MemLoad_ex),
        .isLUI(isLUI_ex),
        .isAUIPC(isAUIPC_ex),
        .ALUOut(ALUOut_ex)
    );

    jump_calc jump (
        .isBranch(isBranch_ex),
        .isJAL(isJAL_ex),
        .isJALR(isJALR_ex),
        .ALUOut(ALUOut_ex),
        .rs1_data(fwd_rs1),
        .rs2_data(fwd_rs2),
        .pc_in(pc_ex),
        .func3(func3_ex),
        .BrOffset(brOffset_ex),
        .JalOffset(jmpOffset_ex),
        .target_pc(target_pc_ex),
        .RetAddr(RetAddr_ex),
        .branch_taken(branch_taken_ex)
    );

    forwarding_unit forward_unit (
        .rs1_idex(rs1_ex),
        .rs2_idex(rs2_ex),
        .rs1_data_idex(rs1_data_ex),
        .rs2_data_idex(rs2_data_ex),
        .rd_exmem(rd_mem),
        .wen1_exmem(wen1_mem),
        .MemLoad_exmem(MemLoad_mem),
        .isJAL_exmem(isJAL_mem),
        .isJALR_exmem(isJALR_mem),
        .ALUOut_exmem(ALUOut_mem),
        .RetAddr_exmem(RetAddr_mem),
        .rd_memwb(rd_wb),
        .wen1_memwb(wen1_wb), 
        .MemLoad_memwb(MemLoad_wb), 
        .isJAL_memwb(isJAL_wb), 
        .isJALR_memwb(isJALR_wb),
        .ALUOut_memwb(ALUOut_wb),
        .RetAddr_memwb(RetAddr_wb),
        .MemDout_memwb(MemDout_wb),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2)
    );

    wire wen1_mem, MemStore_mem, MemLoad_mem, isJAL_mem, isJALR_mem;
    wire [31:0] ALUOut_mem;
    wire [31:0] RetAddr_mem;
    wire [31:0] rs2_data_mem;
    wire [31:0] MemDout_mem;
    wire [4:0] rd_mem;
    wire [2:0] func3_mem;

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem (
        .clk(clk),
        .rst(rst),
        .ALUOut_in(ALUOut_ex),
        .RetAddr_in(RetAddr_ex),
        .rs2_data_in(fwd_rs2),
        .rd_in(rd_ex),
        .func3_in(func3_ex),
        .MemStore_in(MemStore_ex),
        .MemLoad_in(MemLoad_ex), 
        .wen1_in(wen1_ex), 
        .isJAL_in(isJAL_ex), 
        .isJALR_in(isJALR_ex),
        .ALUOut_out(ALUOut_mem),
        .RetAddr_out(RetAddr_mem),
        .rs2_data_out(rs2_data_mem),
        .rd_out(rd_mem),
        .func3_out(func3_mem),
        .MemStore_out(MemStore_mem), 
        .MemLoad_out(MemLoad_mem), 
        .wen1_out(wen1_mem), 
        .isJAL_out(isJAL_mem),
        .isJALR_out(isJALR_mem)
    );

    // MEM Stage
    data_mem dmem (
        .clk(clk),
        .addr(ALUOut_mem),
        .din(rs2_data_mem),
        .func3(func3_mem),
        .MemStore(MemStore_mem),
        .MemDout(MemDout_mem)
    );

    wire wen1_wb, MemLoad_wb, isJAL_wb, isJALR_wb;
    wire [31:0] ALUOut_wb;
    wire [31:0] RetAddr_wb;
    wire [31:0] MemDout_wb;
    wire [4:0] rd_wb;

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb (
        .clk(clk),
        .rst(rst),
        .ALUOut_in(ALUOut_mem),
        .RetAddr_in(RetAddr_mem),
        .MemDout_in(MemDout_mem),
        .rd_in(rd_mem),
        .MemLoad_in(MemLoad_mem), 
        .wen1_in(wen1_mem), 
        .isJAL_in(isJAL_mem), 
        .isJALR_in(isJALR_mem),
        .ALUOut_out(ALUOut_wb),
        .RetAddr_out(RetAddr_wb),
        .MemDout_out(MemDout_wb),
        .rd_out(rd_wb),
        .MemLoad_out(MemLoad_wb), 
        .wen1_out(wen1_wb), 
        .isJAL_out(isJAL_wb), 
        .isJALR_out(isJALR_wb)
    );


endmodule

module cpu_pipelined_tb;

    reg clk;
    reg rst;

    cpu_pipelined uut (
        .clk(clk),
        .rst(rst)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        $strobe("t=%0t rst=%b | rd_id=%d wen1_id=%b | ins=%h pc=%h | branch_taken=%b stall_pc=%b",
            $time, rst,
            uut.rd_id, uut.wen1_id,
            uut.ins_if, uut.pc_out_if,
            uut.branch_taken_ex, uut.stall_pc);
    end

    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, cpu_pipelined_tb);

        rst = 1;
        #12;
        rst = 0;

        #500;
        $display("REG1=%h REG2=%h REG3=%h MEM[0]=%h", 
                uut.regfile_unit.regs[1],
                uut.regfile_unit.regs[2],
                uut.regfile_unit.regs[3],
                uut.dmem.mem[0]);
        $finish;
    end
endmodule
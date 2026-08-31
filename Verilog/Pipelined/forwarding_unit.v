module forwarding_unit (
    input [4:0] rs1_idex,
    input [4:0] rs2_idex,
    input [31:0] rs1_data_idex,
    input [31:0] rs2_data_idex,
    input [4:0] rd_exmem,
    input wen1_exmem, MemLoad_exmem, isJAL_exmem, isJALR_exmem,
    input [31:0] ALUOut_exmem,
    input [31:0] RetAddr_exmem,
    input [4:0] rd_memwb,
    input wen1_memwb, MemLoad_memwb, isJAL_memwb, isJALR_memwb,
    input [31:0] ALUOut_memwb,
    input [31:0] RetAddr_memwb,
    input [31:0] MemDout_memwb,
    output wire [31:0] fwd_rs1,
    output wire [31:0] fwd_rs2
);

    wire [31:0] exmem_value = (isJAL_exmem || isJALR_exmem) ? RetAddr_exmem : ALUOut_exmem;
    wire exmem_valid = wen1_exmem && !MemLoad_exmem && (rd_exmem != 0);

    wire [31:0] memwb_value = (MemLoad_memwb) ? MemDout_memwb :
                              (isJAL_memwb || isJALR_memwb) ? RetAddr_memwb : ALUOut_memwb;
    wire memwb_valid = wen1_memwb && (rd_memwb != 0);

    assign fwd_rs1 = (exmem_valid && rd_exmem == rs1_idex) ? exmem_value : 
                     (memwb_valid && rd_memwb == rs1_idex) ? memwb_value : rs1_data_idex;
    
    assign fwd_rs2 = (exmem_valid && rd_exmem == rs2_idex) ? exmem_value : 
                     (memwb_valid && rd_memwb == rs2_idex) ? memwb_value : rs2_data_idex;
endmodule    

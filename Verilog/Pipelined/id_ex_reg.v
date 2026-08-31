module id_ex_reg(
    input clk,
    input rst,
    input flush,
    input [31:0] rs1_data_in,
    input [31:0] rs2_data_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [31:0] pc_in,
    input [11:0] imm12_in,
    input [19:0] imm20_in,
    input [2:0] func3_in,
    input [6:0] func7_in,
    input isImm_in,
    input isLUI_in, 
    input isAUIPC_in,
    input wen1_in,
    input MemStore_in,
    input MemLoad_in,
    input isBranch_in,
    input isJAL_in,
    input isJALR_in,
    input [12:0] brOffset_in,
    input [20:0] jmpOffset_in,

    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [31:0] pc_out,
    output reg [11:0] imm12_out,
    output reg [19:0] imm20_out,
    output reg [2:0] func3_out,
    output reg [6:0] func7_out,
    output reg isImm_out, isLUI_out, isAUIPC_out, wen1_out, MemStore_out, MemLoad_out, isBranch_out, isJAL_out, isJALR_out,
    output reg [12:0] brOffset_out,
    output reg [20:0] jmpOffset_out
);

    always @(posedge clk or posedge rst) begin
        if (rst | flush) begin
            isImm_out <= 0;
            isLUI_out <= 0;
            isAUIPC_out <= 0;
            wen1_out <= 0;
            MemStore_out <= 0;
            MemLoad_out <= 0;
            isBranch_out <= 0;
            isJAL_out <= 0;
            isJALR_out <= 0;
            pc_out <= 32'b0;
        end else begin
            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            pc_out <= pc_in;
            imm12_out <= imm12_in;
            imm20_out <= imm20_in;
            func3_out <= func3_in;
            func7_out <= func7_in;
            brOffset_out <= brOffset_in;
            jmpOffset_out <= jmpOffset_in;
            isImm_out <= isImm_in;
            isLUI_out <= isLUI_in;
            isAUIPC_out <= isAUIPC_in;
            wen1_out <= wen1_in;
            MemStore_out <= MemStore_in;
            MemLoad_out <= MemLoad_in;
            isBranch_out <= isBranch_in;
            isJAL_out <= isJAL_in;
            isJALR_out <= isJALR_in;
        end
    end
endmodule
module ex_mem_reg(
    input clk,
    input rst,
    input [31:0] ALUOut_in,
    input [31:0] RetAddr_in,
    input [31:0] rs2_data_in,
    input [4:0] rd_in,
    input [2:0] func3_in,
    input MemStore_in, MemLoad_in, wen1_in, isJAL_in, isJALR_in,
    output reg [31:0] ALUOut_out,
    output reg [31:0] RetAddr_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0] rd_out,
    output reg [2:0] func3_out,
    output reg MemStore_out, MemLoad_out, wen1_out, isJAL_out, isJALR_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wen1_out <= 0;
            MemStore_out <= 0;
            MemLoad_out <= 0;
            isJAL_out <= 0;
            isJALR_out <= 0;
            
        end else begin
            ALUOut_out <= ALUOut_in;
            rs2_data_out <= rs2_data_in;
            rd_out <= rd_in;
            RetAddr_out <= RetAddr_in;
            func3_out <= func3_in;
            wen1_out <= wen1_in;
            MemStore_out <= MemStore_in;
            MemLoad_out <= MemLoad_in;
            isJAL_out <= isJAL_in;
            isJALR_out <= isJALR_in;
        end
    end
endmodule
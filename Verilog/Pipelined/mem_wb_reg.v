module mem_wb_reg(
    input clk,
    input rst,
    input [31:0] ALUOut_in,
    input [31:0] RetAddr_in,
    input [31:0] MemDout_in,
    input [4:0] rd_in,
    input MemLoad_in, wen1_in, isJAL_in, isJALR_in,
    output reg [31:0] ALUOut_out,
    output reg [31:0] RetAddr_out,
    output reg [31:0] MemDout_out,
    output reg [4:0] rd_out,
    output reg MemLoad_out, wen1_out, isJAL_out, isJALR_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wen1_out <= 0;
            MemLoad_out <= 0;
            isJAL_out <= 0;
            isJALR_out <= 0;
            
        end else begin
            ALUOut_out <= ALUOut_in;
            MemDout_out <= MemDout_in;
            rd_out <= rd_in;
            RetAddr_out <= RetAddr_in;
            wen1_out <= wen1_in;
            MemLoad_out <= MemLoad_in;
            isJAL_out <= isJAL_in;
            isJALR_out <= isJALR_in;
        end
    end
endmodule
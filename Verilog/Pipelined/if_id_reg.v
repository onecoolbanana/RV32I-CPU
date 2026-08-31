module if_id_reg(
    input clk,
    input rst,
    input stall,      // freeze contents (hold current value)
    input flush,       // clear to bubble/NOP
    input [31:0] instruction_in,
    input [31:0] pc_in,
    output reg [31:0] instruction_out,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst | flush) begin
            instruction_out <= 32'h00000013;
            pc_out <= 32'b0;
        end else if (!stall) begin
            instruction_out <= instruction_in;
            pc_out <= pc_in;
        end
    end
endmodule
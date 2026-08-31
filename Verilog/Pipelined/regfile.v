module regfile (
    input wire clk,
    input wire rst,
    input wire wen1,
    input wire [4:0] ad1,
    input wire [4:0] ad2,
    input wire [4:0] ad3,
    input wire [31:0] din1,
    output reg [31:0] dout2,
    output reg [31:0] dout3
);

    reg [31:0] regs [31:0];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (wen1 && ad1 != 5'b00000) begin
            regs[ad1] <= din1;
        end
    end

    always @(*) begin
        dout2 = (ad2 == 5'b00000) ? 32'b0 : regs[ad2];
        dout3 = (ad3 == 5'b00000) ? 32'b0 : regs[ad3];
    end
endmodule

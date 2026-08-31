module pc_control(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire branch_taken,
    input wire [31:0] target_pc,
    output wire [31:0] pc_out
);
    reg [31:0] pc;
    reg [31:0] next_pc;

    assign pc_out = pc;

    always @(*) begin
        if (branch_taken) begin
            next_pc = target_pc;
        end else begin
            next_pc = pc + 4;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'b0; // Reset PC to 0
        end else if (!stall) begin
            pc <= next_pc; // Update PC based on control logic
        end
    end
endmodule

module pc_control(
    input wire clk,
    input wire rst,
    input wire isBranch,
    input wire isJAL,
    input wire isJALR,
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [2:0] funct3,
    input wire [12:0] BrOffset,
    input wire [20:0] JalOffset,
    input wire [31:0] JalrTarget,
    output wire [31:0] pc_out,
    output wire [31:0] RetAddr
);
    reg [31:0] pc;
    reg [31:0] next_pc;
    
    assign pc_out = pc;
    assign RetAddr = pc + 4;
    
    reg isJump;
    reg [31:0] BrOffsetExtended;
    reg [31:0] JalOffsetExtended;

    always @(*) begin

        BrOffsetExtended = $signed({{19{BrOffset[12]}}, BrOffset}); 
        JalOffsetExtended = $signed({{11{JalOffset[20]}}, JalOffset}); 

        case (funct3)
            3'b000: isJump = (rs1 == rs2); // BEQ
            3'b001: isJump = (rs1 != rs2); // BNE
            3'b100: isJump = ($signed(rs1) < $signed(rs2)); // BLT
            3'b101: isJump = ($signed(rs1) >= $signed(rs2)); // BGE
            3'b110: isJump = (rs1 < rs2); // BLTU
            3'b111: isJump = (rs1 >= rs2); // BGEU
            default: isJump = 1'b0; // Invalid funct3
        endcase

        if (isBranch && isJump) begin
            next_pc = pc + BrOffsetExtended;
            
        end else if (isJAL) begin
            next_pc = pc + JalOffsetExtended;
            
        end else if (isJALR) begin
            next_pc = JalrTarget;
            
        end else begin
            next_pc = pc + 4;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'b0; // Reset PC to 0
        end else begin
            pc <= next_pc; // Update PC based on control logic
        end
    end
endmodule

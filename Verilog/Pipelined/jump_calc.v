module jump_calc(
    input wire isBranch,
    input wire isJAL,
    input wire isJALR,
    input wire [31:0] ALUOut,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] pc_in,
    input wire [2:0] func3,
    input wire [12:0] BrOffset,
    input wire [20:0] JalOffset,
    output reg [31:0] target_pc,
    output reg [31:0] RetAddr,
    output reg branch_taken
);
       
    reg isJump;
    reg [31:0] BrOffsetExtended;
    reg [31:0] JalOffsetExtended;

    always @(*) begin

        BrOffsetExtended = $signed({{19{BrOffset[12]}}, BrOffset}); 
        JalOffsetExtended = $signed({{11{JalOffset[20]}}, JalOffset}); 

        case (func3)
            3'b000: isJump = (rs1_data == rs2_data); // BEQ
            3'b001: isJump = (rs1_data != rs2_data); // BNE
            3'b100: isJump = ($signed(rs1_data) < $signed(rs2_data)); // BLT
            3'b101: isJump = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
            3'b110: isJump = (rs1_data < rs2_data); // BLTU
            3'b111: isJump = (rs1_data >= rs2_data); // BGEU
            default: isJump = 1'b0; // Invalid func3
        endcase

        if (isBranch && isJump) begin
            target_pc = pc_in + BrOffsetExtended;
            branch_taken = 1'b1;
            
        end else if (isJAL) begin
            target_pc = pc_in + JalOffsetExtended;
            branch_taken = 1'b1;
            
        end else if (isJALR) begin
            target_pc = ALUOut;
            branch_taken = 1'b1;
        end else begin
            branch_taken = 1'b0;
            target_pc = pc_in;
        end

        RetAddr = pc_in + 4;
    end

endmodule

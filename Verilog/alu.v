module alu (
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [2:0] func3,
    input wire [6:0] func7,
    input wire [11:0] imm12,
    input wire [19:0] imm20,
    input wire [31:0] pc_in,
    input wire isImm,
    input wire MemStore,
    input wire MemLoad,
    input wire isLUI,
    input wire isAUIPC,
    output reg [31:0] ALUOut   
);
    reg [31:0] ALUOperand;
    
    always @(*) begin

        if (isImm)
            ALUOperand = {{20{imm12[11]}}, imm12};
        else
            ALUOperand = rs2;
        
        if (isLUI)
            ALUOut = imm20 << 12;
        
        else if (isAUIPC)
            ALUOut = pc_in + imm20 << 12;
        
        else if (MemStore | MemLoad)
            ALUOut = rs1 + ALUOperand;
        
        else begin
            case (func3)
                3'b000: begin
                    if (func7 == 7'b0000000)
                        ALUOut = rs1 + ALUOperand; // ADD
                    else if (func7 == 7'b0100000)
                        ALUOut = rs1 - ALUOperand; // SUB
                end
                3'b001: ALUOut = rs1 << ALUOperand[4:0]; // SLL
                3'b010: ALUOut = ($signed(rs1) < $signed(ALUOperand)) ? 32'b1 : 32'b0; // SLT
                3'b011: ALUOut = (rs1 < ALUOperand) ? 32'b1 : 32'b0; // SLTU
                3'b100: ALUOut = rs1 ^ ALUOperand; // XOR
                3'b101: begin
                    if (func7 == 7'b0000000)
                        ALUOut = rs1 >> ALUOperand[4:0]; // SRL
                    else if (func7 == 7'b0100000)
                        ALUOut = $signed(rs1) >>> ALUOperand[4:0]; // SRA
                    else
                        ALUOut = 32'h00000000; // Invalid operation
                end
                3'b110: ALUOut = rs1 | ALUOperand; // OR
                3'b111: ALUOut = rs1 & ALUOperand; // AND
                default: ALUOut = 32'h00000000; // Invalid operation
            endcase
        end
    end
endmodule

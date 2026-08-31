// Load-use hazard: instruction sitting in ID/EX (waiting to be executed) writes memory 
//                  or register and instruction in IF/ID (waiting to be decoded) uses 
//                  the result of the load.

module hazard(
    input isLUI, isAUIPC, isJAL, MemLoad,
    input [6:0] opcode,
    input [4:0] rs1_id,
    input [4:0] rs2_id,
    input [4:0] rd_id_ex,

    output reg stall_pc_if,
    output reg stall_if_id,
    output reg flush_id_ex

);

    wire uses_rs1 = !(isLUI || isAUIPC || isJAL);
    wire uses_rs2 = (opcode == 7'h23) || (opcode == 7'h33) || (opcode == 7'h63);
    wire hazard_detected = MemLoad && (rd_id_ex != 0) &&
                        ((uses_rs1 && (rd_id_ex == rs1_id)) ||
                         (uses_rs2 && (rd_id_ex == rs2_id)));

    always @(*) begin
        stall_pc_if = hazard_detected;
        stall_if_id = hazard_detected;
        flush_id_ex = hazard_detected;
    end
endmodule
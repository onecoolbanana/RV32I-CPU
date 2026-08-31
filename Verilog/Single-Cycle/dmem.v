module data_mem (
    input wire [31:0] addr,
    input wire [31:0] din,
    input wire [2:0] func3,
    input wire MemStore,
    input wire clk,
    output reg [31:0] MemDout

);

    reg [31:0] mem [0:1023];

    always @(*) begin 
        case (func3)
            3'b000: begin
                case (addr[1:0])
                    2'b00: MemDout = {{24{mem[addr[11:2]][7]}}, mem[addr[11:2]][7:0]}; // LB
                    2'b01: MemDout = {{24{mem[addr[11:2]][15]}}, mem[addr[11:2]][15:8]}; // LB
                    2'b10: MemDout = {{24{mem[addr[11:2]][23]}}, mem[addr[11:2]][23:16]}; // LB
                    2'b11: MemDout = {{24{mem[addr[11:2]][31]}}, mem[addr[11:2]][31:24]}; // LB
                endcase
            end
            3'b001: begin
                case (addr[1:0])
                    2'b00: MemDout = {{16{mem[addr[11:2]][15]}}, mem[addr[11:2]][15:0]}; // LH
                    2'b10: MemDout = {{16{mem[addr[11:2]][31]}}, mem[addr[11:2]][31:16]}; // LH
                    default: MemDout = 32'h00000000; // Invalid address for half-word load
                endcase
            end
            3'b010: MemDout = mem[addr[11:2]]; // LW
            3'b100: begin
                case (addr[1:0])
                    2'b00: MemDout = {24'b0, mem[addr[11:2]][7:0]}; // LBU
                    2'b01: MemDout = {24'b0, mem[addr[11:2]][15:8]}; // LBU
                    2'b10: MemDout = {24'b0, mem[addr[11:2]][23:16]}; // LBU
                    2'b11: MemDout = {24'b0, mem[addr[11:2]][31:24]}; // LBU
                endcase
            end
            3'b101: begin
                case (addr[1:0])
                    2'b00: MemDout = {16'b0, mem[addr[11:2]][15:0]}; // LHU
                    2'b10: MemDout = {16'b0, mem[addr[11:2]][31:16]}; // LHU
                    default: MemDout = 32'h00000000; // Invalid address for half-word load
                endcase
            end
            default: MemDout = 32'h00000000; // Invalid func3
        endcase
    end

    always @(posedge clk) begin
        if (MemStore) begin
            case (func3)
                3'b000: begin
                    case (addr[1:0])
                        2'b00: mem[addr[11:2]][7:0] <= din[7:0]; // SB
                        2'b01: mem[addr[11:2]][15:8] <= din[7:0]; // SB
                        2'b10: mem[addr[11:2]][23:16] <= din[7:0]; // SB
                        2'b11: mem[addr[11:2]][31:24] <= din[7:0]; // SB
                    endcase
                end
                3'b001: begin
                    case (addr[1:0])
                        2'b00: mem[addr[11:2]][15:0] <= din[15:0]; // SH
                        2'b10: mem[addr[11:2]][31:16] <= din[15:0]; // SH
                        default: ; // Invalid address for half-word store
                    endcase
                end
                3'b010: mem[addr[11:2]] <= din; // SW
                default: ; // Invalid func3
            endcase
        end
    end

endmodule

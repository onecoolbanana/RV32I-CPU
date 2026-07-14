module instruction_mem (
    input wire [31:0] addr,
    output wire [31:0] instruction
);

  reg[31:0] mem [0:1023];

    initial begin
        $readmemh("program.hex", mem);
    end

    assign instruction = mem[addr[11:2]];

endmodule

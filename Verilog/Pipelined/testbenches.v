module alu_testbench;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [2:0] func3;
    reg [6:0] func7;
    reg [11:0] imm12;
    reg [19:0] imm20;
    reg [31:0] pc_in;
    reg isImm;
    reg MemStore;
    reg MemLoad;
    reg isLUI;
    reg isAUIPC;
    wire [31:0] ALUOut;

    alu uut (
        .rs1(rs1),
        .rs2(rs2),
        .func3(func3),
        .func7(func7),
        .imm12(imm12),
        .imm20(imm20),
        .pc_in(pc_in),
        .isImm(isImm),
        .MemStore(MemStore),
        .MemLoad(MemLoad),
        .isLUI(isLUI),
        .isAUIPC(isAUIPC),
        .ALUOut(ALUOut)
    );

    initial begin
        rs1 = 32'd10;
        rs2 = 32'd5;
        func3 = 3'b000;
        func7 = 7'b0000000;
        #10;
        $display("ADD: ALUOut = %d", ALUOut);

        func7 = 7'b0100000;
        #10;
        $display("SUB: ALUOut = %d", ALUOut);

        rs1 = 32'hFFFFFFFF;
        rs2 = 32'h00000001;
        func3 = 3'b010;
        func7 = 7'b0000000;
        #10;
        $display("SLT: ALUOut = %d", ALUOut);

        rs1 = 32'hFFFFFF00;
        rs2 = 32'd4;
        func3 = 3'b101;
        func7 = 7'b0100000;
        #10;
        $display("SRA: ALUOut = %d", ALUOut);

        rs1 = 32'd100;
        imm12 = 32'd171;
        isImm = 1'b1;
        func3 = 3'b111;
        MemStore = 1'b1;
        #10;
        $display("ForceADD: ALUOut = %d", ALUOut);

        isLUI = 1'b1;
        imm20 = 20'hABCDE;
        #10;
        $display("LUI: ALUOut = %d", ALUOut);

        isLUI = 1'b0;
        isAUIPC = 1'b1;
        pc_in = 32'd1000;
        imm20 = 20'h12345;
        #10;
        $display("AUIPC: ALUOut = %d", ALUOut);
        $finish;
    end
endmodule

module reg_testbench;
    reg clk;
    reg rst;
    reg wen1;
    reg [4:0] ad1;
    reg [4:0] ad2;
    reg [4:0] ad3;
    reg [31:0] din1;
    wire [31:0] dout2;
    wire [31:0] dout3;

    regfile uut (
        .clk(clk),
        .rst(rst),
        .wen1(wen1),
        .ad1(ad1),
        .ad2(ad2),
        .ad3(ad3),
        .din1(din1),
        .dout2(dout2),
        .dout3(dout3)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        wen1 = 0;
        ad1 = 5'b00000;
        ad2 = 5'b00000;
        ad3 = 5'b00000;
        din1 = 32'b0;

        #10;
        rst = 0;
        #10;
        wen1 = 1;
        ad1 = 5'b00001;
        din1 = 32'd42;
        #10;
        ad1 = 5'b00010;
        din1 = 32'd100;
        #10;
        wen1 = 0;
        ad2 = 5'b00001;
        ad3 = 5'b00010;
        #10;
        $display("dout2 = %d, dout3 = %d", dout2, dout3);
        wen1 = 1;
        ad1 = 5'b00000;
        din1 = 32'd999;
        #10;
        wen1 = 0;
        ad2 = 5'b00000;
        #1;
        $display("reg0 = %d (should be 0)", dout2);
        $finish;
    end


endmodule
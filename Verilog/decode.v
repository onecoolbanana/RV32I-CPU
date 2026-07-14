module decode (
    input wire [31:0] ins,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [2:0] func3,
    output reg [6:0] func7,
    output reg [11:0] imm12,
    output reg [19:0] imm20,
    output reg [12:0] brOffset,
    output reg [20:0] jmpOffset,
    output reg isImm,
    output reg MemStore,
    output reg MemLoad,
    output reg isLUI,
    output reg isAUIPC,
    output reg wen1,
    output reg isBranch,
    output reg isJAL,
    output reg isJALR
);

    reg [6:0] opcode;

    always @(*) begin
        opcode = ins[6:0];
        rd = ins[11:7];
        rs1 = ins[19:15];
        rs2 = ins[24:20];
        func3 = ins[14:12];
        imm20 = ins[31:12];

        jmpOffset = {ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};
        brOffset = {ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};

        if (opcode == 7'h67) begin
            isJALR = 1'b1;
        end else begin
            isJALR = 1'b0;
        end
        if (opcode == 7'h6F) begin
            isJAL = 1'b1;
        end else begin
            isJAL = 1'b0;
        end
        if (opcode == 7'h63) begin
            isBranch = 1'b1;
        end else begin
            isBranch = 1'b0;
        end

        
        if (opcode == 7'h23) begin
            MemStore = 1'b1;
            imm12 = {ins[31:25], ins[11:7]};
        end else begin
            MemStore = 1'b0;
            imm12 = ins[31:20];
        end

        if (opcode == 7'h03) begin
            MemLoad = 1'b1;
        end else begin
            MemLoad = 1'b0;
        end

        if (opcode == 7'h13 | opcode == 7'h03 | isJALR | MemStore) begin
            isImm = 1'b1;
        end else begin
            isImm = 1'b0;
        end

        wen1 = ~MemStore & ~isBranch;

        if (MemStore | isImm) begin
            func7 = 7'b0000000;
        end else begin
            func7 = ins[31:25];
        end

        if (opcode == 7'h37) begin
            isLUI = 1'b1;
        end else begin
            isLUI = 1'b0;
        end

        if (opcode == 7'h17) begin
            isAUIPC = 1'b1;
        end else begin
            isAUIPC = 1'b0;
        end

    end
endmodule

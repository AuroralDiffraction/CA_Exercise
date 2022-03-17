module forward_unit(
    input wire [4:0] Rs1,
    input wire [4:0] Rs2,
    input wire [4:0] Rd_EX_ME,
    input wire [4:0] Rd_ME_WB,
    input wire regWrite_EX_ME,
    input wire regWrite_ME_WB,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

always@(*) begin
    if((regWrite_EX_ME == 1) && (Rd_EX_ME == Rs1)) begin
        ForwardA = 2;
    end else if((regWrite_ME_WB == 1) && (Rd_ME_WB == Rs1)) begin
        ForwardA = 1;
    end else begin
        ForwardA = 0;
    end

    if((regWrite_EX_ME == 1) && (Rd_EX_ME == Rs2)) begin
        ForwardB = 2;
    end else if((regWrite_ME_WB == 1) && (Rd_ME_WB == Rs2)) begin
        ForwardB = 1;
    end else begin
        ForwardB = 0;
    end
end
    
endmodule
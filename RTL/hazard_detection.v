module hazard_detection(
    input wire [4:0] Rs1,
    input wire [4:0] Rs2,
    input wire [4:0] Rd,
    input wire memRead,
    output reg hazardMux,
    output reg PCWrite,
    output reg IF_ID_Write
);

    always@(*) begin
        if(memRead == 1 && ((Rd == Rs1) || (Rd == Rs2))) begin
            hazardMux = 0;
            PCWrite = 0;
            IF_ID_Write = 0;
        end else begin
            hazardMux = 1;
            PCWrite = 1;
            IF_ID_Write = 1;
        end
    end

endmodule
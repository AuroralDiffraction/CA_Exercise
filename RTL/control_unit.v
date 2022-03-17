// module: Control
// Function: Generates the control signals for each one of the datapath resources

module control_unit(
      input  wire [6:0] opcode,
      output reg  [1:0] alu_op,     // EX
      output reg        reg_dst,
      output reg        branch,     // M(PC)
      output reg        mem_read,   // M
      output reg        mem_2_reg,  // WB
      output reg        mem_write,  // M
      output reg        alu_src,    // EX
      output reg        reg_write,  // WB
      output reg        jump        // M
   );

   // RISC-V opcode[6:0] (see RISC-V greensheet)
   parameter integer ALU_R      = 7'b0110011;
   parameter integer ALU_I      = 7'b0010011;
   parameter integer BRANCH_EQ  = 7'b1100011;
   parameter integer JUMP       = 7'b1101111;
   parameter integer LOAD       = 7'b0000011;
   parameter integer STORE      = 7'b0100011;
   parameter integer MUL        = 7'b0110011;

   // RISC-V ALUOp[1:0] (see book Figure 4.12)
   parameter [1:0] ADD_OPCODE     = 2'b00;
   parameter [1:0] SUB_OPCODE     = 2'b01;
   parameter [1:0] R_TYPE_OPCODE  = 2'b10;

   //The behavior of the control unit can be found in Chapter 4, Figure 4.18

   always@(*)begin

      case(opcode)
         ALU_R:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
         end
         
         // Declare the control signals for each one of the instructions here...
         ALU_I:begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b0;
            reg_write = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE;
            jump      = 1'b0;
         end

         BRANCH_EQ:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b1;
            alu_op    = SUB_OPCODE;
            jump      = 1'b0;
         end
         
         JUMP:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; 
            jump      = 1'b1;
         end

         LOAD:begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b1;
            reg_write = 1'b1;
            mem_read  = 1'b1;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE;
            jump      = 1'b0;
         end

         STORE:begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b1;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE;
            jump      = 1'b0;
         end

         MUL:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
         end

         default:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
         end
      endcase
   end

endmodule




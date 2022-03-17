//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      31:0] instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;

wire signed [63:0] immediate_extended;

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID_out),
    .immediate_extended  (immediate_extended)
);

pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_PC_EX_ME_out ),
   .jump_pc   (jump_PC_EX_ME_out   ),
   .zero_flag (ALU_ZERO_EX_ME_out ),
   .branch    (control_M_EX_ME_out[3]    ),
   .jump      (control_M_EX_ME_out[0]      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

//-------------PC_BEGIN--------------
// update_PC_IF_ID pipeline register BEGIN
wire [63:0] update_PC_IF_ID_out;
reg_arstn_en#(
   .DATA_W(64)
)update_PC_IF_ID(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (updated_pc ),
      .dout    (update_PC_IF_ID_out)
);
// update_PC_IF_ID pipeline register END

// update_PC_ID_EX pipeline register BEGIN
wire [63:0] update_PC_ID_EX_out;
reg_arstn_en#(
   .DATA_W(64)
)update_PC_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (update_PC_IF_ID_out ),
      .dout    (update_PC_ID_EX_out)
);
// update_PC_ID_EX pipeline register END
//-------------PC_END--------------

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

////////-----------------INSTRUCTION_BEGIN-------------
// instruction_IF_ID pipeline register BEGIN
wire [31:0] instruction_IF_ID_out;

reg_arstn_en#(
   .DATA_W(32)
)instruction_IF_ID(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (instruction ),
      .dout    (instruction_IF_ID_out)
);
// instruction_IF_ID pipeline register END

// instruction_ID_EX pipeline register BEGIN
wire [31:0] instruction_ID_EX_out;

reg_arstn_en#(
   .DATA_W(32)
)instruction_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (instruction_IF_ID_out),
      .dout    (instruction_ID_EX_out)
);
// instruction_ID_EX pipeline register END

// instruction_EX_ME pipeline register BEGIN
wire [31:0] instruction_EX_ME_out;

reg_arstn_en#(
   .DATA_W(32)
)instruction_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (instruction_ID_EX_out),
      .dout    (instruction_EX_ME_out)
);
// instruction_EX_ME pipeline register END

// instruction_ME_WB pipeline register BEGIN
wire [31:0] instruction_ME_WB_out;

reg_arstn_en#(
   .DATA_W(32)
)instruction_ME_WB(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (instruction_EX_ME_out),
      .dout    (instruction_ME_WB_out)
);
// instruction_ME_WB pipeline register END

////////-----------------INSTRUCTION_END-------------


////////-----------------MEM_BEGIN-------------
// DATA_MEM_ME_WB pipeline register BEGIN
wire [63:0] DATA_MEM_ME_WB_out;

reg_arstn_en#(
   .DATA_W(64)
)DATA_MEM_ME_WB(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (mem_data),
      .dout    (DATA_MEM_ME_WB_out)
);
// DATA_MEM_ME_WB pipeline register END
////////-----------------MEM_END-------------

// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (ALU_OUT_EX_ME_out        ),
   .wen      (control_M_EX_ME_out[1]      ),
   .ren      (control_M_EX_ME_out[2]       ),
   .wdata    (RegFile_Data2_EX_ME_out),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

control_unit control_unit(
   .opcode   (instruction_IF_ID_out[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

// control_EX_ID_EX pipeline register BEGIN
wire [2:0] control_EX_ID_EX_out;

reg_arstn_en#(
   .DATA_W(3)
)control_EX_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     ({alu_op[1:0], alu_src}),
      .dout    (control_EX_ID_EX_out)        // alu_op[1:0], alu_src
);
// control_EX_ID_EX pipeline register END


////////////-----------M-BEGIN-------------------
// control_M_ID_EX pipeline register BEGIN
wire [3:0] control_M_ID_EX_out;

reg_arstn_en#(
   .DATA_W(4)
)control_M_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     ({branch, mem_read, mem_write, jump}),
      .dout    (control_M_ID_EX_out)        // branch, mem_read, mem_write, jump
);
// control_M_ID_EX pipeline register END

// control_M_EX_ME pipeline register BEGIN
wire [3:0] control_M_EX_ME_out;

reg_arstn_en#(
   .DATA_W(4)
)control_M_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (control_M_ID_EX_out),
      .dout    (control_M_EX_ME_out)        // branch, mem_read, mem_write, jump
);
// control_M_EX_ME pipeline register END
////////////-----------M-END-------------------




////////////-----------WB-BEGIN-------------------
// control_WB_ID_EX pipeline register BEGIN
wire [1:0] control_WB_ID_EX_out;

reg_arstn_en#(
   .DATA_W(2)
)control_WB_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     ({mem_2_reg, reg_write}),
      .dout    (control_WB_ID_EX_out)        //mem_2_reg, reg_write
);
// control_WB_ID_EX pipeline register END

// control_WB_EX_ME pipeline register BEGIN
wire [1:0] control_WB_EX_ME_out;

reg_arstn_en#(
   .DATA_W(2)
)control_WB_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (control_WB_ID_EX_out),
      .dout    (control_WB_EX_ME_out)        //mem_2_reg, reg_write
);
// control_WB_EX_ME pipeline register END

// control_WB_ME_WB pipeline register BEGIN
wire [1:0] control_WB_ME_WB_out;

reg_arstn_en#(
   .DATA_W(2)
)control_WB_ME_WB(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (control_WB_EX_ME_out),
      .dout    (control_WB_ME_WB_out)        //mem_2_reg, reg_write
);
// control_WB_ME_WB pipeline register END
////////////-----------WB-END-------------------

////////////----------REGISTER_BEGIN-------------
// RegFile_Data1_ID_EX pipeline register BEGIN
wire [63:0] RegFile_Data1_ID_EX_out;

reg_arstn_en#(
   .DATA_W(64)
)RegFile_Data1_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (regfile_rdata_1),
      .dout    (RegFile_Data1_ID_EX_out)
);
// RegFile_Data1_ID_EX pipeline register END

// RegFile_Data2_ID_EX pipeline register BEGIN
wire [63:0] RegFile_Data2_ID_EX_out;

reg_arstn_en#(
   .DATA_W(64)
)RegFile_Data2_ID_EX(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (regfile_rdata_2),
      .dout    (RegFile_Data2_ID_EX_out)
);
// RegFile_Data2_ID_EX pipeline register END

// RegFile_Data2_EX_ME pipeline register BEGIN
wire [63:0] RegFile_Data2_EX_ME_out;

reg_arstn_en#(
   .DATA_W(64)
)RegFile_Data2_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (RegFile_Data2_ID_EX_out),
      .dout    (RegFile_Data2_EX_ME_out)
);
// RegFile_Data2_EX_ME pipeline register END
////////////----------REGISTER_END-------------


////////////----------BRANCH_UNIT_BEGIN-------------
// branch_PC_EX_ME pipeline register BEGIN
wire [63:0] branch_PC_EX_ME_out;

reg_arstn_en#(
   .DATA_W(64)
)branch_PC_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (branch_pc),
      .dout    (branch_PC_EX_ME_out) 
);
// branch_PC_EX_ME pipeline register END

// jump_PC_EX_ME pipeline register BEGIN
wire [63:0] jump_PC_EX_ME_out;

reg_arstn_en#(
   .DATA_W(64)
)jump_PC_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (jump_pc),
      .dout    (jump_PC_EX_ME_out) 
);
// jump_PC_EX_ME pipeline register END
////////////----------BRANCH_UNIT_END-------------

////////////----------IMM_GEN_BEGIN-------------
// imm_gen_ID_EX pipeline register BEGIN
wire [63:0] imm_gen_ID_EX_out;

reg_arstn_en#(
   .DATA_W(64)
)branch_PC_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (immediate_extended),
      .dout    (imm_gen_ID_EX_out) 
);
// imm_gen_ID_EX pipeline register END
////////////----------IMM_GEN_END-------------

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(control_WB_ME_WB_out[0]         ),
   .raddr_1  (instruction_IF_ID_out[19:15]),
   .raddr_2  (instruction_IF_ID_out[24:20]),
   .waddr    (instruction_ME_WB_out[11:7] ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

alu_control alu_ctrl(
   .func7_5       (instruction_ID_EX_out[30]   ),
   .func7_0       (instruction_ID_EX_out[25]),
   .func3          (instruction_ID_EX_out[14:12]),
   .alu_op         (control_EX_ID_EX_out[2:1]  ),
   .alu_control    (alu_control       )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (imm_gen_ID_EX_out),
   .input_b (RegFile_Data2_ID_EX_out   ),
   .select_a(control_EX_ID_EX_out[0]   ),
   .mux_out (alu_operand_2     )
);

////////////----------ALU_BEGIN-------------
// ALU_ZERO_EX_ME pipeline register BEGIN
wire ALU_ZERO_EX_ME_out;

reg_arstn_en#(
   .DATA_W(1)
)ALU_ZERO_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (zero_flag),
      .dout    (ALU_ZERO_EX_ME_out) 
);
// ALU_ZERO_EX_ME pipeline register END

// ALU_OUT_EX_ME pipeline register BEGIN
wire [63:0] ALU_OUT_EX_ME_out;

reg_arstn_en#(
   .DATA_W(64)
)ALU_OUT_EX_ME(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (alu_out),
      .dout    (ALU_OUT_EX_ME_out) 
);
// ALU_OUT_EX_ME pipeline register END

// ALU_OUT_ME_WB pipeline register BEGIN
wire [63:0] ALU_OUT_ME_WB_out;

reg_arstn_en#(
   .DATA_W(64)
)ALU_OUT_ME_WB(
      .clk     (clk        ),
      .arst_n  (arst_n     ),
      .en      (enable     ),
      .din     (ALU_OUT_EX_ME_out),
      .dout    (ALU_OUT_ME_WB_out) 
);
// ALU_OUT_ME_WB pipeline register END

////////////----------ALU_END-------------

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (RegFile_Data1_ID_EX_out),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (DATA_MEM_ME_WB_out     ),
   .input_b  (ALU_OUT_ME_WB_out      ),
   .select_a (control_WB_ME_WB_out[1]    ),
   .mux_out  (regfile_wdata)
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (update_PC_ID_EX_out        ),
   .immediate_extended (imm_gen_ID_EX_out),
   .branch_pc          (branch_pc         ),
   .jump_pc            (jump_pc           )
);


endmodule



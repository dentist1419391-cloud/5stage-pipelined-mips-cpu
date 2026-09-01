`timescale 1ns / 1ps

module pipeline_cpu(

    input clk,
    input reset_n,
    
    output        RegWrite_out
    );
    
    
    wire Stall;
    
    wire Branch_EX;
    wire Zero;
    wire Branchtaken_EX=Branch_EX&&Zero;
    wire Jump;
    
    wire [4:0] rd_MEM;
    wire [4:0] rd_WB;
    
    wire [4:0] rs_EX;
    wire [4:0] rt_EX;
    //pc address
    wire [31:0] Instruction_ID;
    wire [4:0] rs_ID=Instruction_ID[25:21];
    wire [4:0] rt_ID=Instruction_ID[20:16];
    wire [4:0] rd_ID=Instruction_ID[15:11];
    wire MemRead_EX;
    
    
    wire [31:0] PC;
    wire [31:0] Next_PC;

    pc u_pc(
        .clk(clk),
        .Stall(Stall),
        .reset_n(reset_n),
        .Next_PC(Next_PC),
        .PC(PC)
    );
    
    wire [31:0] Instruction_IF;
    Instruction_memory u_inst_mem(
        .PC(PC),
        .Instruction_IF(Instruction_IF)
    );
    
    wire Flush_IF_ID;
    wire Flush_ID_EX;
    assign Flush_IF_ID=Jump||Branchtaken_EX;
    assign Flush_ID_EX=Branchtaken_EX;
    
    wire [31:0] PC_Plus4=PC+4;
    wire [31:0] PC_Plus4_ID;
    IF_ID u_IF_ID(
        .clk(clk),
        .reset_n(reset_n),
        .Stall(Stall),
        .Flush_IF_ID(Flush_IF_ID),
        .Instruction_IF(Instruction_IF),
        .PC_Plus4(PC_Plus4),
        .Instruction_ID(Instruction_ID),
        .PC_Plus4_ID(PC_Plus4_ID)
    );
    
    wire RegDst;
    wire Branch;
    wire MemRead;
    wire MemtoReg;
    wire [1:0] ALUop;
    wire MemWrite;
    wire ALUSrc;
    wire RegWrite;
    
    
    
    
    
    
    wire [5:0] control_opcode=Instruction_ID[31:26];
    wire UseRsRt_ID=(control_opcode==6'b000000||control_opcode==6'b101011||control_opcode==6'b000100);                     //r,sw,beq
    wire UseRs_ID=(control_opcode==6'b100011||control_opcode==6'b001000);                                        //lw,addi
    
    
    
        
     
    HazardDetectionUnit u_hazard_unit(
        .rt_EX(rt_EX),
        .rs_ID(rs_ID),
        .rt_ID(rt_ID),
        .MemRead_EX(MemRead_EX),
        .UseRsRt_ID(UseRsRt_ID),
        .UseRs_ID(UseRs_ID),
        .Stall(Stall)
    );
    
    
    ControlUnit u_control_unit(
        .opcode(control_opcode),
        .Instruction_ID(Instruction_ID),
        .Stall(Stall),
        .RegDst(RegDst),
        .Jump(Jump),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUop(ALUop),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite)
    );
    wire [15:0] i_inst=Instruction_ID[15:0];
    wire [31:0] Sign_extend;
    
    SignExtend u_sign_extend(
        .i_inst(i_inst),
        .Sign_extend(Sign_extend)
    );
    
    wire [4:0] Write_register_WB;
    wire [31:0] Write_data_reg_WB;
    wire [31:0] Read_data1;
    wire [31:0] Read_data2;
    
    wire [4:0] Read_register1=Instruction_ID[25:21];    //rs
    wire [4:0] Read_register2=Instruction_ID[20:16];    //rt
    
    wire RegWrite_WB;
    Regfile u_regfile(
        .clk(clk),
        .reset_n(reset_n),
        .RegWrite_WB(RegWrite_WB),
        .Read_register1(Read_register1),
        .Read_register2(Read_register2),
        .Write_register(Write_register_WB),   
        .Write_data(Write_data_reg_WB),          
        .Read_data1(Read_data1),
        .Read_data2(Read_data2)
    );
    
    
    wire [31:0] PC_Plus4_EX;
    wire RegDst_EX;
    wire ALUSrc_EX;
    wire [1:0] ALUop_EX;
    
    
    wire MemWrite_EX;
    wire RegWrite_EX;
    wire MemtoReg_EX;
    wire [31:0] Read_data1_EX;
    wire [31:0] Read_data2_EX;
    wire [31:0] Sign_extend_EX;
    
    wire [4:0] rd_EX;
    wire [31:0] Instruction_EX;
    ID_EX u_ID_EX(
        .clk(clk),
        .reset_n(reset_n),
        .Flush_ID_EX(Flush_ID_EX),
        .Instruction_ID(Instruction_ID),
        .PC_Plus4_ID(PC_Plus4_ID),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .ALUop(ALUop),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .MemtoReg(MemtoReg),
        .Read_data1(Read_data1),
        .Read_data2(Read_data2),
        .Sign_extend(Sign_extend),
        .rt_ID(rt_ID),
        .rd_ID(rd_ID),
        
        .Instruction_EX(Instruction_EX),
        .PC_Plus4_EX(PC_Plus4_EX),
        .RegDst_EX(RegDst_EX),
        .ALUSrc_EX(ALUSrc_EX),
        .ALUop_EX(ALUop_EX),
        .Branch_EX(Branch_EX),
        .MemRead_EX(MemRead_EX),
        .MemWrite_EX(MemWrite_EX),
        .RegWrite_EX(RegWrite_EX),
        .MemtoReg_EX(MemtoReg_EX),
        .Read_data1_EX(Read_data1_EX),
        .Read_data2_EX(Read_data2_EX),
        .Sign_extend_EX(Sign_extend_EX),
        .rt_EX(rt_EX),
        .rd_EX(rd_EX)
    );
    
    
    //EX
    wire [5:0] Funct=Sign_extend_EX[5:0];
    wire [3:0] ALUControl;
    ALUControl u_alucontrol(
        .ALUop(ALUop_EX),
        .Funct(Funct),
        .ALUControl(ALUControl)
    );
    
    
    wire [31:0] ALU_result;
    
    
    
    wire [31:0] i_data1;
    wire [31:0] i_data2;
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;
    wire [31:0] ALU_result_MEM;
    
    reg [31:0] forward_data1;
    reg [31:0] forward_data2;
    
    
    always@(*) begin
        forward_data1=32'b0;
        case(ForwardA)
        2'b00:forward_data1=Read_data1_EX;
        2'b10:forward_data1=ALU_result_MEM;
        2'b01:forward_data1=Write_data_reg_WB;
        endcase
    end
    
        
    always@(*) begin
        forward_data2=32'b0;
        case(ForwardB)
            2'b00:forward_data2=Read_data2_EX;
            2'b10:forward_data2=ALU_result_MEM;
            2'b01:forward_data2=Write_data_reg_WB;
        endcase
      end
      assign i_data1=forward_data1;
      assign i_data2=ALUSrc_EX?Sign_extend_EX:forward_data2;
      wire [31:0] Write_data_EX;
      assign Write_data_EX=forward_data2;
    
    ALU u_alu(
        .i_data1(i_data1),
        .i_data2(i_data2),
        .ALUControl(ALUControl),
        .ALU_result(ALU_result),
        .Zero(Zero)
    );
    
    wire [4:0] Write_register_EX=(RegDst_EX)?rd_EX:rt_EX;
    
    wire [31:0] Branch_PC_EX=PC_Plus4_EX+(Sign_extend_EX<<2);
    
    wire MemRead_MEM;
    wire MemWrite_MEM;
    wire RegWrite_MEM;
    wire MemtoReg_MEM;
    
    wire [4:0] Write_register_MEM;
    wire [31:0] Write_data_MEM;
    wire [31:0] Instruction_MEM;
    EX_MEM u_EX_MEM(
        .clk(clk),
        .reset_n(reset_n),
        .Instruction_EX(Instruction_EX),
        .MemRead_EX(MemRead_EX),
        .MemWrite_EX(MemWrite_EX),
        .RegWrite_EX(RegWrite_EX),
        .MemtoReg_EX(MemtoReg_EX),
        .ALU_result(ALU_result),
        .Write_register_EX(Write_register_EX),
        .Write_data_EX(Write_data_EX),

        .Instruction_MEM(Instruction_MEM),
        .MemRead_MEM(MemRead_MEM),
        .MemWrite_MEM(MemWrite_MEM),
        .RegWrite_MEM(RegWrite_MEM),
        .MemtoReg_MEM(MemtoReg_MEM),
        .ALU_result_MEM(ALU_result_MEM),
        .Write_register_MEM(Write_register_MEM),
        .Write_data_MEM(Write_data_MEM)
    );
    
    //MEM
    
    
    wire [31:0] Read_data;
    
    Data_memory u_data_memory(
        .clk(clk),
        .Addr(ALU_result_MEM),
        .Write_data(Write_data_MEM),
        .MemWrite(MemWrite_MEM),
        .MemRead(MemRead_MEM),
        .Read_data(Read_data)
    );
    
 
    wire MemtoReg_WB;
    wire [31:0] Read_data_WB;
    wire [31:0] ALU_result_WB;
  
    wire [31:0] Instruction_WB;
    MEM_WB u_MEM_WB(
        .clk(clk),
        .reset_n(reset_n),
        .Instruction_MEM(Instruction_MEM),
        .RegWrite_MEM(RegWrite_MEM),
        .MemtoReg_MEM(MemtoReg_MEM),
        .Read_data(Read_data),
        .ALU_result_MEM(ALU_result_MEM),
        .Write_register_MEM(Write_register_MEM),
        
        .Instruction_WB(Instruction_WB),
        .RegWrite_WB(RegWrite_WB),
        .MemtoReg_WB(MemtoReg_WB),
        .Read_data_WB(Read_data_WB),
        .ALU_result_WB(ALU_result_WB),
        .Write_register_WB(Write_register_WB)
    );
    
    //WB
    assign Write_data_reg_WB=MemtoReg_WB?Read_data_WB:ALU_result_WB;
    
    
    
    
    assign rs_EX=Instruction_EX[25:21];
 
    assign rd_MEM=Instruction_MEM[15:11];
    assign rd_WB=Instruction_WB[15:11];
    
    ForwardingUnit u_fowardingunit(
        .rs_EX(rs_EX),
        .rt_EX(rt_EX),
        .Write_register_MEM(Write_register_MEM),
        .Write_register_WB(Write_register_WB),
        .RegWrite_MEM(RegWrite_MEM),
        .RegWrite_WB(RegWrite_WB),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );
    
        
        
    
    
    
    wire [31:0] Jump_PC={PC_Plus4_ID[31:28],Instruction_ID[25:0],2'b00};
    
    assign Next_PC=Branchtaken_EX?Branch_PC_EX:Jump?Jump_PC:PC_Plus4;
    
    
    
   
    assign RegWrite_out       = RegWrite;

endmodule

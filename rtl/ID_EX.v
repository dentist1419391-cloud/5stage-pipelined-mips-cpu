`timescale 1ns / 1ps
module ID_EX(

    input clk,
    input reset_n, 
    input Flush_ID_EX,
    //pc_plus4
    input [31:0] PC_Plus4_ID, 
    input [31:0] Instruction_ID,
    //control
    input RegDst,
    input ALUSrc,
    input [1:0] ALUop,   
    input Branch,
    input MemRead,
    input MemWrite,  
    input RegWrite,
    input MemtoReg,
    //regfile
    input [31:0] Read_data1,
    input [31:0] Read_data2,
    //instruction
    input [31:0] Sign_extend,
    input [4:0] rt_ID,    //instruction[20:16]
    input [4:0] rd_ID,    //instruction[15:11]
    
    //pc_plus4
    output reg [31:0] Instruction_EX,
    output reg [31:0] PC_Plus4_EX,
       
    //control
    output reg RegDst_EX,
    output reg ALUSrc_EX,
    output reg [1:0] ALUop_EX,   
    output reg Branch_EX,
    output reg MemRead_EX,
    output reg MemWrite_EX,  
    output reg RegWrite_EX,
    output reg MemtoReg_EX,
    
    //regfile
    output reg [31:0] Read_data1_EX,
    output reg [31:0] Read_data2_EX,
    
    output reg [31:0] Sign_extend_EX,
    output reg [4:0] rt_EX,
    output reg [4:0] rd_EX    
   
    );
    
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            PC_Plus4_EX<={32{1'b0}};
            RegDst_EX<=1'b0;
            ALUSrc_EX<=1'b0;
            ALUop_EX<=2'b00;
            Branch_EX<=1'b0;
            MemRead_EX<=1'b0;
            MemWrite_EX<=1'b0;
            RegWrite_EX<=1'b0;
            MemtoReg_EX<=1'b0;
            Read_data1_EX<={32{1'b0}};
            Read_data2_EX<={32{1'b0}};
            Sign_extend_EX<={32{1'b0}};
            rt_EX<={5{1'b0}};
            rd_EX<={5{1'b0}};
            Instruction_EX<={32{1'b0}};
        end
        else if(Flush_ID_EX)begin
            PC_Plus4_EX<={32{1'b0}};
            RegDst_EX<=1'b0;
            ALUSrc_EX<=1'b0;
            ALUop_EX<=2'b00;
            Branch_EX<=1'b0;
            MemRead_EX<=1'b0;
            MemWrite_EX<=1'b0;
            RegWrite_EX<=1'b0;
            MemtoReg_EX<=1'b0;
            Read_data1_EX<={32{1'b0}};
            Read_data2_EX<={32{1'b0}};
            Sign_extend_EX<={32{1'b0}};
            rt_EX<={5{1'b0}};
            rd_EX<={5{1'b0}};
            Instruction_EX<={32{1'b0}};
        end
        else begin
            PC_Plus4_EX<=PC_Plus4_ID;
            RegDst_EX<=RegDst;
            ALUSrc_EX<=ALUSrc;
            ALUop_EX<=ALUop;
            Branch_EX<=Branch;
            MemRead_EX<=MemRead;
            MemWrite_EX<=MemWrite;
            RegWrite_EX<=RegWrite;
            MemtoReg_EX<=MemtoReg;
            Read_data1_EX<=Read_data1;
            Read_data2_EX<=Read_data2;
            Sign_extend_EX<=Sign_extend;
            rt_EX<=rt_ID;
            rd_EX<=rd_ID;
            Instruction_EX<=Instruction_ID;
        end
    end
endmodule

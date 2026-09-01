`timescale 1ns / 1ps
module EX_MEM(
    input clk,
    input reset_n,    
    input MemRead_EX,
    input MemWrite_EX,  
    input RegWrite_EX,
    input MemtoReg_EX,
    input [31:0] Instruction_EX,
    
    input [31:0] ALU_result,
 
    input [4:0] Write_register_EX,
    input [31:0] Write_data_EX,
    
    
    output reg [31:0] Instruction_MEM,
    output reg MemRead_MEM,
    output reg MemWrite_MEM,  
    output reg RegWrite_MEM,
    output reg MemtoReg_MEM,
    
    output reg [31:0] ALU_result_MEM,
    
    output reg [4:0] Write_register_MEM,
    output reg [31:0] Write_data_MEM
    
    
    );
    
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            MemRead_MEM<=1'b0;
            MemWrite_MEM<=1'b0;
            RegWrite_MEM<=1'b0;
            MemtoReg_MEM<=1'b0;
            ALU_result_MEM<={32{1'b0}};   
            Write_register_MEM<={5{1'b0}};
            Write_data_MEM<={32{1'b0}};
            Instruction_MEM<={32{1'b0}};
        end
        else begin
            MemRead_MEM<=MemRead_EX;
            MemWrite_MEM<=MemWrite_EX;
            RegWrite_MEM<=RegWrite_EX;
            MemtoReg_MEM<=MemtoReg_EX;
            ALU_result_MEM<=ALU_result;
            Write_register_MEM<=Write_register_EX;
            Write_data_MEM<=Write_data_EX;
            Instruction_MEM<=Instruction_EX;
        end
    end
endmodule

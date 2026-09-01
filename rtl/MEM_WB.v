`timescale 1ns / 1ps
module MEM_WB(

    input clk,
    input reset_n,
    
    input RegWrite_MEM,
    input MemtoReg_MEM,
    input [31:0] Read_data,
    input [31:0] ALU_result_MEM,
    input [4:0] Write_register_MEM,
    input [31:0] Instruction_MEM,
    
    
    output reg RegWrite_WB,
    output reg MemtoReg_WB,
    output reg [31:0] Read_data_WB,
    output reg [31:0] ALU_result_WB,
    output reg [4:0] Write_register_WB,
    output reg [31:0] Instruction_WB
    

    );
    
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            RegWrite_WB<=1'b0;
            MemtoReg_WB<=1'b0;
            Read_data_WB<={32{1'b0}};
            ALU_result_WB<={32{1'b0}};
            Write_register_WB<={5{1'b0}};
            Instruction_WB<={32{1'b0}};
        end
        else begin
            RegWrite_WB<=RegWrite_MEM;
            MemtoReg_WB<=MemtoReg_MEM;
            Read_data_WB<=Read_data;
            ALU_result_WB<=ALU_result_MEM;
            Write_register_WB<=Write_register_MEM;
            Instruction_WB<=Instruction_MEM;
        end
    end
endmodule

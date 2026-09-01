`timescale 1ns / 1ps
module IF_ID(
    input clk,
    input reset_n,
    input Stall,
    input Flush_IF_ID,
    input [31:0] Instruction_IF,
    input [31:0] PC_Plus4,
    output reg [31:0] Instruction_ID,
    output reg [31:0] PC_Plus4_ID
    
   );
   
   always@(posedge clk or negedge reset_n)begin
       if(!reset_n)begin
           Instruction_ID<={32{1'b0}};
           PC_Plus4_ID<={32{1'b0}};
       end
       else if(Flush_IF_ID)begin
           Instruction_ID<={32{1'b0}};
           PC_Plus4_ID<={32{1'b0}};
       end
       else if(Stall)begin
           Instruction_ID<=Instruction_ID;
           PC_Plus4_ID<=PC_Plus4_ID;
       end
       else begin
           Instruction_ID<=Instruction_IF;
           PC_Plus4_ID<=PC_Plus4;
       end
   end
endmodule

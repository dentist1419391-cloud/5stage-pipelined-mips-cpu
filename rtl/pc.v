`timescale 1ns / 1ps
module pc(
    input clk,
    input reset_n,
    input [31:0] Next_PC,
    input Stall,
    output reg [31:0] PC
    );
    
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            PC<=32'b0;
        end
        else if(Stall)begin
            PC<=PC;
        end
        else begin
            PC<=Next_PC;
        end
    end
    
endmodule

`timescale 1ns / 1ps
module ForwardingUnit(
 
    input [4:0] rs_EX,
    input [4:0] rt_EX,
    input [4:0] Write_register_MEM,
    input [4:0] Write_register_WB,
    input RegWrite_MEM,
    input RegWrite_WB,
    
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB

    );
    
    always@(*)begin
        ForwardA=2'b00;
        ForwardB=2'b00;
        
        
        if((Write_register_MEM==rs_EX)&&RegWrite_MEM)begin
            ForwardA=2'b10;
        end
        else if((Write_register_WB==rs_EX)&&RegWrite_WB)begin
            ForwardA=2'b01;
        end
        
        
        if((Write_register_MEM==rt_EX)&&RegWrite_MEM)begin
            ForwardB=2'b10;
        end
        else if((Write_register_WB==rt_EX)&&RegWrite_WB)begin
            ForwardB=2'b01;
        end
    end
        
endmodule

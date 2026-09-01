`timescale 1ns / 1ps
module HazardDetectionUnit(

    input [4:0] rt_EX,
    input [4:0] rs_ID,
    input [4:0] rt_ID,
    input MemRead_EX,
    input UseRsRt_ID,
    input UseRs_ID,
    
    output reg Stall

    );
    
    always@(*)begin
        Stall=1'b0;
        if(UseRsRt_ID&&(rt_EX==rs_ID||rt_EX==rt_ID)&&MemRead_EX)begin
            Stall=1'b1;
        end
        else if(UseRs_ID&&(rt_EX==rs_ID)&&MemRead_EX)begin
            Stall=1'b1;
        end
   end
    
endmodule

`timescale 1ns / 1ps
module ALU(
    input [31:0] i_data1,
    input [31:0] i_data2,
    input [3:0] ALUControl,
    output reg [31:0] ALU_result,
    output Zero

    );
    
    always@(*)begin
        case(ALUControl)
        4'b0000:ALU_result=(i_data1&i_data2);        //and
        4'b0001:ALU_result=(i_data1|i_data2);        //or
        4'b0010:ALU_result=i_data1+i_data2;          //add
        4'b0110:ALU_result=i_data1-i_data2;          //sub
        4'b0111:ALU_result=(i_data1<i_data2)?1:0;    //slt
        4'b1100:ALU_result=~(i_data1|i_data2);       //nor
        default:ALU_result=0;
        endcase
    end
    assign Zero=(ALU_result==32'b0);
    
endmodule



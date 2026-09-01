`timescale 1ns / 1ps
module Regfile(
    
    input clk,
    input reset_n,
    input RegWrite_WB,
    input [4:0] Read_register1,
    input [4:0] Read_register2,
    input [4:0] Write_register,      //write_register_wb
    input [31:0] Write_data,         //write_data_reg_wb
    output [31:0] Read_data1,
    output [31:0] Read_data2

    );
    reg [31:0] registers [0:31];
    assign Read_data1=(RegWrite_WB&&Read_register1==Write_register&&Write_register!=5'd0)?Write_data:registers[Read_register1];
    assign Read_data2=(RegWrite_WB&&Read_register2==Write_register&&Write_register!=5'd0)?Write_data:registers[Read_register2];
    integer i;
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            for(i=0; i<32 ;i=i+1)begin
                registers[i]<={32{1'b0}};
            end
                       
            registers[1]<=32'd5;
            registers[2]<=32'd9;    
            registers[3]<=32'd10;      
            registers[5]<=32'd12;
            registers[6]<=32'd6;         
            registers[7]<=32'd3;
            registers[10]<=32'd4;
            registers[11]<=32'd1;
            
        end
        else if(RegWrite_WB&&Write_register!=5'd0) begin
            registers[Write_register]<=Write_data;
        end
    end
    
    
endmodule

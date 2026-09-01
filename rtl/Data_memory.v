`timescale 1ns / 1ps

module Data_memory(
    
    input clk,
    input [31:0] Addr,
    input [31:0] Write_data,
    input MemWrite,
    input MemRead,
    output [31:0] Read_data
    );
    
    reg [31:0] Data_memory [0:255];
    initial begin
    Data_memory[100]=32'd100; //¼öÁ¤ 
    end
    
    always@(posedge clk)begin
        if(MemWrite)begin
            Data_memory[Addr[9:2]]<=Write_data;    //sync write
        end
    end
    
    assign Read_data=(MemRead)?Data_memory[Addr[9:2]]:32'b0;  //async read
endmodule

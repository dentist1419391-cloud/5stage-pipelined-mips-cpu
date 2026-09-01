`timescale 1ns / 1ps
module ALUControl(
    input [1:0] ALUop,
    input [5:0] Funct, 
    output reg [3:0] ALUControl
    );
    
    always@(*) begin
        ALUControl=4'b0000;
        case(ALUop)
        2'b00:ALUControl=4'b0010;  //lw,sw,addi   ->  add
        2'b01:ALUControl=4'b0110;  //beq          ->  sub
        2'b10:                     //R-type
              case(Funct)
              6'b100000:ALUControl=4'b0010;   // add
              6'b100010:ALUControl=4'b0110;   //sub
              6'b100100:ALUControl=4'b0000;   //and
              6'b100101:ALUControl=4'b0001;   //or
              6'b101010:ALUControl=4'b0111;   //slt
              endcase
        endcase
    end
        
    
    
endmodule

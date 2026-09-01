`timescale 1ns / 1ps
module SignExtend(
    input [15:0] i_inst,
    output [31:0] Sign_extend
    );
    
    assign Sign_extend={{16{i_inst[15]}},i_inst};
endmodule

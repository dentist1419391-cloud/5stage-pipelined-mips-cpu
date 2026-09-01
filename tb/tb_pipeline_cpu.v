`timescale 1ns / 1ps
module tb_pipeline_cpu;
    
    reg clk;
    reg reset_n;
    
    always
    #5 clk=~clk;
    
    initial begin
        clk<=0;
        reset_n<=1;
        
        #10
        reset_n<=0;
        #10
        reset_n<=1;
        
        #500
        $finish;
    end
    
    pipeline_cpu dut(
        .clk(clk),
        .reset_n(reset_n)
    );
        
endmodule

`timescale 1ns / 1ps
module ControlUnit(
    input [5:0] opcode,
    input [31:0] Instruction_ID,
    input Stall,
    output reg RegDst,     //EX stage
    output reg ALUSrc,
    output reg [1:0] ALUop,
    
    output reg Branch,    //EX stage
    output reg MemRead,
    output reg MemWrite,
    
    output reg RegWrite,   //WB stage
    output reg MemtoReg,
    
    output reg Jump
    );
    
    always@(*)begin
        RegDst=1'b0;
        ALUSrc=1'b0;
        MemtoReg=1'b0;
        RegWrite=1'b0;
        MemRead=1'b0;
        MemWrite=1'b0;
        Branch=1'b0;
        ALUop[1]=1'b0;
        ALUop[0]=1'b0; 
        Jump=1'b0;
        if(Stall)begin
            RegDst=1'b0;
            ALUSrc=1'b0;
            MemtoReg=1'b0;
            RegWrite=1'b0;
            MemRead=1'b0;
            MemWrite=1'b0;
            Branch=1'b0;
            ALUop[1]=1'b0;
            ALUop[0]=1'b0; 
            Jump=1'b0;
        end
        else begin
            if(Instruction_ID==32'b0)begin
                RegDst=1'b0;
                ALUSrc=1'b0;
                MemtoReg=1'b0;
                RegWrite=1'b0;
                MemRead=1'b0;
                MemWrite=1'b0;
                Branch=1'b0;
                ALUop[1]=1'b0;
                ALUop[0]=1'b0; 
                Jump=1'b0;
            end
            else begin
            
                case(opcode)
                6'b000000:begin  //R-format
                    RegDst=1'b1;
                    ALUSrc=1'b0;          
                    RegWrite=1'b1;           
                    ALUop=2'b10;       
                    end
                6'b100011:begin  //lw        
                    ALUSrc=1'b1;
                    MemtoReg=1'b1;
                    RegWrite=1'b1;
                    MemRead=1'b1;        
                    end
                6'b101011:begin  //sw   
                    ALUSrc=1'b1;       
                    MemWrite=1'b1;
                    end
                6'b000100:begin //beq
                    Branch=1'b1;
                    ALUop=2'b01;
                    end
                6'b000010:begin  //jump
                    Jump=1'b1;
                    end
                6'b001000:begin    //addi
                    ALUSrc=1'b1;   
                    RegWrite=1'b1;
                end
                endcase
            end
        end
    end
            
    
endmodule

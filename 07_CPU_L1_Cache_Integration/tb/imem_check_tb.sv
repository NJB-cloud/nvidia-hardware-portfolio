`timescale 1ns/1ps

module imem_check_tb;

    logic [31:0] address;
    logic [31:0] instruction;

    instruction_memory dut (
        .address(address),
        .instruction(instruction)
    );

    initial begin

        address = 32'h0000_0000;
        #1;
        $display("PC=%h INST=%h", address, instruction);

        address = 32'h0000_0004;
        #1;
        $display("PC=%h INST=%h", address, instruction);

        address = 32'h0000_0008;
        #1;
        $display("PC=%h INST=%h", address, instruction);

        address = 32'h0000_000C;
        #1;
        $display("PC=%h INST=%h", address, instruction);

        address = 32'h0000_0010;
        #1;
        $display("PC=%h INST=%h", address, instruction);

        $finish;

    end

endmodule
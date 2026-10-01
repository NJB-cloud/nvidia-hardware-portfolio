`timescale 1ns/1ps

module tb_rv32i_alu;

    // Testbench signals
    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_ctrl;
    logic [31:0] result;
    logic        zero;

    // Instantiate ALU
    rv32i_alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );


    initial begin

        // Create waveform file
        $dumpfile("waveform/alu_wave.vcd");

        // Dump ALL signals including DUT internals
        $dumpvars(0, tb_rv32i_alu);


        $display("===== RV32I ALU VERIFICATION START =====");


        // ADD test
        a = 32'd10;
        b = 32'd20;
        alu_ctrl = 4'b0000;
        #10;

        $display("ADD: %d + %d = %d", a, b, result);


        // SUB test
        a = 32'd50;
        b = 32'd15;
        alu_ctrl = 4'b0001;
        #10;

        $display("SUB: %d - %d = %d", a, b, result);


        // AND test
        a = 32'hFFFF0000;
        b = 32'h0F0F0F0F;
        alu_ctrl = 4'b0010;
        #10;

        $display("AND result = %h", result);


        // OR test
        a = 32'hAAAA0000;
        b = 32'h0000BBBB;
        alu_ctrl = 4'b0011;
        #10;

        $display("OR result = %h", result);


        // XOR test
        a = 32'hAAAAAAAA;
        b = 32'h55555555;
        alu_ctrl = 4'b0100;
        #10;

        $display("XOR result = %h", result);



        // SLT test
        a = 32'd5;
        b = 32'd10;
        alu_ctrl = 4'b0101;
        #10;

        $display("SLT result = %d", result);



        // SLL test
        a = 32'b1;
        b = 32'd4;
        alu_ctrl = 4'b0110;
        #10;

        $display("SLL result = %h", result);



        // SRL test
        a = 32'h80000000;
        b = 32'd4;
        alu_ctrl = 4'b0111;
        #10;

        $display("SRL result = %h", result);



        $display("===== TEST COMPLETE =====");

        #10;
        $finish;

    end

endmodule
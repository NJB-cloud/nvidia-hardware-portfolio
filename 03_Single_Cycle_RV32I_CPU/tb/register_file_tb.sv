// ============================================================
// Project 3: Single-Cycle RV32I CPU
// Testbench: RV32I Register File
// ============================================================

`timescale 1ns/1ps

module register_file_tb;

    logic        clk;
    logic        rst_n;

    logic [4:0]  rs1;
    logic [4:0]  rs2;

    logic [31:0] read_data1;
    logic [31:0] read_data2;

    logic [4:0]  rd;
    logic [31:0] write_data;
    logic        reg_write;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    register_file dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .rs1       (rs1),
        .rs2       (rs2),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .rd        (rd),
        .write_data(write_data),
        .reg_write (reg_write)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Waveform
    // --------------------------------------------------------

    initial begin
        $dumpfile("register_file_wave.vcd");
        $dumpvars(0, register_file_tb);
    end

    // --------------------------------------------------------
    // Check task
    // --------------------------------------------------------

    task automatic check_value(
        input logic [31:0] expected,
        input logic [31:0] actual,
        input string       message
    );

        begin

            if (actual === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS: %s | Value = 0x%08h",
                    message,
                    actual
                );

            end

            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %s | Expected = 0x%08h, Got = 0x%08h",
                    message,
                    expected,
                    actual
                );

            end

        end

    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n     = 1'b0;
        rs1       = 5'd0;
        rs2       = 5'd0;
        rd        = 5'd0;
        write_data = 32'h0;
        reg_write = 1'b0;

        $display("");
        $display("==============================================");
        $display("       RV32I REGISTER FILE TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        check_value(
            32'h0000_0000,
            read_data1,
            "x0 reads zero after reset"
        );

        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        rst_n = 1'b1;

        // ----------------------------------------------------
        // Write x1 = 10
        // ----------------------------------------------------

        rd         = 5'd1;
        write_data = 32'd10;
        reg_write  = 1'b1;

        @(posedge clk);
        #1;

        reg_write = 1'b0;

        rs1 = 5'd1;
        #1;

        check_value(
            32'd10,
            read_data1,
            "x1 contains 10"
        );

        // ----------------------------------------------------
        // Write x2 = 20
        // ----------------------------------------------------

        rd         = 5'd2;
        write_data = 32'd20;
        reg_write  = 1'b1;

        @(posedge clk);
        #1;

        reg_write = 1'b0;

        rs2 = 5'd2;
        #1;

        check_value(
            32'd20,
            read_data2,
            "x2 contains 20"
        );

        // ----------------------------------------------------
        // Simultaneous read of x1 and x2
        // ----------------------------------------------------

        rs1 = 5'd1;
        rs2 = 5'd2;
        #1;

        check_value(
            32'd10,
            read_data1,
            "Read port 1 returns x1"
        );

        check_value(
            32'd20,
            read_data2,
            "Read port 2 returns x2"
        );

        // ----------------------------------------------------
        // Attempt to write x0
        // ----------------------------------------------------

        rd         = 5'd0;
        write_data = 32'hFFFF_FFFF;
        reg_write  = 1'b1;

        @(posedge clk);
        #1;

        reg_write = 1'b0;

        rs1 = 5'd0;
        #1;

        check_value(
            32'h0000_0000,
            read_data1,
            "x0 remains permanently zero"
        );

        // ----------------------------------------------------
        // Write a larger value
        // ----------------------------------------------------

        rd         = 5'd10;
        write_data = 32'hDEAD_BEEF;
        reg_write  = 1'b1;

        @(posedge clk);
        #1;

        reg_write = 1'b0;

        rs1 = 5'd10;
        #1;

        check_value(
            32'hDEAD_BEEF,
            read_data1,
            "x10 stores 0xDEADBEEF"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       REGISTER FILE TEST RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display("      ALL REGISTER FILE TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("      REGISTER FILE TESTS FAILED");
            $display("==============================================");

        end

        $finish;

    end

endmodule
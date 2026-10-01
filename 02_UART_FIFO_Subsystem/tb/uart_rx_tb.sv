`timescale 1ns/1ps

// ============================================================
// Project 2: UART + FIFO RTL Subsystem
// Testbench: UART Receiver
// Protocol: 8-N-1
// ============================================================

module uart_rx_tb;

    // --------------------------------------------------------
    // UART configuration
    // --------------------------------------------------------

    localparam int CLK_FREQ  = 1_000_000;
    localparam int BAUD_RATE = 100_000;
    localparam int BAUD_DIV  = CLK_FREQ / BAUD_RATE;

    // --------------------------------------------------------
    // Signals
    // --------------------------------------------------------

    logic       clk;
    logic       rst_n;
    logic       rx;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       busy;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (rx),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .busy     (busy)
    );

    // --------------------------------------------------------
    // Clock
    // 1 MHz = 10 ns period
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // --------------------------------------------------------
    // Waveform dump
    // --------------------------------------------------------

    initial begin
        $dumpfile("waveform/uart_rx_wave.vcd");
        $dumpvars(0, uart_rx_tb);
    end

    // --------------------------------------------------------
    // Check helper
    // --------------------------------------------------------

    task automatic check(
        input logic condition,
        input string message
    );

        begin

            if (condition) begin
                pass_count = pass_count + 1;
                $display("PASS: %s", message);
            end

            else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s", message);
            end

        end

    endtask

    // ========================================================
    // UART BYTE TRANSMITTER
    //
    // 8-N-1:
    //
    //   Idle  = 1
    //   Start = 0
    //   Data  = 8 bits, LSB first
    //   Stop  = 1
    //
    // One UART bit = BAUD_DIV clock cycles
    // ========================================================

    task automatic send_uart_byte(
        input logic [7:0] data
    );

        integer i;

        begin

            // ------------------------------------------------
            // Idle
            // ------------------------------------------------

            rx = 1'b1;

            // ------------------------------------------------
            // Start bit
            // ------------------------------------------------

            rx = 1'b0;

            #(BAUD_DIV * 10);

            // ------------------------------------------------
            // Data bits
            // LSB first
            // ------------------------------------------------

            for (i = 0; i < 8; i = i + 1) begin

                rx = data[i];

                #(BAUD_DIV * 10);

            end

            // ------------------------------------------------
            // Stop bit
            // ------------------------------------------------

            rx = 1'b1;

            // Wait only a small amount here.
            //
            // IMPORTANT:
            // We intentionally do NOT wait a complete extra
            // UART bit here because rx_valid is only a
            // one-clock pulse.
            // ------------------------------------------------

            #10;

        end

    endtask

    // ========================================================
    // MAIN TEST
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initialize
        // ----------------------------------------------------

        pass_count = 0;
        fail_count = 0;

        rx    = 1'b1;
        rst_n = 1'b0;

        // ----------------------------------------------------
        // Header
        // ----------------------------------------------------

        $display("");
        $display("================================================");
        $display("          UART RX VERIFICATION START");
        $display("================================================");

        $display("");
        $display("Configuration:");
        $display("CLK_FREQ  = %0d Hz", CLK_FREQ);
        $display("BAUD_RATE = %0d baud", BAUD_RATE);
        $display("BAUD_DIV  = %0d clocks", BAUD_DIV);

        // ====================================================
        // RESET TEST
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("RESET TEST");
        $display("----------------------------------------------");

        repeat (3)
            @(posedge clk);

        #1;

        check(
            rx_data == 8'h00,
            "RX data is cleared after reset"
        );

        check(
            rx_valid == 1'b0,
            "RX valid is LOW after reset"
        );

        check(
            busy == 1'b0,
            "UART RX is idle after reset"
        );

        // Release reset
        rst_n = 1'b1;

        #1;

        // ====================================================
        // TEST 1
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 1: Receiving 0xA5");
        $display("----------------------------------------------");

        send_uart_byte(8'hA5);

        // Wait for receiver to assert valid
        wait (rx_valid == 1'b1);

        #1;

        check(
            rx_data == 8'hA5,
            "Received byte 0xA5 correctly"
        );

        // rx_valid must be a one-clock pulse
        @(posedge clk);
        #1;

        check(
            rx_valid == 1'b0,
            "RX valid returns LOW after byte 0xA5"
        );

        // ====================================================
        // TEST 2
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 2: Receiving 0x3C");
        $display("----------------------------------------------");

        send_uart_byte(8'h3C);

        wait (rx_valid == 1'b1);

        #1;

        check(
            rx_data == 8'h3C,
            "Received byte 0x3C correctly"
        );

        @(posedge clk);
        #1;

        check(
            rx_valid == 1'b0,
            "RX valid returns LOW after byte 0x3C"
        );

        // ====================================================
        // TEST 3
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 3: Receiving 0x00");
        $display("----------------------------------------------");

        send_uart_byte(8'h00);

        wait (rx_valid == 1'b1);

        #1;

        check(
            rx_data == 8'h00,
            "Received byte 0x00 correctly"
        );

        @(posedge clk);
        #1;

        check(
            rx_valid == 1'b0,
            "RX valid returns LOW after byte 0x00"
        );

        // ====================================================
        // TEST 4
        // ====================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 4: Receiving 0xFF");
        $display("----------------------------------------------");

        send_uart_byte(8'hFF);

        wait (rx_valid == 1'b1);

        #1;

        check(
            rx_data == 8'hFF,
            "Received byte 0xFF correctly"
        );

        @(posedge clk);
        #1;

        check(
            rx_valid == 1'b0,
            "RX valid returns LOW after byte 0xFF"
        );

        // ====================================================
        // FINAL IDLE CHECK
        // ====================================================

        #1;

        check(
            busy == 1'b0,
            "UART RX returns to idle after final byte"
        );

        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("================================================");
        $display("          UART RX VERIFICATION RESULT");
        $display("================================================");

        $display("");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("================================================");
            $display("        ALL UART RX TESTS PASSED");
            $display("================================================");

        end

        else begin

            $display("");
            $display("================================================");
            $display("        UART RX TESTS FAILED");
            $display("================================================");

        end

        $display("");

        // ----------------------------------------------------
        // End simulation
        // ----------------------------------------------------

        $finish;

    end

endmodule
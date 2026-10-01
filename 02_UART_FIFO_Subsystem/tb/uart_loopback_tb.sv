`timescale 1ns/1ps

// ============================================================
// Project 2: UART + FIFO RTL Subsystem
// Testbench: UART TX -> UART RX Loopback
// Protocol: 8-N-1
//
// Purpose:
//   Verify that the UART transmitter and receiver operate
//   correctly together as an integrated subsystem.
//
// TX serial output is directly connected to RX serial input.
// ============================================================

module uart_loopback_tb;

    // --------------------------------------------------------
    // Test configuration
    // --------------------------------------------------------

    localparam int CLK_FREQ  = 1_000_000;
    localparam int BAUD_RATE = 100_000;

    localparam int BAUD_DIV  = CLK_FREQ / BAUD_RATE;

    // --------------------------------------------------------
    // Clock and reset
    // --------------------------------------------------------

    logic clk;
    logic rst_n;

    // --------------------------------------------------------
    // UART TX interface
    // --------------------------------------------------------

    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready;
    logic       tx_serial;
    logic       tx_busy;

    // --------------------------------------------------------
    // UART RX interface
    // --------------------------------------------------------

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;

    // --------------------------------------------------------
    // Verification counters
    // --------------------------------------------------------

    integer pass_count;
    integer fail_count;

    // ========================================================
    // DUT 1: UART TRANSMITTER
    // ========================================================

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) tx_dut (
        .clk      (clk),
        .rst_n    (rst_n),

        .tx_data  (tx_data),
        .tx_valid (tx_valid),
        .tx_ready (tx_ready),

        .tx       (tx_serial),

        .busy     (tx_busy)
    );

    // ========================================================
    // DUT 2: UART RECEIVER
    // ========================================================

    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) rx_dut (
        .clk      (clk),
        .rst_n    (rst_n),

        .rx       (tx_serial),

        .rx_data  (rx_data),
        .rx_valid (rx_valid),

        .busy     (rx_busy)
    );

    // ========================================================
    // CLOCK
    // ========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ========================================================
    // WAVEFORM
    // ========================================================

    initial begin
        $dumpfile("waveform/uart_loopback_wave.vcd");
        $dumpvars(0, uart_loopback_tb);
    end

    // ========================================================
    // CHECK HELPER
    // ========================================================

    task automatic check(
        input logic   condition,
        input string  message
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
    // WAIT FOR RX BYTE
    //
    // Waits until rx_valid becomes active.
    // A timeout protects the testbench from hanging forever
    // if the UART subsystem fails.
    // ========================================================

    task automatic wait_for_rx(
        input logic [7:0] expected_data,
        input string      test_name
    );

        integer timeout_count;
        logic   received;

        begin

            timeout_count = 0;
            received      = 1'b0;

            while ((timeout_count < (BAUD_DIV * 20)) &&
                   !received) begin

                @(posedge clk);

                if (rx_valid) begin

                    received = 1'b1;

                    check(
                        rx_data == expected_data,
                        test_name
                    );

                end

                timeout_count = timeout_count + 1;

            end

            if (!received) begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL: %s -- RX timeout",
                    test_name
                );

            end

        end

    endtask

    // ========================================================
    // SEND ONE BYTE
    //
    // Waits for TX ready, presents one byte, and generates
    // a one-clock tx_valid pulse.
    // ========================================================

    task automatic send_byte(
        input logic [7:0] data
    );

        begin

            // Wait until transmitter is available
            while (!tx_ready)
                @(posedge clk);

            // Present data
            tx_data  = data;
            tx_valid = 1'b1;

            @(posedge clk);

            // Remove valid request
            tx_valid = 1'b0;

            // Keep data stable until transmission starts
            tx_data = data;

        end

    endtask

    // ========================================================
    // MAIN TEST
    // ========================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        tx_data  = 8'h00;
        tx_valid = 1'b0;

        rst_n = 1'b0;

        $display("");
        $display("================================================");
        $display("       UART TX -> RX LOOPBACK VERIFICATION");
        $display("================================================");

        $display("");
        $display("Clock frequency : %0d Hz", CLK_FREQ);
        $display("Baud rate       : %0d", BAUD_RATE);
        $display("Baud divider    : %0d clocks", BAUD_DIV);

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        repeat (5)
            @(posedge clk);

        check(
            tx_serial == 1'b1,
            "TX serial line is HIGH during reset"
        );

        check(
            tx_busy == 1'b0,
            "TX is idle after reset"
        );

        check(
            rx_busy == 1'b0,
            "RX is idle after reset"
        );

        check(
            rx_valid == 1'b0,
            "RX valid is LOW after reset"
        );

        rst_n = 1'b1;

        @(posedge clk);

        // ====================================================
        // TEST 1
        // ====================================================

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 1: Loopback byte 0xA5");
        $display("-----------------------------------------------");

        send_byte(8'hA5);

        wait_for_rx(
            8'hA5,
            "Loopback received 0xA5 correctly"
        );

        // Wait for transmitter to return idle
        while (tx_busy)
            @(posedge clk);

        // ====================================================
        // TEST 2
        // ====================================================

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 2: Loopback byte 0x3C");
        $display("-----------------------------------------------");

        send_byte(8'h3C);

        wait_for_rx(
            8'h3C,
            "Loopback received 0x3C correctly"
        );

        while (tx_busy)
            @(posedge clk);

        // ====================================================
        // TEST 3
        // ====================================================

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 3: Loopback byte 0x00");
        $display("-----------------------------------------------");

        send_byte(8'h00);

        wait_for_rx(
            8'h00,
            "Loopback received 0x00 correctly"
        );

        while (tx_busy)
            @(posedge clk);

        // ====================================================
        // TEST 4
        // ====================================================

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 4: Loopback byte 0xFF");
        $display("-----------------------------------------------");

        send_byte(8'hFF);

        wait_for_rx(
            8'hFF,
            "Loopback received 0xFF correctly"
        );

        while (tx_busy)
            @(posedge clk);

        // ====================================================
        // FINAL IDLE CHECK
        // ====================================================

        @(posedge clk);

        check(
            tx_busy == 1'b0,
            "TX returns to idle after final byte"
        );

        check(
            rx_busy == 1'b0,
            "RX returns to idle after final byte"
        );

        check(
            tx_serial == 1'b1,
            "TX returns to UART idle HIGH"
        );

        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("================================================");
        $display("        UART LOOPBACK VERIFICATION RESULT");
        $display("================================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("================================================");
            $display("       ALL UART LOOPBACK TESTS PASSED");
            $display("================================================");

        end
        else begin

            $display("");
            $display("================================================");
            $display("       UART LOOPBACK TESTS FAILED");
            $display("================================================");

        end

        $display("");

        $finish;

    end

endmodule
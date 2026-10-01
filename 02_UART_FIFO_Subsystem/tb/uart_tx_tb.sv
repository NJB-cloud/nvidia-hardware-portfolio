`timescale 1ns/1ps

// ============================================================
// Project 2: UART + FIFO RTL Subsystem
// Testbench: UART Transmitter
// Protocol: 8-N-1
// ============================================================

module uart_tx_tb;

    // Use small values for fast simulation.
    localparam int CLK_FREQ  = 1_000_000;
    localparam int BAUD_RATE = 100_000;

    localparam int BAUD_DIV = CLK_FREQ / BAUD_RATE;

    logic clk;
    logic rst_n;

    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready;

    logic       tx;
    logic       busy;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),

        .tx_data   (tx_data),
        .tx_valid  (tx_valid),
        .tx_ready  (tx_ready),

        .tx        (tx),
        .busy      (busy)
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
        $dumpfile("waveform/uart_tx_wave.vcd");
        $dumpvars(0, uart_tx_tb);
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

    // --------------------------------------------------------
    // Transmit one byte
    // --------------------------------------------------------

    task automatic transmit_byte(
        input logic [7:0] data
    );
        begin

            // Wait until transmitter is ready
            wait (tx_ready == 1'b1);

            @(negedge clk);

            tx_data  = data;
            tx_valid = 1'b1;

            @(posedge clk);

            #1;

            tx_valid = 1'b0;

            check(
                busy == 1'b1,
                $sformatf(
                    "UART starts transmission of 0x%02h",
                    data
                )
            );

            // Wait until transmission completes
            wait (busy == 1'b0);

            check(
                tx == 1'b1,
                "TX returns to idle HIGH"
            );

        end
    endtask

    // --------------------------------------------------------
    // Main test
    // --------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        tx_data  = 8'h00;
        tx_valid = 1'b0;

        rst_n = 1'b0;

        $display("");
        $display("==============================================");
        $display("      UART TX VERIFICATION START");
        $display("==============================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (3)
            @(posedge clk);

        #1;

        check(
            tx == 1'b1,
            "TX idle state is HIGH after reset"
        );

        check(
            busy == 1'b0,
            "UART TX is not busy after reset"
        );

        check(
            tx_ready == 1'b1,
            "UART TX is ready after reset"
        );

        rst_n = 1'b1;

        // ----------------------------------------------------
        // Byte transmission tests
        // ----------------------------------------------------

        transmit_byte(8'hA5);

        transmit_byte(8'h3C);

        transmit_byte(8'h00);

        transmit_byte(8'hFF);

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("        UART TX VERIFICATION RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display("          ALL UART TX TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("          UART TX TESTS FAILED");
            $display("==============================================");

        end

        $finish;

    end

endmodule
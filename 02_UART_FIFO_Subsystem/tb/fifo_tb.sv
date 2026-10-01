`timescale 1ns/1ps

// ============================================================
// Project 2: Verified UART + FIFO Subsystem
// Testbench: Parameterized FIFO
// Self-checking verification environment
// ============================================================

module fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;

    logic clk;
    logic rst_n;

    logic [DATA_WIDTH-1:0] wr_data;
    logic                  wr_en;

    logic [DATA_WIDTH-1:0] rd_data;
    logic                  rd_en;

    logic                  full;
    logic                  empty;
    logic                  overflow;
    logic                  underflow;

    logic [$clog2(DEPTH+1)-1:0] count;

    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),

        .wr_data   (wr_data),
        .wr_en     (wr_en),

        .rd_data   (rd_data),
        .rd_en     (rd_en),

        .full      (full),
        .empty     (empty),

        .overflow  (overflow),
        .underflow (underflow),

        .count     (count)
    );

    // --------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Waveform dump
    // --------------------------------------------------------

    initial begin
        $dumpfile("waveform/fifo_wave.vcd");
        $dumpvars(0, fifo_tb);
    end

    // --------------------------------------------------------
    // Test helpers
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
    // Write one entry
    // --------------------------------------------------------

    task automatic fifo_write(
        input logic [DATA_WIDTH-1:0] data
    );
        begin

            @(negedge clk);

            wr_data = data;
            wr_en   = 1'b1;

            @(posedge clk);

            #1;

            wr_en = 1'b0;

        end
    endtask

    // --------------------------------------------------------
    // Read one entry
    // --------------------------------------------------------

    task automatic fifo_read(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin

            @(negedge clk);

            rd_en = 1'b1;

            @(posedge clk);

            #1;

            check(
                rd_data === expected,
                $sformatf(
                    "Read data = 0x%02h, expected = 0x%02h",
                    rd_data,
                    expected
                )
            );

            rd_en = 1'b0;

        end
    endtask

    // --------------------------------------------------------
    // Main verification
    // --------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        wr_data = '0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;

        rst_n   = 1'b0;

        $display("");
        $display("==============================================");
        $display("     FIFO VERIFICATION START");
        $display("==============================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        check(empty, "FIFO is empty after reset");
        check(!full, "FIFO is not full after reset");
        check(count == 0, "FIFO count is zero after reset");

        rst_n = 1'b1;

        // ----------------------------------------------------
        // Basic write/read test
        // ----------------------------------------------------

        fifo_write(8'hA5);

        check(
            count == 1,
            "Count becomes 1 after one write"
        );

        check(
            !empty,
            "FIFO is not empty after write"
        );

        fifo_read(8'hA5);

        check(
            empty,
            "FIFO becomes empty after reading stored data"
        );

        check(
            count == 0,
            "Count returns to zero"
        );

        // ----------------------------------------------------
        // Multiple-entry FIFO test
        // ----------------------------------------------------

        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);
        fifo_write(8'h44);

        check(
            count == 4,
            "Count becomes 4 after four writes"
        );

        fifo_read(8'h11);
        fifo_read(8'h22);
        fifo_read(8'h33);
        fifo_read(8'h44);

        check(
            empty,
            "FIFO empty after reading all four entries"
        );

        // ----------------------------------------------------
        // Fill FIFO completely
        // ----------------------------------------------------

        fifo_write(8'h00);
        fifo_write(8'h01);
        fifo_write(8'h02);
        fifo_write(8'h03);
        fifo_write(8'h04);
        fifo_write(8'h05);
        fifo_write(8'h06);
        fifo_write(8'h07);
        fifo_write(8'h08);
        fifo_write(8'h09);
        fifo_write(8'h0A);
        fifo_write(8'h0B);
        fifo_write(8'h0C);
        fifo_write(8'h0D);
        fifo_write(8'h0E);
        fifo_write(8'h0F);

        check(
            full,
            "FIFO reports FULL after 16 writes"
        );

        check(
            count == DEPTH,
            "FIFO count equals DEPTH when full"
        );

        // ----------------------------------------------------
        // Overflow test
        // ----------------------------------------------------

        @(negedge clk);

        wr_data = 8'hFF;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        check(
            overflow,
            "Overflow detected when writing to full FIFO"
        );

        check(
            count == DEPTH,
            "Count remains unchanged during overflow"
        );

        wr_en = 1'b0;

        // ----------------------------------------------------
        // Read all entries and verify ordering
        // ----------------------------------------------------

        fifo_read(8'h00);
        fifo_read(8'h01);
        fifo_read(8'h02);
        fifo_read(8'h03);
        fifo_read(8'h04);
        fifo_read(8'h05);
        fifo_read(8'h06);
        fifo_read(8'h07);
        fifo_read(8'h08);
        fifo_read(8'h09);
        fifo_read(8'h0A);
        fifo_read(8'h0B);
        fifo_read(8'h0C);
        fifo_read(8'h0D);
        fifo_read(8'h0E);
        fifo_read(8'h0F);

        check(
            empty,
            "FIFO empty after reading all 16 entries"
        );

        // ----------------------------------------------------
        // Underflow test
        // ----------------------------------------------------

        @(negedge clk);

        rd_en = 1'b1;

        @(posedge clk);

        #1;

        check(
            underflow,
            "Underflow detected when reading empty FIFO"
        );

        check(
            count == 0,
            "Count remains zero during underflow"
        );

        rd_en = 1'b0;

        // ----------------------------------------------------
        // Simultaneous read/write test
        // ----------------------------------------------------

        fifo_write(8'h55);

        @(negedge clk);

        wr_data = 8'hAA;
        wr_en   = 1'b1;
        rd_en   = 1'b1;

        @(posedge clk);

        #1;

        check(
            rd_data === 8'h55,
            "Simultaneous read/write returns previous FIFO data"
        );

        check(
            count == 1,
            "Count remains unchanged during simultaneous read/write"
        );

        wr_en = 1'b0;
        rd_en = 1'b0;

        fifo_read(8'hAA);

        check(
            empty,
            "FIFO empty after final simultaneous-operation test"
        );

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("          FIFO VERIFICATION RESULT");
        $display("==============================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin
            $display("");
            $display("==============================================");
            $display("          ALL TESTS PASSED");
            $display("==============================================");
        end
        else begin
            $display("");
            $display("==============================================");
            $display("          TESTS FAILED");
            $display("==============================================");
        end

        $finish;

    end

endmodule
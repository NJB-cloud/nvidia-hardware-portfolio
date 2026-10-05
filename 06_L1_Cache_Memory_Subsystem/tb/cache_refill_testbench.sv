`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Miss / Refill / Hit Testbench
//
// Verifies:
//
// 1. First access produces a miss.
// 2. Cache requests a memory line.
// 3. Memory returns 128-bit line.
// 4. Cache installs the line.
// 5. CPU receives requested data.
// 6. Second access to same address hits.
// 7. Second access does NOT request memory again.
// ============================================================

module cache_refill_testbench;

    logic clk;
    logic reset_n;

    // --------------------------------------------------------
    // CPU interface
    // --------------------------------------------------------

    logic        cpu_req_valid;
    logic        cpu_req_ready;
    logic [31:0] cpu_req_addr;
    logic        cpu_req_write;
    logic [31:0] cpu_req_wdata;
    logic [3:0]  cpu_req_be;

    logic        cpu_rsp_valid;
    logic [31:0] cpu_rsp_rdata;

    // --------------------------------------------------------
    // Memory interface
    // --------------------------------------------------------

    logic         mem_req_valid;
    logic         mem_req_ready;
    logic         mem_req_write;
    logic [31:0]  mem_req_addr;
    logic [127:0] mem_req_wdata;

    logic         mem_rsp_valid;
    logic [127:0] mem_rsp_rdata;

    // Count memory transactions for verification.
    integer memory_request_count;


    // ========================================================
    // DUT
    // ========================================================

    l1_cache dut (
        .clk(clk),
        .reset_n(reset_n),

        .cpu_req_valid(cpu_req_valid),
        .cpu_req_ready(cpu_req_ready),

        .cpu_req_addr(cpu_req_addr),
        .cpu_req_write(cpu_req_write),
        .cpu_req_wdata(cpu_req_wdata),
        .cpu_req_be(cpu_req_be),

        .cpu_rsp_valid(cpu_rsp_valid),
        .cpu_rsp_rdata(cpu_rsp_rdata),

        .mem_req_valid(mem_req_valid),
        .mem_req_ready(mem_req_ready),

        .mem_req_write(mem_req_write),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),

        .mem_rsp_valid(mem_rsp_valid),
        .mem_rsp_rdata(mem_rsp_rdata)
    );


    // ========================================================
    // Clock
    // ========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ========================================================
    // VCD
    // ========================================================

    initial begin

        $dumpfile("cache_refill.vcd");

        $dumpvars(0, cache_refill_testbench);

    end


    // ========================================================
    // Memory request monitor
    // ========================================================

    always @(posedge clk) begin

        if (mem_req_valid && mem_req_ready) begin

            memory_request_count =
                memory_request_count + 1;

            $display(
                "MEMORY REQUEST %0d : %s ADDR = %08h",
                memory_request_count,
                mem_req_write ? "WRITE" : "READ ",
                mem_req_addr
            );

        end

    end


    // ========================================================
    // Main test
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------

        reset_n = 1'b0;

        cpu_req_valid = 1'b0;
        cpu_req_addr  = 32'b0;
        cpu_req_write = 1'b0;
        cpu_req_wdata = 32'b0;
        cpu_req_be    = 4'b1111;

        mem_req_ready = 1'b1;

        mem_rsp_valid = 1'b0;
        mem_rsp_rdata = 128'b0;

        memory_request_count = 0;


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (3)
            @(posedge clk);

        reset_n = 1'b1;


        // ====================================================
        // TEST 1
        //
        // First access to 0x00001000.
        //
        // This should MISS.
        // ====================================================

        @(posedge clk);

        cpu_req_addr  <= 32'h00001000;
        cpu_req_write <= 1'b0;
        cpu_req_wdata <= 32'b0;
        cpu_req_be    <= 4'b1111;
        cpu_req_valid <= 1'b1;


        // Wait until cache accepts request.

        wait (cpu_req_ready == 1'b1);

        @(posedge clk);

        cpu_req_valid <= 1'b0;


        // ----------------------------------------------------
        // Wait for refill memory request.
        // ----------------------------------------------------

        wait (mem_req_valid == 1'b1);


        if (mem_req_write !== 1'b0) begin

            $display(
                "ERROR: First access unexpectedly requested write-back."
            );

            $finish;

        end


        if (mem_req_addr !== 32'h00001000) begin

            $display(
                "ERROR: Wrong refill address. Expected %08h got %08h",
                32'h00001000,
                mem_req_addr
            );

            $finish;

        end


        $display(
            "PASS: Initial access generated refill request."
        );


        // ====================================================
        // Supply memory line
        //
        // Word 0 = AAAAAAAA
        // Word 1 = BBBBBBBB
        // Word 2 = CCCCCCCC
        // Word 3 = DDDDDDDD
        // ====================================================

        @(posedge clk);

        mem_rsp_rdata <= {
            32'hDDDDDDDD,
            32'hCCCCCCCC,
            32'hBBBBBBBB,
            32'hAAAAAAAA
        };

        mem_rsp_valid <= 1'b1;


        @(posedge clk);

        mem_rsp_valid <= 1'b0;


        // ----------------------------------------------------
        // Wait for CPU response.
        // ----------------------------------------------------

        wait (cpu_rsp_valid == 1'b1);


        if (cpu_rsp_rdata !== 32'hAAAAAAAA) begin

            $display(
                "ERROR: Refill returned wrong data. Expected %08h got %08h",
                32'hAAAAAAAA,
                cpu_rsp_rdata
            );

            $finish;

        end


        $display(
            "PASS: Refill completed and returned correct Word 0."
        );


        // ----------------------------------------------------
        // Allow RESPOND to return to IDLE.
        // ----------------------------------------------------

        @(posedge clk);


        // ====================================================
        // TEST 2
        //
        // Access exactly the same address again.
        //
        // This MUST be a cache hit.
        // ====================================================

        cpu_req_addr  <= 32'h00001000;
        cpu_req_write <= 1'b0;
        cpu_req_wdata <= 32'b0;
        cpu_req_be    <= 4'b1111;
        cpu_req_valid <= 1'b1;


        // Wait for request acceptance.

        wait (cpu_req_ready == 1'b1);

        @(posedge clk);

        cpu_req_valid <= 1'b0;


        // ----------------------------------------------------
        // Verify that no memory request occurs before the
        // cache response.
        // ----------------------------------------------------

        fork

            begin

                wait (cpu_rsp_valid == 1'b1);

            end


            begin

                wait (mem_req_valid == 1'b1);

                $display(
                    "ERROR: Cache hit generated an unexpected memory request."
                );

                $finish;

            end

        join_any

        disable fork;


        // ----------------------------------------------------
        // Verify hit data.
        // ----------------------------------------------------

        if (cpu_rsp_rdata !== 32'hAAAAAAAA) begin

            $display(
                "ERROR: Cache hit returned wrong data. Expected %08h got %08h",
                32'hAAAAAAAA,
                cpu_rsp_rdata
            );

            $finish;

        end


        $display(
            "PASS: Second access hit and returned cached data."
        );


        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================");
        $display(" CACHE REFILL TEST COMPLETE");
        $display("==============================");
        $display("PASS: MISS -> REFILL -> HIT");
        $display("==============================");
        $display("");


        #20;

        $finish;

    end

endmodule
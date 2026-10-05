`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Performance Regression
//
// Measures:
//
//   - CPU accesses
//   - CPU hits
//   - CPU misses
//   - Hit rate
//   - Miss rate
//   - Read/write accesses
//   - Refill transactions
//   - Write-back transactions
//   - CPU request-to-response latency
//   - Average latency
//
// IMPORTANT:
// Hit/miss classification is inferred from whether a memory
// transaction occurs between CPU request acceptance and CPU
// response.
//
// This avoids relying on undocumented internal DUT signals.
// ============================================================

module cache_performance_testbench;

    // ========================================================
    // Clock / reset
    // ========================================================

    logic clk;
    logic reset_n;


    // ========================================================
    // CPU interface
    // ========================================================

    logic        cpu_req_valid;
    logic        cpu_req_ready;

    logic [31:0] cpu_req_addr;
    logic        cpu_req_write;
    logic [31:0] cpu_req_wdata;
    logic [3:0]  cpu_req_be;

    logic        cpu_rsp_valid;
    logic [31:0] cpu_rsp_rdata;


    // ========================================================
    // Memory interface
    // ========================================================

    logic         mem_req_valid;
    logic         mem_req_ready;

    logic         mem_req_write;
    logic [31:0]  mem_req_addr;
    logic [127:0] mem_req_wdata;

    logic         mem_rsp_valid;
    logic [127:0] mem_rsp_rdata;


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

        $dumpfile("cache_performance.vcd");

        $dumpvars(0, cache_performance_testbench);

    end


    // ========================================================
    // Backing memory
    // ========================================================

    logic [127:0] memory [0:4095];

    integer i;


    // ========================================================
    // Performance counters
    // ========================================================

    integer total_accesses;

    integer read_accesses;
    integer write_accesses;

    integer hit_count;
    integer miss_count;

    integer refill_count;
    integer writeback_count;

    integer total_latency;
    integer min_latency;
    integer max_latency;

    integer current_latency;

    integer test_failures;


    // ========================================================
    // Temporary transaction state
    // ========================================================

    integer request_cycle;
    integer response_cycle;

    integer memory_activity_count;


    // ========================================================
    // Initialize memory
    // ========================================================

    initial begin

        for (i = 0; i < 4096; i = i + 1) begin

            memory[i] = {
                32'h10000000 + i,
                32'h20000000 + i,
                32'h30000000 + i,
                32'h40000000 + i
            };

        end

    end


    // ========================================================
    // Memory interface always ready
    // ========================================================

    assign mem_req_ready = 1'b1;


    // ========================================================
    // Memory model
    // ========================================================

    always @(posedge clk) begin

        mem_rsp_valid <= 1'b0;


        if (mem_req_valid && mem_req_ready) begin

            memory_activity_count =
                memory_activity_count + 1;


            // ------------------------------------------------
            // Write-back
            // ------------------------------------------------

            if (mem_req_write) begin

                writeback_count =
                    writeback_count + 1;

                memory[mem_req_addr[15:4]] <=
                    mem_req_wdata;

            end


            // ------------------------------------------------
            // Refill
            // ------------------------------------------------

            else begin

                refill_count =
                    refill_count + 1;

                mem_rsp_rdata <=
                    memory[mem_req_addr[15:4]];

                mem_rsp_valid <= 1'b1;

            end

        end

    end


    // ========================================================
    // CPU READ TASK
    // ========================================================

    task automatic do_read;

        input [31:0] address;

        integer start_memory_activity;
        integer end_memory_activity;

        begin

            // -----------------------------------------------
            // Record memory activity before request.
            // -----------------------------------------------

            start_memory_activity =
                memory_activity_count;


            // -----------------------------------------------
            // Issue request.
            // -----------------------------------------------

            cpu_req_addr  <= address;
            cpu_req_write <= 1'b0;
            cpu_req_wdata <= 32'b0;
            cpu_req_be    <= 4'b1111;
            cpu_req_valid <= 1'b1;


            wait (cpu_req_ready == 1'b1);


            @(posedge clk);


            cpu_req_valid <= 1'b0;


            // -----------------------------------------------
            // Record request cycle.
            // -----------------------------------------------

            request_cycle =
                $time / 10;


            // -----------------------------------------------
            // Wait for CPU response.
            // -----------------------------------------------

            wait (cpu_rsp_valid == 1'b1);


            response_cycle =
                $time / 10;


            current_latency =
                response_cycle - request_cycle;


            if (current_latency < 0)
                current_latency = 0;


            // -----------------------------------------------
            // Determine hit/miss from memory activity.
            // -----------------------------------------------

            end_memory_activity =
                memory_activity_count;


            total_accesses =
                total_accesses + 1;

            read_accesses =
                read_accesses + 1;


            total_latency =
                total_latency + current_latency;


            if (current_latency < min_latency)
                min_latency = current_latency;


            if (current_latency > max_latency)
                max_latency = current_latency;


            if (end_memory_activity ==
                start_memory_activity) begin

                hit_count =
                    hit_count + 1;

            end

            else begin

                miss_count =
                    miss_count + 1;

            end


            $display(
                "READ  ADDR=%08h LATENCY=%0d cycles %s",
                address,
                current_latency,
                (end_memory_activity ==
                 start_memory_activity)
                 ? "HIT"
                 : "MISS"
            );


            @(posedge clk);

        end

    endtask


    // ========================================================
    // CPU WRITE TASK
    // ========================================================

    task automatic do_write;

        input [31:0] address;
        input [31:0] data;
        input [3:0]  byte_enable;

        integer start_memory_activity;
        integer end_memory_activity;

        begin

            start_memory_activity =
                memory_activity_count;


            // -----------------------------------------------
            // Issue request.
            // -----------------------------------------------

            cpu_req_addr  <= address;
            cpu_req_write <= 1'b1;
            cpu_req_wdata <= data;
            cpu_req_be    <= byte_enable;
            cpu_req_valid <= 1'b1;


            wait (cpu_req_ready == 1'b1);


            @(posedge clk);


            cpu_req_valid <= 1'b0;


            request_cycle =
                $time / 10;


            // -----------------------------------------------
            // Wait for response.
            // -----------------------------------------------

            wait (cpu_rsp_valid == 1'b1);


            response_cycle =
                $time / 10;


            current_latency =
                response_cycle - request_cycle;


            if (current_latency < 0)
                current_latency = 0;


            end_memory_activity =
                memory_activity_count;


            total_accesses =
                total_accesses + 1;

            write_accesses =
                write_accesses + 1;


            total_latency =
                total_latency + current_latency;


            if (current_latency < min_latency)
                min_latency = current_latency;


            if (current_latency > max_latency)
                max_latency = current_latency;


            if (end_memory_activity ==
                start_memory_activity) begin

                hit_count =
                    hit_count + 1;

            end

            else begin

                miss_count =
                    miss_count + 1;

            end


            $display(
                "WRITE ADDR=%08h DATA=%08h BE=%b LATENCY=%0d cycles %s",
                address,
                data,
                byte_enable,
                current_latency,
                (end_memory_activity ==
                 start_memory_activity)
                 ? "HIT"
                 : "MISS"
            );


            @(posedge clk);

        end

    endtask


    // ========================================================
    // Main performance workload
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initialize counters
        // ----------------------------------------------------

        total_accesses = 0;

        read_accesses = 0;
        write_accesses = 0;

        hit_count = 0;
        miss_count = 0;

        refill_count = 0;
        writeback_count = 0;

        total_latency = 0;

        min_latency = 999999;

        max_latency = 0;

        memory_activity_count = 0;

        test_failures = 0;


        // ----------------------------------------------------
        // CPU initial state
        // ----------------------------------------------------

        reset_n = 1'b0;

        cpu_req_valid = 1'b0;
        cpu_req_addr  = 32'b0;
        cpu_req_write = 1'b0;
        cpu_req_wdata = 32'b0;
        cpu_req_be    = 4'b1111;

        mem_rsp_valid = 1'b0;
        mem_rsp_rdata = 128'b0;


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (4)
            @(posedge clk);

        reset_n = 1'b1;


        // ====================================================
        // PERFORMANCE WORKLOAD
        //
        // 1. Cold reads
        // 2. Repeated reads -> hits
        // 3. Writes -> write hits
        // 4. Conflicting lines -> misses/writebacks
        // 5. Different words
        // ====================================================

        $display("");
        $display("==============================================");
        $display(" L1 CACHE PERFORMANCE REGRESSION");
        $display("==============================================");
        $display("");


        // ----------------------------------------------------
        // Cold misses
        // ----------------------------------------------------

        do_read(32'h00001000);
        do_read(32'h00001010);
        do_read(32'h00001020);
        do_read(32'h00001030);


        // ----------------------------------------------------
        // Repeated accesses
        // These should be hits.
        // ----------------------------------------------------

        do_read(32'h00001000);
        do_read(32'h00001010);
        do_read(32'h00001020);
        do_read(32'h00001030);


        // ----------------------------------------------------
        // Word offsets
        // ----------------------------------------------------

        do_read(32'h00001004);
        do_read(32'h00001008);
        do_read(32'h0000100C);


        // ----------------------------------------------------
        // Write hits
        // ----------------------------------------------------

        do_write(
            32'h00001000,
            32'hAAAA0001,
            4'b1111
        );

        do_write(
            32'h00001004,
            32'hBBBB0002,
            4'b1111
        );


        // ----------------------------------------------------
        // Conflict:
        //
        // 0x1000 and 0x5000 map to the same direct-mapped
        // cache index.
        // ----------------------------------------------------

        do_write(
            32'h00001000,
            32'hDEADBEEF,
            4'b1111
        );

        do_read(32'h00005000);


        // ----------------------------------------------------
        // Return to A.
        //
        // This should force another conflict.
        // ----------------------------------------------------

        do_read(32'h00001000);


        // ----------------------------------------------------
        // More conflict traffic
        // ----------------------------------------------------

        do_write(
            32'h00005000,
            32'hCAFEBABE,
            4'b1111
        );

        do_read(32'h00001000);

        do_read(32'h00005000);


        // ----------------------------------------------------
        // Partial writes
        // ----------------------------------------------------

        do_write(
            32'h00001008,
            32'h000000AA,
            4'b0001
        );

        do_write(
            32'h00001008,
            32'h0000BB00,
            4'b0010
        );

        do_write(
            32'h00001008,
            32'h00CC0000,
            4'b0100
        );

        do_write(
            32'h00001008,
            32'hDD000000,
            4'b1000
        );


        // ----------------------------------------------------
        // Final hit accesses
        // ----------------------------------------------------

        do_read(32'h00001008);
        do_read(32'h00001000);


        // ====================================================
        // PERFORMANCE REPORT
        // ====================================================

        $display("");
        $display("==============================================");
        $display(" L1 CACHE PERFORMANCE RESULTS");
        $display("==============================================");

        $display(
            "Total CPU accesses   : %0d",
            total_accesses
        );

        $display(
            "Read accesses        : %0d",
            read_accesses
        );

        $display(
            "Write accesses       : %0d",
            write_accesses
        );

        $display(
            "Hits                 : %0d",
            hit_count
        );

        $display(
            "Misses               : %0d",
            miss_count
        );


        if (total_accesses > 0) begin

            $display(
                "Hit rate             : %0.2f%%",
                (100.0 * hit_count) /
                total_accesses
            );

            $display(
                "Miss rate            : %0.2f%%",
                (100.0 * miss_count) /
                total_accesses
            );

        end


        $display(
            "Memory refills       : %0d",
            refill_count
        );

        $display(
            "Memory write-backs   : %0d",
            writeback_count
        );

        $display(
            "Total latency        : %0d cycles",
            total_latency
        );

        $display(
            "Minimum latency      : %0d cycles",
            min_latency
        );

        $display(
            "Maximum latency      : %0d cycles",
            max_latency
        );


        if (total_accesses > 0) begin

            $display(
                "Average latency      : %0.2f cycles",
                (1.0 * total_latency) /
                total_accesses
            );

        end


        $display("==============================================");


        // ====================================================
        // Sanity checks
        // ====================================================

        if (hit_count + miss_count != total_accesses) begin

            test_failures =
                test_failures + 1;

            $display(
                "ERROR: Hit + miss count does not equal total accesses."
            );

        end


        if (refill_count != miss_count) begin

            $display(
                "WARNING: Refill count (%0d) differs from miss count (%0d).",
                refill_count,
                miss_count
            );

        end


        if (test_failures == 0) begin

            $display("");
            $display(
                "PERFORMANCE REGRESSION: PASS"
            );

        end

        else begin

            $display("");
            $display(
                "PERFORMANCE REGRESSION: FAIL"
            );

        end


        $display("");
        $display("==============================================");
        $display("");


        #20;

        $finish;

    end

endmodule
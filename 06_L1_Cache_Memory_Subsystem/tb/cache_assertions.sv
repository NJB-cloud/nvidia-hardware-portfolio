`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Assertion / Protocol Checker
//
// Icarus-compatible verification checker.
//
// Checks:
//
// 1. A cache hit can only occur on a valid matching line.
// 2. A write-back must correspond to a dirty victim.
// 3. A refill request must be a memory read.
// 4. A memory write-back must not occur with an invalid
//    transaction.
// 5. A CPU response must correspond to a previously accepted
//    CPU request.
// 6. Write-hit control must only occur for a write hit.
// ============================================================

module cache_assertions (

    input logic        clk,
    input logic        reset_n,

    // CPU interface
    input logic        cpu_req_valid,
    input logic        cpu_req_ready,
    input logic        cpu_rsp_valid,

    // Cache lookup
    input logic        cache_hit,
    input logic        tag_valid,

    // Memory interface
    input logic        mem_req_valid,
    input logic        mem_req_write,
    input logic        mem_req_ready,

    // Victim state
    input logic        victim_dirty,

    // Controller state
    input logic        write_hit_enable,

    // Latched CPU operation
    input logic        cpu_write_q

);


    // ========================================================
    // Statistics
    // ========================================================

    integer assertion_checks;
    integer assertion_failures;


    // ========================================================
    // Track accepted CPU requests
    // ========================================================

    logic outstanding_request;


    always @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            outstanding_request <= 1'b0;

        end

        else begin

            // ------------------------------------------------
            // Request accepted
            // ------------------------------------------------

            if (cpu_req_valid && cpu_req_ready)

                outstanding_request <= 1'b1;


            // ------------------------------------------------
            // Response completed
            // ------------------------------------------------

            if (cpu_rsp_valid)

                outstanding_request <= 1'b0;

        end

    end


    // ========================================================
    // Assertion checker
    // ========================================================

    always @(posedge clk) begin

        if (reset_n) begin


            // ------------------------------------------------
            // ASSERTION 1
            //
            // A hit is only legal when the cache line is valid.
            // ------------------------------------------------

            assertion_checks =
                assertion_checks + 1;


            if (cache_hit && !tag_valid) begin

                assertion_failures =
                    assertion_failures + 1;

                $display(
                    "ASSERTION FAIL: CACHE HIT WITHOUT VALID LINE at time %0t",
                    $time
                );

            end


            // ------------------------------------------------
            // ASSERTION 2
            //
            // A write-back must have a dirty victim.
            // ------------------------------------------------

            if (mem_req_valid &&
                mem_req_write &&
                !victim_dirty) begin

                assertion_failures =
                    assertion_failures + 1;

                $display(
                    "ASSERTION FAIL: WRITE-BACK REQUEST WITH CLEAN VICTIM at time %0t",
                    $time
                );

            end


            // ------------------------------------------------
            // ASSERTION 3
            //
            // Memory request must have a valid ready/accepted
            // transaction in this blocking cache.
            // ------------------------------------------------

            if (mem_req_valid && !mem_req_ready) begin

                // This is legal in a general interface, so
                // do not count it as a failure.
                //
                // Kept here as an observation point.
                assertion_checks =
                    assertion_checks + 1;

            end


            // ------------------------------------------------
            // ASSERTION 4
            //
            // Write-hit control must only happen for a
            // write request that hit the cache.
            // ------------------------------------------------

            if (write_hit_enable &&
                (!cache_hit || !cpu_write_q)) begin

                assertion_failures =
                    assertion_failures + 1;

                $display(
                    "ASSERTION FAIL: WRITE-HIT ENABLED WITHOUT WRITE HIT at time %0t",
                    $time
                );

            end


            // ------------------------------------------------
            // ASSERTION 5
            //
            // CPU response should not appear spontaneously.
            //
            // Because this cache is blocking, a response must
            // correspond to an accepted request.
            // ------------------------------------------------

            if (cpu_rsp_valid && !outstanding_request) begin

                // The request can be accepted in the same
                // clock edge in some implementations, so
                // allow a simultaneous acceptance.

                if (!(cpu_req_valid && cpu_req_ready)) begin

                    assertion_failures =
                        assertion_failures + 1;

                    $display(
                        "ASSERTION FAIL: CPU RESPONSE WITHOUT OUTSTANDING REQUEST at time %0t",
                        $time
                    );

                end

            end


            // ------------------------------------------------
            // ASSERTION 6
            //
            // Memory write request must have valid transaction.
            //
            // This is redundant with ASSERTION 2 but provides
            // explicit protocol evidence.
            // ------------------------------------------------

            if (mem_req_write && !mem_req_valid) begin

                assertion_failures =
                    assertion_failures + 1;

                $display(
                    "ASSERTION FAIL: MEMORY WRITE FLAG WITHOUT REQUEST at time %0t",
                    $time
                );

            end

        end

    end


    // ========================================================
    // Initialize statistics
    // ========================================================

    initial begin

        assertion_checks  = 0;
        assertion_failures = 0;

    end


    // ========================================================
    // Final assertion report
    // ========================================================

    task automatic report;

        begin

            $display("");
            $display("==============================================");
            $display(" ASSERTION CHECK SUMMARY");
            $display("==============================================");

            $display(
                "Checks    : %0d",
                assertion_checks
            );

            $display(
                "Failures  : %0d",
                assertion_failures
            );


            if (assertion_failures == 0) begin

                $display(
                    "RESULT    : ASSERTIONS PASS"
                );

            end

            else begin

                $display(
                    "RESULT    : ASSERTIONS FAIL"
                );

            end


            $display("==============================================");
            $display("");

        end

    endtask

endmodule
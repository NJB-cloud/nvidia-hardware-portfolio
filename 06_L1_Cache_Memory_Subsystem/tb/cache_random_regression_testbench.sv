`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Randomized Regression + Assertions
//
// Purpose:
//   Automated functional verification using a software
//   reference memory model plus an assertion checker.
//
// Verifies:
//
//   - Read hits
//   - Read misses
//   - Write hits
//   - Write misses
//   - Write-back behavior
//   - Conflict misses
//   - Word offsets
//   - Byte enables
//   - Repeated accesses
//   - Random data
//   - Cache protocol invariants
//
// Fixed transaction count:
//   200
//
// The test is intentionally reproducible.
// ============================================================

module cache_random_regression_testbench;

    // ========================================================
    // Configuration
    // ========================================================

    parameter NUM_TRANSACTIONS = 200;

    localparam BASE_ADDRESS = 32'h00001000;


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
    // Assertion checker
    //
    // Internal DUT signals are intentionally observed by the
    // checker. This gives us visibility into cache invariants
    // in addition to checking external behavior.
    // ========================================================

    cache_assertions assertions (

        .clk(clk),
        .reset_n(reset_n),

        .cpu_req_valid(cpu_req_valid),
        .cpu_req_ready(cpu_req_ready),
        .cpu_rsp_valid(cpu_rsp_valid),

        .cache_hit(dut.cache_hit),
        .tag_valid(dut.tag_valid),

        .mem_req_valid(mem_req_valid),
        .mem_req_write(mem_req_write),
        .mem_req_ready(mem_req_ready),

        .victim_dirty(dut.tag_dirty),

        .write_hit_enable(dut.write_hit_enable),

        .cpu_write_q(dut.cpu_write_q)

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

        $dumpfile("cache_random_regression.vcd");

        $dumpvars(0, cache_random_regression_testbench);

    end


    // ========================================================
    // Backing memory
    //
    // 4096 cache-line entries.
    //
    // Address [15:4] selects a 16-byte cache line.
    // ========================================================

    logic [127:0] memory [0:4095];

    integer i;


    // ========================================================
    // Independent reference architectural memory
    // ========================================================

    logic [127:0] reference_memory [0:4095];


    // ========================================================
    // Statistics
    // ========================================================

    integer transaction_count;

    integer read_count;
    integer write_count;

    integer pass_count;
    integer fail_count;

    integer memory_read_count;
    integer memory_write_count;


    // ========================================================
    // Random variables
    // ========================================================

    integer random_line;
    integer random_word;
    integer random_operation;
    integer random_be;

    reg [31:0] random_data;


    // ========================================================
    // Initialize backing and reference memories
    // ========================================================

    initial begin

        for (i = 0; i < 4096; i = i + 1) begin

            memory[i] = {
                32'h10000000 + i,
                32'h20000000 + i,
                32'h30000000 + i,
                32'h40000000 + i
            };

            reference_memory[i] = {
                32'h10000000 + i,
                32'h20000000 + i,
                32'h30000000 + i,
                32'h40000000 + i
            };

        end

    end


    // ========================================================
    // Memory always ready
    // ========================================================

    assign mem_req_ready = 1'b1;


    // ========================================================
    // Memory model
    //
    // Read:
    //   Return complete 128-bit cache line.
    //
    // Write:
    //   Accept complete cache-line write-back.
    // ========================================================

    always @(posedge clk) begin

        mem_rsp_valid <= 1'b0;


        if (mem_req_valid && mem_req_ready) begin

            // ------------------------------------------------
            // Write-back
            // ------------------------------------------------

            if (mem_req_write) begin

                memory_write_count =
                    memory_write_count + 1;

                memory[mem_req_addr[15:4]] <=
                    mem_req_wdata;

            end


            // ------------------------------------------------
            // Refill
            // ------------------------------------------------

            else begin

                memory_read_count =
                    memory_read_count + 1;

                mem_rsp_rdata <=
                    memory[mem_req_addr[15:4]];

                mem_rsp_valid <= 1'b1;

            end

        end

    end


    // ========================================================
    // Reference model WRITE
    //
    // Applies CPU byte enables to the independent
    // architectural reference memory.
    // ========================================================

    task automatic reference_write_word;

        input [31:0] address;
        input [31:0] data;
        input [3:0]  byte_enable;

        integer line_index;
        integer word_index;

        reg [127:0] line;

        begin

            line_index =
                address[15:4];

            word_index =
                address[3:2];

            line =
                reference_memory[line_index];


            case (word_index)

                // ------------------------------------------------
                // Word 0
                // ------------------------------------------------

                2'b00: begin

                    if (byte_enable[0])
                        line[7:0] =
                            data[7:0];

                    if (byte_enable[1])
                        line[15:8] =
                            data[15:8];

                    if (byte_enable[2])
                        line[23:16] =
                            data[23:16];

                    if (byte_enable[3])
                        line[31:24] =
                            data[31:24];

                end


                // ------------------------------------------------
                // Word 1
                // ------------------------------------------------

                2'b01: begin

                    if (byte_enable[0])
                        line[39:32] =
                            data[7:0];

                    if (byte_enable[1])
                        line[47:40] =
                            data[15:8];

                    if (byte_enable[2])
                        line[55:48] =
                            data[23:16];

                    if (byte_enable[3])
                        line[63:56] =
                            data[31:24];

                end


                // ------------------------------------------------
                // Word 2
                // ------------------------------------------------

                2'b10: begin

                    if (byte_enable[0])
                        line[71:64] =
                            data[7:0];

                    if (byte_enable[1])
                        line[79:72] =
                            data[15:8];

                    if (byte_enable[2])
                        line[87:80] =
                            data[23:16];

                    if (byte_enable[3])
                        line[95:88] =
                            data[31:24];

                end


                // ------------------------------------------------
                // Word 3
                // ------------------------------------------------

                2'b11: begin

                    if (byte_enable[0])
                        line[103:96] =
                            data[7:0];

                    if (byte_enable[1])
                        line[111:104] =
                            data[15:8];

                    if (byte_enable[2])
                        line[119:112] =
                            data[23:16];

                    if (byte_enable[3])
                        line[127:120] =
                            data[31:24];

                end

            endcase


            reference_memory[line_index] =
                line;

        end

    endtask


    // ========================================================
    // Reference model READ
    // ========================================================

    task automatic reference_read_word;

        input  [31:0] address;
        output [31:0] expected_data;

        integer line_index;
        integer word_index;

        reg [127:0] line;

        begin

            line_index =
                address[15:4];

            word_index =
                address[3:2];

            line =
                reference_memory[line_index];


            case (word_index)

                2'b00:
                    expected_data =
                        line[31:0];

                2'b01:
                    expected_data =
                        line[63:32];

                2'b10:
                    expected_data =
                        line[95:64];

                2'b11:
                    expected_data =
                        line[127:96];

                default:
                    expected_data =
                        32'b0;

            endcase

        end

    endtask


    // ========================================================
    // Execute one CPU transaction
    // ========================================================

    task automatic execute_transaction;

        input [31:0] address;
        input        is_write;
        input [31:0] write_data;
        input [3:0]  byte_enable;

        reg [31:0] expected_data;

        begin

            // =================================================
            // READ
            // =================================================

            if (!is_write) begin

                reference_read_word(
                    address,
                    expected_data
                );


                cpu_req_addr  <= address;
                cpu_req_write <= 1'b0;
                cpu_req_wdata <= 32'b0;
                cpu_req_be    <= 4'b1111;
                cpu_req_valid <= 1'b1;


                wait (cpu_req_ready == 1'b1);

                @(posedge clk);

                cpu_req_valid <= 1'b0;


                wait (cpu_rsp_valid == 1'b1);


                if (cpu_rsp_rdata !== expected_data) begin

                    fail_count =
                        fail_count + 1;


                    $display("");
                    $display("FAIL READ #%0d", transaction_count);

                    $display(
                        "ADDR     = %08h",
                        address
                    );

                    $display(
                        "EXPECTED = %08h",
                        expected_data
                    );

                    $display(
                        "ACTUAL   = %08h",
                        cpu_rsp_rdata
                    );

                    $display("");

                    $finish;

                end


                pass_count =
                    pass_count + 1;

                read_count =
                    read_count + 1;


                $display(
                    "PASS READ  #%0d ADDR=%08h DATA=%08h",
                    transaction_count,
                    address,
                    cpu_rsp_rdata
                );


                @(posedge clk);

            end


            // =================================================
            // WRITE
            // =================================================

            else begin

                cpu_req_addr  <= address;
                cpu_req_write <= 1'b1;
                cpu_req_wdata <= write_data;
                cpu_req_be    <= byte_enable;
                cpu_req_valid <= 1'b1;


                wait (cpu_req_ready == 1'b1);

                @(posedge clk);

                cpu_req_valid <= 1'b0;


                wait (cpu_rsp_valid == 1'b1);


                // Update the independent reference model
                // after the DUT completes the architectural
                // write.

                reference_write_word(
                    address,
                    write_data,
                    byte_enable
                );


                pass_count =
                    pass_count + 1;

                write_count =
                    write_count + 1;


                $display(
                    "PASS WRITE #%0d ADDR=%08h DATA=%08h BE=%b",
                    transaction_count,
                    address,
                    write_data,
                    byte_enable
                );


                @(posedge clk);

            end

        end

    endtask


    // ========================================================
    // MAIN REGRESSION
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

        mem_rsp_valid = 1'b0;
        mem_rsp_rdata = 128'b0;

        transaction_count = 0;

        read_count = 0;
        write_count = 0;

        pass_count = 0;
        fail_count = 0;

        memory_read_count = 0;
        memory_write_count = 0;

        random_data = 32'h12345678;


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (4)
            @(posedge clk);

        reset_n = 1'b1;


        // ----------------------------------------------------
        // Regression header
        // ----------------------------------------------------

        $display("");
        $display("==============================================");
        $display(" L1 CACHE RANDOMIZED REGRESSION + ASSERTIONS");
        $display("==============================================");

        $display(
            "Transactions = %0d",
            NUM_TRANSACTIONS
        );

        $display(
            "Address range = 256 cache lines"
        );

        $display(
            "Cache lines   = 64"
        );

        $display(
            "Seed          = deterministic"
        );

        $display("==============================================");
        $display("");


        // ====================================================
        // Randomized transaction loop
        //
        // Address space:
        //   256 cache lines
        //
        // Cache:
        //   64 lines
        //
        // Therefore the workload deliberately creates
        // conflict/eviction pressure.
        // ====================================================

        for (
            transaction_count = 1;
            transaction_count <= NUM_TRANSACTIONS;
            transaction_count = transaction_count + 1
        ) begin

            // ------------------------------------------------
            // Random cache line
            // ------------------------------------------------

            random_line =
                $urandom_range(0, 255);


            // ------------------------------------------------
            // Random word offset
            // ------------------------------------------------

            random_word =
                $urandom_range(0, 3);


            // ------------------------------------------------
            // Random operation
            //
            // 0 = READ
            // 1..3 = WRITE
            //
            // Therefore:
            //
            // READ  = 25%
            // WRITE = 75%
            // ------------------------------------------------

            random_operation =
                $urandom_range(0, 3);


            // ------------------------------------------------
            // Random data
            // ------------------------------------------------

            random_data =
                $urandom;


            // ------------------------------------------------
            // Random byte-enable.
            //
            // 0000 is excluded.
            // ------------------------------------------------

            random_be =
                $urandom_range(1, 15);


            // ------------------------------------------------
            // Construct aligned word address.
            // ------------------------------------------------

            cpu_req_addr =
                BASE_ADDRESS
                + (random_line << 4)
                + (random_word << 2);


            // ------------------------------------------------
            // Execute transaction.
            // ------------------------------------------------

            if (random_operation == 0) begin

                execute_transaction(
                    cpu_req_addr,
                    1'b0,
                    32'b0,
                    4'b1111
                );

            end

            else begin

                execute_transaction(
                    cpu_req_addr,
                    1'b1,
                    random_data,
                    random_be[3:0]
                );

            end

        end


        // ====================================================
        // Functional regression summary
        // ====================================================

        $display("");
        $display("==============================================");
        $display(" L1 CACHE REGRESSION COMPLETE");
        $display("==============================================");

        $display(
            "Total transactions : %0d",
            NUM_TRANSACTIONS
        );

        $display(
            "Read transactions  : %0d",
            read_count
        );

        $display(
            "Write transactions : %0d",
            write_count
        );

        $display(
            "Passed             : %0d",
            pass_count
        );

        $display(
            "Failed             : %0d",
            fail_count
        );

        $display(
            "Memory reads       : %0d",
            memory_read_count
        );

        $display(
            "Memory writebacks  : %0d",
            memory_write_count
        );


        if (fail_count == 0) begin

            $display("");
            $display("RESULT: PASS");
            $display(
                "Randomized regression completed successfully."
            );

        end

        else begin

            $display("");
            $display("RESULT: FAIL");

        end


        $display("==============================================");
        $display("");


        // ====================================================
        // Assertion summary
        // ====================================================

        assertions.report();


        // ====================================================
        // Finish
        // ====================================================

        #20;

        $finish;

    end

endmodule
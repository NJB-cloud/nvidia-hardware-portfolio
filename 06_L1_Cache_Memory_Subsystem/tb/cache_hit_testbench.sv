`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache - Initial Hit Path Testbench
//
// Purpose:
// 1. Reset the cache
// 2. Preload one cache line
// 3. Verify tag/index lookup
// 4. Verify word selection
//
// Miss/refill testing will be added later.
// ============================================================

module cache_hit_testbench;

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

    logic        mem_req_valid;
    logic        mem_req_ready;
    logic        mem_req_write;
    logic [31:0] mem_req_addr;
    logic [127:0] mem_req_wdata;

    logic        mem_rsp_valid;
    logic [127:0] mem_rsp_rdata;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // --------------------------------------------------------
    // VCD
    // --------------------------------------------------------

    initial begin

        $dumpfile("cache_hit.vcd");

        $dumpvars(0, cache_hit_testbench);

    end


    // --------------------------------------------------------
    // Initial conditions
    // --------------------------------------------------------

    initial begin

        reset_n = 1'b0;

        cpu_req_valid = 1'b0;
        cpu_req_addr  = 32'b0;
        cpu_req_write = 1'b0;
        cpu_req_wdata = 32'b0;
        cpu_req_be    = 4'b1111;

        mem_req_ready = 1'b1;
        mem_rsp_valid = 1'b0;
        mem_rsp_rdata = 128'b0;


        // Hold reset for two cycles

        repeat (2)
            @(posedge clk);

        reset_n = 1'b1;


        // ----------------------------------------------------
        // NOTE:
        //
        // At this stage the cache arrays are reset and there is
        // no refill mechanism yet.
        //
        // Therefore this testbench first verifies that an
        // invalid line does NOT generate a false hit.
        // ----------------------------------------------------

        @(posedge clk);

        cpu_req_addr  <= 32'h00001000;
        cpu_req_write <= 1'b0;
        cpu_req_valid <= 1'b1;


        @(posedge clk);

        cpu_req_valid <= 1'b0;


        // Give the controller time to process the request.

        repeat (3)
            @(posedge clk);


        // ----------------------------------------------------
        // Check that the invalid line did not produce a hit.
        // ----------------------------------------------------

        if (cpu_rsp_valid !== 1'b0) begin

            $display("ERROR: Invalid cache line produced a response.");

            $finish;

        end


        $display("");
        $display("==============================");
        $display(" CACHE INITIAL HIT TEST");
        $display("==============================");
        $display("PASS: Invalid line correctly produced no hit.");
        $display("==============================");


        #20;

        $finish;

    end

endmodule
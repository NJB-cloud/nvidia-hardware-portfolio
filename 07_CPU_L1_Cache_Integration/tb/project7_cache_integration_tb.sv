`timescale 1ns/1ps

// ============================================================
// Project 7
// CPU + L1 Cache Integration Testbench
//
// Purpose:
//   Verifies the top-level connection:
//
//       RV32I CPU
//          |
//          v
//       L1 Cache
//          |
//          v
//       Memory Model
//
// This is the first end-to-end Project 7 integration test.
// ============================================================

module project7_cache_integration_tb;

    // ========================================================
    // CLOCK / RESET
    // ========================================================

    logic clk;
    logic rst_n;

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;


    // ========================================================
    // CPU <-> L1 CACHE INTERFACE
    // ========================================================

    logic        cache_req_valid;
    logic        cache_req_ready;

    logic [31:0] cache_req_addr;
    logic        cache_req_write;
    logic [31:0] cache_req_wdata;
    logic [3:0]  cache_req_be;

    logic        cache_rsp_valid;
    logic [31:0] cache_rsp_rdata;


    // ========================================================
    // L1 CACHE <-> MEMORY
    // ========================================================

    logic        mem_req_valid;
    logic        mem_req_ready;

    logic        mem_req_write;
    logic [31:0] mem_req_addr;
    logic [127:0] mem_req_wdata;

    logic        mem_rsp_valid;
    logic [127:0] mem_rsp_rdata;


    // ========================================================
    // CPU DEBUG SIGNALS
    // ========================================================

    logic [31:0] current_pc;
    logic [31:0] instruction;

    logic [31:0] ex_alu_result_debug;
    logic [31:0] mem_alu_result_debug;
    logic [31:0] wb_data_debug;

    logic        stall_debug;
    logic [1:0]  forward_a_debug;
    logic [1:0]  forward_b_debug;


    // ========================================================
    // CPU
    // ========================================================

    pipelined_core #(
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256)
    ) dut_cpu (

        .clk(clk),
        .rst_n(rst_n),

        // CPU -> L1
        .cache_req_valid(cache_req_valid),
        .cache_req_ready(cache_req_ready),

        .cache_req_addr(cache_req_addr),
        .cache_req_write(cache_req_write),
        .cache_req_wdata(cache_req_wdata),
        .cache_req_be(cache_req_be),

        // L1 -> CPU
        .cache_rsp_valid(cache_rsp_valid),
        .cache_rsp_rdata(cache_rsp_rdata),

        // Debug
        .current_pc(current_pc),
        .instruction(instruction),

        .ex_alu_result_debug(ex_alu_result_debug),
        .mem_alu_result_debug(mem_alu_result_debug),
        .wb_data_debug(wb_data_debug),

        .stall_debug(stall_debug),
        .forward_a_debug(forward_a_debug),
        .forward_b_debug(forward_b_debug)
    );


    // ========================================================
    // L1 CACHE
    // ========================================================

    l1_cache #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .LINE_COUNT(64),
        .LINE_WIDTH(128)
    ) dut_l1_cache (

        .clk(clk),
        .reset_n(rst_n),

        // CPU side
        .cpu_req_valid(cache_req_valid),
        .cpu_req_ready(cache_req_ready),

        .cpu_req_addr(cache_req_addr),
        .cpu_req_write(cache_req_write),
        .cpu_req_wdata(cache_req_wdata),
        .cpu_req_be(cache_req_be),

        .cpu_rsp_valid(cache_rsp_valid),
        .cpu_rsp_rdata(cache_rsp_rdata),

        // Memory side
        .mem_req_valid(mem_req_valid),
        .mem_req_ready(mem_req_ready),

        .mem_req_write(mem_req_write),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),

        .mem_rsp_valid(mem_rsp_valid),
        .mem_rsp_rdata(mem_rsp_rdata)
    );


    // ========================================================
    // MAIN MEMORY MODEL
    // ========================================================

    memory_model #(
        .DEPTH(256)
    ) dut_memory (

        .clk(clk),
        .reset_n(rst_n),

        .req_valid(mem_req_valid),
        .req_ready(mem_req_ready),

        .req_write(mem_req_write),
        .req_addr(mem_req_addr),
        .req_wdata(mem_req_wdata),

        .rsp_valid(mem_rsp_valid),
        .rsp_rdata(mem_rsp_rdata)
    );


    // ========================================================
    // RESET
    // ========================================================

    initial begin

        rst_n = 1'b0;

        #25;

        rst_n = 1'b1;

    end


    // ========================================================
    // MONITOR
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            $display(
                "T=%0t PC=%08h INST=%08h CACHE_REQ=%b CACHE_READY=%b CACHE_WRITE=%b CACHE_RSP=%b STALL=%b",
                $time,
                current_pc,
                instruction,
                cache_req_valid,
                cache_req_ready,
                cache_req_write,
                cache_rsp_valid,
                stall_debug
            );

        end

    end


    // ========================================================
    // TIMEOUT
    // ========================================================

    initial begin

        #5000;

        $display("");
        $display("==============================================");
        $display("PROJECT 7 TIMEOUT");
        $display("==============================================");

        $finish;

    end


    // ========================================================
    // VCD WAVEFORM
    // ========================================================

    initial begin

        $dumpfile("./reports/project7_cache_integration.vcd");

        $dumpvars(
            0,
            project7_cache_integration_tb
        );

    end


    // ========================================================
    // END-OF-SIMULATION CHECK
    // ========================================================

    initial begin

        #4500;

        $display("");
        $display("==============================================");
        $display("PROJECT 7 INTEGRATION SIMULATION COMPLETED");
        $display("==============================================");

        $display(
            "Final PC        = %08h",
            current_pc
        );

        $display(
            "Final WB data   = %08h",
            wb_data_debug
        );

        $display(
            "Cache request   = %b",
            cache_req_valid
        );

        $display(
            "Cache response  = %b",
            cache_rsp_valid
        );

        $display(
            "==============================================");

        $finish;

    end

endmodule
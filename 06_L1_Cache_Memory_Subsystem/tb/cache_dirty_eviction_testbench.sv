`timescale 1ns/1ps

// ============================================================
// Project 6
// Dirty Eviction / Write-Back Testbench
//
// Test sequence:
//
// 1. Read address A
// 2. A misses and is refilled
// 3. Write DEADBEEF to A
// 4. A becomes dirty
// 5. Read conflicting address B
// 6. A is written back to memory
// 7. B is refilled
// 8. Verify memory contains modified A
//
// A = 0x00001000
// B = 0x00005000
//
// Both addresses map to cache index 0,
// but have different tags.
// ============================================================

module cache_dirty_eviction_testbench;

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
    // Clock generation
    // ========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ========================================================
    // VCD waveform
    // ========================================================

    initial begin

        $dumpfile("cache_dirty_eviction.vcd");

        $dumpvars(0, cache_dirty_eviction_testbench);

    end


    // ========================================================
    // Testbench memory model
    //
    // 4096 cache-line entries.
    //
    // Address mapping:
    //
    // memory index = address[15:4]
    //
    // This allows:
    //
    // 0x1000 >> 4 = 0x100 = 256
    // 0x5000 >> 4 = 0x500 = 1280
    // ========================================================

    logic [127:0] memory [0:4095];

    integer i;

    integer memory_read_count;
    integer memory_write_count;


    // ========================================================
    // Initialize test memory
    // ========================================================

    initial begin

        for (i = 0; i < 4096; i = i + 1)

            memory[i] = 128'b0;


        // ----------------------------------------------------
        // Initial cache line for A
        //
        // Word 0 = 11111111
        // Word 1 = 22222222
        // Word 2 = 33333333
        // Word 3 = 44444444
        // ----------------------------------------------------

        memory[32'h00001000 >> 4] = {

            32'h44444444,
            32'h33333333,
            32'h22222222,
            32'h11111111

        };


        // ----------------------------------------------------
        // Initial cache line for B
        //
        // Word 0 = BBBBBBBB
        // Word 1 = CCCCCCCC
        // Word 2 = DDDDDDDD
        // Word 3 = EEEEEEEE
        // ----------------------------------------------------

        memory[32'h00005000 >> 4] = {

            32'hEEEEEEEE,
            32'hDDDDDDDD,
            32'hCCCCCCCC,
            32'hBBBBBBBB

        };

    end


    // ========================================================
    // Memory is always ready
    // ========================================================

    assign mem_req_ready = 1'b1;


    // ========================================================
    // Memory transaction / response logic
    // ========================================================

    always @(posedge clk) begin

        // Default: no response this cycle.

        mem_rsp_valid <= 1'b0;


        // ----------------------------------------------------
        // Accept memory transaction
        // ----------------------------------------------------

        if (mem_req_valid && mem_req_ready) begin


            // =================================================
            // WRITE-BACK
            // =================================================

            if (mem_req_write) begin

                memory_write_count =
                    memory_write_count + 1;


                memory[mem_req_addr[15:4]] <=
                    mem_req_wdata;


                $display(
                    "MEMORY WRITE %0d : ADDR = %08h DATA = %032h",
                    memory_write_count,
                    mem_req_addr,
                    mem_req_wdata
                );

            end


            // =================================================
            // READ / REFILL
            // =================================================

            else begin

                memory_read_count =
                    memory_read_count + 1;


                mem_rsp_rdata <=
                    memory[mem_req_addr[15:4]];


                mem_rsp_valid <= 1'b1;


                $display(
                    "MEMORY READ %0d  : ADDR = %08h",
                    memory_read_count,
                    mem_req_addr
                );

            end

        end

    end


    // ========================================================
    // CPU READ TASK
    // ========================================================

    task automatic cpu_read;

        input [31:0] address;
        input [31:0] expected_data;

        begin

            cpu_req_addr  <= address;
            cpu_req_write <= 1'b0;
            cpu_req_wdata <= 32'b0;
            cpu_req_be    <= 4'b1111;
            cpu_req_valid <= 1'b1;


            // Wait until cache accepts request.

            wait (cpu_req_ready == 1'b1);


            @(posedge clk);

            cpu_req_valid <= 1'b0;


            // Wait for cache response.

            wait (cpu_rsp_valid == 1'b1);


            // Check returned data.

            if (cpu_rsp_rdata !== expected_data) begin

                $display(
                    "ERROR: READ %08h expected %08h got %08h",
                    address,
                    expected_data,
                    cpu_rsp_rdata
                );

                $finish;

            end


            $display(
                "PASS: READ %08h returned %08h",
                address,
                cpu_rsp_rdata
            );


            // Allow response state to complete.

            @(posedge clk);

        end

    endtask


    // ========================================================
    // CPU WRITE TASK
    // ========================================================

    task automatic cpu_write;

        input [31:0] address;
        input [31:0] data;

        begin

            cpu_req_addr  <= address;
            cpu_req_write <= 1'b1;
            cpu_req_wdata <= data;
            cpu_req_be    <= 4'b1111;
            cpu_req_valid <= 1'b1;


            // Wait until cache accepts request.

            wait (cpu_req_ready == 1'b1);


            @(posedge clk);

            cpu_req_valid <= 1'b0;


            // Wait for write response.

            wait (cpu_rsp_valid == 1'b1);


            $display(
                "PASS: WRITE %08h <= %08h",
                address,
                data
            );


            @(posedge clk);

        end

    endtask


    // ========================================================
    // MAIN TEST
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

        memory_read_count  = 0;
        memory_write_count = 0;


        // ====================================================
        // RESET
        // ====================================================

        repeat (3)
            @(posedge clk);

        reset_n = 1'b1;


        // ====================================================
        // STEP 1
        //
        // Read A.
        //
        // Expected:
        //
        // MISS
        //   ↓
        // MEMORY READ
        //   ↓
        // REFILL
        // ====================================================

        cpu_read(
            32'h00001000,
            32'h11111111
        );


        // ====================================================
        // STEP 2
        //
        // Write DEADBEEF to A.
        //
        // This should be a WRITE HIT.
        //
        // The cache line should become DIRTY.
        // ====================================================

        cpu_write(
            32'h00001000,
            32'hDEADBEEF
        );


        // ====================================================
        // STEP 3
        //
        // Read B.
        //
        // A and B have the same cache index:
        //
        // A = 0x00001000
        // B = 0x00005000
        //
        // But their tags differ.
        //
        // Therefore B causes a conflict miss.
        //
        // Since A is dirty:
        //
        // WRITE BACK A
        //       ↓
        // REFILL B
        // ====================================================

        cpu_read(
            32'h00005000,
            32'hBBBBBBBB
        );


        // ====================================================
        // Verify exactly one write-back occurred.
        // ====================================================

        if (memory_write_count !== 1) begin

            $display(
                "ERROR: Expected exactly 1 write-back, got %0d",
                memory_write_count
            );

            $finish;

        end


        $display(
            "PASS: Dirty victim generated exactly one write-back."
        );


        // ====================================================
        // Verify modified A data reached memory.
        //
        // Word 0 must now be DEADBEEF.
        // ====================================================

        #1;


        if (memory[32'h00001000 >> 4][31:0]
            !== 32'hDEADBEEF) begin

            $display(
                "ERROR: Memory did not receive modified A data."
            );

            $display(
                "Expected: DEADBEEF"
            );

            $display(
                "Actual  : %08h",
                memory[32'h00001000 >> 4][31:0]
            );

            $finish;

        end


        $display(
            "PASS: Modified A data was written back to memory."
        );


        // ====================================================
        // Final result
        // ====================================================

        $display("");

        $display("==============================");
        $display(" DIRTY EVICTION TEST COMPLETE");
        $display("==============================");

        $display("PASS: READ MISS");
        $display("PASS: WRITE HIT");
        $display("PASS: DIRTY VICTIM");
        $display("PASS: WRITE-BACK");
        $display("PASS: CONFLICT REFILL");
        $display("PASS: MEMORY DATA PRESERVED");

        $display("==============================");
        $display("");


        #20;

        $finish;

    end

endmodule
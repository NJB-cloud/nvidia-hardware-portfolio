`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Data Path Verification
//
// Verifies:
//
// 1. All four 32-bit words in a 128-bit cache line.
// 2. Word offset decoding.
// 3. Full-word write.
// 4. Individual byte-enable writes.
// 5. Data persistence after writes.
//
// Cache line:
//
// Address 0x1000 -> Word 0 = AAAAAAAA
// Address 0x1004 -> Word 1 = BBBBBBBB
// Address 0x1008 -> Word 2 = CCCCCCCC
// Address 0x100C -> Word 3 = DDDDDDDD
// ============================================================

module cache_data_path_testbench;

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

        $dumpfile("cache_data_path.vcd");

        $dumpvars(0, cache_data_path_testbench);

    end


    // ========================================================
    // Simple memory model
    //
    // 4096 cache lines.
    // ========================================================

    logic [127:0] memory [0:4095];

    integer i;


    initial begin

        for (i = 0; i < 4096; i = i + 1)

            memory[i] = 128'b0;


        // ----------------------------------------------------
        // Test cache line at 0x1000
        //
        // Word 0 = AAAAAAAA
        // Word 1 = BBBBBBBB
        // Word 2 = CCCCCCCC
        // Word 3 = DDDDDDDD
        // ----------------------------------------------------

        memory[32'h00001000 >> 4] = {
            32'hDDDDDDDD,
            32'hCCCCCCCC,
            32'hBBBBBBBB,
            32'hAAAAAAAA
        };

    end


    // ========================================================
    // Memory always ready
    // ========================================================

    assign mem_req_ready = 1'b1;


    // ========================================================
    // Memory response
    // ========================================================

    always @(posedge clk) begin

        mem_rsp_valid <= 1'b0;


        if (mem_req_valid && mem_req_ready) begin

            if (!mem_req_write) begin

                mem_rsp_rdata <=
                    memory[mem_req_addr[15:4]];

                mem_rsp_valid <= 1'b1;

            end

        end

    end


    // ========================================================
    // CPU READ TASK
    // ========================================================

    task automatic cpu_read_check;

        input [31:0] address;
        input [31:0] expected_data;

        begin

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

                $display(
                    "ERROR: READ %08h expected %08h got %08h",
                    address,
                    expected_data,
                    cpu_rsp_rdata
                );

                $finish;

            end


            $display(
                "PASS: READ %08h -> %08h",
                address,
                cpu_rsp_rdata
            );


            @(posedge clk);

        end

    endtask


    // ========================================================
    // CPU WRITE TASK
    // ========================================================

    task automatic cpu_write_check;

        input [31:0] address;
        input [31:0] data;
        input [3:0]  byte_enable;

        begin

            cpu_req_addr  <= address;
            cpu_req_write <= 1'b1;
            cpu_req_wdata <= data;
            cpu_req_be    <= byte_enable;
            cpu_req_valid <= 1'b1;


            wait (cpu_req_ready == 1'b1);

            @(posedge clk);

            cpu_req_valid <= 1'b0;


            wait (cpu_rsp_valid == 1'b1);


            $display(
                "PASS: WRITE %08h <= %08h BE=%b",
                address,
                data,
                byte_enable
            );


            @(posedge clk);

        end

    endtask


    // ========================================================
    // Main test
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initial conditions
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

        repeat (3)
            @(posedge clk);

        reset_n = 1'b1;


        // ====================================================
        // PART 1
        // Verify all four words of the cache line.
        // ====================================================

        $display("");
        $display("==============================");
        $display(" WORD OFFSET TEST");
        $display("==============================");


        cpu_read_check(
            32'h00001000,
            32'hAAAAAAAA
        );


        cpu_read_check(
            32'h00001004,
            32'hBBBBBBBB
        );


        cpu_read_check(
            32'h00001008,
            32'hCCCCCCCC
        );


        cpu_read_check(
            32'h0000100C,
            32'hDDDDDDDD
        );


        // ====================================================
        // PART 2
        // Full-word write.
        // ====================================================

        $display("");
        $display("==============================");
        $display(" FULL WORD WRITE TEST");
        $display("==============================");


        cpu_write_check(
            32'h00001004,
            32'h12345678,
            4'b1111
        );


        cpu_read_check(
            32'h00001004,
            32'h12345678
        );


        // ====================================================
        // PART 3
        // BYTE ENABLE TEST 1
        //
        // Original Word 2:
        //
        // CCCCCCCC
        //
        // BE = 0001
        // Data = 000000AA
        //
        // Result:
        //
        // CCCCCC AA
        // ====================================================

        $display("");
        $display("==============================");
        $display(" BYTE ENABLE TEST 1");
        $display("==============================");


        cpu_write_check(
            32'h00001008,
            32'h000000AA,
            4'b0001
        );


        cpu_read_check(
            32'h00001008,
            32'hCCCCCCAA
        );


        // ====================================================
        // BYTE ENABLE TEST 2
        //
        // Current:
        //
        // CCCCCC AA
        //
        // Write byte 1 = BB
        //
        // Result:
        //
        // CCCC BBAA
        // ====================================================

        cpu_write_check(
            32'h00001008,
            32'h0000BB00,
            4'b0010
        );


        cpu_read_check(
            32'h00001008,
            32'hCCCCBBAA
        );


        // ====================================================
        // BYTE ENABLE TEST 3
        //
        // Write byte 2 = DD
        //
        // Current:
        //
        // CCCC BBAA
        //
        // Result:
        //
        // CC DD BBAA
        // ====================================================

        cpu_write_check(
            32'h00001008,
            32'h00DD0000,
            4'b0100
        );


        cpu_read_check(
            32'h00001008,
            32'hCCDDBBAA
        );


        // ====================================================
        // BYTE ENABLE TEST 4
        //
        // Write byte 3 = EE
        //
        // Current:
        //
        // CC DD BBAA
        //
        // Result:
        //
        // EE DD BBAA
        // ====================================================

        cpu_write_check(
            32'h00001008,
            32'hEE000000,
            4'b1000
        );


        cpu_read_check(
            32'h00001008,
            32'hEEDDBBAA
        );


        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("==============================");
        $display(" DATA PATH TEST COMPLETE");
        $display("==============================");

        $display("PASS: WORD 0");
        $display("PASS: WORD 1");
        $display("PASS: WORD 2");
        $display("PASS: WORD 3");

        $display("PASS: FULL WORD WRITE");

        $display("PASS: BYTE ENABLE 0001");
        $display("PASS: BYTE ENABLE 0010");
        $display("PASS: BYTE ENABLE 0100");
        $display("PASS: BYTE ENABLE 1000");

        $display("==============================");
        $display("");


        #20;

        $finish;

    end

endmodule
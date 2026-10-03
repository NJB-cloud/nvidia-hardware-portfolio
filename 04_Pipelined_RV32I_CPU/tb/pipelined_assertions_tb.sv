// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Assertion-Based Verification Testbench
//
// Purpose:
//   Add a dedicated verification layer around the integrated
//   five-stage pipeline without modifying the proven CPU RTL.
//
// Verification checks:
//   1. x0 remains architecturally zero
//   2. Forwarding control encodings are legal
//   3. Reset control state is safe
//   4. Load-use hazard produces the required stall/flush response
//   5. stall_debug matches the actual PC-write control
//   6. Load-use architectural result is correct
//
// Simulator:
//   Icarus Verilog 12.0
// ============================================================

`timescale 1ns/1ps

module pipelined_assertions_tb;

    // ========================================================
    // Clock and reset
    // ========================================================

    logic clk;
    logic rst_n;

    // ========================================================
    // DUT debug outputs
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
    // Assertion accounting
    // ========================================================

    integer assertion_checks;
    integer assertion_passes;
    integer assertion_failures;

    // ========================================================
    // DUT
    // ========================================================

    pipelined_core dut (
        .clk                  (clk),
        .rst_n                (rst_n),

        .current_pc           (current_pc),
        .instruction          (instruction),

        .ex_alu_result_debug  (ex_alu_result_debug),
        .mem_alu_result_debug (mem_alu_result_debug),
        .wb_data_debug        (wb_data_debug),

        .stall_debug          (stall_debug),
        .forward_a_debug      (forward_a_debug),
        .forward_b_debug      (forward_b_debug)
    );

    // ========================================================
    // Clock generation
    // ========================================================

    initial begin

        clk = 1'b0;

        forever
            #5 clk = ~clk;

    end

    // ========================================================
    // Assertion PASS helper
    // ========================================================

    task automatic pass_check;

        input [255:0] name;

        begin

            assertion_checks = assertion_checks + 1;
            assertion_passes = assertion_passes + 1;

            $display(
                "ASSERT PASS: %0s",
                name
            );

        end

    endtask

    // ========================================================
    // Assertion FAIL helper
    // ========================================================

    task automatic fail_check;

        input [255:0] name;

        begin

            assertion_checks = assertion_checks + 1;
            assertion_failures = assertion_failures + 1;

            $display(
                "ASSERT FAIL: %0s",
                name
            );

        end

    endtask

    // ========================================================
    // ASSERTION 1
    //
    // RISC-V x0 must always remain zero.
    //
    // The register file prevents writes to x0.
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            if (dut.u_register_file.registers[0]
                !== 32'h0000_0000) begin

                fail_check(
                    "x0 must remain zero"
                );

            end

            else begin

                pass_check(
                    "x0 remains zero"
                );

            end

        end

    end

    // ========================================================
    // ASSERTION 2
    //
    // Forwarding control encoding:
    //
    // 00 = register-file operand
    // 01 = MEM/WB forwarding
    // 10 = EX/MEM forwarding
    // 11 = reserved
    //
    // Therefore 11 must never appear.
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            if (forward_a_debug === 2'b11) begin

                fail_check(
                    "ForwardA never uses reserved encoding"
                );

            end

            else begin

                pass_check(
                    "ForwardA encoding legal"
                );

            end


            if (forward_b_debug === 2'b11) begin

                fail_check(
                    "ForwardB never uses reserved encoding"
                );

            end

            else begin

                pass_check(
                    "ForwardB encoding legal"
                );

            end

        end

    end

    // ========================================================
    // ASSERTION 3
    //
    // During reset:
    //
    // ForwardA = 00
    // ForwardB = 00
    // Stall    = 0
    //
    // This verifies a safe reset control state.
    // ========================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            if (forward_a_debug !== 2'b00) begin

                fail_check(
                    "ForwardA inactive during reset"
                );

            end

            else begin

                pass_check(
                    "ForwardA reset state"
                );

            end


            if (forward_b_debug !== 2'b00) begin

                fail_check(
                    "ForwardB inactive during reset"
                );

            end

            else begin

                pass_check(
                    "ForwardB reset state"
                );

            end


            if (stall_debug !== 1'b0) begin

                fail_check(
                    "Stall inactive during reset"
                );

            end

            else begin

                pass_check(
                    "Stall reset state"
                );

            end

        end

    end

    // ========================================================
    // ASSERTION 4
    //
    // Load-use hazard behavior.
    //
    // The hazard unit specification is:
    //
    // id_ex_flush = 1
    // pc_write    = 0
    // if_id_stall = 1
    //
    // This creates one pipeline bubble while holding the
    // dependent instruction.
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            if (dut.id_ex_flush) begin

                if (dut.pc_write !== 1'b0) begin

                    fail_check(
                        "Load-use flush requires PC hold"
                    );

                end

                else begin

                    pass_check(
                        "Load-use flush holds PC"
                    );

                end


                if (dut.if_id_stall !== 1'b1) begin

                    fail_check(
                        "Load-use flush requires IF/ID hold"
                    );

                end

                else begin

                    pass_check(
                        "Load-use flush holds IF/ID"
                    );

                end

            end

        end

    end

    // ========================================================
    // ASSERTION 5
    //
    // stall_debug is derived from:
    //
    //     stall_debug = !pc_write
    //
    // Verify that the externally visible debug signal matches
    // the actual pipeline control.
    // ========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            if (stall_debug !== !dut.pc_write) begin

                fail_check(
                    "stall_debug matches PC write control"
                );

            end

            else begin

                pass_check(
                    "stall_debug matches PC write control"
                );

            end

        end

    end

    // ========================================================
    // TEST PROGRAM
    //
    // This program intentionally creates a load-use dependency:
    //
    //     LW  x6,0(x0)
    //     ADD x7,x6,x1
    //
    // Data memory:
    //
    //     memory[0] = 20
    //
    // Register:
    //
    //     x1 = 10
    //
    // Expected:
    //
    //     x6 = 20
    //     x7 = 30
    //
    // IMPORTANT:
    // Register initialization occurs AFTER reset because the
    // register-file reset clears all registers.
    // ========================================================

    initial begin

        assertion_checks   = 0;
        assertion_passes   = 0;
        assertion_failures = 0;

        // ----------------------------------------------------
        // Initial reset state
        // ----------------------------------------------------

        rst_n = 1'b0;

        // ----------------------------------------------------
        // Clear instruction memory.
        //
        // NOP = ADDI x0,x0,0
        // ----------------------------------------------------

        for (integer i = 0; i < 256; i = i + 1) begin

            dut.u_instruction_memory.memory[i] =
                32'h0000_0013;

        end

        // ----------------------------------------------------
        // Clear data memory.
        // ----------------------------------------------------

        for (integer j = 0; j < 256; j = j + 1) begin

            dut.data_memory[j] =
                32'h0000_0000;

        end

        // ----------------------------------------------------
        // Deterministic load data
        // ----------------------------------------------------

        dut.data_memory[0] = 32'd20;

        // ====================================================
        // Instruction 0
        //
        // LW x6,0(x0)
        //
        // Encoding:
        // imm[11:0] | rs1 | funct3 | rd | opcode
        // ====================================================

        dut.u_instruction_memory.memory[0] =
            {
                12'd0,
                5'd0,
                3'b010,
                5'd6,
                7'b0000011
            };

        // ====================================================
        // Instruction 1
        //
        // ADD x7,x6,x1
        //
        // x6 comes from the immediately preceding LW.
        // This deliberately creates a load-use hazard.
        // ====================================================

        dut.u_instruction_memory.memory[1] =
            {
                7'b0000000,
                5'd1,
                5'd6,
                3'b000,
                5'd7,
                7'b0110011
            };

        // ====================================================
        // RESET
        //
        // The register file is cleared during reset.
        // ====================================================

        repeat (2)
            @(posedge clk);

        #1;

        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        rst_n = 1'b1;

        #1;

        // ====================================================
        // IMPORTANT:
        //
        // Seed x1 AFTER reset.
        //
        // Reset clears the register file, so seeding before
        // reset would result in x1 becoming zero.
        // ====================================================

        dut.u_register_file.registers[1] = 32'd10;

        // ----------------------------------------------------
        // Allow the pipeline to execute.
        // ----------------------------------------------------

        repeat (15)
            @(posedge clk);

        #1;

        // ====================================================
        // FINAL ARCHITECTURAL CHECKS
        // ====================================================

        // ----------------------------------------------------
        // Expected:
        //
        // LW x6,0(x0)
        //
        // x6 = memory[0] = 20
        // ----------------------------------------------------

        if (dut.u_register_file.registers[6]
            === 32'd20) begin

            pass_check(
                "Load result x6 = 20"
            );

        end

        else begin

            fail_check(
                "Load result x6 = 20"
            );

        end

        // ----------------------------------------------------
        // Expected:
        //
        // ADD x7,x6,x1
        //
        // x7 = 20 + 10 = 30
        // ----------------------------------------------------

        if (dut.u_register_file.registers[7]
            === 32'd30) begin

            pass_check(
                "Load-use result x7 = 30"
            );

        end

        else begin

            fail_check(
                "Load-use result x7 = 30"
            );

        end

        // ====================================================
        // FINAL REPORT
        // ====================================================

        $display("");
        $display("============================================================");
        $display("       ASSERTION-BASED VERIFICATION RESULT");
        $display("============================================================");

        $display(
            "CHECKS EXECUTED = %0d",
            assertion_checks
        );

        $display(
            "PASSED          = %0d",
            assertion_passes
        );

        $display(
            "FAILED          = %0d",
            assertion_failures
        );

        if (assertion_failures == 0) begin

            $display("");
            $display("============================================================");
            $display("             ALL ASSERTION CHECKS PASSED");
            $display("============================================================");

        end

        else begin

            $display("");
            $display("============================================================");
            $display("             ASSERTION FAILURES DETECTED");
            $display("============================================================");

        end

        $display("");

        $finish;

    end

endmodule
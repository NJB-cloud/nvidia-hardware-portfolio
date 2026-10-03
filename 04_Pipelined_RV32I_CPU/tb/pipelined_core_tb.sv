// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Testbench: Pipelined Core Integration Verification
//
// Current CPU subset:
//   R-type: ADD, SUB, AND, OR, XOR, SLT
//   LW
//   SW
//   BEQ
//
// Verification targets:
//   - 5-stage pipeline execution
//   - EX/MEM forwarding
//   - MEM/WB forwarding
//   - Store-data forwarding
//   - Load-use hazard
//   - Branch control
//   - x0 protection
// ============================================================

`timescale 1ns/1ps

module pipelined_core_tb;

    logic clk;
    logic rst_n;

    logic [31:0] current_pc;
    logic [31:0] instruction;

    logic [31:0] ex_alu_result_debug;
    logic [31:0] mem_alu_result_debug;
    logic [31:0] wb_data_debug;

    logic        stall_debug;
    logic [1:0]  forward_a_debug;
    logic [1:0]  forward_b_debug;

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
    // Clock
    // ========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ========================================================
    // RV32I instruction encoders
    // ========================================================

    function automatic [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;

        begin
            enc_r = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                opcode
            };
        end
    endfunction


    function automatic [31:0] enc_i;
        input signed [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;

        begin
            enc_i = {
                imm[11:0],
                rs1,
                funct3,
                rd,
                opcode
            };
        end
    endfunction


    function automatic [31:0] enc_s;
        input signed [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;

        begin
            enc_s = {
                imm[11:5],
                rs2,
                rs1,
                funct3,
                imm[4:0],
                opcode
            };
        end
    endfunction


    function automatic [31:0] enc_b;
        input signed [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;

        begin
            enc_b = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                funct3,
                imm[4:1],
                imm[11],
                opcode
            };
        end
    endfunction

    // ========================================================
    // Opcodes
    // ========================================================

    localparam [6:0] OPCODE_R    = 7'b0110011;
    localparam [6:0] OPCODE_I    = 7'b0010011;
    localparam [6:0] OPCODE_LW   = 7'b0000011;
    localparam [6:0] OPCODE_SW   = 7'b0100011;
    localparam [6:0] OPCODE_BEQ  = 7'b1100011;

    // ========================================================
    // funct fields
    // ========================================================

    localparam [6:0] FUNCT7_ADD = 7'b0000000;
    localparam [6:0] FUNCT7_SUB = 7'b0100000;

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_AND     = 3'b111;
    localparam [2:0] F3_OR      = 3'b110;
    localparam [2:0] F3_XOR     = 3'b100;
    localparam [2:0] F3_SLT     = 3'b010;

    // ========================================================
    // Clear memories
    // ========================================================

    task automatic clear_memories;

        integer i;

        begin

            for (i = 0; i < 256; i = i + 1)
                dut.u_instruction_memory.memory[i] =
                    32'h0000_0013;

            for (i = 0; i < 256; i = i + 1)
                dut.data_memory[i] =
                    32'h0000_0000;

        end

    endtask

    // ========================================================
    // Reset
    // ========================================================

    task automatic reset_cpu;

        begin

            rst_n = 1'b0;

            repeat (2)
                @(posedge clk);

            #1;

            rst_n = 1'b1;

            #1;

        end

    endtask

    // ========================================================
    // Register check
    // ========================================================

    task automatic check_reg;

        input integer reg_num;
        input [31:0] expected;
        input [127:0] test_name;

        reg [31:0] actual;

        begin

            actual =
                dut.u_register_file.registers[reg_num];

            if (actual === expected) begin

                $display(
                    "PASS: %-38s x%0d=%h",
                    test_name,
                    reg_num,
                    actual
                );

            end

            else begin

                $display(
                    "FAIL: %-38s x%0d Expected=%h Got=%h",
                    test_name,
                    reg_num,
                    expected,
                    actual
                );

                $fatal;
            end

        end

    endtask

    // ========================================================
    // Memory check
    // ========================================================

    task automatic check_mem;

        input integer index;
        input [31:0] expected;
        input [127:0] test_name;

        reg [31:0] actual;

        begin

            actual = dut.data_memory[index];

            if (actual === expected) begin

                $display(
                    "PASS: %-38s MEM[%0d]=%h",
                    test_name,
                    index,
                    actual
                );

            end

            else begin

                $display(
                    "FAIL: %-38s MEM[%0d] Expected=%h Got=%h",
                    test_name,
                    index,
                    expected,
                    actual
                );

                $fatal;
            end

        end

    endtask

    // ========================================================
    // Load test program
    //
    // x1 = 10
    // x2 = 20
    //
    // ADD x3,x1,x2
    //      x3 = 30
    //
    // ADD x4,x3,x1
    //      x4 = 40
    //
    // SUB x5,x4,x2
    //      x5 = 20
    //
    // SW x5,0(x0)
    //
    // LW x6,0(x0)
    //      x6 = 20
    //
    // ADD x7,x6,x1
    //      x7 = 30
    //
    // BEQ x7,x3,+8
    //      30 == 30
    //      branch TAKEN
    //
    // instruction after branch is skipped
    //
    // ADD x8,x7,x2
    //      x8 = 50
    //
    // Attempt:
    // ADD x0,x8,x1
    // x0 must remain zero.
    // ========================================================

    task automatic load_program;

        begin

            clear_memories;

            // ------------------------------------------------
            // Program 01
            // ADD x3,x1,x2
            // ------------------------------------------------

            dut.u_instruction_memory.memory[0] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd1,
                    F3_ADD_SUB,
                    5'd3,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Program 02
            // ADD x4,x3,x1
            // EX/MEM forwarding
            // ------------------------------------------------

            dut.u_instruction_memory.memory[1] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd3,
                    F3_ADD_SUB,
                    5'd4,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Program 03
            // SUB x5,x4,x2
            // Forwarding from previous result
            // ------------------------------------------------

            dut.u_instruction_memory.memory[2] =
                enc_r(
                    FUNCT7_SUB,
                    5'd2,
                    5'd4,
                    F3_ADD_SUB,
                    5'd5,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Program 04
            // SW x5,0(x0)
            // Store-data forwarding
            // ------------------------------------------------

            dut.u_instruction_memory.memory[3] =
                enc_s(
                    12'sd0,
                    5'd5,
                    5'd0,
                    3'b010,
                    OPCODE_SW
                );

            // ------------------------------------------------
            // Program 05
            // LW x6,0(x0)
            // ------------------------------------------------

            dut.u_instruction_memory.memory[4] =
                enc_i(
                    12'sd0,
                    5'd0,
                    3'b010,
                    5'd6,
                    OPCODE_LW
                );

            // ------------------------------------------------
            // Program 06
            // ADD x7,x6,x1
            //
            // Deliberate load-use dependency.
            // ------------------------------------------------

            dut.u_instruction_memory.memory[5] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd6,
                    F3_ADD_SUB,
                    5'd7,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Program 07
            // BEQ x7,x3,+8
            //
            // x7 = 30
            // x3 = 30
            //
            // Branch taken.
            // ------------------------------------------------

            dut.u_instruction_memory.memory[6] =
                enc_b(
                    13'sd8,
                    5'd3,
                    5'd7,
                    3'b000,
                    OPCODE_BEQ
                );

            // ------------------------------------------------
            // This instruction should be flushed/skipped.
            //
            // ADD x8,x0,x0
            // If executed, x8 becomes 0.
            // ------------------------------------------------

            dut.u_instruction_memory.memory[7] =
                enc_r(
                    FUNCT7_ADD,
                    5'd0,
                    5'd0,
                    F3_ADD_SUB,
                    5'd8,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Branch target.
            //
            // Address = 0x20 = instruction index 8
            //
            // ADD x8,x7,x2
            // x8 = 30 + 20 = 50
            // ------------------------------------------------

            dut.u_instruction_memory.memory[8] =
                enc_r(
                    FUNCT7_ADD,
                    5'd2,
                    5'd7,
                    F3_ADD_SUB,
                    5'd8,
                    OPCODE_R
                );

            // ------------------------------------------------
            // Attempt to modify x0.
            //
            // ADD x0,x8,x1
            // x0 must remain zero.
            // ------------------------------------------------

            dut.u_instruction_memory.memory[9] =
                enc_r(
                    FUNCT7_ADD,
                    5'd1,
                    5'd8,
                    F3_ADD_SUB,
                    5'd0,
                    OPCODE_R
                );

        end

    endtask

    // ========================================================
    // Main test
    // ========================================================

    initial begin

        rst_n = 1'b0;

        $display("");
        $display("============================================================");
        $display("          PIPELINED RV32I CPU INTEGRATION TEST");
        $display("============================================================");

        // Load instructions.
        load_program;

        // Reset CPU.
        reset_cpu;

        // ----------------------------------------------------
        // Seed source registers after reset.
        //
        // Register-file reset itself remains verified.
        // These values provide deterministic operands for
        // this directed pipeline integration test.
        // ----------------------------------------------------

        dut.u_register_file.registers[1] = 32'd10;
        dut.u_register_file.registers[2] = 32'd20;

        #1;

        // ----------------------------------------------------
        // Allow pipeline to execute and drain.
        // ----------------------------------------------------

        repeat (20)
            @(posedge clk);

        #1;

        // ====================================================
        // ARCHITECTURAL CHECKS
        // ====================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("ARCHITECTURAL RESULT CHECKS");
        $display("------------------------------------------------------------");

        check_reg(
            1,
            32'd10,
            "Source operand x1"
        );

        check_reg(
            2,
            32'd20,
            "Source operand x2"
        );

        check_reg(
            3,
            32'd30,
            "ADD x3,x1,x2"
        );

        check_reg(
            4,
            32'd40,
            "Forwarded ADD x4,x3,x1"
        );

        check_reg(
            5,
            32'd20,
            "Forwarded SUB x5,x4,x2"
        );

        check_mem(
            0,
            32'd20,
            "SW x5,0(x0)"
        );

        check_reg(
            6,
            32'd20,
            "LW x6,0(x0)"
        );

        check_reg(
            7,
            32'd30,
            "Load-use ADD x7,x6,x1"
        );

        check_reg(
            8,
            32'd50,
            "Branch target ADD x8,x7,x2"
        );

        check_reg(
            0,
            32'd0,
            "x0 protection"
        );

        // ====================================================
        // DEBUG OBSERVATION
        // ====================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("PIPELINE DEBUG OBSERVATION");
        $display("------------------------------------------------------------");

        $display(
            "Current PC       = %h",
            current_pc
        );

        $display(
            "Current INST     = %h",
            instruction
        );

        $display(
            "EX ALU result    = %h",
            ex_alu_result_debug
        );

        $display(
            "MEM ALU result   = %h",
            mem_alu_result_debug
        );

        $display(
            "WB data          = %h",
            wb_data_debug
        );

        $display(
            "ForwardA         = %b",
            forward_a_debug
        );

        $display(
            "ForwardB         = %b",
            forward_b_debug
        );

        $display(
            "Stall            = %b",
            stall_debug
        );

        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("============================================================");
        $display("       PIPELINED CPU INTEGRATION TEST PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule
// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Testbench: Randomized Reference-Model Verification
//
// Verification target:
//   - 20 deterministic randomized programs
//   - 40 instructions per program
//   - independent sequential reference model
//   - register comparison
//   - memory comparison
//   - reproducible random seed
//   - valid aligned data-memory addresses
//
// Supported randomized ISA:
//   ADD, SUB, AND, OR, XOR, SLT
//   LW, SW
//
// Branch instructions are verified separately by the directed
// regression and functional-coverage environments.
//
// IMPORTANT:
//   random_value is an UNSIGNED 32-bit value.
//   This prevents negative values from being produced by the
//   modulo operation used for randomized memory indices.
// ============================================================

`timescale 1ns/1ps

module pipelined_randomized_tb;

    // ========================================================
    // CONFIGURATION
    // ========================================================

    localparam integer NUM_PROGRAMS   = 20;
    localparam integer PROGRAM_LENGTH = 40;
    localparam integer MEMORY_WORDS   = 16;

    localparam [31:0] RANDOM_SEED = 32'h5A17_C0DE;

    // Five-stage pipeline:
    // IF -> ID -> EX -> MEM -> WB
    //
    // 40 instructions + generous drain margin.
    localparam integer RUN_CYCLES = PROGRAM_LENGTH + 20;

    // ========================================================
    // CLOCK / RESET
    // ========================================================

    reg clk;
    reg rst_n;

    // ========================================================
    // DUT DEBUG SIGNALS
    // ========================================================

    wire [31:0] current_pc;
    wire [31:0] instruction;

    wire [31:0] ex_alu_result_debug;
    wire [31:0] mem_alu_result_debug;
    wire [31:0] wb_data_debug;

    wire        stall_debug;
    wire [1:0]  forward_a_debug;
    wire [1:0]  forward_b_debug;

    // ========================================================
    // RANDOM GENERATOR
    //
    // MUST be unsigned.
    //
    // A signed integer here can turn a valid $urandom()
    // result into a negative value before the % operation.
    // ========================================================

    integer random_seed;
    reg [31:0] random_value;

    // ========================================================
    // RANDOMIZED PROGRAM
    // ========================================================

    reg [31:0] randomized_program [0:PROGRAM_LENGTH-1];

    // ========================================================
    // REFERENCE MODEL
    // ========================================================

    reg [31:0] reference_registers [0:31];
    reg [31:0] reference_memory    [0:MEMORY_WORDS-1];

    // ========================================================
    // STATISTICS
    // ========================================================

    integer programs_run;
    integer programs_passed;
    integer programs_failed;

    integer register_checks;
    integer memory_checks;

    integer register_failures;
    integer memory_failures;

    integer total_instructions;

    integer program_number;
    integer instruction_number;

    // ========================================================
    // OPCODES
    // ========================================================

    localparam [6:0] OPCODE_R  = 7'b0110011;
    localparam [6:0] OPCODE_LW = 7'b0000011;
    localparam [6:0] OPCODE_SW = 7'b0100011;

    // ========================================================
    // FUNCT7
    // ========================================================

    localparam [6:0] FUNCT7_ADD = 7'b0000000;
    localparam [6:0] FUNCT7_SUB = 7'b0100000;

    // ========================================================
    // FUNCT3
    // ========================================================

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_SLT     = 3'b010;
    localparam [2:0] F3_XOR     = 3'b100;
    localparam [2:0] F3_OR      = 3'b110;
    localparam [2:0] F3_AND     = 3'b111;
    localparam [2:0] F3_LW_SW   = 3'b010;

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
    // CLOCK
    // ========================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // ========================================================
    // R-TYPE ENCODER
    // ========================================================

    function [31:0] enc_r;

        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;

        begin

            enc_r = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                OPCODE_R
            };

        end

    endfunction

    // ========================================================
    // LW ENCODER
    //
    // Memory model:
    //
    //   x0 + (word_index * 4)
    //
    // Therefore:
    //
    //   memory[0] -> address 0
    //   memory[1] -> address 4
    //   ...
    //   memory[15] -> address 60
    //
    // All generated addresses are positive and aligned.
    // ========================================================

    function [31:0] enc_lw;

        input integer mem_index;
        input [4:0] rd;

        reg [11:0] imm;

        begin

            imm = mem_index * 4;

            enc_lw = {
                imm,
                5'd0,
                F3_LW_SW,
                rd,
                OPCODE_LW
            };

        end

    endfunction

    // ========================================================
    // SW ENCODER
    // ========================================================

    function [31:0] enc_sw;

        input integer mem_index;
        input [4:0] rs2;

        reg [11:0] imm;

        begin

            imm = mem_index * 4;

            enc_sw = {
                imm[11:5],
                rs2,
                5'd0,
                F3_LW_SW,
                imm[4:0],
                OPCODE_SW
            };

        end

    endfunction

    // ========================================================
    // NOP
    // ========================================================

    function [31:0] nop;

        begin
            nop = 32'h0000_0013;
        end

    endfunction

    // ========================================================
    // CLEAR DUT MEMORIES
    // ========================================================

    task clear_dut_memory;

        integer i;

        begin

            // ------------------------------------------------
            // Instruction memory
            // ------------------------------------------------

            for (i = 0; i < 256; i = i + 1) begin

                dut.u_instruction_memory.memory[i] =
                    32'h0000_0013;

            end

            // ------------------------------------------------
            // Data memory
            // ------------------------------------------------

            for (i = 0; i < 256; i = i + 1) begin

                dut.data_memory[i] =
                    32'h0000_0000;

            end

        end

    endtask

    // ========================================================
    // INITIALIZE REFERENCE MODEL
    // ========================================================

    task initialize_reference_model;

        integer i;

        begin

            // ------------------------------------------------
            // Registers
            // ------------------------------------------------

            for (i = 0; i < 32; i = i + 1) begin

                reference_registers[i] =
                    32'h0000_0000;

            end

            // ------------------------------------------------
            // Deterministic initial register state
            // ------------------------------------------------

            reference_registers[1] = 32'd10;
            reference_registers[2] = 32'd20;
            reference_registers[3] = 32'd30;
            reference_registers[4] = 32'd40;
            reference_registers[5] = 32'd50;
            reference_registers[6] = 32'd60;
            reference_registers[7] = 32'd70;
            reference_registers[8] = 32'd80;

            // ------------------------------------------------
            // Data memory
            // ------------------------------------------------

            for (i = 0; i < MEMORY_WORDS; i = i + 1) begin

                reference_memory[i] =
                    32'd1000 + (i * 32);

            end

            // x0 is always zero.

            reference_registers[0] =
                32'h0000_0000;

        end

    endtask

    // ========================================================
    // INITIALIZE DUT FROM REFERENCE MODEL
    // ========================================================

    task initialize_dut_state;

        integer i;

        begin

            // ------------------------------------------------
            // Register file
            // ------------------------------------------------

            for (i = 0; i < 32; i = i + 1) begin

                dut.u_register_file.registers[i] =
                    reference_registers[i];

            end

            // ------------------------------------------------
            // Data memory
            // ------------------------------------------------

            for (i = 0; i < MEMORY_WORDS; i = i + 1) begin

                dut.data_memory[i] =
                    reference_memory[i];

            end

            // x0 protection.

            dut.u_register_file.registers[0] =
                32'h0000_0000;

        end

    endtask

    // ========================================================
    // GENERATE RANDOM PROGRAM
    // ========================================================

    task generate_program;

        integer i;

        integer local_op;
        integer local_rd;
        integer local_rs1;
        integer local_rs2;
        integer local_mem;

        begin

            for (i = 0; i < PROGRAM_LENGTH; i = i + 1) begin

                // ------------------------------------------------
                // Operation
                // ------------------------------------------------

                random_value =
                    $urandom(random_seed);

                local_op =
                    random_value % 8;

                // ------------------------------------------------
                // Destination register x1-x15
                // ------------------------------------------------

                random_value =
                    $urandom(random_seed);

                local_rd =
                    1 + (random_value % 15);

                // ------------------------------------------------
                // Source register x1-x15
                // ------------------------------------------------

                random_value =
                    $urandom(random_seed);

                local_rs1 =
                    1 + (random_value % 15);

                // ------------------------------------------------
                // Second source register x1-x15
                // ------------------------------------------------

                random_value =
                    $urandom(random_seed);

                local_rs2 =
                    1 + (random_value % 15);

                // ------------------------------------------------
                // Valid data-memory word index.
                //
                // Because random_value is UNSIGNED:
                //
                //   0 <= local_mem < MEMORY_WORDS
                //
                // There can be no negative address.
                // ------------------------------------------------

                random_value =
                    $urandom(random_seed);

                local_mem =
                    random_value % MEMORY_WORDS;

                // ------------------------------------------------
                // Select instruction
                // ------------------------------------------------

                case (local_op)

                    // --------------------------------------------
                    // ADD
                    // --------------------------------------------

                    0: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_ADD,
                                local_rs2,
                                local_rs1,
                                F3_ADD_SUB,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // SUB
                    // --------------------------------------------

                    1: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_SUB,
                                local_rs2,
                                local_rs1,
                                F3_ADD_SUB,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // AND
                    // --------------------------------------------

                    2: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_ADD,
                                local_rs2,
                                local_rs1,
                                F3_AND,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // OR
                    // --------------------------------------------

                    3: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_ADD,
                                local_rs2,
                                local_rs1,
                                F3_OR,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // XOR
                    // --------------------------------------------

                    4: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_ADD,
                                local_rs2,
                                local_rs1,
                                F3_XOR,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // SLT
                    // --------------------------------------------

                    5: begin

                        randomized_program[i] =
                            enc_r(
                                FUNCT7_ADD,
                                local_rs2,
                                local_rs1,
                                F3_SLT,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // LW
                    // --------------------------------------------

                    6: begin

                        randomized_program[i] =
                            enc_lw(
                                local_mem,
                                local_rd
                            );

                    end

                    // --------------------------------------------
                    // SW
                    // --------------------------------------------

                    7: begin

                        randomized_program[i] =
                            enc_sw(
                                local_mem,
                                local_rs2
                            );

                    end

                    default: begin

                        randomized_program[i] =
                            nop();

                    end

                endcase

            end

        end

    endtask

    // ========================================================
    // PRINT PROGRAM
    // ========================================================

    task print_program;

        integer i;

        begin

            $display("");
            $display(
                "PROGRAM %0d INSTRUCTIONS:",
                program_number + 1
            );

            $display(
                "------------------------------------------------------------"
            );

            for (i = 0; i < PROGRAM_LENGTH; i = i + 1) begin

                $display(
                    "  [%02d] %08h",
                    i,
                    randomized_program[i]
                );

            end

            $display(
                "------------------------------------------------------------"
            );

            $display("");

        end

    endtask

    // ========================================================
    // REFERENCE MODEL
    //
    // Executes instructions sequentially.
    //
    // This intentionally does NOT model pipeline timing.
    //
    // The DUT must produce the same final architectural state.
    // ========================================================

    task execute_reference_model;

        integer i;
        integer memory_index;

        reg [31:0] instruction_word;

        reg [6:0] opcode;
        reg [6:0] funct7;
        reg [2:0] funct3;

        integer rs1;
        integer rs2;
        integer rd;

        reg signed [31:0] signed_rs1;
        reg signed [31:0] signed_rs2;

        reg [11:0] lw_imm12;
        reg [11:0] sw_imm12;

        begin

            for (i = 0; i < PROGRAM_LENGTH; i = i + 1) begin

                instruction_word =
                    randomized_program[i];

                opcode =
                    instruction_word[6:0];

                rs1 =
                    instruction_word[19:15];

                rs2 =
                    instruction_word[24:20];

                rd =
                    instruction_word[11:7];

                funct3 =
                    instruction_word[14:12];

                funct7 =
                    instruction_word[31:25];

                case (opcode)

                    // =================================================
                    // R-TYPE
                    // =================================================

                    OPCODE_R: begin

                        case (funct3)

                            // -----------------------------------------
                            // ADD / SUB
                            // -----------------------------------------

                            F3_ADD_SUB: begin

                                if (funct7 == FUNCT7_SUB) begin

                                    reference_registers[rd] =
                                        reference_registers[rs1]
                                        -
                                        reference_registers[rs2];

                                end

                                else begin

                                    reference_registers[rd] =
                                        reference_registers[rs1]
                                        +
                                        reference_registers[rs2];

                                end

                            end

                            // -----------------------------------------
                            // SLT
                            // -----------------------------------------

                            F3_SLT: begin

                                signed_rs1 =
                                    reference_registers[rs1];

                                signed_rs2 =
                                    reference_registers[rs2];

                                if (signed_rs1 < signed_rs2) begin

                                    reference_registers[rd] =
                                        32'd1;

                                end

                                else begin

                                    reference_registers[rd] =
                                        32'd0;

                                end

                            end

                            // -----------------------------------------
                            // XOR
                            // -----------------------------------------

                            F3_XOR: begin

                                reference_registers[rd] =
                                    reference_registers[rs1]
                                    ^
                                    reference_registers[rs2];

                            end

                            // -----------------------------------------
                            // OR
                            // -----------------------------------------

                            F3_OR: begin

                                reference_registers[rd] =
                                    reference_registers[rs1]
                                    |
                                    reference_registers[rs2];

                            end

                            // -----------------------------------------
                            // AND
                            // -----------------------------------------

                            F3_AND: begin

                                reference_registers[rd] =
                                    reference_registers[rs1]
                                    &
                                    reference_registers[rs2];

                            end

                            default: begin

                            end

                        endcase

                    end

                    // =================================================
                    // LW
                    //
                    // Only valid generated addresses are used:
                    //
                    //   0, 4, 8, ... 60
                    //
                    // =================================================

                    OPCODE_LW: begin

                        lw_imm12 =
                            instruction_word[31:20];

                        memory_index =
                            lw_imm12 / 4;

                        if (
                            (memory_index >= 0) &&
                            (memory_index < MEMORY_WORDS)
                        ) begin

                            reference_registers[rd] =
                                reference_memory[memory_index];

                        end

                        else begin

                            $display(
                                "REFERENCE MODEL ERROR: invalid LW address %0d",
                                memory_index
                            );

                        end

                    end

                    // =================================================
                    // SW
                    // =================================================

                    OPCODE_SW: begin

                        sw_imm12 = {
                            instruction_word[31:25],
                            instruction_word[11:7]
                        };

                        memory_index =
                            sw_imm12 / 4;

                        if (
                            (memory_index >= 0) &&
                            (memory_index < MEMORY_WORDS)
                        ) begin

                            reference_memory[memory_index] =
                                reference_registers[rs2];

                        end

                        else begin

                            $display(
                                "REFERENCE MODEL ERROR: invalid SW address %0d",
                                memory_index
                            );

                        end

                    end

                    // =================================================
                    // Unsupported instruction
                    // =================================================

                    default: begin

                    end

                endcase

                // ----------------------------------------------------
                // x0 architectural invariant
                // ----------------------------------------------------

                reference_registers[0] =
                    32'h0000_0000;

            end

        end

    endtask

    // ========================================================
    // RESET CPU
    // ========================================================

    task reset_cpu;

        begin

            rst_n = 1'b0;

            repeat (3) begin
                @(posedge clk);
            end

            #1;

            rst_n = 1'b1;

            #1;

        end

    endtask

    // ========================================================
    // RUN PIPELINE
    // ========================================================

    task run_pipeline;

        input integer cycles;

        integer i;

        begin

            for (i = 0; i < cycles; i = i + 1) begin

                @(posedge clk);

            end

            #1;

        end

    endtask

    // ========================================================
    // COMPARE REGISTERS
    // ========================================================

    task compare_registers;

        integer i;

        begin

            for (i = 0; i < 32; i = i + 1) begin

                register_checks =
                    register_checks + 1;

                if (
                    dut.u_register_file.registers[i]
                    !==
                    reference_registers[i]
                ) begin

                    register_failures =
                        register_failures + 1;

                    $display(
                        "REGISTER MISMATCH: x%0d Expected=%08h Got=%08h",
                        i,
                        reference_registers[i],
                        dut.u_register_file.registers[i]
                    );

                end

            end

        end

    endtask

    // ========================================================
    // COMPARE MEMORY
    // ========================================================

    task compare_memory;

        integer i;

        begin

            for (i = 0; i < MEMORY_WORDS; i = i + 1) begin

                memory_checks =
                    memory_checks + 1;

                if (
                    dut.data_memory[i]
                    !==
                    reference_memory[i]
                ) begin

                    memory_failures =
                        memory_failures + 1;

                    $display(
                        "MEMORY MISMATCH: MEM[%0d] Expected=%08h Got=%08h",
                        i,
                        reference_memory[i],
                        dut.data_memory[i]
                    );

                end

            end

        end

    endtask

    // ========================================================
    // DISPLAY FINAL REGISTER STATE
    // ========================================================

    task display_register_state;

        integer i;

        begin

            $display("");
            $display("FINAL REGISTER STATE");
            $display(
                "------------------------------------------------------------"
            );

            for (i = 0; i < 32; i = i + 1) begin

                $display(
                    "x%02d  Expected=%08h  RTL=%08h",
                    i,
                    reference_registers[i],
                    dut.u_register_file.registers[i]
                );

            end

            $display(
                "------------------------------------------------------------"
            );

        end

    endtask

    // ========================================================
    // DISPLAY FINAL MEMORY STATE
    // ========================================================

    task display_memory_state;

        integer i;

        begin

            $display("");
            $display("FINAL DATA MEMORY STATE");
            $display(
                "------------------------------------------------------------"
            );

            for (i = 0; i < MEMORY_WORDS; i = i + 1) begin

                $display(
                    "MEM[%02d] Expected=%08h  RTL=%08h",
                    i,
                    reference_memory[i],
                    dut.data_memory[i]
                );

            end

            $display(
                "------------------------------------------------------------"
            );

        end

    endtask

    // ========================================================
    // MAIN TEST
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // Initialize statistics
        // ----------------------------------------------------

        programs_run       = 0;
        programs_passed    = 0;
        programs_failed    = 0;

        register_checks    = 0;
        memory_checks      = 0;

        register_failures  = 0;
        memory_failures    = 0;

        total_instructions = 0;

        rst_n = 1'b0;

        // ----------------------------------------------------
        // Initialize deterministic random seed.
        //
        // $urandom requires a variable as the seed argument.
        // ----------------------------------------------------

        random_seed =
            RANDOM_SEED;

        // Advance generator once using the same seed variable.

        random_value =
            $urandom(random_seed);

        // ----------------------------------------------------
        // Header
        // ----------------------------------------------------

        $display("");
        $display("============================================================");
        $display("      RV32I RANDOMIZED REFERENCE-MODEL VERIFICATION");
        $display("============================================================");
        $display("");

        $display(
            "RANDOM SEED = %08h",
            RANDOM_SEED
        );

        $display(
            "PROGRAMS    = %0d",
            NUM_PROGRAMS
        );

        $display(
            "LENGTH      = %0d instructions/program",
            PROGRAM_LENGTH
        );

        $display(
            "MEMORY      = %0d words",
            MEMORY_WORDS
        );

        $display("");

        // ====================================================
        // RANDOMIZED PROGRAM LOOP
        // ====================================================

        for (
            program_number = 0;
            program_number < NUM_PROGRAMS;
            program_number = program_number + 1
        ) begin

            $display(
                "------------------------------------------------------------"
            );

            $display(
                "Randomized Program %0d / %0d",
                program_number + 1,
                NUM_PROGRAMS
            );

            // ------------------------------------------------
            // Reset counters for this program.
            // ------------------------------------------------

            register_failures = 0;
            memory_failures   = 0;

            // ------------------------------------------------
            // Clear DUT memories.
            // ------------------------------------------------

            clear_dut_memory;

            // ------------------------------------------------
            // Initialize reference state.
            // ------------------------------------------------

            initialize_reference_model;

            // ------------------------------------------------
            // Generate randomized instruction stream.
            // ------------------------------------------------

            generate_program;

            // ------------------------------------------------
            // Print complete program.
            // ------------------------------------------------

            print_program;

            // ------------------------------------------------
            // Load program into instruction memory.
            // ------------------------------------------------

            for (
                instruction_number = 0;
                instruction_number < PROGRAM_LENGTH;
                instruction_number = instruction_number + 1
            ) begin

                dut.u_instruction_memory.memory[
                    instruction_number
                ] =
                    randomized_program[
                        instruction_number
                    ];

            end

            // ------------------------------------------------
            // Reset pipeline state.
            // ------------------------------------------------

            reset_cpu;

            // ------------------------------------------------
            // Restore architectural initial state.
            //
            // Reset clears the register file, so the initial
            // randomized-test state is loaded after reset.
            // ------------------------------------------------

            initialize_dut_state;

            // ------------------------------------------------
            // Execute independent sequential model.
            // ------------------------------------------------

            execute_reference_model;

            // ------------------------------------------------
            // Execute DUT.
            //
            // 40 instructions + 20 extra cycles.
            // ------------------------------------------------

            run_pipeline(
                RUN_CYCLES
            );

            // ------------------------------------------------
            // Compare architectural state.
            // ------------------------------------------------

            compare_registers;

            compare_memory;

            // ------------------------------------------------
            // Statistics.
            // ------------------------------------------------

            programs_run =
                programs_run + 1;

            total_instructions =
                total_instructions +
                PROGRAM_LENGTH;

            // ------------------------------------------------
            // PASS / FAIL
            // ------------------------------------------------

            if (
                (register_failures == 0) &&
                (memory_failures == 0)
            ) begin

                programs_passed =
                    programs_passed + 1;

                $display(
                    "PROGRAM %0d PASS",
                    program_number + 1
                );

            end

            else begin

                programs_failed =
                    programs_failed + 1;

                $display("");
                $display("============================================================");
                $display(
                    "PROGRAM %0d FAIL",
                    program_number + 1
                );
                $display("============================================================");

                $display(
                    "Register failures = %0d",
                    register_failures
                );

                $display(
                    "Memory failures   = %0d",
                    memory_failures
                );

                $display(
                    "REPRODUCE WITH RANDOM SEED = %08h",
                    RANDOM_SEED
                );

                $display(
                    "FAILED PROGRAM NUMBER = %0d",
                    program_number + 1
                );

                display_register_state;
                display_memory_state;

                $display("");

                // Stop at first failure so the exact randomized
                // program remains easy to reproduce.

                $finish;

            end

        end

        // ====================================================
        // FINAL REPORT
        // ====================================================

        $display("");
        $display("============================================================");
        $display("       RANDOMIZED VERIFICATION FINAL REPORT");
        $display("============================================================");
        $display("");

        $display(
            "Random seed             = %08h",
            RANDOM_SEED
        );

        $display(
            "Programs executed       = %0d",
            programs_run
        );

        $display(
            "Programs passed         = %0d",
            programs_passed
        );

        $display(
            "Programs failed         = %0d",
            programs_failed
        );

        $display(
            "Random instructions     = %0d",
            total_instructions
        );

        $display(
            "Register comparisons    = %0d",
            register_checks
        );

        $display(
            "Memory comparisons      = %0d",
            memory_checks
        );

        $display("");

        if (programs_failed == 0) begin

            $display(
                "============================================================"
            );

            $display(
                "       ALL RANDOMIZED PROGRAMS PASSED"
            );

            $display(
                "============================================================"
            );

        end

        else begin

            $display(
                "============================================================"
            );

            $display(
                "       RANDOMIZED VERIFICATION FAILED"
            );

            $display(
                "============================================================"
            );

        end

        $display("");

        $finish;

    end

endmodule
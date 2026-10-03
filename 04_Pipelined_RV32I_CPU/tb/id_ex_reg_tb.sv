// ============================================================
// Project 4: ID/EX Pipeline Register Testbench
// ============================================================

`timescale 1ns/1ps

module id_ex_reg_tb;

    logic clk;
    logic rst_n;
    logic stall;
    logic flush;

    logic [31:0] id_pc;
    logic [31:0] id_pc_plus4;

    logic [31:0] id_register_data1;
    logic [31:0] id_register_data2;

    logic [31:0] id_immediate;

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] id_rd;

    logic [2:0] id_funct3;
    logic       id_funct7_bit5;

    logic       id_RegWrite;
    logic       id_ALUSrc;
    logic       id_MemRead;
    logic       id_MemWrite;
    logic       id_MemToReg;
    logic       id_Branch;
    logic [1:0] id_ALUOp;

    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus4;

    logic [31:0] ex_register_data1;
    logic [31:0] ex_register_data2;

    logic [31:0] ex_immediate;

    logic [4:0] ex_rs1;
    logic [4:0] ex_rs2;
    logic [4:0] ex_rd;

    logic [2:0] ex_funct3;
    logic       ex_funct7_bit5;

    logic       ex_RegWrite;
    logic       ex_ALUSrc;
    logic       ex_MemRead;
    logic       ex_MemWrite;
    logic       ex_MemToReg;
    logic       ex_Branch;
    logic [1:0] ex_ALUOp;

    logic       ex_valid;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    id_ex_reg dut (
        .clk               (clk),
        .rst_n             (rst_n),
        .stall             (stall),
        .flush             (flush),

        .id_pc             (id_pc),
        .id_pc_plus4       (id_pc_plus4),

        .id_register_data1 (id_register_data1),
        .id_register_data2 (id_register_data2),

        .id_immediate      (id_immediate),

        .id_rs1            (id_rs1),
        .id_rs2            (id_rs2),
        .id_rd             (id_rd),

        .id_funct3         (id_funct3),
        .id_funct7_bit5    (id_funct7_bit5),

        .id_RegWrite       (id_RegWrite),
        .id_ALUSrc         (id_ALUSrc),
        .id_MemRead        (id_MemRead),
        .id_MemWrite       (id_MemWrite),
        .id_MemToReg       (id_MemToReg),
        .id_Branch         (id_Branch),
        .id_ALUOp          (id_ALUOp),

        .ex_pc             (ex_pc),
        .ex_pc_plus4       (ex_pc_plus4),

        .ex_register_data1 (ex_register_data1),
        .ex_register_data2 (ex_register_data2),

        .ex_immediate      (ex_immediate),

        .ex_rs1            (ex_rs1),
        .ex_rs2            (ex_rs2),
        .ex_rd             (ex_rd),

        .ex_funct3         (ex_funct3),
        .ex_funct7_bit5    (ex_funct7_bit5),

        .ex_RegWrite       (ex_RegWrite),
        .ex_ALUSrc         (ex_ALUSrc),
        .ex_MemRead        (ex_MemRead),
        .ex_MemWrite       (ex_MemWrite),
        .ex_MemToReg       (ex_MemToReg),
        .ex_Branch         (ex_Branch),
        .ex_ALUOp          (ex_ALUOp),

        .ex_valid          (ex_valid)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Check task
    // --------------------------------------------------------

    task automatic check(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_data1,
        input logic [31:0] expected_data2,
        input logic [31:0] expected_imm,
        input logic [4:0]  expected_rs1,
        input logic [4:0]  expected_rs2,
        input logic [4:0]  expected_rd,
        input logic        expected_RegWrite,
        input logic        expected_ALUSrc,
        input logic        expected_MemRead,
        input logic        expected_MemWrite,
        input logic        expected_MemToReg,
        input logic        expected_Branch,
        input logic [1:0]  expected_ALUOp,
        input logic        expected_valid,
        input string       test_name
    );

        begin

            #1;

            if (
                ex_pc             === expected_pc &&
                ex_register_data1 === expected_data1 &&
                ex_register_data2 === expected_data2 &&
                ex_immediate      === expected_imm &&
                ex_rs1            === expected_rs1 &&
                ex_rs2            === expected_rs2 &&
                ex_rd             === expected_rd &&
                ex_RegWrite       === expected_RegWrite &&
                ex_ALUSrc         === expected_ALUSrc &&
                ex_MemRead        === expected_MemRead &&
                ex_MemWrite       === expected_MemWrite &&
                ex_MemToReg       === expected_MemToReg &&
                ex_Branch         === expected_Branch &&
                ex_ALUOp          === expected_ALUOp &&
                ex_valid          === expected_valid
            ) begin

                $display(
                    "PASS: %s",
                    test_name
                );

            end
            else begin

                $display(
                    "FAIL: %s",
                    test_name
                );

                $display(
                    "Expected PC=%08h DATA1=%08h DATA2=%08h IMM=%08h",
                    expected_pc,
                    expected_data1,
                    expected_data2,
                    expected_imm
                );

                $display(
                    "Got      PC=%08h DATA1=%08h DATA2=%08h IMM=%08h",
                    ex_pc,
                    ex_register_data1,
                    ex_register_data2,
                    ex_immediate
                );

                $fatal;

            end

        end

    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        $display("");
        $display("============================================================");
        $display("          ID/EX PIPELINE REGISTER VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------

        rst_n = 1'b0;
        stall = 1'b0;
        flush = 1'b0;

        id_pc = 32'h0000_0010;
        id_pc_plus4 = 32'h0000_0014;

        id_register_data1 = 32'h0000_000A;
        id_register_data2 = 32'h0000_0014;

        id_immediate = 32'h0000_0020;

        id_rs1 = 5'd1;
        id_rs2 = 5'd2;
        id_rd  = 5'd3;

        id_funct3 = 3'b000;
        id_funct7_bit5 = 1'b0;

        id_RegWrite = 1'b1;
        id_ALUSrc = 1'b0;
        id_MemRead = 1'b0;
        id_MemWrite = 1'b0;
        id_MemToReg = 1'b0;
        id_Branch = 1'b0;
        id_ALUOp = 2'b10;

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        @(posedge clk);
        #1;

        check(
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            5'd0,
            5'd0,
            5'd0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b00,
            1'b0,
            "Reset"
        );

        // ----------------------------------------------------
        // NORMAL CAPTURE
        // ----------------------------------------------------

        rst_n = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0010,
            32'h0000_000A,
            32'h0000_0014,
            32'h0000_0020,
            5'd1,
            5'd2,
            5'd3,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b10,
            1'b1,
            "Normal capture"
        );

        // ----------------------------------------------------
        // STALL / HOLD
        // ----------------------------------------------------

        stall = 1'b1;

        id_pc = 32'h0000_0050;
        id_register_data1 = 32'hAAAA_AAAA;
        id_register_data2 = 32'hBBBB_BBBB;
        id_immediate = 32'hCCCC_CCCC;

        @(posedge clk);

        check(
            32'h0000_0010,
            32'h0000_000A,
            32'h0000_0014,
            32'h0000_0020,
            5'd1,
            5'd2,
            5'd3,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b10,
            1'b1,
            "Stall / hold"
        );

        // ----------------------------------------------------
        // FLUSH
        // ----------------------------------------------------

        flush = 1'b1;

        @(posedge clk);

        check(
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            5'd0,
            5'd0,
            5'd0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b00,
            1'b0,
            "Flush / bubble"
        );

        // ----------------------------------------------------
        // RESUME NORMAL OPERATION
        // ----------------------------------------------------

        flush = 1'b0;
        stall = 1'b0;

        id_pc = 32'h0000_0060;
        id_register_data1 = 32'h0000_0033;
        id_register_data2 = 32'h0000_0044;
        id_immediate = 32'h0000_0055;

        id_rs1 = 5'd6;
        id_rs2 = 5'd7;
        id_rd = 5'd8;

        @(posedge clk);

        check(
            32'h0000_0060,
            32'h0000_0033,
            32'h0000_0044,
            32'h0000_0055,
            5'd6,
            5'd7,
            5'd8,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            2'b10,
            1'b1,
            "Resume after flush"
        );

        $display("");
        $display("============================================================");
        $display("             ID/EX REGISTER RESULT");
        $display("============================================================");
        $display("ALL ID/EX PIPELINE REGISTER TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule
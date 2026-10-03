// ============================================================
// Project 4: EX Stage Testbench
// ============================================================

`timescale 1ns/1ps

module ex_stage_tb;

    logic [31:0] ex_register_data1;
    logic [31:0] ex_register_data2;
    logic [31:0] ex_immediate;

    logic [2:0] ex_funct3;
    logic       ex_funct7_bit5;

    logic       ex_ALUSrc;
    logic [1:0] ex_ALUOp;

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    logic [31:0] ex_mem_forward_value;
    logic [31:0] mem_wb_forward_value;

    logic [31:0] alu_result;
    logic        alu_zero;

    logic [31:0] store_data;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    ex_stage dut (
        .ex_register_data1 (ex_register_data1),
        .ex_register_data2 (ex_register_data2),
        .ex_immediate      (ex_immediate),

        .ex_funct3         (ex_funct3),
        .ex_funct7_bit5    (ex_funct7_bit5),

        .ex_ALUSrc         (ex_ALUSrc),
        .ex_ALUOp          (ex_ALUOp),

        .forward_a         (forward_a),
        .forward_b         (forward_b),

        .ex_mem_forward_value(ex_mem_forward_value),
        .mem_wb_forward_value(mem_wb_forward_value),

        .alu_result        (alu_result),
        .alu_zero          (alu_zero),

        .store_data        (store_data)
    );

    // --------------------------------------------------------
    // Constants
    // --------------------------------------------------------

    localparam logic [1:0] ALUOP_RTYPE = 2'b10;
    localparam logic [1:0] ALUOP_IMM   = 2'b00;

    // funct3
    localparam logic [2:0] F3_ADD_SUB = 3'b000;
    localparam logic [2:0] F3_XOR     = 3'b100;
    localparam logic [2:0] F3_SLT     = 3'b010;

    // --------------------------------------------------------
    // Check ALU result
    // --------------------------------------------------------

    task automatic check_result(
        input logic [31:0] expected_result,
        input logic [31:0] expected_store,
        input string       test_name
    );

        begin

            #1;

            if (
                alu_result === expected_result &&
                store_data === expected_store
            ) begin

                $display(
                    "PASS: %-40s ALU=%08h STORE=%08h",
                    test_name,
                    alu_result,
                    store_data
                );

            end
            else begin

                $display(
                    "FAIL: %-40s ALU=%08h STORE=%08h",
                    test_name,
                    alu_result,
                    store_data
                );

                $display(
                    "      Expected ALU=%08h STORE=%08h",
                    expected_result,
                    expected_store
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
        $display("                 EX STAGE VERIFICATION");
        $display("============================================================");

        // ----------------------------------------------------
        // Test 1: Normal ADD
        // ----------------------------------------------------

        ex_register_data1 = 32'd10;
        ex_register_data2 = 32'd20;
        ex_immediate = 32'd0;

        ex_funct3 = F3_ADD_SUB;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b0;
        ex_ALUOp = ALUOP_RTYPE;

        forward_a = 2'b00;
        forward_b = 2'b00;

        ex_mem_forward_value = 32'd0;
        mem_wb_forward_value = 32'd0;

        check_result(
            32'd30,
            32'd20,
            "Normal ADD"
        );

        // ----------------------------------------------------
        // Test 2: EX/MEM forwarding to A
        //
        // 100 + 20 = 120
        // ----------------------------------------------------

        ex_register_data1 = 32'd10;
        ex_register_data2 = 32'd20;

        ex_mem_forward_value = 32'd100;

        forward_a = 2'b10;
        forward_b = 2'b00;

        check_result(
            32'd120,
            32'd20,
            "EX/MEM forwarding to A"
        );

        // ----------------------------------------------------
        // Test 3: EX/MEM forwarding to B
        //
        // 10 + 100 = 110
        // ----------------------------------------------------

        ex_register_data1 = 32'd10;
        ex_register_data2 = 32'd20;

        ex_mem_forward_value = 32'd100;

        forward_a = 2'b00;
        forward_b = 2'b10;

        check_result(
            32'd110,
            32'd100,
            "EX/MEM forwarding to B"
        );

        // ----------------------------------------------------
        // Test 4: MEM/WB forwarding to A
        // ----------------------------------------------------

        ex_register_data1 = 32'd10;
        ex_register_data2 = 32'd20;

        mem_wb_forward_value = 32'd50;

        forward_a = 2'b01;
        forward_b = 2'b00;

        check_result(
            32'd70,
            32'd20,
            "MEM/WB forwarding to A"
        );

        // ----------------------------------------------------
        // Test 5: MEM/WB forwarding to B
        // ----------------------------------------------------

        mem_wb_forward_value = 32'd50;

        forward_a = 2'b00;
        forward_b = 2'b01;

        check_result(
            32'd60,
            32'd50,
            "MEM/WB forwarding to B"
        );

        // ----------------------------------------------------
        // Test 6: Immediate operation
        //
        // 10 + 25 = 35
        // ----------------------------------------------------

        ex_register_data1 = 32'd10;
        ex_register_data2 = 32'd99;
        ex_immediate = 32'd25;

        ex_funct3 = F3_ADD_SUB;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b1;
        ex_ALUOp = ALUOP_IMM;

        forward_a = 2'b00;
        forward_b = 2'b00;

        check_result(
            32'd35,
            32'd99,
            "Immediate ALU operation"
        );

        // ----------------------------------------------------
        // Test 7: Signed SLT
        //
        // -5 < 3 = 1
        // ----------------------------------------------------

        ex_register_data1 = -32'sd5;
        ex_register_data2 = 32'd3;

        ex_immediate = 32'd0;

        ex_funct3 = F3_SLT;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b0;
        ex_ALUOp = ALUOP_RTYPE;

        forward_a = 2'b00;
        forward_b = 2'b00;

        check_result(
            32'd1,
            32'd3,
            "Signed SLT"
        );

        // ----------------------------------------------------
        // Test 8: BEQ equality
        //
        // 42 - 42 = 0
        // ----------------------------------------------------

        ex_register_data1 = 32'd42;
        ex_register_data2 = 32'd42;

        ex_funct3 = F3_ADD_SUB;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b0;
        ex_ALUOp = 2'b01;

        forward_a = 2'b00;
        forward_b = 2'b00;

        check_result(
            32'd0,
            32'd42,
            "BEQ equality comparison"
        );

        if (alu_zero !== 1'b1) begin
            $display("FAIL: BEQ zero flag");
            $fatal;
        end
        else begin
            $display("PASS: BEQ zero flag");
        end

        // ----------------------------------------------------
        // Test 9: Store-data forwarding
        // ----------------------------------------------------

        ex_register_data1 = 32'd100;
        ex_register_data2 = 32'd20;
        ex_immediate = 32'd4;

        ex_funct3 = F3_ADD_SUB;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b1;
        ex_ALUOp = ALUOP_IMM;

        ex_mem_forward_value = 32'd55;

        forward_a = 2'b00;
        forward_b = 2'b10;

        check_result(
            32'd104,
            32'd55,
            "Store-data forwarding"
        );

        // ----------------------------------------------------
        // Test 10: Both operands forwarded
        // ----------------------------------------------------

        ex_register_data1 = 32'd1;
        ex_register_data2 = 32'd2;

        ex_mem_forward_value = 32'd30;
        mem_wb_forward_value = 32'd40;

        ex_funct3 = F3_XOR;
        ex_funct7_bit5 = 1'b0;

        ex_ALUSrc = 1'b0;
        ex_ALUOp = ALUOP_RTYPE;

        forward_a = 2'b10;
        forward_b = 2'b01;

        check_result(
            32'h0000_0036,
            32'd40,
            "Both operands forwarded"
        );

        $display("");
        $display("============================================================");
        $display("                  EX STAGE RESULT");
        $display("============================================================");
        $display("TOTAL TESTS = 10");
        $display("PASSED      = 10");
        $display("FAILED      = 0");
        $display("ALL EX STAGE TESTS PASSED");
        $display("============================================================");
        $display("");

        $finish;

    end

endmodule
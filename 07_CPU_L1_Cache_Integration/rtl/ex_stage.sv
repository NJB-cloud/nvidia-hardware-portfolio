// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: EX Stage
//
// Purpose:
//   Execute-stage datapath with operand forwarding.
//
// Forwarding:
//
//   00 -> ID/EX register value
//   01 -> MEM/WB write-back value
//   10 -> EX/MEM ALU result
//
// Supported:
//   ADD, SUB, AND, OR, XOR, SLT
//   Immediate ALU operations used by LW/SW
//   BEQ comparison
// ============================================================

module ex_stage (

    // --------------------------------------------------------
    // ID/EX inputs
    // --------------------------------------------------------

    input logic [31:0] ex_register_data1,
    input logic [31:0] ex_register_data2,
    input logic [31:0] ex_immediate,

    input logic [2:0] ex_funct3,
    input logic       ex_funct7_bit5,

    input logic       ex_ALUSrc,
    input logic [1:0] ex_ALUOp,

    // --------------------------------------------------------
    // Forwarding controls
    // --------------------------------------------------------

    input logic [1:0] forward_a,
    input logic [1:0] forward_b,

    // --------------------------------------------------------
    // Forwarding sources
    // --------------------------------------------------------

    input logic [31:0] ex_mem_forward_value,
    input logic [31:0] mem_wb_forward_value,

    // --------------------------------------------------------
    // Outputs
    // --------------------------------------------------------

    output logic [31:0] alu_result,
    output logic        alu_zero,

    output logic [31:0] store_data
);


    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------

    logic [31:0] operand_a;
    logic [31:0] operand_b_register;
    logic [31:0] alu_input_b;

    logic [3:0] alu_control;



    // ========================================================
    // FORWARDING MUX
    // ========================================================

    always_comb begin

        // Default register values

        operand_a        = ex_register_data1;
        operand_b_register = ex_register_data2;


        // ----------------------------------------------------
        // Forward operand A
        // ----------------------------------------------------

        case (forward_a)

            2'b10: begin
                operand_a = ex_mem_forward_value;
            end


            2'b01: begin
                operand_a = mem_wb_forward_value;
            end


            default: begin
                operand_a = ex_register_data1;
            end

        endcase



        // ----------------------------------------------------
        // Forward operand B
        // ----------------------------------------------------

        case (forward_b)

            2'b10: begin
                operand_b_register = ex_mem_forward_value;
            end


            2'b01: begin
                operand_b_register = mem_wb_forward_value;
            end


            default: begin
                operand_b_register = ex_register_data2;
            end

        endcase

    end



    // ========================================================
    // STORE DATA PATH
    //
    // SW needs forwarded rs2 value
    // ========================================================

    always_comb begin

        store_data = operand_b_register;

    end



    // ========================================================
    // ALU INPUT B SELECTION
    //
    // ALUSrc = 0 : register operand
    // ALUSrc = 1 : immediate
    // ========================================================

    always_comb begin

        if (ex_ALUSrc)

            alu_input_b = ex_immediate;

        else

            alu_input_b = operand_b_register;

    end



    // ========================================================
    // ALU CONTROL
    // ========================================================

    alu_control u_alu_control (

        .alu_op      (ex_ALUOp),
        .funct3      (ex_funct3),
        .funct7_bit5 (ex_funct7_bit5),
        .alu_control (alu_control)

    );



    // ========================================================
    // ALU
    // ========================================================

    alu u_alu (

        .a           (operand_a),
        .b           (alu_input_b),
        .alu_control (alu_control),
        .result      (alu_result),
        .zero        (alu_zero)

    );


endmodule
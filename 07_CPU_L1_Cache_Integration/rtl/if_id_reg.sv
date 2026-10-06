// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: IF/ID Pipeline Register
//
// Purpose:
//   Stores instruction fetch information between IF and ID.
//
// Supports:
//   - Normal pipeline advance
//   - Stall / hold
//   - Flush bubble
//   - Reset
//
// Project 7 Fix:
//   - Proper valid-bit propagation
//   - Prevents NOPs during stalls from becoming real instructions
// ============================================================


module if_id_reg (

    input logic clk,
    input logic rst_n,


    // --------------------------------------------------------
    // Pipeline control
    // --------------------------------------------------------

    input logic stall,
    input logic flush,


    // --------------------------------------------------------
    // IF stage inputs
    // --------------------------------------------------------

    input logic [31:0] if_pc,
    input logic [31:0] if_pc_plus4,
    input logic [31:0] if_instruction,


    // --------------------------------------------------------
    // ID stage outputs
    // --------------------------------------------------------

    output logic [31:0] id_pc,
    output logic [31:0] id_pc_plus4,
    output logic [31:0] id_instruction,

    output logic id_valid

);



always_ff @(posedge clk or negedge rst_n) begin


    // --------------------------------------------------------
    // RESET
    // --------------------------------------------------------

    if (!rst_n) begin


        id_pc          <= 32'h0000_0000;
        id_pc_plus4    <= 32'h0000_0000;

        // RISC-V NOP
        id_instruction <= 32'h0000_0013;

        id_valid       <= 1'b0;


    end



    // --------------------------------------------------------
    // FLUSH
    //
    // Insert pipeline bubble
    // --------------------------------------------------------

    else if (flush) begin


        id_pc          <= 32'h0000_0000;
        id_pc_plus4    <= 32'h0000_0000;

        id_instruction <= 32'h0000_0013;

        id_valid       <= 1'b0;


    end



    // --------------------------------------------------------
    // STALL
    //
    // Hold current instruction.
    // Used during cache wait.
    // --------------------------------------------------------

    else if (stall) begin


        id_pc          <= id_pc;
        id_pc_plus4    <= id_pc_plus4;

        id_instruction <= id_instruction;

        id_valid       <= id_valid;


    end



    // --------------------------------------------------------
    // NORMAL ADVANCE
    // --------------------------------------------------------

    else begin


        id_pc          <= if_pc;

        id_pc_plus4    <= if_pc_plus4;

        id_instruction <= if_instruction;


        id_valid       <= 1'b1;


    end


end


endmodule
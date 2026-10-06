// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: Program Counter
//
// Purpose:
//   Holds current instruction address.
//
// Features:
//   - Synchronous PC update
//   - Reset support
//   - Stall support for cache/pipeline wait
//   - Branch/jump next PC selection handled externally
// ============================================================


module pc (

    input logic clk,
    input logic rst_n,


    // --------------------------------------------------------
    // Control
    // --------------------------------------------------------

    input logic stall,


    // --------------------------------------------------------
    // Next PC input
    // --------------------------------------------------------

    input logic [31:0] next_pc,


    // --------------------------------------------------------
    // Current PC output
    // --------------------------------------------------------

    output logic [31:0] current_pc

);



always_ff @(posedge clk or negedge rst_n) begin


    // --------------------------------------------------------
    // RESET
    // --------------------------------------------------------

    if (!rst_n) begin


        current_pc <= 32'h0000_0000;


    end



    // --------------------------------------------------------
    // STALL
    //
    // Hold PC during:
    // - cache miss
    // - memory wait
    // - pipeline stall
    // --------------------------------------------------------

    else if (stall) begin


        current_pc <= current_pc;


    end



    // --------------------------------------------------------
    // NORMAL UPDATE
    // --------------------------------------------------------

    else begin


        current_pc <= next_pc;


    end


end


endmodule
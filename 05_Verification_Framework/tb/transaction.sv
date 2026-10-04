`ifndef FIFO_TRANSACTION_SV
`define FIFO_TRANSACTION_SV
// ============================================================
// Project 5
// FIFO Transaction Object
//
// Icarus-compatible transaction class
// Demonstrates transaction-based verification
// ============================================================


class fifo_transaction;


    // --------------------------------------------------------
    // Operation
    // --------------------------------------------------------

    bit write;


    // --------------------------------------------------------
    // Payload
    // --------------------------------------------------------

    bit [31:0] data;



    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------

    function new();

        write = 0;
        data  = 32'h0;

    endfunction



    // --------------------------------------------------------
    // Randomize transaction
    //
    // Manual constraint-random generation
    // Compatible with Icarus Verilog
    // --------------------------------------------------------

    function void randomize_transaction();


        write = $urandom_range(0,1);

        data  = $urandom;


    endfunction



    // --------------------------------------------------------
    // Display
    // --------------------------------------------------------

    function void display();


        if(write) begin

            $display(
                "FIFO WRITE : DATA = %08h",
                data
            );

        end

        else begin

            $display(
                "FIFO READ REQUEST"
            );

        end


    endfunction


endclass
`endif
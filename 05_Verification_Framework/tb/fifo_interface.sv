// ============================================================
// Project 5
// FIFO Verification Interface
//
// Connects verification components to DUT
// ============================================================


interface fifo_interface(input logic clk);


    logic rst_n;


    // Write channel

    logic        write_valid;
    logic        write_ready;
    logic [31:0] write_data;



    // Read channel

    logic        read_valid;
    logic        read_ready;
    logic [31:0] read_data;



    // Status

    logic empty;
    logic full;



endinterface
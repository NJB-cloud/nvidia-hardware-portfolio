// ============================================================
// Project 5
// FIFO Monitor
//
// Icarus-compatible monitor
// Observes FIFO interface signals
// ============================================================


`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV


`include "tb/transaction.sv"


class fifo_monitor;


    // Observed transaction counter

    integer transaction_count;



    function new();

        transaction_count = 0;

    endfunction



    // --------------------------------------------------------
    // Monitor write observation
    // --------------------------------------------------------

    task observe_write(
        input logic [31:0] data
    );


        fifo_transaction tr;


        tr = new();


        tr.write = 1'b1;

        tr.data = data;


        transaction_count =
            transaction_count + 1;


        $display(
            "MONITOR WRITE : DATA = %08h",
            tr.data
        );


    endtask



    // --------------------------------------------------------
    // Monitor read observation
    // --------------------------------------------------------

    task observe_read(
        input logic [31:0] data
    );


        fifo_transaction tr;


        tr = new();


        tr.write = 1'b0;

        tr.data = data;


        transaction_count =
            transaction_count + 1;


        $display(
            "MONITOR READ : DATA = %08h",
            tr.data
        );


    endtask



endclass


`endif
`ifndef FIFO_GENERATOR_SV
`define FIFO_GENERATOR_SV
// ============================================================
// Project 5
// Transaction Generator
//
// Creates randomized FIFO transactions
// ============================================================


`include "tb/transaction.sv"


class fifo_generator;


    // Number of transactions

    integer num_transactions;



    // Constructor

    function new();

        num_transactions = 100;

    endfunction



    // Generate transactions

    task generate_transactions();


        fifo_transaction tr;


        for(
            integer i = 0;
            i < num_transactions;
            i = i + 1
        ) begin


            tr = new();


            tr.randomize_transaction();


            $display(
                "GENERATOR TRANSACTION %0d",
                i
            );


            tr.display();


        end


    endtask


endclass
`endif
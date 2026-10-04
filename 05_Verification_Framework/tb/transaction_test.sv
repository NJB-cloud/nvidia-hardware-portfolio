// ============================================================
// Project 5
// Transaction Class Test
// ============================================================

`include "tb/transaction.sv"


module transaction_test;


    fifo_transaction tr;


    initial begin


        tr = new();


        repeat(5) begin


            tr.randomize_transaction();


            tr.display();


        end


        $finish;


    end


endmodule
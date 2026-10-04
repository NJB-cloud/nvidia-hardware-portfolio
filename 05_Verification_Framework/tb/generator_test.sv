// ============================================================
// Generator Test
// ============================================================

`include "tb/generator.sv"


module generator_test;


    fifo_generator gen;


    initial begin


        gen = new();


        gen.num_transactions = 10;


        gen.generate_transactions();


        $finish;


    end


endmodule
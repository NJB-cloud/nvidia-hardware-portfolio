// ============================================================
// Project 5
// FIFO Integrated Verification Testbench
// ============================================================


`include "tb/fifo_interface.sv"
`include "tb/transaction.sv"
`include "tb/generator.sv"


module fifo_testbench;


    logic clk;


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin

        clk = 0;

        forever #5 clk = ~clk;

    end



    // --------------------------------------------------------
    // Interface
    // --------------------------------------------------------

    fifo_interface fifo_if(clk);



    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    packet_fifo dut (

        .clk          (clk),
        .rst_n        (fifo_if.rst_n),

        .write_valid  (fifo_if.write_valid),
        .write_ready  (fifo_if.write_ready),
        .write_data   (fifo_if.write_data),

        .read_valid   (fifo_if.read_valid),
        .read_ready   (fifo_if.read_ready),
        .read_data    (fifo_if.read_data),

        .empty        (fifo_if.empty),
        .full         (fifo_if.full),

        .occupancy    ()

    );



    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin


        fifo_if.rst_n = 0;

        fifo_if.write_valid = 0;
        fifo_if.read_ready  = 0;
        fifo_if.write_data  = 0;


        repeat(3)
            @(posedge clk);


        fifo_if.rst_n = 1;



        $display(
            "FIFO VERIFICATION ENVIRONMENT STARTED"
        );


        repeat(10)
            @(posedge clk);



        $display(
            "FIFO TEST COMPLETED"
        );


        $finish;


    end


endmodule
// ============================================================
// Project 5
// FIFO Verification Environment Test
//
// Integrated verification environment
// With Assertion-Based Verification
//
// Icarus compatible
// ============================================================


`include "tb/transaction.sv"
`include "tb/generator.sv"
`include "tb/driver.sv"
`include "tb/scoreboard.sv"
`include "tb/reference_model.sv"
`include "tb/fifo_assertions.sv"



module fifo_environment_test;



    // ========================================================
    // Clock and Reset
    // ========================================================

    logic clk;

    logic rst_n;



    // ========================================================
    // FIFO Signals
    // ========================================================

    logic write_valid;

    logic write_ready;

    logic [31:0] write_data;


    logic read_valid;

    logic read_ready;

    logic [31:0] read_data;


    logic empty;

    logic full;

    logic [4:0] occupancy;



    // ========================================================
    // DUT
    // ========================================================

    packet_fifo dut (

        .clk(clk),

        .rst_n(rst_n),


        .write_valid(write_valid),

        .write_ready(write_ready),

        .write_data(write_data),


        .read_valid(read_valid),

        .read_ready(read_ready),

        .read_data(read_data),


        .empty(empty),

        .full(full),

        .occupancy(occupancy)

    );



    // ========================================================
    // Assertion Module
    // ========================================================

    fifo_assertions assertions (

        .clk(clk),

        .rst_n(rst_n),

        .empty(empty),

        .full(full),

        .occupancy(occupancy),

        .write_valid(write_valid),

        .read_ready(read_ready)

    );



    // ========================================================
    // Driver Module
    // ========================================================

    fifo_driver driver (

        .clk(clk),

        .write_valid(write_valid),

        .write_data(write_data),

        .read_ready(read_ready)

    );



    // ========================================================
    // Reference Model
    // ========================================================

    fifo_reference_model reference();



    // ========================================================
    // Clock
    // ========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end



    // ========================================================
    // Verification Components
    // ========================================================

    fifo_generator generator;

    fifo_scoreboard scoreboard;



    // ========================================================
    // Main Test
    // ========================================================

    initial begin


        // GTKWave

        $dumpfile(
            "fifo_environment.vcd"
        );

        $dumpvars(0);



        generator = new();

        scoreboard = new();



        // Reset

        rst_n = 1'b0;



        repeat(3)

            @(posedge clk);



        rst_n = 1'b1;



        $display("");

        $display("==============================");

        $display(
            " FIFO VERIFICATION START"
        );

        $display("==============================");



        // ====================================================
        // Transaction Generation
        // ====================================================


        repeat(10) begin



            fifo_transaction tr;



            tr = new();



            tr.randomize_transaction();



            tr.display();



            // ----------------------------
            // WRITE
            // ----------------------------

            if(tr.write) begin



                driver.drive_write(

                    tr.data

                );



                reference.write(

                    tr.data

                );



            end



            // ----------------------------
            // READ
            // ----------------------------

            else begin



                driver.drive_read();



                reference.read();



                scoreboard.compare(

                    reference.expected_data,

                    read_data

                );



            end



        end



        scoreboard.report();



        $display("");

        $display(
            "FIFO VERIFICATION COMPLETE"
        );



        $finish;



    end



endmodule
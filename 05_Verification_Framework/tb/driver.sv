// ============================================================
// Project 5
// FIFO Driver Module
//
// Icarus-compatible DUT driver
// ============================================================


module fifo_driver(

    input  clk,

    output reg write_valid,

    output reg [31:0] write_data,

    output reg read_ready

);



    integer drive_count;



    initial begin

        drive_count = 0;

        write_valid = 1'b0;

        write_data  = 32'h00000000;

        read_ready  = 1'b0;

    end



    // --------------------------------------------------------
    // Drive WRITE
    // --------------------------------------------------------

    task drive_write;


        input [31:0] data;


        begin


            @(posedge clk);


            write_valid = 1'b1;

            write_data  = data;


            drive_count = drive_count + 1;


            $display(
                "DRIVER WRITE : DATA = %08h",
                data
            );


            @(posedge clk);


            write_valid = 1'b0;

            write_data  = 32'h00000000;


        end


    endtask



    // --------------------------------------------------------
    // Drive READ
    // --------------------------------------------------------

    task drive_read;


        begin


            @(posedge clk);


            read_ready = 1'b1;


            drive_count = drive_count + 1;


            $display(
                "DRIVER READ REQUEST"
            );


            @(posedge clk);


            read_ready = 1'b0;


        end


    endtask



endmodule
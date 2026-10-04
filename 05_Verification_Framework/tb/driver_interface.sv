// ============================================================
// Project 5
// Driver Interface
// ============================================================


module driver_interface;


    reg write_valid;

    reg [31:0] write_data;


    reg read_ready;



    initial begin

        write_valid = 1'b0;

        write_data  = 32'h00000000;

        read_ready  = 1'b0;

    end


endmodule
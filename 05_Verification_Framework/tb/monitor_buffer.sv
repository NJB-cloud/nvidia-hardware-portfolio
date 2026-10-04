// ============================================================
// Project 5
// Monitor Transaction Buffer
//
// Shared communication channel between monitor and scoreboard
// Icarus-compatible implementation
// ============================================================


module monitor_buffer;


    reg [31:0] observed_data;

    reg observed_write;

    reg observed_valid;



    initial begin

        observed_data  = 32'h00000000;

        observed_write = 1'b0;

        observed_valid = 1'b0;

    end


endmodule
// ============================================================
// Project 5
// FIFO Scoreboard
//
// Compares DUT output with reference model output
// ============================================================


`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV


class fifo_scoreboard;


    integer pass_count;
    integer fail_count;



    function new();

        pass_count = 0;
        fail_count = 0;

    endfunction



    // --------------------------------------------------------
    // Compare transaction
    // --------------------------------------------------------

    task compare(

        input logic [31:0] expected,
        input logic [31:0] actual

    );


        if(expected === actual) begin


            pass_count = pass_count + 1;


            $display(
                "SCOREBOARD PASS : DATA = %08h",
                actual
            );


        end

        else begin


            fail_count = fail_count + 1;


            $display(
                "SCOREBOARD FAIL : EXPECTED=%08h ACTUAL=%08h",
                expected,
                actual
            );


        end


    endtask



    // --------------------------------------------------------
    // Report
    // --------------------------------------------------------

    task report();


        $display("");
        $display("===============================");
        $display(" SCOREBOARD REPORT");
        $display("===============================");

        $display(
            "PASS = %0d",
            pass_count
        );

        $display(
            "FAIL = %0d",
            fail_count
        );

        $display("===============================");


    endtask



endclass


`endif
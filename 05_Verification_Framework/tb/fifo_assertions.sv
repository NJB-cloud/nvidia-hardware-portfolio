// ============================================================
// Project 5
// FIFO Assertion Checks
//
// Assertion-based verification
// ============================================================


module fifo_assertions(

    input clk,

    input rst_n,

    input empty,

    input full,

    input [4:0] occupancy,

    input write_valid,

    input read_ready

);



    // --------------------------------------------------------
    // Reset must clear FIFO
    // --------------------------------------------------------

    always @(posedge clk) begin

        if(!rst_n) begin

            assert(occupancy == 0)

            else

                $error("FIFO RESET FAILURE");


        end

    end



    // --------------------------------------------------------
    // Occupancy cannot exceed depth
    // --------------------------------------------------------

    always @(posedge clk) begin


        assert(occupancy <= 5'd16)

        else

            $error("FIFO OVERFLOW");


    end



    // --------------------------------------------------------
    // Empty FIFO should not allow read
    // --------------------------------------------------------

    always @(posedge clk) begin


        if(empty)

            assert(!read_ready)

            else

                $error("READ FROM EMPTY FIFO");


    end



    // --------------------------------------------------------
    // Full FIFO should not accept write
    // --------------------------------------------------------

    always @(posedge clk) begin


        if(full)

            assert(!write_valid)

            else

                $error("WRITE TO FULL FIFO");


    end



endmodule
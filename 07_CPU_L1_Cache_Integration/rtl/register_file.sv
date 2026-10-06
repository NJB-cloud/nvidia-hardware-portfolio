// ============================================================
// Project 4: 5-Stage Pipelined RV32I CPU
// Module: RV32I Register File
//
// Purpose:
//   32 x 32-bit integer register file with:
//     - two asynchronous read ports
//     - one synchronous write port
//     - x0 hardwired to zero
//     - WB-to-ID write-through bypass
//
// ============================================================

module register_file (

    input logic         clk,
    input logic         rst_n,

    // --------------------------------------------------------
    // Read ports
    // --------------------------------------------------------

    input logic [4:0]   rs1,
    input logic [4:0]   rs2,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    // --------------------------------------------------------
    // Write port
    // --------------------------------------------------------

    input logic [4:0]   rd,
    input logic [31:0]  write_data,
    input logic         reg_write
);


    logic [31:0] registers [0:31];

    integer i;


    // ========================================================
    // ASYNCHRONOUS READ + WB WRITE THROUGH
    // ========================================================

    always_comb begin


        // -------------------------
        // READ PORT 1
        // -------------------------

        if (rs1 == 5'd0) begin

            read_data1 = 32'h0000_0000;

        end

        else if (
            reg_write &&
            (rd != 5'd0) &&
            (rd == rs1)
        ) begin

            read_data1 = write_data;

        end

        else begin

            read_data1 = registers[rs1];

        end



        // -------------------------
        // READ PORT 2
        // -------------------------

        if (rs2 == 5'd0) begin

            read_data2 = 32'h0000_0000;

        end

        else if (
            reg_write &&
            (rd != 5'd0) &&
            (rd == rs2)
        ) begin

            read_data2 = write_data;

        end

        else begin

            read_data2 = registers[rs2];

        end


    end



    // ========================================================
    // SYNCHRONOUS WRITE
    //
    // x0 is always zero.
    // ========================================================


    always_ff @(posedge clk or negedge rst_n) begin


        if (!rst_n) begin


            for (i = 0; i < 32; i = i + 1) begin

                registers[i] <= 32'h0000_0000;

            end


        end


        else begin


            if (
                reg_write &&
                (rd != 5'd0)
            ) begin


                registers[rd] <= write_data;


                // --------------------------------------------
                // DEBUG ONLY
                // Remove after verification
                // --------------------------------------------

                $display(
                    "REG_WRITE T=%0t RD=%0d DATA=%08h",
                    $time,
                    rd,
                    write_data
                );


            end


            // x0 protection

            registers[0] <= 32'h0000_0000;


        end


    end


endmodule
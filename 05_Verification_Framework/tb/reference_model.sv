`ifndef FIFO_REFERENCE_MODEL_MODULE
`define FIFO_REFERENCE_MODEL_MODULE
// ============================================================
// Project 5
// FIFO Reference Model
//
// Icarus-compatible module implementation
// ============================================================


module fifo_reference_model;


    reg [31:0] model_memory [0:15];


    integer write_pointer;
    integer read_pointer;
    integer count;


    reg [31:0] expected_data;



    initial begin

        write_pointer = 0;
        read_pointer  = 0;
        count         = 0;
        expected_data = 32'h00000000;

    end



    task write;

        input [31:0] data;


        begin

            if(count < 16) begin


                model_memory[write_pointer] = data;


                write_pointer =
                (write_pointer + 1) % 16;


                count = count + 1;


            end

        end


    endtask



    task read;


        begin


            if(count > 0) begin


                expected_data =
                model_memory[read_pointer];


                read_pointer =
                (read_pointer + 1) % 16;


                count = count - 1;


            end

            else begin

                expected_data = 32'h00000000;

            end


        end


    endtask



endmodule
`endif
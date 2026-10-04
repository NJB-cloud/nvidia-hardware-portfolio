// ============================================================
// Project 5: Advanced SystemVerilog Verification Framework
//
// DUT: AXI-Stream Style Synchronous Packet FIFO
//
// Features:
//   - Parameterized data width
//   - Parameterized depth
//   - Ready/valid handshake
//   - Full/empty detection
//   - Overflow protection
//   - Underflow protection
//   - Synthesizable RTL
//
// Target:
// NVIDIA Summer 2027 Hardware Verification Portfolio
// ============================================================


module packet_fifo #(

    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16

)(

    input  logic                  clk,
    input  logic                  rst_n,


    // -------------------------------
    // Write interface
    // -------------------------------

    input  logic                  write_valid,
    output logic                  write_ready,
    input  logic [DATA_WIDTH-1:0] write_data,


    // -------------------------------
    // Read interface
    // -------------------------------

    output logic                  read_valid,
    input  logic                  read_ready,
    output logic [DATA_WIDTH-1:0] read_data,


    // -------------------------------
    // Status
    // -------------------------------

    output logic                  empty,
    output logic                  full,

    output logic [$clog2(DEPTH+1)-1:0] occupancy

);


    // ========================================================
    // Local parameters
    // ========================================================

    localparam PTR_WIDTH = $clog2(DEPTH);


    // ========================================================
    // FIFO memory
    // ========================================================

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];


    // ========================================================
    // Pointers
    // ========================================================

    logic [PTR_WIDTH-1:0] write_ptr;
    logic [PTR_WIDTH-1:0] read_ptr;



    // ========================================================
    // Handshake conditions
    // ========================================================

    assign empty =
        (occupancy == 0);


    assign full =
        (occupancy == DEPTH);


    assign write_ready =
        !full;


    assign read_valid =
        !empty;



    // ========================================================
    // Output data
    // ========================================================

    assign read_data =
        memory[read_ptr];



    // ========================================================
    // FIFO control
    // ========================================================

    always_ff @(posedge clk or negedge rst_n) begin


        if (!rst_n) begin

            write_ptr <= '0;
            read_ptr  <= '0;
            occupancy <= '0;

        end


        else begin


            // --------------------------------------------
            // Write operation
            // --------------------------------------------

            if (write_valid && write_ready) begin

                memory[write_ptr] <= write_data;

                write_ptr <= write_ptr + 1'b1;

            end



            // --------------------------------------------
            // Read operation
            // --------------------------------------------

            if (read_valid && read_ready) begin

                read_ptr <= read_ptr + 1'b1;

            end



            // --------------------------------------------
            // Occupancy update
            // --------------------------------------------

            case ({
                (write_valid && write_ready),
                (read_valid && read_ready)
            })


                2'b10:

                    occupancy <= occupancy + 1'b1;


                2'b01:

                    occupancy <= occupancy - 1'b1;


                default:

                    occupancy <= occupancy;


            endcase


        end

    end


endmodule
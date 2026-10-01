// ============================================================
// Project 2: Verified UART + FIFO Subsystem
// Module: Parameterized Synchronous FIFO
// Language: SystemVerilog
// ============================================================

module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Write interface
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic                  wr_en,

    // Read interface
    output logic [DATA_WIDTH-1:0] rd_data,
    input  logic                  rd_en,

    // Status
    output logic                  full,
    output logic                  empty,
    output logic                  overflow,
    output logic                  underflow,

    // Number of stored entries
    output logic [$clog2(DEPTH+1)-1:0] count
);

    // --------------------------------------------------------
    // Pointer widths
    // --------------------------------------------------------

    localparam int PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    // Internal accepted operations
    logic write_accept;
    logic read_accept;

    // --------------------------------------------------------
    // Status logic
    // --------------------------------------------------------

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    assign write_accept = wr_en && !full;
    assign read_accept  = rd_en && !empty;

    // --------------------------------------------------------
    // FIFO sequential logic
    // --------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            wr_ptr    <= '0;
            rd_ptr    <= '0;
            rd_data   <= '0;
            count     <= '0;

            overflow  <= 1'b0;
            underflow <= 1'b0;

        end else begin

            // ------------------------------------------------
            // Overflow / underflow indication
            // ------------------------------------------------

            overflow  <= wr_en && full;
            underflow <= rd_en && empty;

            // ------------------------------------------------
            // Write operation
            // ------------------------------------------------

            if (write_accept) begin

                mem[wr_ptr] <= wr_data;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end

            // ------------------------------------------------
            // Read operation
            // ------------------------------------------------

            if (read_accept) begin

                rd_data <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end

            // ------------------------------------------------
            // Occupancy counter
            // ------------------------------------------------

            case ({write_accept, read_accept})

                2'b10: begin
                    count <= count + 1'b1;
                end

                2'b01: begin
                    count <= count - 1'b1;
                end

                2'b11: begin
                    count <= count;
                end

                default: begin
                    count <= count;
                end

            endcase

        end
    end

endmodule
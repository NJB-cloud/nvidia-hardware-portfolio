// ============================================================
// Project 2: UART + FIFO RTL Subsystem
// Module: UART Receiver
// Protocol: 8-N-1
// ============================================================

module uart_rx #(
    parameter int CLK_FREQ  = 50_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic       clk,
    input  logic       rst_n,

    // Serial input
    input  logic       rx,

    // Receive interface
    output logic [7:0] rx_data,
    output logic       rx_valid,

    // Status
    output logic       busy
);

    // --------------------------------------------------------
    // Baud-rate timing
    // --------------------------------------------------------

    localparam int BAUD_DIV =
        CLK_FREQ / BAUD_RATE;

    localparam int BAUD_CNT_WIDTH =
        (BAUD_DIV <= 1) ? 1 : $clog2(BAUD_DIV);

    localparam int HALF_BAUD =
        (BAUD_DIV / 2);

    logic [BAUD_CNT_WIDTH-1:0] baud_counter;

    // --------------------------------------------------------
    // Receiver state machine
    // --------------------------------------------------------

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    // --------------------------------------------------------
    // Data storage
    // --------------------------------------------------------

    logic [7:0] shift_reg;

    logic [2:0] bit_index;

    // --------------------------------------------------------
    // UART receiver
    // --------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state        <= IDLE;

            baud_counter <= '0;

            shift_reg    <= 8'h00;

            bit_index    <= 3'd0;

            rx_data      <= 8'h00;

            rx_valid     <= 1'b0;

            busy         <= 1'b0;

        end

        else begin

            // rx_valid is a one-clock pulse
            rx_valid <= 1'b0;

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------

                IDLE: begin

                    busy         <= 1'b0;
                    baud_counter <= '0;
                    bit_index    <= 3'd0;

                    // UART start bit is LOW
                    if (rx == 1'b0) begin

                        state        <= START_BIT;
                        busy         <= 1'b1;

                        // Sample approximately halfway through
                        // the start bit.
                        baud_counter <= HALF_BAUD - 1;

                    end

                end

                // ------------------------------------------------
                // START BIT
                // ------------------------------------------------

                START_BIT: begin

                    busy <= 1'b1;

                    if (baud_counter == 0) begin

                        // Confirm that the start bit is still LOW.
                        if (rx == 1'b0) begin

                            state        <= DATA_BITS;
                            bit_index    <= 3'd0;
                            baud_counter <= BAUD_DIV - 1;

                        end

                        else begin

                            // False start
                            state <= IDLE;
                            busy  <= 1'b0;
                        end

                    end

                    else begin

                        baud_counter <= baud_counter - 1'b1;

                    end

                end

                // ------------------------------------------------
                // DATA BITS
                // ------------------------------------------------

                DATA_BITS: begin

                    busy <= 1'b1;

                    if (baud_counter == 0) begin

                        // UART transmits LSB first
                        shift_reg[bit_index] <= rx;

                        baud_counter <= BAUD_DIV - 1;

                        if (bit_index == 3'd7) begin

                            state <= STOP_BIT;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin

                        baud_counter <= baud_counter - 1'b1;

                    end

                end

                // ------------------------------------------------
                // STOP BIT
                // ------------------------------------------------

                STOP_BIT: begin

                    busy <= 1'b1;

                    if (baud_counter == 0) begin

                        // Stop bit should be HIGH.
                        if (rx == 1'b1) begin

                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1;

                        end

                        state        <= IDLE;
                        busy         <= 1'b0;
                        baud_counter <= '0;
                        bit_index    <= 3'd0;

                    end

                    else begin

                        baud_counter <= baud_counter - 1'b1;

                    end

                end

                // ------------------------------------------------
                // Safety recovery
                // ------------------------------------------------

                default: begin

                    state        <= IDLE;
                    baud_counter <= '0;
                    bit_index    <= 3'd0;
                    busy         <= 1'b0;

                end

            endcase

        end

    end

endmodule
// ============================================================
// Project 2: UART + FIFO RTL Subsystem
// Module: UART Transmitter
// Protocol: 8-N-1
// ============================================================

module uart_tx #(
    parameter int CLK_FREQ  = 50_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic       clk,
    input  logic       rst_n,

    // Transmit interface
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,

    // Serial output
    output logic       tx,

    // Status
    output logic       busy
);

    localparam int BAUD_DIV =
        (CLK_FREQ / BAUD_RATE);

    localparam int BAUD_CNT_WIDTH =
        (BAUD_DIV <= 1) ? 1 : $clog2(BAUD_DIV);

    logic [BAUD_CNT_WIDTH-1:0] baud_counter;

    logic [3:0] bit_index;

    logic [9:0] shift_reg;

    // --------------------------------------------------------
    // UART transmitter state
    //
    // Frame format:
    //
    //       START  DATA[7:0]              STOP
    //         0   D0 D1 D2 D3 D4 D5 D6 D7  1
    //
    // --------------------------------------------------------

    assign tx_ready = !busy;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx           <= 1'b1;
            busy         <= 1'b0;

            baud_counter <= '0;
            bit_index    <= '0;
            shift_reg    <= 10'b1111111111;

        end else begin

            // ------------------------------------------------
            // Idle state
            // ------------------------------------------------

            if (!busy) begin

                tx <= 1'b1;

                if (tx_valid) begin

                    // 8-N-1 frame
                    //
                    // bit 0 = start
                    // bits 1-8 = data
                    // bit 9 = stop

                    shift_reg <= {
                        1'b1,
                        tx_data,
                        1'b0
                    };

                    busy         <= 1'b1;
                    bit_index    <= 4'd0;
                    baud_counter <= '0;

                    tx <= 1'b0;
                end

            end

            // ------------------------------------------------
            // Active transmission
            // ------------------------------------------------

            else begin

                if (baud_counter == BAUD_DIV-1) begin

                    baud_counter <= '0;

                    if (bit_index == 4'd9) begin

                        // Transmission complete
                        busy      <= 1'b0;
                        bit_index <= '0;
                        tx        <= 1'b1;

                    end else begin

                        bit_index <= bit_index + 1'b1;

                        shift_reg <= {
                            1'b1,
                            shift_reg[9:1]
                        };

                        tx <= shift_reg[1];

                    end

                end else begin

                    baud_counter <= baud_counter + 1'b1;

                end

            end

        end

    end

endmodule
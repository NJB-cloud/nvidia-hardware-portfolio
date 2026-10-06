`timescale 1ns/1ps

// ============================================================
// Project 6
// Cache Data Array
//
// 64 entries × 128 bits
// ============================================================

module cache_data_array #(
    parameter LINE_COUNT = 64,
    parameter LINE_WIDTH = 128
)(
    input  logic                  clk,
    input  logic                  we,
    input  logic [5:0]            index,
    input  logic [LINE_WIDTH-1:0] wdata,
    output logic [LINE_WIDTH-1:0] rdata
);

    logic [LINE_WIDTH-1:0] data_array [0:LINE_COUNT-1];

    always_ff @(posedge clk) begin

        if (we)
            data_array[index] <= wdata;

    end

    assign rdata = data_array[index];

endmodule
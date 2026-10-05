`timescale 1ns/1ps
module cache_tag_array #(
    parameter LINE_COUNT = 64,
    parameter TAG_WIDTH  = 22
)(
    input  logic                    clk,
    input  logic                    reset_n,

    input  logic                    we,
    input  logic [5:0]              index,
    input  logic [TAG_WIDTH-1:0]    tag_in,
    input  logic                    valid_in,
    input  logic                    dirty_in,

    output logic [TAG_WIDTH-1:0]    tag_out,
    output logic                    valid_out,
    output logic                    dirty_out
);

    logic [TAG_WIDTH-1:0] tag_array [0:LINE_COUNT-1];
    logic                 valid_array [0:LINE_COUNT-1];
    logic                 dirty_array [0:LINE_COUNT-1];

    integer i;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < LINE_COUNT; i = i + 1) begin
                tag_array[i]   <= '0;
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end
        else if (we) begin
            tag_array[index]   <= tag_in;
            valid_array[index] <= valid_in;
            dirty_array[index] <= dirty_in;
        end
    end

    assign tag_out   = tag_array[index];
    assign valid_out = valid_array[index];
    assign dirty_out = dirty_array[index];

endmodule
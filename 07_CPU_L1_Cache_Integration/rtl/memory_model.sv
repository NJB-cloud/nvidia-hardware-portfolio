`timescale 1ns/1ps

// ============================================================
// Project 6
// Simple 128-bit Line Memory Model
//
// Simulation-only memory model.
//
// One transaction transfers one complete 16-byte cache line.
// ============================================================

module memory_model #(
    parameter DEPTH = 256
)(
    input  logic         clk,
    input  logic         reset_n,

    input  logic         req_valid,
    output logic         req_ready,

    input  logic         req_write,
    input  logic [31:0]  req_addr,
    input  logic [127:0] req_wdata,

    output logic         rsp_valid,
    output logic [127:0] rsp_rdata
);

    logic [127:0] memory [0:DEPTH-1];

    logic         pending_read;
    logic [31:0]  pending_addr;

    integer i;


    // --------------------------------------------------------
    // Memory initialization
    //
    // Deterministic pattern makes waveform debugging easier.
    // --------------------------------------------------------

    initial begin

        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = {
                32'h10000000 + i,
                32'h20000000 + i,
                32'h30000000 + i,
                32'h40000000 + i
            };

    end


    // --------------------------------------------------------
    // Memory is always ready in this simple model.
    // --------------------------------------------------------

    assign req_ready = 1'b1;


    // --------------------------------------------------------
    // Request / response
    // --------------------------------------------------------

    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            pending_read <= 1'b0;

            pending_addr <= 32'b0;

            rsp_valid <= 1'b0;

            rsp_rdata <= 128'b0;

        end

        else begin

            rsp_valid <= 1'b0;


            if (pending_read) begin

                rsp_rdata <=
                    memory[pending_addr[11:4]];

                rsp_valid <= 1'b1;

                pending_read <= 1'b0;

            end


            if (req_valid && req_ready) begin

                if (req_write) begin

                    memory[req_addr[11:4]] <= req_wdata;

                end

                else begin

                    pending_addr <= req_addr;

                    pending_read <= 1'b1;

                end

            end

        end

    end

endmodule
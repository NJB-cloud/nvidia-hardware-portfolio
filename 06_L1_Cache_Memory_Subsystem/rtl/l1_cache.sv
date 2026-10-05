`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Data Cache
//
// Configuration:
//   Capacity      = 1 KiB
//   Line size     = 16 bytes
//   Lines         = 64
//   Mapping       = Direct-mapped
//   Address       = 32 bits
//
// Policy:
//   Write-back
//   Write-allocate
//
// Blocking cache.
// ============================================================

module l1_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_COUNT = 64,
    parameter LINE_WIDTH = 128
)(
    input  logic                     clk,
    input  logic                     reset_n,

    // --------------------------------------------------------
    // CPU-side interface
    // --------------------------------------------------------

    input  logic                     cpu_req_valid,
    output logic                     cpu_req_ready,

    input  logic [ADDR_WIDTH-1:0]     cpu_req_addr,
    input  logic                     cpu_req_write,
    input logic [DATA_WIDTH-1:0]     cpu_req_wdata,
    input logic [3:0]                cpu_req_be,

    output logic                     cpu_rsp_valid,
    output logic [DATA_WIDTH-1:0]    cpu_rsp_rdata,

    // --------------------------------------------------------
    // Memory-side interface
    // --------------------------------------------------------

    output logic                     mem_req_valid,
    input logic                      mem_req_ready,

    output logic                     mem_req_write,
    output logic [ADDR_WIDTH-1:0]    mem_req_addr,
    output logic [LINE_WIDTH-1:0]    mem_req_wdata,

    input logic                      mem_rsp_valid,
    input logic [LINE_WIDTH-1:0]     mem_rsp_rdata
);


    // ========================================================
    // Latched CPU request
    // ========================================================

    logic [ADDR_WIDTH-1:0] cpu_addr_q;
    logic                  cpu_write_q;
    logic [DATA_WIDTH-1:0] cpu_wdata_q;
    logic [3:0]            cpu_be_q;


    // ========================================================
    // Refill buffer
    // ========================================================

    logic [LINE_WIDTH-1:0] refill_data_q;
    logic                  refill_valid_q;


    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            refill_data_q  <= '0;
            refill_valid_q <= 1'b0;

        end

        else begin

            if (mem_rsp_valid) begin

                refill_data_q  <= mem_rsp_rdata;
                refill_valid_q <= 1'b1;

            end

            else begin

                refill_valid_q <= 1'b0;

            end

        end

    end


    // ========================================================
    // Address decomposition
    // ========================================================

    logic [21:0] request_tag;
    logic [5:0]  request_index;
    logic [3:0]  request_offset;


    assign request_tag =
        cpu_addr_q[31:10];

    assign request_index =
        cpu_addr_q[9:4];

    assign request_offset =
        cpu_addr_q[3:0];


    // ========================================================
    // Tag array
    // ========================================================

    logic [21:0] tag_out;

    logic tag_valid;
    logic tag_dirty;

    logic tag_write;

    logic [21:0] tag_in;
    logic valid_in;
    logic dirty_in;


    // ========================================================
    // Data array
    // ========================================================

    logic [LINE_WIDTH-1:0] data_out;
    logic [LINE_WIDTH-1:0] data_in;

    logic data_write;


    // ========================================================
    // Cache arrays
    // ========================================================

    cache_tag_array #(
        .LINE_COUNT(LINE_COUNT),
        .TAG_WIDTH(22)
    ) tag_array (

        .clk(clk),
        .reset_n(reset_n),

        .we(tag_write),
        .index(request_index),

        .tag_in(tag_in),
        .valid_in(valid_in),
        .dirty_in(dirty_in),

        .tag_out(tag_out),
        .valid_out(tag_valid),
        .dirty_out(tag_dirty)

    );


    cache_data_array #(
        .LINE_COUNT(LINE_COUNT),
        .LINE_WIDTH(LINE_WIDTH)
    ) data_array (

        .clk(clk),

        .we(data_write),
        .index(request_index),

        .wdata(data_in),
        .rdata(data_out)

    );


    // ========================================================
    // Cache hit
    // ========================================================

    logic cache_hit;


    assign cache_hit =
        tag_valid &&
        (tag_out == request_tag);


    // ========================================================
    // Controller
    // ========================================================

    logic update_enable;
    logic write_hit_enable;


    cache_controller controller (

        .clk(clk),
        .reset_n(reset_n),

        .cpu_req_valid(cpu_req_valid),

        .cache_hit(cache_hit),
        .victim_dirty(tag_dirty),

        .cpu_req_write(cpu_write_q),

        .mem_req_ready(mem_req_ready),
        .mem_rsp_valid(mem_rsp_valid),

        .cpu_req_ready(cpu_req_ready),
        .cpu_rsp_valid(cpu_rsp_valid),

        .tag_write(tag_write),
        .data_write(data_write),

        .mem_req_valid(mem_req_valid),
        .mem_req_write(mem_req_write),

        .update_enable(update_enable),

        .write_hit_enable(write_hit_enable)

    );


    // ========================================================
    // CPU request register
    // ========================================================

    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            cpu_addr_q  <= '0;
            cpu_write_q <= 1'b0;
            cpu_wdata_q <= '0;
            cpu_be_q    <= 4'b0;

        end

        else if (cpu_req_valid && cpu_req_ready) begin

            cpu_addr_q  <= cpu_req_addr;
            cpu_write_q <= cpu_req_write;
            cpu_wdata_q <= cpu_req_wdata;
            cpu_be_q    <= cpu_req_be;

        end

    end


    // ========================================================
    // Line address
    // ========================================================

    logic [ADDR_WIDTH-1:0] line_address;


    assign line_address =
        {cpu_addr_q[ADDR_WIDTH-1:4], 4'b0000};


    // ========================================================
    // Victim address
    // ========================================================

    logic [ADDR_WIDTH-1:0] victim_address;


    assign victim_address =
        {tag_out, request_index, 4'b0000};


    // ========================================================
    // Memory request address
    // ========================================================

    always @(*) begin

        if (mem_req_write)

            mem_req_addr = victim_address;

        else

            mem_req_addr = line_address;

    end


    // ========================================================
    // Memory write-back data
    // ========================================================

    assign mem_req_wdata =
        data_out;


    // ========================================================
    // Store-modified cache line
    // ========================================================

    logic [LINE_WIDTH-1:0] store_modified_data;


    always @(*) begin

        store_modified_data = data_out;


        case (request_offset[3:2])

            // ------------------------------------------------
            // Word 0
            // ------------------------------------------------

            2'b00: begin

                if (cpu_be_q[0])
                    store_modified_data[7:0] =
                        cpu_wdata_q[7:0];

                if (cpu_be_q[1])
                    store_modified_data[15:8] =
                        cpu_wdata_q[15:8];

                if (cpu_be_q[2])
                    store_modified_data[23:16] =
                        cpu_wdata_q[23:16];

                if (cpu_be_q[3])
                    store_modified_data[31:24] =
                        cpu_wdata_q[31:24];

            end


            // ------------------------------------------------
            // Word 1
            // ------------------------------------------------

            2'b01: begin

                if (cpu_be_q[0])
                    store_modified_data[39:32] =
                        cpu_wdata_q[7:0];

                if (cpu_be_q[1])
                    store_modified_data[47:40] =
                        cpu_wdata_q[15:8];

                if (cpu_be_q[2])
                    store_modified_data[55:48] =
                        cpu_wdata_q[23:16];

                if (cpu_be_q[3])
                    store_modified_data[63:56] =
                        cpu_wdata_q[31:24];

            end


            // ------------------------------------------------
            // Word 2
            // ------------------------------------------------

            2'b10: begin

                if (cpu_be_q[0])
                    store_modified_data[71:64] =
                        cpu_wdata_q[7:0];

                if (cpu_be_q[1])
                    store_modified_data[79:72] =
                        cpu_wdata_q[15:8];

                if (cpu_be_q[2])
                    store_modified_data[87:80] =
                        cpu_wdata_q[23:16];

                if (cpu_be_q[3])
                    store_modified_data[95:88] =
                        cpu_wdata_q[31:24];

            end


            // ------------------------------------------------
            // Word 3
            // ------------------------------------------------

            2'b11: begin

                if (cpu_be_q[0])
                    store_modified_data[103:96] =
                        cpu_wdata_q[7:0];

                if (cpu_be_q[1])
                    store_modified_data[111:104] =
                        cpu_wdata_q[15:8];

                if (cpu_be_q[2])
                    store_modified_data[119:112] =
                        cpu_wdata_q[23:16];

                if (cpu_be_q[3])
                    store_modified_data[127:120] =
                        cpu_wdata_q[31:24];

            end

        endcase

    end


    // ========================================================
    // Cache update data
    // ========================================================

    always @(*) begin

        tag_in   = request_tag;

        valid_in = 1'b1;

        dirty_in = 1'b0;

        data_in  = data_out;


        // ----------------------------------------------------
        // Refill
        // ----------------------------------------------------

        if (update_enable && refill_valid_q) begin

            tag_in   = request_tag;

            valid_in = 1'b1;

            data_in  = refill_data_q;

            dirty_in = cpu_write_q;

        end


        // ----------------------------------------------------
        // Write hit
        // ----------------------------------------------------

        if (write_hit_enable) begin

            tag_in   = tag_out;

            valid_in = tag_valid;

            dirty_in = 1'b1;

            data_in  = store_modified_data;

        end

    end


    // ========================================================
    // CPU response data
    // ========================================================

    always @(*) begin

        case (request_offset[3:2])

            2'b00:
                cpu_rsp_rdata = data_out[31:0];

            2'b01:
                cpu_rsp_rdata = data_out[63:32];

            2'b10:
                cpu_rsp_rdata = data_out[95:64];

            2'b11:
                cpu_rsp_rdata = data_out[127:96];

            default:
                cpu_rsp_rdata = 32'b0;

        endcase

    end


endmodule
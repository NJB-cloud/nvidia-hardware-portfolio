`timescale 1ns/1ps

// ============================================================
// Project 6
// L1 Cache Controller
//
// Blocking direct-mapped cache controller.
//
// States:
//   IDLE
//   TAG_CHECK
//   CHECK_DIRTY
//   WRITEBACK
//   REFILL_REQ
//   REFILL_WAIT
//   UPDATE
//   RESPOND
//
// Write-back + write-allocate
// ============================================================

module cache_controller (

    input  logic clk,
    input  logic reset_n,

    // CPU request
    input logic cpu_req_valid,

    // Cache lookup
    input logic cache_hit,
    input logic victim_dirty,

    // CPU operation
    input logic cpu_req_write,

    // Memory
    input logic mem_req_ready,
    input logic mem_rsp_valid,

    // CPU control
    output logic cpu_req_ready,
    output logic cpu_rsp_valid,

    // Cache-array control
    output logic tag_write,
    output logic data_write,

    // Memory control
    output logic mem_req_valid,
    output logic mem_req_write,

    // Refill/update control
    output logic update_enable,

    // Write-hit control
    output logic write_hit_enable

);

    typedef enum logic [3:0] {

        IDLE,
        TAG_CHECK,
        CHECK_DIRTY,
        WRITEBACK,
        REFILL_REQ,
        REFILL_WAIT,
        UPDATE,
        RESPOND

    } state_t;


    state_t state;
    state_t next_state;


    // ========================================================
    // State register
    // ========================================================

    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n)

            state <= IDLE;

        else

            state <= next_state;

    end


    // ========================================================
    // Next-state logic
    // ========================================================

    always_comb begin

        next_state = state;

        case (state)

            IDLE: begin

                if (cpu_req_valid)

                    next_state = TAG_CHECK;

            end


            TAG_CHECK: begin

                if (cache_hit)

                    next_state = RESPOND;

                else

                    next_state = CHECK_DIRTY;

            end


            CHECK_DIRTY: begin

                if (victim_dirty)

                    next_state = WRITEBACK;

                else

                    next_state = REFILL_REQ;

            end


            WRITEBACK: begin

                if (mem_req_ready)

                    next_state = REFILL_REQ;

            end


            REFILL_REQ: begin

                if (mem_req_ready)

                    next_state = REFILL_WAIT;

            end


            REFILL_WAIT: begin

                if (mem_rsp_valid)

                    next_state = UPDATE;

            end


            UPDATE: begin

                next_state = RESPOND;

            end


            RESPOND: begin

                next_state = IDLE;

            end


            default: begin

                next_state = IDLE;

            end

        endcase

    end


    // ========================================================
    // Output control
    // ========================================================

    always_comb begin

        cpu_req_ready = 1'b0;

        cpu_rsp_valid = 1'b0;

        tag_write = 1'b0;

        data_write = 1'b0;

        mem_req_valid = 1'b0;

        mem_req_write = 1'b0;

        update_enable = 1'b0;

        write_hit_enable = 1'b0;


        case (state)

            IDLE: begin

                cpu_req_ready = 1'b1;

            end


            TAG_CHECK: begin

                // Hit/miss decision occurs here.

            end


            CHECK_DIRTY: begin

                // Examine victim dirty bit.

            end


            WRITEBACK: begin

                mem_req_valid = 1'b1;

                mem_req_write = 1'b1;

            end


            REFILL_REQ: begin

                mem_req_valid = 1'b1;

                mem_req_write = 1'b0;

            end


            REFILL_WAIT: begin

                // Waiting for memory response.

            end


            UPDATE: begin

                tag_write = 1'b1;

                data_write = 1'b1;

                update_enable = 1'b1;

            end


            RESPOND: begin

                cpu_rsp_valid = 1'b1;

                // A write hit modifies the cache line.
                //
                // A read hit only returns data.

                if (cpu_req_write && cache_hit) begin

                    data_write = 1'b1;

                    tag_write = 1'b1;

                    write_hit_enable = 1'b1;

                end

            end


            default: begin

            end

        endcase

    end

endmodule
// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: EX/MEM Pipeline Register
//
// Purpose:
//   Transfers EX stage results into MEM stage.
//
// Supports:
//   - ALU result forwarding
//   - Store data forwarding
//   - Memory control propagation
//   - Register write propagation
//   - Valid-bit control
//   - Stall during cache transaction
// ============================================================


module ex_mem_reg (

    input logic clk,
    input logic rst_n,


    // --------------------------------------------------------
    // Pipeline control
    // --------------------------------------------------------

    input logic stall,
    input logic flush,


    // --------------------------------------------------------
    // EX stage inputs
    // --------------------------------------------------------

    input logic [31:0] ex_alu_result,
    input logic [31:0] ex_store_data,

    input logic [4:0] ex_rd,


    input logic ex_RegWrite,
    input logic ex_MemRead,
    input logic ex_MemWrite,
    input logic ex_MemToReg,

    input logic ex_valid,


    // --------------------------------------------------------
    // MEM stage outputs
    // --------------------------------------------------------

    output logic [31:0] mem_alu_result,
    output logic [31:0] mem_store_data,

    output logic [4:0] mem_rd,


    output logic mem_RegWrite,
    output logic mem_MemRead,
    output logic mem_MemWrite,
    output logic mem_MemToReg,

    output logic mem_valid

);



always_ff @(posedge clk or negedge rst_n) begin


    if (!rst_n) begin


        mem_alu_result <= 32'h0000_0000;
        mem_store_data <= 32'h0000_0000;

        mem_rd         <= 5'd0;


        mem_RegWrite   <= 1'b0;
        mem_MemRead    <= 1'b0;
        mem_MemWrite   <= 1'b0;
        mem_MemToReg   <= 1'b0;


        mem_valid      <= 1'b0;


    end



    else if (flush) begin


        mem_alu_result <= 32'h0000_0000;
        mem_store_data <= 32'h0000_0000;

        mem_rd         <= 5'd0;


        mem_RegWrite   <= 1'b0;
        mem_MemRead    <= 1'b0;
        mem_MemWrite   <= 1'b0;
        mem_MemToReg   <= 1'b0;


        mem_valid      <= 1'b0;


    end



    else if (stall) begin


        mem_alu_result <= mem_alu_result;
        mem_store_data <= mem_store_data;

        mem_rd         <= mem_rd;


        mem_RegWrite   <= mem_RegWrite;
        mem_MemRead    <= mem_MemRead;
        mem_MemWrite   <= mem_MemWrite;
        mem_MemToReg   <= mem_MemToReg;


        mem_valid      <= mem_valid;


    end



    else begin


        mem_alu_result <= ex_alu_result;

        mem_store_data <= ex_store_data;


        mem_rd         <= ex_rd;


        mem_RegWrite   <= ex_RegWrite;
        mem_MemRead    <= ex_MemRead;
        mem_MemWrite   <= ex_MemWrite;
        mem_MemToReg   <= ex_MemToReg;


        mem_valid      <= ex_valid;


    end


end


endmodule
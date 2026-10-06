// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: MEM/WB Pipeline Register
// ============================================================


module mem_wb_reg (

    input logic clk,
    input logic rst_n,


    input logic [31:0] mem_alu_result,
    input logic [31:0] mem_read_data,

    input logic [4:0] mem_rd,

    input logic mem_RegWrite,
    input logic mem_MemToReg,

    input logic mem_valid,


    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_read_data,

    output logic [4:0] wb_rd,

    output logic wb_RegWrite,
    output logic wb_MemToReg,

    output logic wb_valid

);



always_ff @(posedge clk or negedge rst_n) begin


    if (!rst_n) begin


        wb_alu_result <= 32'b0;
        wb_read_data  <= 32'b0;

        wb_rd         <= 5'b0;


        wb_RegWrite   <= 1'b0;
        wb_MemToReg   <= 1'b0;

        wb_valid      <= 1'b0;


    end


    else begin


        wb_alu_result <= mem_alu_result;
        wb_read_data  <= mem_read_data;


        wb_rd         <= mem_rd;


        wb_RegWrite   <= mem_RegWrite;
        wb_MemToReg   <= mem_MemToReg;


        wb_valid      <= mem_valid;


    end


end


endmodule
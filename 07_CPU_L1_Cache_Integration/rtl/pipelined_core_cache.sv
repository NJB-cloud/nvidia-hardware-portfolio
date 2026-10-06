// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: Pipelined RV32I Core with L1 Cache Interface
//
// Based on existing Project 4 pipeline.
// Added:
//   - CPU -> L1 cache request interface
//   - L1 cache response interface
//   - Blocking cache transaction control
// ============================================================

module pipelined_core #(
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256
)(
    input logic clk,
    input logic rst_n,


    // ========================================================
    // CPU <-> L1 CACHE INTERFACE
    // ========================================================

    // CPU -> Cache

    output logic        cache_req_valid,
    input  logic        cache_req_ready,

    output logic [31:0] cache_req_addr,
    output logic        cache_req_write,
    output logic [31:0] cache_req_wdata,
    output logic [3:0]  cache_req_be,


    // Cache -> CPU

    input  logic        cache_rsp_valid,
    input  logic [31:0] cache_rsp_rdata,


    // ========================================================
    // DEBUG OUTPUTS
    // ========================================================

    output logic [31:0] current_pc,
    output logic [31:0] instruction,

    output logic [31:0] ex_alu_result_debug,
    output logic [31:0] mem_alu_result_debug,
    output logic [31:0] wb_data_debug,

    output logic        stall_debug,
    output logic [1:0]  forward_a_debug,
    output logic [1:0]  forward_b_debug
);



    // ========================================================
    // IF STAGE
    // ========================================================

    logic [31:0] pc_plus4;
    logic [31:0] next_pc;

    logic [31:0] if_instruction;



    // ========================================================
    // IF / ID
    // ========================================================

    logic [31:0] id_pc;
    logic [31:0] id_pc_plus4;
    logic [31:0] id_instruction;
    logic        id_valid;

    logic if_id_stall;
    logic if_id_flush;



    // ========================================================
    // ID STAGE
    // ========================================================

    logic [6:0] id_opcode;

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] id_rd;

    logic [2:0] id_funct3;
    logic       id_funct7_bit5;


    logic [31:0] id_register_data1;
    logic [31:0] id_register_data2;
    logic [31:0] id_immediate;


    logic id_RegWrite;
    logic id_ALUSrc;
    logic id_MemRead;
    logic id_MemWrite;
    logic id_MemToReg;
    logic id_Branch;
    logic [1:0] id_ALUOp;


    logic id_uses_rs1;
    logic id_uses_rs2;



    // ========================================================
    // ID / EX
    // ========================================================

    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus4;

    logic [31:0] ex_register_data1;
    logic [31:0] ex_register_data2;

    logic [31:0] ex_immediate;


    logic [4:0] ex_rs1;
    logic [4:0] ex_rs2;
    logic [4:0] ex_rd;


    logic [2:0] ex_funct3;
    logic       ex_funct7_bit5;


    logic ex_RegWrite;
    logic ex_ALUSrc;
    logic ex_MemRead;
    logic ex_MemWrite;
    logic ex_MemToReg;
    logic ex_Branch;

    logic [1:0] ex_ALUOp;


    logic ex_valid;



    // ========================================================
    // FORWARDING
    // ========================================================

    logic [1:0] forward_a;
    logic [1:0] forward_b;



    // ========================================================
    // EX STAGE
    // ========================================================

    logic [31:0] ex_alu_result;
    logic        ex_alu_zero;

    logic [31:0] ex_store_data;



    // ========================================================
    // EX / MEM
    // ========================================================

    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;

    logic [4:0] mem_rd;


    logic mem_RegWrite;
    logic mem_MemRead;
    logic mem_MemWrite;
    logic mem_MemToReg;

    logic mem_valid;



    // ========================================================
    // MEM / WB
    // ========================================================

    logic [31:0] wb_alu_result;
    logic [31:0] wb_read_data;
    logic [31:0] mem_read_data;

    logic [4:0] wb_rd;


    logic wb_RegWrite;
    logic wb_MemToReg;

    logic wb_valid;


    logic [31:0] wb_data;



    // ========================================================
    // HAZARD CONTROL
    // ========================================================

    logic pc_write;
    logic id_ex_flush;



    // ========================================================
    // BRANCH
    // ========================================================

    logic branch_taken;
    logic [31:0] branch_target;



    // ========================================================
    // CACHE CONTROL
    // ========================================================

    logic cache_stall;

    logic cache_transaction_active;

    logic cache_transaction_done;

    logic cache_mem_operation;



    logic cache_request_fire;



    // ========================================================
    // CACHE REQUEST REGISTERED STATE
    // ========================================================

    logic cache_waiting;



    // ========================================================
    // CACHE OPERATION DETECTION
    // ========================================================

    assign cache_mem_operation =
        mem_valid &&
        (mem_MemRead || mem_MemWrite);



// ========================================================
// INSTRUCTION FIELD EXTRACTION
// ========================================================

assign id_opcode      = id_instruction[6:0];
assign id_rd          = id_instruction[11:7];
assign id_funct3      = id_instruction[14:12];
assign id_rs1         = id_instruction[19:15];
assign id_rs2         = id_instruction[24:20];
assign id_funct7_bit5 = id_instruction[30];



// ========================================================
// SOURCE REGISTER USAGE
// ========================================================

always_comb begin

    id_uses_rs1 = 1'b0;
    id_uses_rs2 = 1'b0;


    case (id_opcode)

        // R-Type
        7'b0110011: begin

            id_uses_rs1 = 1'b1;
            id_uses_rs2 = 1'b1;

        end


        // LW
        7'b0000011: begin

            id_uses_rs1 = 1'b1;
            id_uses_rs2 = 1'b0;

        end


        // SW
        7'b0100011: begin

            id_uses_rs1 = 1'b1;
            id_uses_rs2 = 1'b1;

        end


        // BEQ
        7'b1100011: begin

            id_uses_rs1 = 1'b1;
            id_uses_rs2 = 1'b1;

        end


        default: begin

            id_uses_rs1 = 1'b0;
            id_uses_rs2 = 1'b0;

        end

    endcase

end



// ========================================================
// PC LOGIC
// ========================================================

assign pc_plus4 = current_pc + 32'd4;



assign branch_target =
    ex_pc + ex_immediate;



assign branch_taken =
    ex_valid &&
    ex_Branch &&
    ex_alu_zero;



always_comb begin

    if (branch_taken)

        next_pc = branch_target;

    else if (!pc_write || cache_stall)

        next_pc = current_pc;

    else

        next_pc = pc_plus4;

end



// ========================================================
// PROGRAM COUNTER
// ========================================================

pc u_pc (

    .clk        (clk),
    .rst_n      (rst_n),

    .next_pc    (next_pc),

    .current_pc (current_pc)

);



// ========================================================
// INSTRUCTION MEMORY
// ========================================================

instruction_memory #(
    .DEPTH(IMEM_DEPTH)

) u_instruction_memory (

    .address    (current_pc),

    .instruction(if_instruction)

);



assign instruction = if_instruction;



// ========================================================
// IF / ID PIPELINE REGISTER
// ========================================================

assign if_id_stall =
    !pc_write ||
    cache_stall;


assign if_id_flush =
    branch_taken;



if_id_reg u_if_id (

    .clk           (clk),
    .rst_n         (rst_n),


    .stall         (if_id_stall),
    .flush         (if_id_flush),


    .if_pc         (current_pc),
    .if_pc_plus4   (pc_plus4),
    .if_instruction(if_instruction),


    .id_pc         (id_pc),
    .id_pc_plus4   (id_pc_plus4),
    .id_instruction(id_instruction),
    .id_valid      (id_valid)

);



// ========================================================
// CONTROL UNIT
// ========================================================

control_unit u_control (

    .opcode   (id_opcode),


    .RegWrite (id_RegWrite),
    .ALUSrc   (id_ALUSrc),

    .MemRead  (id_MemRead),
    .MemWrite (id_MemWrite),

    .MemToReg (id_MemToReg),

    .Branch   (id_Branch),

    .ALUOp    (id_ALUOp)

);



// ========================================================
// REGISTER FILE
// ========================================================

register_file u_register_file (

    .clk        (clk),
    .rst_n      (rst_n),


    .rs1        (id_rs1),
    .rs2        (id_rs2),


    .read_data1 (id_register_data1),
    .read_data2 (id_register_data2),


    .rd         (wb_rd),

    .write_data (wb_data),

    .reg_write  (wb_RegWrite && wb_valid)

);



// ========================================================
// IMMEDIATE GENERATOR
// ========================================================

immediate_generator u_immediate (

    .instruction(id_instruction),

    .immediate  (id_immediate)

);



// ========================================================
// HAZARD UNIT
// ========================================================

hazard_unit u_hazard (

    .id_ex_MemRead
        (ex_MemRead && ex_valid),

    .id_ex_rd
        (ex_rd),


    .if_id_rs1
        (id_rs1),

    .if_id_rs2
        (id_rs2),


    .if_id_uses_rs1
        (id_uses_rs1),

    .if_id_uses_rs2
        (id_uses_rs2),


    .pc_write
        (pc_write),

    .if_id_write
        (),

    .id_ex_flush
        (id_ex_flush)

);


// ========================================================
// ID / EX PIPELINE REGISTER
// ========================================================

id_ex_reg u_id_ex (

    .clk
    (
        clk
    ),

    .rst_n
    (
        rst_n
    ),


    // Pipeline control

    .stall
    (
        1'b0
    ),

    .flush
    (
        id_ex_flush || branch_taken
    ),



    // ID stage inputs

    .id_pc
    (
        id_pc
    ),

    .id_pc_plus4
    (
        id_pc_plus4
    ),


    .id_register_data1
    (
        id_register_data1
    ),

    .id_register_data2
    (
        id_register_data2
    ),


    .id_immediate
    (
        id_immediate
    ),



    // Register identifiers

    .id_rs1
    (
        id_rs1
    ),

    .id_rs2
    (
        id_rs2
    ),

    .id_rd
    (
        id_rd
    ),



    // Instruction information

    .id_funct3
    (
        id_funct3
    ),

    .id_funct7_bit5
    (
        id_funct7_bit5
    ),



    // Control signals

    .id_RegWrite
    (
        id_RegWrite
    ),

    .id_ALUSrc
    (
        id_ALUSrc
    ),

    .id_MemRead
    (
        id_MemRead
    ),

    .id_MemWrite
    (
        id_MemWrite
    ),

    .id_MemToReg
    (
        id_MemToReg
    ),

    .id_Branch
    (
        id_Branch
    ),

   .id_ALUOp
    (id_ALUOp),

.id_valid
    (id_valid),



    // Project 7 FIX
    // propagate IF/ID validity





    // EX outputs

    .ex_pc
    (
        ex_pc
    ),

    .ex_pc_plus4
    (
        ex_pc_plus4
    ),


    .ex_register_data1
    (
        ex_register_data1
    ),

    .ex_register_data2
    (
        ex_register_data2
    ),


    .ex_immediate
    (
        ex_immediate
    ),



    .ex_rs1
    (
        ex_rs1
    ),

    .ex_rs2
    (
        ex_rs2
    ),

    .ex_rd
    (
        ex_rd
    ),



    .ex_funct3
    (
        ex_funct3
    ),

    .ex_funct7_bit5
    (
        ex_funct7_bit5
    ),



    .ex_RegWrite
    (
        ex_RegWrite
    ),

    .ex_ALUSrc
    (
        ex_ALUSrc
    ),

    .ex_MemRead
    (
        ex_MemRead
    ),

    .ex_MemWrite
    (
        ex_MemWrite
    ),

    .ex_MemToReg
    (
        ex_MemToReg
    ),

    .ex_Branch
    (
        ex_Branch
    ),

    .ex_ALUOp
    (
        ex_ALUOp
    ),


    .ex_valid
    (
        ex_valid
    )

);


// ========================================================
// FORWARDING UNIT
// ========================================================

forwarding_unit u_forwarding (

    .id_ex_rs1
        (ex_rs1),

    .id_ex_rs2
        (ex_rs2),


    .ex_mem_rd
        (mem_rd),

    .ex_mem_RegWrite
        (mem_RegWrite && mem_valid),


    .mem_wb_rd
        (wb_rd),

    .mem_wb_RegWrite
        (wb_RegWrite && wb_valid),


    .forward_a
        (forward_a),

    .forward_b
        (forward_b)

);



// ========================================================
// EX STAGE
// ========================================================

ex_stage u_ex_stage (

    .ex_register_data1
        (ex_register_data1),

    .ex_register_data2
        (ex_register_data2),


    .ex_immediate
        (ex_immediate),


    .ex_funct3
        (ex_funct3),

    .ex_funct7_bit5
        (ex_funct7_bit5),


    .ex_ALUSrc
        (ex_ALUSrc),

    .ex_ALUOp
        (ex_ALUOp),


    .forward_a
        (forward_a),

    .forward_b
        (forward_b),


    .ex_mem_forward_value
        (mem_alu_result),

    .mem_wb_forward_value
        (wb_data),


    .alu_result
        (ex_alu_result),

    .alu_zero
        (ex_alu_zero),


    .store_data
        (ex_store_data)

);



// ========================================================
// EX / MEM PIPELINE REGISTER
// ========================================================

ex_mem_reg u_ex_mem (

    .clk
        (clk),

    .rst_n
        (rst_n),


    .flush
        (1'b0),

    .stall
        (cache_stall),



    .ex_alu_result
        (ex_alu_result),

    .ex_store_data
        (ex_store_data),


    .ex_rd
        (ex_rd),



    .ex_RegWrite
        (ex_RegWrite),

    .ex_MemRead
        (ex_MemRead),

    .ex_MemWrite
        (ex_MemWrite),

    .ex_MemToReg
        (ex_MemToReg),


    .ex_valid
        (ex_valid),



    .mem_alu_result
        (mem_alu_result),

    .mem_store_data
        (mem_store_data),


    .mem_rd
        (mem_rd),


    .mem_RegWrite
        (mem_RegWrite),

    .mem_MemRead
        (mem_MemRead),

    .mem_MemWrite
        (mem_MemWrite),

    .mem_MemToReg
        (mem_MemToReg),


    .mem_valid
(
    mem_valid
);



// DEBUG ONLY
always_ff @(posedge clk) begin

    if (mem_valid && (mem_MemRead || mem_MemWrite)) begin

        $display(
        "MEM_STAGE T=%0t READ=%b WRITE=%b ADDR=%h DATA=%h VALID=%b",
        $time,
        mem_MemRead,
        mem_MemWrite,
        mem_alu_result,
        mem_store_data,
        mem_valid
        );

    end

end



// ========================================================
// CACHE TRANSACTION CONTROL
// ========================================================

assign cache_req_valid =
        cache_mem_operation &&
        !cache_transaction_active &&
        !cache_transaction_done;

assign cache_request_fire =
        cache_req_valid &&
        cache_req_ready;



always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        cache_transaction_active <= 1'b0;

    end

    else begin

        if (cache_request_fire)

            cache_transaction_active <= 1'b1;


        else if (cache_rsp_valid)

            cache_transaction_active <= 1'b0;

    end

end



assign cache_transaction_done =
        cache_rsp_valid;



assign cache_stall =
        cache_transaction_active;


// ========================================================
// CACHE REQUEST OUTPUTS
// ========================================================

assign cache_req_addr =
        mem_alu_result;


assign cache_req_write =
        mem_MemWrite;


assign cache_req_wdata =
        mem_store_data;


assign cache_req_be =
        4'b1111;




// ========================================================
// MEMORY READ DATA FROM CACHE RESPONSE
// ========================================================

always_comb begin

    if (
        mem_MemRead &&
        mem_valid
)

        mem_read_data = cache_rsp_rdata;

    else

        mem_read_data = 32'h0000_0000;

end



// ========================================================
// MEM / WB PIPELINE REGISTER
// ========================================================

mem_wb_reg u_mem_wb (

    .clk
        (clk),

    .rst_n
        (rst_n),




    .mem_alu_result
        (mem_alu_result),

    .mem_read_data
        (mem_read_data),


    .mem_rd
        (mem_rd),


    .mem_RegWrite
        (mem_RegWrite),

    .mem_MemToReg
        (mem_MemToReg),


    .mem_valid
        (mem_valid),



    .wb_alu_result
        (wb_alu_result),

    .wb_read_data
        (wb_read_data),


    .wb_rd
        (wb_rd),


    .wb_RegWrite
        (wb_RegWrite),

    .wb_MemToReg
        (wb_MemToReg),


    .wb_valid
        (wb_valid)

);



// ========================================================
// WRITE BACK
// ========================================================

always_comb begin

    if (wb_MemToReg)

        wb_data = wb_read_data;

    else

        wb_data = wb_alu_result;

end



// ========================================================
// DEBUG OUTPUTS
// ========================================================

assign ex_alu_result_debug =
        ex_alu_result;


assign mem_alu_result_debug =
        mem_alu_result;


assign wb_data_debug =
        wb_data;


assign stall_debug =
        !pc_write ||
        cache_stall;


assign forward_a_debug =
        forward_a;


assign forward_b_debug =
        forward_b;



endmodule
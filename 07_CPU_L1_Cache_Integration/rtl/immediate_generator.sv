// ============================================================
// Project 7: CPU + L1 Cache Integration
// Module: Immediate Generator
//
// Supports:
//   I-type : ADDI, LW
//   S-type : SW
//   B-type : BEQ
// ============================================================

module immediate_generator (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    logic [6:0] opcode;

    assign opcode = instruction[6:0];


    always_comb begin

        case (opcode)


            // ------------------------------------------------
            // I-Type
            //
            // ADDI
            // LW
            //
            // imm[11:0] = instruction[31:20]
            // ------------------------------------------------

            7'b0010011,
            7'b0000011: begin

                immediate =
                    {{20{instruction[31]}},
                     instruction[31:20]};

            end



            // ------------------------------------------------
            // S-Type
            //
            // SW
            //
            // imm[11:5] = instruction[31:25]
            // imm[4:0]  = instruction[11:7]
            // ------------------------------------------------

            7'b0100011: begin

                immediate =
                    {{20{instruction[31]}},
                     instruction[31:25],
                     instruction[11:7]};

            end



            // ------------------------------------------------
            // B-Type
            //
            // BEQ
            //
            // imm =
            // {12,10:5,4:1,11,0}
            // ------------------------------------------------

            7'b1100011: begin

                immediate =
                    {{19{instruction[31]}},
                     instruction[31],
                     instruction[7],
                     instruction[30:25],
                     instruction[11:8],
                     1'b0};

            end



            default: begin

                immediate = 32'h0000_0000;

            end


        endcase

    end


endmodule
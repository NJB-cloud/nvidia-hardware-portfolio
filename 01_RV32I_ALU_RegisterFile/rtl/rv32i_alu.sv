module rv32i_alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_sel,

    output logic [31:0] result,
    output logic        zero,
    output logic        carry
);

    logic [32:0] temp;

    always_comb begin

        result = 32'b0;
        carry  = 1'b0;

        case (alu_sel)

            4'b0000: begin       // ADD
                temp   = {1'b0,a} + {1'b0,b};
                result = temp[31:0];
                carry  = temp[32];
            end

            4'b0001: begin       // SUB
                temp   = {1'b0,a} - {1'b0,b};
                result = temp[31:0];
                carry  = temp[32];
            end

            4'b0010: begin       // AND
                result = a & b;
            end

            4'b0011: begin       // OR
                result = a | b;
            end

            4'b0100: begin       // XOR
                result = a ^ b;
            end

            4'b0101: begin       // Shift Left Logical
                result = a << b[4:0];
            end

            4'b0110: begin       // Shift Right Logical
                result = a >> b[4:0];
            end

            4'b0111: begin       // Set Less Than Signed
                result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            end

            default: begin
                result = 32'b0;
            end

        endcase
    end


    assign zero = (result == 32'b0);

endmodule
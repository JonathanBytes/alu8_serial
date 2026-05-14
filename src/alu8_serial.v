`default_nettype none

module alu8_serial (
    input  wire       CLK,
    input  wire       RST_n,      // Reset activo en bajo
    input  wire       Bit_in,     // Entrada de bit serial
    input  wire       Carry_in,   // Entrada de acarreo
    input  wire [2:0] op,         // Operación a realizar (3 bits para hasta 8 operaciones)
    output reg  [7:0] Data_out,   // Salida de datos de 8 bits
    output reg        Carry_out,  // Señal de acarreo/prestado
    output reg        Zero,       // Señal de resultado cero
    output reg        Negative,   // Señal de resultado negativo
    output reg        Overflow,   // Señal de desbordamiento
    output reg        Done        // Señal de finalización de la operación
);

    reg [7:0] A;            // Operand A (loaded LSB-first into bit positions)
    reg [7:0] B;            // Operand B (loaded LSB-first into bit positions)
    reg [4:0] bit_cnt;      // Counter: 0-15 for 16 bits received (needs 5 bits!)
    reg [2:0] op_reg;       // Latch operation on first bit
    reg       carry_in_reg; // Latch carry_in on first bit

    // Compute A and B with the current input bit factored in
    wire [7:0] A_next = (bit_cnt < 5'd8) ? {Bit_in, A[7:1]} : A;
    wire [7:0] B_next = (bit_cnt >= 5'd8 && bit_cnt < 5'd16) ? {Bit_in, B[7:1]} : B;

    reg [8:0] alu_result;
    reg alu_overflow;

    // Combinational ALU logic using the "next" values
    always @(*) begin
        case (op_reg)
            3'b000: begin // ADD
                alu_result = {1'b0, A_next} + {1'b0, B_next} + carry_in_reg;
                alu_overflow = (A_next[7] == B_next[7]) && (alu_result[7] != A_next[7]);
            end
            3'b001: begin // SUB
                alu_result = {1'b0, A_next} - {1'b0, B_next} - carry_in_reg;
                alu_overflow = (A_next[7] != B_next[7]) && (alu_result[7] != A_next[7]);
            end
            3'b010: begin // AND
                alu_result = {1'b0, A_next & B_next};
                alu_overflow = 1'b0;
            end
            3'b011: begin // OR
                alu_result = {1'b0, A_next | B_next};
                alu_overflow = 1'b0;
            end
            3'b100: begin // XOR
                alu_result = {1'b0, A_next ^ B_next};
                alu_overflow = 1'b0;
            end
            3'b101: begin // NOT A
                alu_result = {1'b0, ~A_next};
                alu_overflow = 1'b0;
            end
            3'b110: begin // SHL A (left shift, MSB out to carry)
                alu_result = {A_next[7], A_next[6:0], 1'b0};
                alu_overflow = 1'b0;
            end
            3'b111: begin // SHR A (right shift, LSB out to carry)
                alu_result = {A_next[0], 1'b0, A_next[7:1]};
                alu_overflow = 1'b0;
            end
            default: begin
                alu_result = 9'b0;
                alu_overflow = 1'b0;
            end
        endcase
    end

    // Sequential logic: load bits, latch operation, compute result when all 16 bits received
    always @(posedge CLK or negedge RST_n) begin
        if (!RST_n) begin
            A               <= 8'b0;
            B               <= 8'b0;
            op_reg          <= 3'b0;
            carry_in_reg    <= 1'b0;
            bit_cnt         <= 5'b0;
            Data_out        <= 8'b0;
            Carry_out       <= 1'b0;
            Zero            <= 1'b0;
            Negative        <= 1'b0;
            Overflow        <= 1'b0;
            Done            <= 1'b0;
        end else if (!Done) begin
            // Latch operation code and carry_in once on first bit
            if (bit_cnt == 5'b0) begin
                op_reg <= op;
                carry_in_reg <= Carry_in;
            end

            // Load bits 0-7 into A (LSB-first using right-shift pattern)
            if (bit_cnt < 5'd8) begin
                A <= {Bit_in, A[7:1]};
                bit_cnt <= bit_cnt + 5'd1;
            end
            // Load bits 8-15 into B (LSB-first using right-shift pattern)
            else if (bit_cnt < 5'd16) begin
                B <= {Bit_in, B[7:1]};
                bit_cnt <= bit_cnt + 5'd1;

                // When we're about to shift the 16th bit (bit_cnt == 15, this is the last shift)
                // Compute and latch result DURING this clock cycle using the about-to-be-shifted value
                if (bit_cnt == 5'd15) begin
                    Data_out  <= alu_result[7:0];
                    Carry_out <= alu_result[8];
                    Zero      <= (alu_result[7:0] == 8'b0);
                    Negative  <= alu_result[7];
                    Overflow  <= alu_overflow;
                    Done      <= 1'b1;
                end
            end
        end
    end

endmodule

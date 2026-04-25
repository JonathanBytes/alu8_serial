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

    output reg Done  // Señal de finalización de la operación
);
endmodule

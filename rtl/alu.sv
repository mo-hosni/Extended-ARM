module alu(input logic [31:0] a, b,
input logic [1:0] ALUControl,
output logic [31:0] Result,
output logic [3:0] Flags,
input logic [31:0] address_for_alu,
/*EDITED*/
input logic BranchE,
output logic Correct_addr_prediction,
input logic fetch_predicted_addr_E);
//
logic neg, zero, carry, overflow;
logic [31:0] condinvb;
logic [32:0] sum;
/*EDITED*/
logic [31:0] a_edited;
//assign correct_address = address_for_alu;
mux2 #(32) a_edited_mux (a, address_for_alu, BranchE & fetch_predicted_addr_E, a_edited);
assign Correct_addr_prediction = (sum[31:0] + 32'd8 == a) & BranchE;
//
assign condinvb = ALUControl[0] ? ~b : b;
assign sum = a_edited + condinvb + ALUControl[0]; //edited
always_comb
    casex (ALUControl[1:0])
        2'b0?: Result = sum;
        2'b10: Result = a & b;
        2'b11: Result = a | b;
    endcase
assign neg = Result[31];
assign zero = (Result == 32'b0);
assign carry = (ALUControl[1] == 1'b0) & sum[32];
assign overflow = (ALUControl[1] == 1'b0) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
assign Flags = {neg, zero, carry, overflow};
endmodule

module adder #(parameter WIDTH=8)
(input logic [WIDTH-1:0] a, b,
output logic [WIDTH-1:0] y);
assign y = a + b;
endmodule
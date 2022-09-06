module datapath(
    input logic clk, reset,
    input logic [1:0] RegSrcD, ImmSrcD,
    input logic ALUSrcE, BranchTakenE,
    input logic [1:0] ALUControlE,
    input logic MemtoRegW, PCSrcW, RegWriteW,
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    output logic [31:0] InstrD,
    output logic [31:0] ALUOutM, WriteDataM,
    input logic [31:0] ReadDataM,
    output logic [3:0] ALUFlagsE,
    // hazard logic
    output logic Match_1E_M, Match_1E_W, Match_2E_M, Match_2E_W, Match_12D_E,
    input logic [1:0] ForwardAE, ForwardBE,
    input logic StallF, StallD, FlushD,
    /*EDITED*/ 
    input logic  BranchD, BranchE,
    output logic Correct_addr_prediction,
    input logic BranchTakenE_for_predictor, 
    output logic prediction_E,
    input logic Branched_wrong);
//
logic [31:0] PCPlus4F, PCnext1F, PCnextF;
logic [31:0] ExtImmD, rd1D, rd2D, PCPlus8D;
logic [31:0] rd1E, rd2E, ExtImmE, SrcAE, SrcBE, WriteDataE, ALUResultE;
logic [31:0] ReadDataW, ALUOutW, ResultW;
logic [3:0] RA1D, RA2D, RA1E, RA2E, WA3E, WA3M, WA3W;
logic Match_1D_E, Match_2D_E;
// Fetch stage
//ADDED LOGIC
logic hit, prediction, prediction_D, prediction_D2;
logic [31:0] b_address;
//mux2 #(32) pcnextmux(PCPlus4F, ResultW, 1'b0/*PCSrcW*/, PCnext1F);
logic [31:0] PCPlus4F_or_predict_address1, PCPlus4F_or_predict_address2, address_for_alu;
logic fetch_predicted_addr_F, fetch_predicted_addr_D, fetch_predicted_addr_D2, fetch_predicted_addr_E;
assign fetch_predicted_addr_F = hit & prediction;
//
flopenr #(32) address_for_alu_ff (clk, reset, fetch_predicted_addr_F, PCPlus4F, address_for_alu);
mux2 #(32) pcnextmux1(PCPlus4F, b_address, fetch_predicted_addr_F, PCPlus4F_or_predict_address1);
mux2 #(32) pcnextmux2(PCPlus4F_or_predict_address1, address_for_alu, Branched_wrong, PCPlus4F_or_predict_address2);
//mux2 #(32) pcnextmux2(PCPlus4F_or_predict_address, ResultW, PCSrcW, PCnext1F);
mux2 #(32) pcnextmux3(PCPlus4F_or_predict_address2, ALUResultE, BranchTakenE, PCnext1F);
//
flopr #(1) addr_D_reg1 (clk, reset, fetch_predicted_addr_F, fetch_predicted_addr_D);
mux2 #(1) addr_buffer (fetch_predicted_addr_D, fetch_predicted_addr_D, 1'b0, fetch_predicted_addr_D2);
flopr #(1) addr_E_reg1 (clk, reset, fetch_predicted_addr_D2, fetch_predicted_addr_E);
//
mux2 #(32) branchmux(PCnext1F, ALUResultE, BranchTakenE, PCnextF);
flopenr #(32) pcreg(clk, reset, ~StallF, PCnextF, PCF);
adder #(32) pcadd(PCF, 32'h4, PCPlus4F);
// Decode Stage
assign PCPlus8D = PCPlus4F; // skip register
flopenrc #(32) instrreg(clk, reset, ~StallD, FlushD, InstrF, InstrD);
mux2 #(4) ra1mux(InstrD[19:16], 4'b1111, RegSrcD[0], RA1D);
mux2 #(4) ra2mux(InstrD[3:0], InstrD[15:12], RegSrcD[1], RA2D);
regfile rf(clk, RegWriteW, RA1D, RA2D, WA3W, ResultW, PCPlus8D, rd1D, rd2D);
extend ext(InstrD[23:0], ImmSrcD, ExtImmD);
//
// Execute Stage
flopr #(32) rd1reg(clk, reset, rd1D, rd1E);
flopr #(32) rd2reg(clk, reset, rd2D, rd2E);
flopr #(32) immreg(clk, reset, ExtImmD, ExtImmE);
flopr #(4) wa3ereg(clk, reset, InstrD[15:12], WA3E);
flopr #(4) ra1reg(clk, reset, RA1D, RA1E);
flopr #(4) ra2reg(clk, reset, RA2D, RA2E);
mux3 #(32) byp1mux(rd1E, ResultW, ALUOutM, ForwardAE, SrcAE);
mux3 #(32) byp2mux(rd2E, ResultW, ALUOutM, ForwardBE, WriteDataE);
mux2 #(32) srcbmux(WriteDataE, ExtImmE, ALUSrcE, SrcBE);
//EDITED logic
//alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ALUFlagsE);
alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ALUFlagsE, address_for_alu, BranchE, Correct_addr_prediction, fetch_predicted_addr_E);
// Memory Stage
flopr #(32) aluresreg(clk, reset, ALUResultE, ALUOutM);
flopr #(32) wdreg(clk, reset, WriteDataE, WriteDataM);
flopr #(4) wa3mreg(clk, reset, WA3E, WA3M);
// Writeback Stage
flopr #(32) aluoutreg(clk, reset, ALUOutM, ALUOutW);
flopr #(32) rdreg(clk, reset, ReadDataM, ReadDataW);
flopr #(4) wa3wreg(clk, reset, WA3M, WA3W);
mux2 #(32) resmux(ALUOutW, ReadDataW, MemtoRegW, ResultW);
// hazard comparison
eqcmp #(4) m0(WA3M, RA1E, Match_1E_M);
eqcmp #(4) m1(WA3W, RA1E, Match_1E_W);
eqcmp #(4) m2(WA3M, RA2E, Match_2E_M);
eqcmp #(4) m3(WA3W, RA2E, Match_2E_W);
eqcmp #(4) m4a(WA3E, RA1D, Match_1D_E);
eqcmp #(4) m4b(WA3E, RA2D, Match_2D_E);
assign Match_12D_E = Match_1D_E | Match_2D_E;

//added logic
BTB branch_btb (clk, reset, PCF, BranchE, ALUResultE, b_address, hit);
Global_predictor branch_predictor (clk, reset, hit, PCF [5:2], BranchTakenE_for_predictor, prediction);
//
flopr #(1) predect_D_reg1 (clk, reset, prediction, prediction_D);
mux2 #(1) predect_D_buff (prediction_D, prediction_D, 1'b0, prediction_D2);
flopr #(1) predect_D_reg2 (clk, reset, prediction_D2, prediction_E);
//
endmodule

module flopenr #(parameter WIDTH = 8)
(input logic clk, reset, en,
input logic [WIDTH-1:0] d,
output logic [WIDTH-1:0] q);
always_ff @(posedge clk, posedge reset)
if (reset) q <= 0;
else if (en) q <= d;
endmodule
module flopr #(parameter WIDTH = 8)
(input logic clk, reset,
input logic [WIDTH-1:0] d,
output logic [WIDTH-1:0] q);
always_ff @(posedge clk, posedge reset)
if (reset) q <= 0;
else q <= d;
endmodule
module flopenrc #(parameter WIDTH = 8)
(input logic clk, reset, en, clear,
input logic [WIDTH-1:0] d,
output logic [WIDTH-1:0] q);
always_ff @(posedge clk, posedge reset)
if (reset) q <= 0;
else if (en)
if (clear) q <= 0;
else q <= d;
endmodule
module floprc #(parameter WIDTH = 8)
(input logic clk, reset, clear,
input logic [WIDTH-1:0] d,
output logic [WIDTH-1:0] q);
always_ff @(posedge clk, posedge reset)
if (reset) q <= 0;
else
if (clear) q <= 0;
else q <= d;
endmodule
module mux2 #(parameter WIDTH = 8)
(input logic [WIDTH-1:0] d0, d1,
input logic s,
output logic [WIDTH-1:0] y);
assign y = s ? d1 : d0;
endmodule
module mux3 #(parameter WIDTH = 8)
(input logic [WIDTH-1:0] d0, d1, d2,
input logic [1:0] s,
output logic [WIDTH-1:0] y);
assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule
module eqcmp #(parameter WIDTH = 8)
(input logic [WIDTH-1:0] a, b,
output logic y);
assign y = (a == b);
endmodule
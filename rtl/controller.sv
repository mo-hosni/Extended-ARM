module controller(
    input logic clk, reset,
    input logic [31:12] InstrD,
    input logic [3:0] ALUFlagsE,
    output logic [1:0] RegSrcD, ImmSrcD,
    output logic ALUSrcE, BranchTakenE,
    output logic [1:0] ALUControlE,
    output logic MemWriteM,
    output logic MemtoRegW, PCSrcW, RegWriteW,
    // hazard interface
    output logic RegWriteM, MemtoRegE,
    output logic PCWrPendingF,
    input logic FlushE,
    output logic BranchD, BranchE,
    /*EDITED*/
    input logic Correct_addr_prediction,
    output logic BranchTakenE_for_predictor);
//
logic [9:0] controlsD;
logic CondExE, ALUOpD;
logic [1:0] ALUControlD;
logic ALUSrcD;
logic MemtoRegD, MemtoRegM;
logic RegWriteD, RegWriteE, RegWriteGatedE;
logic MemWriteD, MemWriteE, MemWriteGatedE;
//logic BranchD, BranchE;
logic [1:0] FlagWriteD, FlagWriteE;
logic PCSrcD, PCSrcE, PCSrcM;
logic [3:0] FlagsE, FlagsNextE, CondE;
// Decode stage
always_comb
    casex(InstrD[27:26])
        2'b00: if (InstrD[25]) controlsD = 10'b0000101001; // DP imm
        else controlsD = 10'b0000001001; // DP reg
        2'b01: if (InstrD[20]) controlsD = 10'b0001111000; // LDR
        else controlsD = 10'b1001110100; // STR
        2'b10: controlsD = 10'b0110100010; // B
        default: controlsD = 10'bx; //unimplemented
    endcase
assign {RegSrcD, ImmSrcD, ALUSrcD, MemtoRegD, RegWriteD, MemWriteD, BranchD, ALUOpD} = controlsD;
always_comb
    if (ALUOpD) 
    begin // which Data-processing Instr?
        case(InstrD[24:21])
            4'b0100: ALUControlD = 2'b00; // ADD
            4'b0010: ALUControlD = 2'b01; // SUB
            4'b0000: ALUControlD = 2'b10; // AND
            4'b1100: ALUControlD = 2'b11; // ORR
            default: ALUControlD = 2'bx; // unimplemented
        endcase
        FlagWriteD[1] = InstrD[20]; // update N and Z Flags if S bit is set
        FlagWriteD[0] = InstrD[20] & (ALUControlD == 2'b00 | ALUControlD == 2'b01);
    end 
    else 
    begin
        ALUControlD = 2'b00; // perform addition for non-dataprocessing instr
        FlagWriteD = 2'b00; // don't update Flags
    end
assign PCSrcD = (((InstrD[15:12] == 4'b1111) & RegWriteD) | BranchD);
// Execute stage
floprc#(7) flushedregsE(clk, reset, FlushE, {FlagWriteD, BranchD, MemWriteD, RegWriteD, PCSrcD, MemtoRegD}, {FlagWriteE, BranchE, MemWriteE, RegWriteE, PCSrcE, MemtoRegE});
flopr #(3) regsE(clk, reset, {ALUSrcD, ALUControlD}, {ALUSrcE, ALUControlE});
flopr #(4) condregE(clk, reset, InstrD[31:28], CondE);
flopr #(4) flagsreg(clk, reset, FlagsNextE, FlagsE);
// write and Branch controls are conditional
conditional Cond(CondE, FlagsE, ALUFlagsE, FlagWriteE, CondExE, FlagsNextE);
//EDITED LOGIC
//assign BranchTakenE = BranchE & CondExE ;
assign BranchTakenE_for_predictor = BranchE & CondExE ;
assign BranchTakenE = BranchE & CondExE & ~Correct_addr_prediction;
//
assign RegWriteGatedE = RegWriteE & CondExE;
assign MemWriteGatedE = MemWriteE & CondExE;
assign PCSrcGatedE = PCSrcE & CondExE;
// Memory stage
flopr #(4) regsM(clk, reset, {MemWriteGatedE, MemtoRegE, RegWriteGatedE, PCSrcGatedE}, {MemWriteM, MemtoRegM, RegWriteM, PCSrcM});
// Writeback stage
flopr #(3) regsW(clk, reset, {MemtoRegM, RegWriteM, PCSrcM}, {MemtoRegW, RegWriteW, PCSrcW});
// Hazard Prediction
assign PCWrPendingF = PCSrcD | PCSrcE | PCSrcM;
endmodule
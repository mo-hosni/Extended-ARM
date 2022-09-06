module BTB (
    input clk, reset,
    input [31:0] PC,
    input BranchE,
    input [31:0] branch_address_Execute,
    output logic [31:0] b_address,
    output logic hit
);
//
logic [3:0] PC_buff1, PC_delayed1, PC_buff2, PC_delayed2;
// memory
logic [58:0] memory [15:0]; // the memory line is: {1-bit busy, tag 26-bit, branch address from execute phase 32-bit}
// write
mux2 #(4) buffer1 (PC[5:2], PC[5:2], 1'b0, PC_buff1);
flopr #(4) pc_reg1 (clk, reset, PC_buff1, PC_delayed1);
mux2 #(4) buffer2 (PC_delayed1, PC_delayed1, 1'b0, PC_buff2);
flopr #(4) pc_reg2 (clk, reset, PC_buff2, PC_delayed2);
//
always_ff@(negedge clk, posedge reset) 
begin
    if(reset)
        for(integer i = 0; i < 16; i = i + 1)
            memory [i] <= 0;
    else if (BranchE)
        if(~(memory [PC_delayed2] [58]))
            memory[PC_delayed2] <= {1'b1, PC[31:6], branch_address_Execute};
end
// read
assign b_address = memory [(PC[5:2])] [31:0];
assign hit = (memory [(PC[5:2])] [57:32] == PC[31:6]) & (memory [(PC[5:2])] [58]); 
endmodule
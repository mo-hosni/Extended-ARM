module pattern_state_table #(parameter DW = 4)(
    input clk, reset, en_taken,
    input [DW-1:0] Waddr, Raddr,
    input [1:0] next_state,
    output logic [1:0] current_state, state_for_pred
);
// memory
logic [1:0] memory [2**DW-1:0];
// write
always_ff@(negedge clk, posedge reset) 
begin
    if(reset)
    begin
        for(integer i = 0; i < 2**DW; i = i + 1)
            memory [i] <= 2'b01;
    end
    else if (en_taken)
        memory [Waddr] <= next_state;
end
// read
always_ff@(posedge clk, posedge reset) 
begin
    if(reset)
        current_state <= 0;
    else
        current_state <= memory [Waddr];
end
//
assign state_for_pred =  memory [Raddr];
endmodule
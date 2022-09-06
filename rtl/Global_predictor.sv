module Global_predictor (
    input clk, reset, branch,
    input [3:0] PC,
    input taken,
    output prediction
);
//
logic en_taken_buff1, en_taken_buff2, en_taken;
logic [1:0] current_state, next_state, state_for_pred;
logic [3:0] Waddr, Raddr;
//en_taken logic
always_ff@(posedge clk, posedge reset)
begin
    if(reset)
    begin
        en_taken <= 0;
        en_taken_buff1 <= 0;
    end
    else
    begin
        en_taken <= en_taken_buff1;
        en_taken_buff1 <= branch;
    end
end
//shift register for GR and memory address calculation
logic [3:0] GR_SR;
always_ff@(posedge clk, posedge reset)
begin
    if(reset)
        GR_SR <= 0;
    else if (en_taken)
        GR_SR <= {taken, GR_SR[3:1]}; //shifting the GR 
end
//
always_ff@(posedge clk, posedge reset)
begin
    if(reset)
    begin
        Waddr <= 0;
    end
    else if (branch) 
        Waddr = PC^GR_SR; //computing the write address of the pattern state table 
end
//
assign Raddr = PC^GR_SR; //computing the read address of the pattern state table 
//
pattern_state_table #(4) memory_instance (.clk(clk), .reset, .en_taken, .Waddr, .Raddr, .next_state, .current_state, .state_for_pred);
//next state logic 
always_comb
begin
    begin
        case (current_state)
        2'b00: //strong not taken 
            if(taken)
                next_state = 2'b01;
            else
                next_state = 2'b00;
        2'b01: //weak not taken 
            if(taken)
                next_state = 2'b11;
            else
                next_state = 2'b00;
        2'b11: //strong taken 
            if(taken)
                next_state = 2'b11;
            else
                next_state = 2'b10;
        2'b10: //weak taken 
            if(taken)
                next_state = 2'b11;
            else
                next_state = 2'b00;
        default: next_state = 2'b00;
        endcase
    end
end
//output logic
assign prediction = ((state_for_pred == 2'b11) || (state_for_pred == 2'b10)) && branch;
//
endmodule
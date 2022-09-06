// ARM pipelined processor
module testbench();
logic clk;
logic reset;
logic [31:0] WriteData, DataAdr;
logic MemWrite;
// instantiate device to be tested
top dut(clk, reset, WriteData, DataAdr, MemWrite);
// initialize test
initial
begin
    reset <= 1; # 22; reset <= 0;
end
// generate clock to sequence tests
always
begin
    clk <= 1; # 5; clk <= 0; # 5;
end
//

initial 
begin
    int fd;
    fd = $fopen("./output.txt", "w");
    if (fd)
        $display("File opend successfuly");
    else
        $display("Failed to open file");
    forever 
    begin
        @(negedge clk)
        begin
            $display("%h", dut.InstrF);
            if(dut.InstrF == 32'he04f000f)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " SUB R0, R15, R15            ");
            else if(dut.InstrF == 32'he2801032)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " ADD R1, R0, #50             ");
            else if(dut.InstrF == 32'he2802004)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " OUTER_LOOP: ADD R2, R0, #4  ");
            else if(dut.InstrF == 32'he2833001)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " INNER_LOOP: ADD R3, R3, #1  ");
            else if(dut.InstrF == 32'he2834002)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " ADD R4, R3, #2              ");
            else if(dut.InstrF == 32'he2803003)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " ADD R3, R0, #3              ");
            else if(dut.InstrF == 32'he2522001)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " SUBS R2, R2, #1             ");
            else if(dut.InstrF == 32'h1afffffa)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " BNE FOR_INNER               ");
            else if(dut.InstrF == 32'he2855002)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " ADD R5, R5, #2              "); 
            else if(dut.InstrF == 32'he2856002)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " ADD R6, R5, #2              ");
            else if(dut.InstrF == 32'he2511001)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " SUBS R1, R1, #1             ");
            else if(dut.InstrF == 32'h1afffff5)
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " BNE FOR_OUTER               ");
            else
                $fwrite(fd, "PC: %.4d | ", dut.PCF, " XXXX XXXX                   ");
            $fwrite(fd, " ", "   |   REGISTER FILE: R0 = %.3d, R1 = %.3d, R2 = %.3d, R3 = %.3d, R4 = %.3d, R5 = %3d, R6 = %.3d\n", dut.arm.dp.rf.rf[0], dut.arm.dp.rf.rf[1], dut.arm.dp.rf.rf[2], dut.arm.dp.rf.rf[3], dut.arm.dp.rf.rf[4], dut.arm.dp.rf.rf[5], dut.arm.dp.rf.rf[6]);
        end
    end
    #12000;
    $fclose(fd);
    $stop;
end
// always@(negedge clk)
// begin
//     $display("%h", dut.InstrF);
//     $fwrite(dut.InstrF);
// end
// check results

endmodule
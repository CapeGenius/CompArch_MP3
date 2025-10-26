`timescale  10ns/10ns
`include "top.sv"

module game_of_life_tb;

    logic clk = 0;
    logic SW = 1'b1;
    logic BOOT = 1'b1;
    logic _48b;
    logic _45a;

    top #() u1 (
        .clk        (clk),
        .SW         (SW),
        .BOOT       (BOOT),
        ._48b       (_48b),
        ._45a       (_45a)
    );

    initial begin
        $dumpfile("game_of_life_tb.vcd");
        $dumpvars(0, game_of_life_tb);
        #90000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
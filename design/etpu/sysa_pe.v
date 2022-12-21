`default_nettype none
`timescale 1ns/1ns

module pe
    (
        input clk,
        input rst,
        input en,
        input [15:0] up,
        input [7:0] left,
        input [7:0] w,
        output reg [7:0] right,
        output reg [15:0] down
    );

    
    always@ (posedge clk) 
    begin
        if(rst) 
            begin
                right <= 8'b0;
                down <= 16'b0;
            end
        else if (en)
            begin
                down <= left * w + up;
                right <= left;
            end
        else 
            begin
                right <= right;
                down <= down;
            end
    end
endmodule

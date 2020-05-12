`include "parameters.vh"
module modAdder(   
    input clk,
    input enable,
    input  [`DATAWIDTH -1 : 0] a,
    input  [`DATAWIDTH -1 : 0] b,
    output                  outputReady,
    output [`DATAWIDTH -1 : 0] sum);

localparam START 	   = 1'b0;
localparam RESULTREADY = 1'b1;

reg state;



reg  [`DATAWIDTH   	 : 0]   difference, result;
reg                         ready,finished;
always @(posedge clk)begin
case(state)
START:
      if(finished)
        state = RESULTREADY;  
RESULTREADY:
    if(!finished)
        state = START;
default: 
    state = START;        
endcase
end
always @(posedge clk) begin
case(state) 
START:
    if(enable)begin
        difference = a + b -`p;
        ready      = 1'b0;
        finished   = 1'b1;   
    end    
RESULTREADY:   
    begin
        result     = difference[`DATAWIDTH] ? difference + `p : difference;
        ready      = 1'b1;
        finished   = 1'b0;
    end    
endcase    
end   


	assign sum         = result [`DATAWIDTH - 1 : 0];
	assign outputReady = ready;

endmodule

	

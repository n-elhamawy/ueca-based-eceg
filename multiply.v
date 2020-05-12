`include "parameters.vh"
module multiply(
    input                       clk,
    input                       enable,
    input   [`DATAWIDTH       : 0] multiplicand,
    input   [`DATAWIDTH       : 0] multiplier,
    output  [2*`DATAWIDTH - 1 : 0] product,
    output                       ready
    );


integer i;
localparam IDLE     = 2'b00;
localparam INDEX    = 2'b01;
localparam COMPUTE  = 2'b10;
localparam  READY   = 2'b11;

reg [2*`DATAWIDTH - 1 : 0] result, r;
reg [`DATAWIDTH       : 0]  m,n;
reg                         sign;
reg [1 : 0]                 state;
reg skip,start,outReady,finished;
always@(posedge clk)begin
case(state)
IDLE:
    if(start)
        if(skip)
            state = READY;
        else    
            state = INDEX;
INDEX:
    if(finished)
        state = COMPUTE;        
COMPUTE:
    if(i < 0)
        state = READY;
READY:
    if(outReady)
        state = IDLE;
default: state = IDLE;            
endcase
end
always@(posedge clk)begin
case(state)
IDLE:
    begin
        if(enable)begin
            outReady  = 1'b0;
            i         = `DATAWIDTH - 1;
            skip      = (multiplier == 'h1 |multiplier == 'h0 | multiplicand == 'h1 |multiplicand == 'h0)? 1'b1 : 1'b0;
            m         =  multiplier[`DATAWIDTH]? ~multiplier + 1 : multiplier;
            result    =  'h0;
            n         = multiplicand[`DATAWIDTH]? ~multiplicand + 1 : multiplicand;
            start     = 1'b1;
            finished  = 1'b0;
            sign      = multiplicand[`DATAWIDTH] ^ multiplier[`DATAWIDTH];
        end
        else 
            start = 1'b0;
    end            
INDEX:
    if(m[i] == 1'b1)begin
        i        = i - 1;
        result   = n;
        finished = 1'b1;
    end    
    else begin
        finished = 1'b0;
        i        = i - 1;
   end
COMPUTE:
    begin
        result = result << 1;
        if(m[i] == 1'b1)
            result = result + n;
        i = i - 1;
    end        
READY:
    begin
        if(skip)begin
            if(m == 'h0 | n == 'h0)
                r = 'h0;
            else if(m == 'h1)
                r = n;
            else 
                r = m;
        end            
        else
                r  = result;					 
        outReady = 1'b1;
    end
endcase
end 

assign ready   = outReady;
assign product = sign ? ~r + 1 : r;
          
endmodule

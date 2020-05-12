`include "parameters.vh"
module moduloP(
    input                         clk,
    input                         enable,
    input  [2*`DATAWIDTH + 1 : 0] x,
    output [`DATAWIDTH   - 1 : 0] result,
    output                        ready
    );
    
/*Variables*/
integer i; 
integer shiftBy;
reg                         start,finished,outputReady,goBack,skip;
reg  [2*`DATAWIDTH + 1 : 0] a,b;
reg  [  `DATAWIDTH - 1 : 0] finalResult;

/*FSM variables*/
reg [2 : 0] state;
localparam IDLE      = 3'h0;
localparam FINDINDEX = 3'h1;
localparam CHECK     = 3'h2;
localparam SUBTRACT  = 3'h3;
localparam OUTREADY  = 3'h4;

always @(posedge clk)begin
case (state)
IDLE:
    if(start)
        if(skip)
            state = OUTREADY;
        else
            state = FINDINDEX;    
FINDINDEX:
    if(finished)
        if(skip)
            state = OUTREADY;
        else        
            state = CHECK;
CHECK:
    state = SUBTRACT;                  
SUBTRACT:
    state = OUTREADY;      
OUTREADY:
    if(finished)
        if(a > `p)
            state = FINDINDEX;
        else
            state = IDLE;    
default: state = IDLE;
endcase
end

always @(posedge clk)begin
case (state)
IDLE:
    begin
        if(enable)begin
            i        = 2*`DATAWIDTH + 1;
            shiftBy  =   `DATAWIDTH + 2;
            outputReady = 1'b0;
            skip     = (x < `p)? 1'b1 : 1'b0;
            a        = x;
            finished = 1'b0;
            goBack   = 1'b0;
            start    = 1'b1;
        end   
        else
            start = 1'b0;
    end                       
FINDINDEX:
    begin 
        if(a[i]) begin
        b        = `p << shiftBy;
        finished = 1'b1;
        end
        else begin
            i        = i - 1;
            shiftBy  = shiftBy - 1;
            finished = 1'b0; 
         end
    end     
CHECK:
    if( b > a )
        if( i > `DATAWIDTH - 1)
            b = b >> 1;                
SUBTRACT:
    begin 
        a      = a - b;         
        goBack = 1'b0;
    end    
OUTREADY:
    begin
        goBack      = (i > `DATAWIDTH)? 1'b1 : 1'b0;   
        outputReady = (a < `p)? 1'b1 : 1'b0;
        finished = 1'b1;
    end   
endcase
end

assign result = a[`DATAWIDTH - 1 : 0];
assign ready  = outputReady;
endmodule

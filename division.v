`include "parameters.vh"
module division(
    input                        clk,
    input                        enable,
    input  [`DATAWIDTH - 1 : 0 ] dividend,
    input  [`DATAWIDTH - 1 : 0 ] divisor,
    output                       ready,
    output [`DATAWIDTH - 1 : 0 ] quotient,
    output [`DATAWIDTH -1  : 0 ] remainder
    );
     
 /*Variables*/
 integer i,j,k,indexA,indexB;
 reg                         start,foundA,foundB,finished,outReady,goBack,skip;
 reg  [  `DATAWIDTH - 1 : 0] a,b,c,d,q,r,shift;
 
 /*FSM variables*/
 reg [2 : 0] state;
 localparam IDLE      = 3'h0;
 localparam FINDINDEX = 3'h1;
 localparam SHIFT     = 3'h2;
 localparam CHECK     = 3'h3;
 localparam SUBTRACT  = 3'h4;
 localparam OUTREADY  = 3'h5;
 
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
        state = SHIFT;
SHIFT:
    if(skip)
        state = SUBTRACT;
    else    
        state = CHECK;         
CHECK:
 state = SUBTRACT;                  
SUBTRACT:
 state = OUTREADY;      
OUTREADY:
     if(goBack)
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
         outReady = 1'b0;
         skip     = dividend < divisor | divisor == `DATAWIDTH'h1 ? 1'b1 : 1'b0;
         a        = dividend;
         b        = divisor;
         d        = divisor;
         c        =  'h0;
         shift    =  'h0;
         finished = 1'b0;
         goBack   = 1'b0;
         start    = 1'b1;
         foundA   = 1'b0;
         foundB   = 1'b0;
         indexA   = `DATAWIDTH - 1;
         indexB   = `DATAWIDTH - 1;
     end   
     else
         start = 1'b0;
 end                       
FINDINDEX:
 begin 
    
    //FIND MSB (a)
    if(a[indexA]) 
        foundA = 1'b1;
    else
        indexA = indexA - 1;
        
      //FIND MSB (b) only once
     if(!foundB)begin
        if(b[indexB]) 
            foundB = 1'b1;
         else
             indexB = indexB - 1;
         end
      finished = foundA & foundB;   
     end
SHIFT:
    begin   
        b      = b <<(indexA - indexB);
        shift  = indexA - indexB;
    end         
CHECK:
 if( b > a )
     begin
         b     = b >> 1;
         shift = indexA - indexB - 1;
     end                    
SUBTRACT:
 begin 
     a      = a - b;
     c      = c + (1'b1 << shift);
     goBack = 1'b0;
     foundA = 1'b0;
 end    
OUTREADY:
 begin
     if(a < d) begin   
        outReady = 1'b1;
        r        = a;
        q        = c;
     end
     else begin
        goBack = 1'b1;
        b      = d;
     end      
 end   
endcase
end

assign remainder = r;
assign quotient  = q;
assign ready     = outReady;
endmodule

